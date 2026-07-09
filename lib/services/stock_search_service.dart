import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

typedef _CachedAt = DateTime;

/// 股票搜索结果模型
class StockSearchResult {
  final String code;       // 股票代码，如 AAPL, 00700
  final String name;       // 股票名称
  final String market;     // 市场标识：美股、港股
  final String secid;      // 东方财富 secid，如 105.AAPL, 116.00700
  final String? exchange;  // 交易所名称

  StockSearchResult({
    required this.code,
    required this.name,
    required this.market,
    required this.secid,
    this.exchange,
  });
}

/// 股票实时行情
class StockQuote {
  final String code;
  final String name;
  final double currentPrice;
  final double changePercent;
  final String market;
  final String? logoUrl;

  StockQuote({
    required this.code,
    required this.name,
    required this.currentPrice,
    required this.changePercent,
    required this.market,
    this.logoUrl,
  });
}

/// 股票搜索服务 - 使用东方财富 API（AKShare 底层数据源）
/// 单例模式：缓存和熔断状态跨 dialog 持久化，避免重复请求被封IP
class StockSearchService {
  // 单例
  static final StockSearchService _instance = StockSearchService._internal();
  factory StockSearchService() => _instance;
  StockSearchService._internal();

  static const String _searchBaseUrl =
      'https://searchapi.eastmoney.com/api/suggest/get';
  static const String _tencentQuoteBaseUrl =
      'https://qt.gtimg.cn/q=';
  static const String _searchToken = 'D43BF722C8E33BDC906FB84D85E326E8';

  // 不再复用共享 Client，每次请求都新建，避免连接异常后持续失败

  /// 行情缓存：secid -> (缓存时间, StockQuote)
  final Map<String, (_CachedAt, StockQuote?)> _quoteCache = {};
  static const Duration _cacheTTL = Duration(minutes: 10);

  /// 搜索缓存：keyword -> (缓存时间, 搜索结果)
  final Map<String, (_CachedAt, List<StockSearchResult>)> _searchCache = {};
  static const Duration _searchCacheTTL = Duration(minutes: 5);

  /// 熔断机制：连续失败后进入冷却期，不再发请求
  int _consecutiveFailures = 0;
  DateTime? _cooldownUntil;
  static const int _failureThreshold = 3;  // 失败 3 次就熔断
  static const Duration _cooldownDuration = Duration(minutes: 5); // 冷却 5 分钟（IP被封需要更长恢复时间）

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
      debugPrint('请求连续失败$_consecutiveFailures次，进入冷却期${_cooldownDuration.inSeconds}秒');
    }
  }


  /// 搜索股票（支持港股、美股，按名称或代码搜索）
  Future<List<StockSearchResult>> searchStocks(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    // 先查搜索缓存，同样的关键词不重复请求
    final cachedSearch = _searchCache[keyword];
    if (cachedSearch != null &&
        DateTime.now().difference(cachedSearch.$1) < _searchCacheTTL) {
      debugPrint('搜索命中缓存: $keyword');
      return cachedSearch.$2;
    }

    // 搜索 API 也受熔断保护
    if (_isInCooldown) {
      debugPrint('处于冷却期，跳过搜索请求');
      return cachedSearch?.$2 ?? [];
    }

    Client? client;
    try {
      final uri = Uri.parse(
        '$_searchBaseUrl?input=${Uri.encodeComponent(keyword)}'
        '&type=14&token=$_searchToken&count=20',
      );

      client = Client();
      final response = await client.get(uri).timeout(
        const Duration(seconds: 10),
      );
      client.close();
      client = null;

      if (response.statusCode == 200) {
        _onRequestSuccess();
        final data = json.decode(response.body);
        final results = _parseSearchResults(data);
        // 缓存搜索结果
        _searchCache[keyword] = (DateTime.now(), results);
        return results;
      }
      return [];
    } catch (e) {
      client?.close();
      debugPrint('搜索股票失败: $e');
      _onRequestFailure();
      return [];
    }
  }

  /// 解析搜索结果
  List<StockSearchResult> _parseSearchResults(Map<String, dynamic> data) {
    final results = <StockSearchResult>[];
    final quoteList = data['QuotationCodeTable']?['Data'];
    if (quoteList == null) return results;

    for (final item in quoteList) {
      final code = item['Code']?.toString() ?? '';
      final name = item['Name']?.toString() ?? '';
      final marketId = item['MktNum']?.toString() ?? '';
      final exchange = item['ExchangeName']?.toString() ?? '';

      // 只保留港股和美股
      String? market;
      String? secid;
      switch (marketId) {
        case '105': // 纳斯达克
        case '106': // 纽约证券交易所
          market = '美股';
          secid = '$marketId.$code';
          break;
        case '116': // 港股
          market = '港股';
          secid = '$marketId.$code';
          break;
        default:
          // 也接受通过 SecurityTypeName 判断的港美股
          if (exchange.contains('纳斯达克') ||
              exchange.contains('纽约') ||
              exchange.contains('美国')) {
            market = '美股';
            secid = '105.$code';
          } else if (exchange.contains('港股') || exchange.contains('香港')) {
            market = '港股';
            secid = '116.$code';
          }
          break;
      }

      if (market != null && secid != null && code.isNotEmpty) {
        results.add(StockSearchResult(
          code: code,
          name: name,
          market: market,
          secid: secid,
          exchange: exchange,
        ));
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
    final now = DateTime.now();

    // 1. 从缓存中取有效的
    for (final stock in stocks) {
      final cached = _quoteCache[stock.secid];
      if (cached != null && now.difference(cached.$1) < _cacheTTL) {
        result[stock.secid] = cached.$2;
      } else {
        needFetch.add(stock);
      }
    }

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
      debugPrint('处于冷却期，跳过行情请求: ${stock.secid}');
      return null;
    }

    try {
      // 腾讯API格式：https://qt.gtimg.cn/q=usAAPL, hk00700
      final prefix = stock.market == '美股' ? 'us' : 'hk';
      final symbol = '$prefix${stock.code}';
      
      final client = Client();
      final uri = Uri.parse('$_tencentQuoteBaseUrl$symbol');

      final response = await client.get(uri).timeout(
        const Duration(seconds: 10),
      );
      client.close();
      _onRequestSuccess();

      if (response.statusCode == 200) {
        final quote = _parseTencentQuote(response.body, stock);
        _quoteCache[stock.secid] = (DateTime.now(), quote);
        return quote;
      }
      return null;
    } catch (e) {
      debugPrint('腾讯API获取行情失败: $e');
      _onRequestFailure();
      return null;
    }
  }

  /// 根据股票代码和市场类型生成 Logo URL
  /// 美股：使用 StockTwits CDN（免费、无需 API key）
  /// 港股：暂无免费 CDN 支持，返回 null（UI 会显示 fallback）
  static String? getLogoUrl(String code, String market) {
    if (market == '美股') {
      // StockTwits CDN: 免费美股 logo CDN，支持所有 US ticker
      return 'https://logos.stocktwits-cdn.com/${code.toUpperCase()}.png?w=64';
    } else if (market == '港股') {
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
      debugPrint('解析腾讯行情数据失败: $e');
      return null;
    }
  }

  /// 获取缓存中的行情（不发起网络请求，仅查缓存）
  StockQuote? getCachedQuote(String secid) {
    final cached = _quoteCache[secid];
    if (cached != null && DateTime.now().difference(cached.$1) < _cacheTTL) {
      return cached.$2;
    }
    return null;
  }

  /// 获取单只股票实时行情（使用腾讯API，无重试，带熔断 + 缓存）
  Future<StockQuote?> getStockQuote(StockSearchResult stock) async {
    // 先查缓存
    final cached = _quoteCache[stock.secid];
    if (cached != null && DateTime.now().difference(cached.$1) < _cacheTTL) {
      return cached.$2;
    }

    // 熔断中，不发请求
    if (_isInCooldown) {
      debugPrint('处于冷却期，跳过行情请求: ${stock.secid}');
      return null;
    }

    try {
      // 腾讯API格式：https://qt.gtimg.cn/q=usAAPL, hk00700
      final prefix = stock.market == '美股' ? 'us' : 'hk';
      final symbol = '$prefix${stock.code}';
      
      final client = Client();
      final uri = Uri.parse('$_tencentQuoteBaseUrl$symbol');

      final response = await client.get(uri).timeout(
        const Duration(seconds: 10),
      );
      client.close();
      _onRequestSuccess();

      if (response.statusCode == 200) {
        final quote = _parseTencentQuote(response.body, stock);
        _quoteCache[stock.secid] = (DateTime.now(), quote);
        return quote;
      }
      return null;
    } catch (e) {
      debugPrint('腾讯API获取行情失败: $e');
      _onRequestFailure();
      return null;
    }
  }
}
