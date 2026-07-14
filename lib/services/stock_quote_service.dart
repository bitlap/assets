import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../config/app_config.dart';
import '../models/stock_search_models.dart';
import 'circuit_breaker.dart';

class StockQuoteService {
  static final StockQuoteService _instance = StockQuoteService._internal();
  factory StockQuoteService() => _instance;
  StockQuoteService._internal();

  final CircuitBreaker _breaker = CircuitBreaker();
  static const String _tencentQuoteBaseUrl = 'https://qt.gtimg.cn/q=';

  final Map<String, DateTime> _quoteCacheTime = {};
  final Map<String, StockQuote?> _quoteCacheValue = {};
  static const Duration _cacheTTL = Duration(
    minutes: DevConfig.quoteCacheTTLMin,
  );

  int get cooldownRemainingSeconds => _breaker.cooldownRemainingSeconds;

  Future<StockQuote?> getStockQuote(StockSearchResult stock) async {
    final cachedTime = _quoteCacheTime[stock.secid];
    if (cachedTime != null &&
        DateTime.now().difference(cachedTime) < _cacheTTL) {
      return _quoteCacheValue[stock.secid];
    }
    return _fetchTencentQuote(stock);
  }

  Future<Map<String, StockQuote?>> getStockQuotesBatch(
    List<StockSearchResult> stocks,
  ) async {
    final result = <String, StockQuote?>{};
    final needFetch = <StockSearchResult>[];
    final seenSecids = <String>{};
    final now = DateTime.now();

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

    for (final stock in needFetch) {
      final quote = await _fetchTencentQuote(stock);
      result[stock.secid] = quote;
    }

    return result;
  }

  StockQuote? getCachedQuote(String secid) {
    final cachedTime = _quoteCacheTime[secid];
    if (cachedTime != null &&
        DateTime.now().difference(cachedTime) < _cacheTTL) {
      return _quoteCacheValue[secid];
    }
    return null;
  }

  static String? getLogoUrl(String code, String market) {
    if (market == DevConfig.searchMarketUS) {
      return 'https://logos.stocktwits-cdn.com/${code.toUpperCase()}.png?w=64';
    } else if (market == DevConfig.searchMarketHK) {
      return null;
    }
    return null;
  }

  Future<StockQuote?> _fetchTencentQuote(StockSearchResult stock) async {
    if (_breaker.isInCooldown) {
      debugPrint('[行情] ⏸️ 冷却期中，跳过: ${stock.code}');
      return null;
    }

    try {
      final prefix = stock.market == DevConfig.searchMarketUS ? 'us' : 'hk';
      final symbol = '$prefix${stock.code}';

      final client = Client();
      final uri = Uri.parse('$_tencentQuoteBaseUrl$symbol');

      final response = await client
          .get(uri)
          .timeout(Duration(seconds: DevConfig.httpTimeoutSec));
      client.close();
      _breaker.onSuccess();

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
      _breaker.onFailure();
      return null;
    }
  }

  StockQuote? _parseTencentQuote(String responseBody, StockSearchResult stock) {
    try {
      final match = RegExp(r'"([^"]+)"').firstMatch(responseBody);
      if (match == null) return null;

      final content = match.group(1)!;
      final parts = content.split('~');

      if (parts.length < 5) return null;

      final name = stock.name;
      final code = stock.code;
      final currentPrice = double.tryParse(parts[3]) ?? 0.0;

      if (currentPrice == 0.0) return null;

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
}
