import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../config/app_config.dart';
import '../models/stock_search_models.dart';

/// 股票搜索服务 - 使用东方财富 API（AKShare 底层数据源）
/// 单例模式：缓存和熔断状态跨 dialog 持久化，避免重复请求被封IP
class StockSearchService {
  // 单例
  static final StockSearchService _instance = StockSearchService._internal();
  factory StockSearchService() => _instance;
  StockSearchService._internal();

  static const String _searchBaseUrl =
      'https://searchapi.eastmoney.com/api/suggest/get';
  static const String _tencentQuoteBaseUrl = 'https://qt.gtimg.cn/q=';
  static const String _searchToken = 'D43BF722C8E33BDC906FB84D85E326E8';

  // 不再复用共享 Client，每次请求都新建，避免连接异常后持续失败

  /// 行情缓存：secid -> 缓存时间 / StockQuote
  final Map<String, DateTime> _quoteCacheTime = {};
  final Map<String, StockQuote?> _quoteCacheValue = {};
  static const Duration _cacheTTL = Duration(
    minutes: DevConfig.quoteCacheTTLMin,
  );

  /// 搜索缓存：keyword -> 缓存时间 / 搜索结果
  final Map<String, DateTime> _searchCacheTime = {};
  final Map<String, List<StockSearchResult>> _searchCacheValue = {};
  static const Duration _searchCacheTTL = Duration(
    minutes: DevConfig.searchCacheTTLMin,
  );

  /// 熔断机制：连续失败后进入冷却期，不再发请求
  int _consecutiveFailures = 0;
  DateTime? _cooldownUntil;
  static const int _failureThreshold = DevConfig.failureThreshold;
  static const Duration _cooldownDuration = Duration(
    minutes: DevConfig.cooldownDurationMin,
  );

  /// 是否在冷却中
  bool get _isInCooldown {
    if (_cooldownUntil == null) return false;
    if (DateTime.now().isAfter(_cooldownUntil!)) {
      _cooldownUntil = null;
      _consecutiveFailures = 0;
      return false;
    }
    return true;
  }

  /// 冷却剩余秒数（供 UI 显示提示）
  int get cooldownRemainingSeconds {
    if (_cooldownUntil == null) return 0;
    final remaining = _cooldownUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// 记录成功，重置熔断
  void _onRequestSuccess() {
    _consecutiveFailures = 0;
    _cooldownUntil = null;
  }

  /// 记录失败，触发熔断
  void _onRequestFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _failureThreshold) {
      _cooldownUntil = DateTime.now().add(_cooldownDuration);
      debugPrint(
        '[网络] ❌ 连续失败$_consecutiveFailures次，进入冷却期${_cooldownDuration.inMinutes}分钟',
      );
    } else {
      debugPrint('[网络] ❌ 请求失败 ($_consecutiveFailures/$_failureThreshold)');
    }
  }

  /// 搜索股票（支持港股、美股，按名称或代码搜索）
  Future<List<StockSearchResult>> searchStocks(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    // 先查搜索缓存，同样的关键词不重复请求
    final cachedTime = _searchCacheTime[keyword];
    final cachedResults = _searchCacheValue[keyword];
    if (cachedTime != null &&
        cachedResults != null &&
        DateTime.now().difference(cachedTime) < _searchCacheTTL) {
      debugPrint('[搜索] ✅ 缓存命中: $keyword (${cachedResults.length}条)');
      return cachedResults;
    }

    // 搜索 API 也受熔断保护
    if (_isInCooldown) {
      debugPrint('[搜索] ⏸️ 冷却期中，跳过搜索: $keyword');
      return cachedResults ?? [];
    }

    debugPrint('[搜索] 🔍 搜索: $keyword');
    Client? client;
    try {
      final uri = Uri.parse(
        '$_searchBaseUrl?input=${Uri.encodeComponent(keyword)}'
        '&type=14&token=$_searchToken&count=20',
      );

      client = Client();
      final response = await client
          .get(uri)
          .timeout(Duration(seconds: DevConfig.httpTimeoutSec));
      client.close();
      client = null;

      if (response.statusCode == 200) {
        _onRequestSuccess();
        final data = json.decode(response.body);
        final results = _parseSearchResults(data);
        // 缓存搜索结果
        _searchCacheTime[keyword] = DateTime.now();
        _searchCacheValue[keyword] = results;
        debugPrint('[搜索] ✅ 搜索成功: $keyword -> ${results.length}条结果');
        return results;
      }
      debugPrint('[搜索] ❌ HTTP ${response.statusCode}');
      return [];
    } catch (e) {
      client?.close();
      debugPrint('[搜索] ❌ 搜索失败: $e');
      _onRequestFailure();
      return [];
    }
  }

  /// 解析搜索结果
  List<StockSearchResult> _parseSearchResults(Map<String, dynamic> data) {
    final results = <StockSearchResult>[];
    final seenCodes = <String>{};
    final quoteList = data['QuotationCodeTable']?['Data'];
    if (quoteList == null) return results;

    for (final item in quoteList) {
      final code = item['Code']?.toString() ?? '';
      final name = item['Name']?.toString() ?? '';
      final marketId = item['MktNum']?.toString() ?? '';
      final exchange = item['ExchangeName']?.toString() ?? '';

      // 去重：同一代码只保留第一个
      if (seenCodes.contains(code)) continue;

      // 只保留港股和美股
      String? market;
      String? secid;
      switch (marketId) {
        case '105': // 纳斯达克
        case '106': // 纽约证券交易所
          market = DevConfig.searchMarketUS;
          secid = '$marketId.$code';
          break;
        case '107': // NYSE Arca / 美国证券交易所（ETF等）
          market = DevConfig.searchMarketUS;
          secid = '105.$code';
          break;
        case '116': // 港股
          market = DevConfig.searchMarketHK;
          secid = '$marketId.$code';
          break;
        default:
          // 也接受以 10 开头的美国市场代码
          if (marketId.startsWith('10')) {
            market = DevConfig.searchMarketUS;
            secid = '105.$code';
          } else if (exchange.contains('纳斯达克') ||
              exchange.contains('纽约') ||
              exchange.contains('美国') ||
              exchange.contains('NYSE') ||
              exchange.contains('NASDAQ') ||
              exchange.contains('ARCA')) {
            market = DevConfig.searchMarketUS;
            secid = '105.$code';
          } else if (exchange.contains('港股') || exchange.contains('香港')) {
            market = DevConfig.searchMarketHK;
            secid = '116.$code';
          }
          break;
      }

      if (market != null && secid != null && code.isNotEmpty) {
        results.add(
          StockSearchResult(
            code: code,
            name: name,
            market: market,
            secid: secid,
            exchange: exchange,
          ),
        );
      }
    }

    return results;
  }

  /// 批量获取行情（优先用缓存，只请求未缓存/过期的）
  Future<Map<String, StockQuote?>> getStockQuotesBatch(
    List<StockSearchResult> stocks,
  ) async {
    final result = <String, StockQuote?>{};
    final needFetch = <StockSearchResult>[];
    final seenSecids = <String>{};
    final now = DateTime.now();

    // 1. 从缓存中取有效的（去重 secid）
    for (final stock in stocks) {
      if (seenSecids.contains(stock.secid)) continue;
      seenSecids.add(stock.secid);
      final cachedTime = _quoteCacheTime[stock.secid];
      final cachedValue = _quoteCacheValue[stock.secid];
      if (cachedTime != null && now.difference(cachedTime) < _cacheTTL) {
        result[stock.secid] = cachedValue;
      } else {
        needFetch.add(stock);
      }
    }

    debugPrint(
      '[行情] 📊 批量获取: ${stocks.length}只, 缓存命中${stocks.length - needFetch.length}只, 需请求${needFetch.length}只',
    );

    if (needFetch.isEmpty) return result;

    // 2. 逐个请求未缓存的（腾讯API不支持batch）
    for (final stock in needFetch) {
      final quote = await _fetchTencentQuote(stock);
      result[stock.secid] = quote;
    }

    return result;
  }

  /// 使用腾讯API获取单只股票行情
  Future<StockQuote?> _fetchTencentQuote(StockSearchResult stock) async {
    // 熔断中，不发请求
    if (_isInCooldown) {
      debugPrint('[行情] ⏸️ 冷却期中，跳过: ${stock.code}');
      return null;
    }

    try {
      // 腾讯API格式：https://qt.gtimg.cn/q=usAAPL, hk00700
      final prefix = stock.market == DevConfig.searchMarketUS ? 'us' : 'hk';
      final symbol = '$prefix${stock.code}';

      final client = Client();
      final uri = Uri.parse('$_tencentQuoteBaseUrl$symbol');

      final response = await client
          .get(uri)
          .timeout(Duration(seconds: DevConfig.httpTimeoutSec));
      client.close();
      _onRequestSuccess();

      if (response.statusCode == 200) {
        final quote = _parseTencentQuote(response.body, stock);
        _quoteCacheTime[stock.secid] = DateTime.now();
        _quoteCacheValue[stock.secid] = quote;
        debugPrint(
          '[行情] ✅ ${stock.code}: ¥${quote?.currentPrice ?? "N/A"} (${quote?.changePercent ?? 0}%)',
        );
        return quote;
      }
      debugPrint('[行情] ❌ HTTP ${response.statusCode}: ${stock.code}');
      return null;
    } catch (e) {
      debugPrint('[行情] ❌ 获取失败 ${stock.code}: $e');
      _onRequestFailure();
      return null;
    }
  }

  /// 根据股票代码和市场类型生成 Logo URL
  /// 美股：使用 StockTwits CDN（免费、无需 API key）
  /// 港股：暂无免费 CDN 支持，返回 null（UI 会显示 fallback）
  static String? getLogoUrl(String code, String market) {
    if (market == DevConfig.searchMarketUS) {
      // StockTwits CDN: 免费美股 logo CDN，支持所有 US ticker
      return 'https://logos.stocktwits-cdn.com/${code.toUpperCase()}.png?w=64';
    } else if (market == DevConfig.searchMarketHK) {
      // 港股暂无免费 CDN 支持，返回 null，UI 会显示首字母 fallback
      // 大部分港股可能无法获取，UI 会显示 fallback
      return null;
    }
    return null;
  }

  /// 解析腾讯API返回的行情数据
  /// 格式示例：v_usAAPL="1~Apple Inc~AAPL~173.50~..."
  StockQuote? _parseTencentQuote(String responseBody, StockSearchResult stock) {
    try {
      // 提取引号内的内容
      final match = RegExp(r'"([^"]+)"').firstMatch(responseBody);
      if (match == null) return null;

      final content = match.group(1)!;
      final parts = content.split('~');

      if (parts.length < 5) return null;

      // 注意：腾讯API返回的名称可能是GBK编码的中文，使用东方财富的名称
      String name = stock.name;
      // 腾讯API返回的代码可能带后缀，需要清理为原始代码
      // 使用搜索结果中的原始代码，而不是API返回的代码
      final code = stock.code;
      final currentPrice = double.tryParse(parts[3]) ?? 0.0;

      if (currentPrice == 0.0) return null;

      // 涨跌幅
      double changePercent = 0.0;
      if (parts.length > 32) {
        changePercent = double.tryParse(parts[32]) ?? 0.0;
      }

      return StockQuote(
        code: code,
        name: name,
        currentPrice: currentPrice,
        changePercent: changePercent,
        market: stock.market,
        logoUrl: getLogoUrl(code, stock.market),
      );
    } catch (e) {
      debugPrint('[行情] ❌ 解析失败 ${stock.code}: $e');
      return null;
    }
  }

  /// 获取缓存中的行情（不发起网络请求，仅查缓存）
  StockQuote? getCachedQuote(String secid) {
    final cachedTime = _quoteCacheTime[secid];
    if (cachedTime != null &&
        DateTime.now().difference(cachedTime) < _cacheTTL) {
      return _quoteCacheValue[secid];
    }
    return null;
  }

  /// 获取单只股票实时行情（使用腾讯API，无重试，带熔断 + 缓存）
  Future<StockQuote?> getStockQuote(StockSearchResult stock) async {
    // 先查缓存
    final cachedTime = _quoteCacheTime[stock.secid];
    if (cachedTime != null &&
        DateTime.now().difference(cachedTime) < _cacheTTL) {
      return _quoteCacheValue[stock.secid];
    }
    // 委托给内部获取方法
    return _fetchTencentQuote(stock);
  }
}
