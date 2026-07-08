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
  // 基本面数据
  final double peRatio;        // 市盈率
  final double marketCap;      // 总市值
  final double dividendYield;  // 股息率(%)
  final double annualDividend; // 每股股息

  StockQuote({
    required this.code,
    required this.name,
    required this.currentPrice,
    required this.changePercent,
    required this.market,
    this.logoUrl,
    this.peRatio = 0,
    this.marketCap = 0,
    this.dividendYield = 0,
    this.annualDividend = 0,
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
  static const String _quoteBaseUrl =
      'https://push2.eastmoney.com/api/qt/stock/get';
  static const String _batchQuoteBaseUrl =
      'https://push2.eastmoney.com/api/qt/ulist.np/get';
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
    // if (_isInCooldown) {
    //   debugPrint('处于冷却期，跳过搜索请求');
    //   return cachedSearch?.$2 ?? [];
    // }

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

    // 2. 用批量 API 一次请求所有未缓存的
    final batchResult = await _fetchBatchQuotes(needFetch);
    result.addAll(batchResult);

    return result;
  }

  /// 批量请求行情（单次 HTTP，使用 ulist.np 接口）
  Future<Map<String, StockQuote?>> _fetchBatchQuotes(
    List<StockSearchResult> stocks,
  ) async {
    final result = <String, StockQuote?>{};
    // 建立 code -> secid 映射
    final codeToSecid = {for (final s in stocks) s.code: s.secid};

    // 熔断中，不发请求
    if (_isInCooldown) {
      debugPrint('处于冷却期，跳过批量请求');
      return result;
    }

    try {
      final secids = stocks.map((s) => s.secid).join(',');
      final uri = Uri.parse(
        '$_batchQuoteBaseUrl?secids=$secids'
        '&fields=f43,f44,f45,f46,f47,f57,f58,f59,f116,f117,f162,f163,f167,f170,f171',
      );

      final client = Client();
      final response = await client.get(uri).timeout(
        const Duration(seconds: 10),
      );
      client.close();
      _onRequestSuccess();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final diffList = data['data']?['diff'] as List?;
        if (diffList != null) {
          for (final dc in diffList) {
            final code = dc['f57']?.toString() ?? '';
            final secid = codeToSecid[code];
            if (secid == null) continue;
            final quote = _parseBatchQuoteItem(dc, stocks);
            if (quote != null) {
              result[secid] = quote;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('批量获取行情失败: $e');
      _onRequestFailure();
      // 批量失败不再逐个重试，避免加重封禁
    }

    // 写入缓存
    final now = DateTime.now();
    for (final entry in result.entries) {
      _quoteCache[entry.key] = (now, entry.value);
    }
    // 未返回的也缓存（避免重复请求不存在的）
    for (final stock in stocks) {
      if (!result.containsKey(stock.secid)) {
        _quoteCache[stock.secid] = (now, null);
      }
    }

    return result;
  }

  /// 解析批量行情中的单条
  StockQuote? _parseBatchQuoteItem(
    Map<String, dynamic> dc,
    List<StockSearchResult> stocks,
  ) {
    final rawPrice = _parseInt(dc['f43']);
    if (rawPrice == 0) return null;
    final decimals = _parseInt(dc['f59']).toInt();
    final price = decimals > 0 ? rawPrice / _pow10(decimals) : rawPrice;
    final changePercent = _parseDouble(dc['f170']) / 100;
    final code = dc['f57']?.toString() ?? '';
    final name = dc['f58']?.toString() ?? '';
    final marketCap = _parseDouble(dc['f116']);
    final rawPe = _parseDouble(dc['f163']);
    final peRatio = rawPe > 0 ? rawPe / 100 : (_parseDouble(dc['f162']) / 100);
    final dividendYield = _parseDouble(dc['f167']) / 10000;
    final annualDividend = price * dividendYield / 100;

    // 找到对应的 stock 以获取 market 信息
    final matched = stocks.firstWhere(
      (s) => s.code == code,
      orElse: () => stocks.first,
    );

    return StockQuote(
      code: code,
      name: name,
      currentPrice: price,
      changePercent: changePercent,
      market: matched.market,
      logoUrl: 'https://logo.clearbit.com/${code.toLowerCase()}.com',
      peRatio: peRatio,
      marketCap: marketCap,
      dividendYield: dividendYield,
      annualDividend: annualDividend,
    );
  }

  /// 获取单只股票实时行情（无重试，带熔断 + 缓存）
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
      final client = Client();
      final uri = Uri.parse(
        '$_quoteBaseUrl?secid=${stock.secid}'
        '&fields=f43,f44,f45,f46,f47,f57,f58,f59,f116,f117,f162,f163,f167,f170,f171',
      );

      final response = await client.get(uri).timeout(
        const Duration(seconds: 10),
      );
      client.close();
      _onRequestSuccess();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dc = data['data'];
        if (dc == null) {
          _quoteCache[stock.secid] = (DateTime.now(), null);
          return null;
        }

        final rawPrice = _parseInt(dc['f43']);
        final decimals = _parseInt(dc['f59']).toInt();
        final price = decimals > 0 ? rawPrice / _pow10(decimals) : rawPrice;
        final changePercent = _parseDouble(dc['f170']) / 100;
        final name = dc['f58']?.toString() ?? stock.name;
        final marketCap = _parseDouble(dc['f116']);
        final rawPe = _parseDouble(dc['f163']);
        final peRatio = rawPe > 0 ? rawPe / 100 : (_parseDouble(dc['f162']) / 100);
        final dividendYield = _parseDouble(dc['f167']) / 10000;
        final annualDividend = price * dividendYield / 100;

        final quote = StockQuote(
          code: stock.code,
          name: name,
          currentPrice: price,
          changePercent: changePercent,
          market: stock.market,
          logoUrl: 'https://logo.clearbit.com/${stock.code.toLowerCase()}.com',
          peRatio: peRatio,
          marketCap: marketCap,
          dividendYield: dividendYield,
          annualDividend: annualDividend,
        );
        _quoteCache[stock.secid] = (DateTime.now(), quote);
        return quote;
      }
      return null;
    } catch (e) {
      debugPrint('获取行情失败: $e');
      _onRequestFailure();
      return null;
    }
  }

  /// 解析整数（东方财富返回的原始值）
  double _parseInt(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed ?? 0.0;
  }

  /// 10的n次方
  double _pow10(int n) {
    double result = 1.0;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  /// 解析价格
  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed ?? 0.0;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed ?? 0.0;
  }

  void dispose() {
    // 不再需要关闭共享 client，每次请求已自行管理
  }
}
