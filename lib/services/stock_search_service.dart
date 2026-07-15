import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../config/app_config.dart';
import '../models/stock_search_models.dart';
import 'circuit_breaker.dart';

class StockSearchService {
  static final StockSearchService _instance = StockSearchService._internal();
  factory StockSearchService() => _instance;
  StockSearchService._internal();

  final CircuitBreaker _breaker = CircuitBreaker();
  static const String _searchBaseUrl =
      'https://searchapi.eastmoney.com/api/suggest/get';
  static const String _searchToken = 'D43BF722C8E33BDC906FB84D85E326E8';

  final Map<String, DateTime> _searchCacheTime = {};
  final Map<String, List<StockSearchResult>> _searchCacheValue = {};
  static const Duration _searchCacheTTL = Duration(
    minutes: DevConfig.searchCacheTTLMin,
  );

  int get cooldownRemainingSeconds => _breaker.cooldownRemainingSeconds;

  Future<List<StockSearchResult>> searchStocks(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    final cachedTime = _searchCacheTime[keyword];
    final cachedResults = _searchCacheValue[keyword];
    if (cachedTime != null &&
        cachedResults != null &&
        DateTime.now().difference(cachedTime) < _searchCacheTTL) {
      debugPrint('[搜索] ✅ 缓存命中: $keyword (${cachedResults.length}条)');
      return cachedResults;
    }

    if (_breaker.isInCooldown) {
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
        _breaker.onSuccess();
        final data = json.decode(response.body);
        final results = _parseSearchResults(data);
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
      _breaker.onFailure();
      return [];
    }
  }

  List<StockSearchResult> _parseSearchResults(Map<String, dynamic> data) {
    final results = <StockSearchResult>[];
    final seenCodes = <String>{};
    final quoteList = data['QuotationCodeTable']?['Data'];
    if (quoteList == null) return results;

    for (final item in quoteList) {
      final rawCode = item['Code']?.toString() ?? '';
      final code = rawCode.replaceAll('_', '.');
      final name = item['Name']?.toString() ?? '';
      final marketId = item['MktNum']?.toString() ?? '';
      final exchange = item['ExchangeName']?.toString() ?? '';

      if (seenCodes.contains(code)) continue;

      String? market;
      String? secid;
      switch (marketId) {
        case '105':
        case '106':
          market = DevConfig.searchMarketUS;
          secid = '$marketId.$rawCode';
          break;
        case '107':
          market = DevConfig.searchMarketUS;
          secid = '105.$rawCode';
          break;
        case '116':
          market = DevConfig.searchMarketHK;
          secid = '$marketId.$rawCode';
          break;
        default:
          if (exchange.contains('纳斯达克') ||
              exchange.contains('纽约') ||
              exchange.contains('美国') ||
              exchange.contains('NYSE') ||
              exchange.contains('NASDAQ') ||
              exchange.contains('ARCA')) {
            market = DevConfig.searchMarketUS;
            secid = '105.$rawCode';
          } else if (exchange.contains('港股') || exchange.contains('香港')) {
            market = DevConfig.searchMarketHK;
            secid = '116.$rawCode';
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
}
