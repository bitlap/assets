import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../config/app_config.dart';
import '../models/stock_search_models.dart';
import 'circuit_breaker.dart';

class EastMoneyQuoteService {
  static final EastMoneyQuoteService _instance =
      EastMoneyQuoteService._internal();
  factory EastMoneyQuoteService() => _instance;
  EastMoneyQuoteService._internal();

  final CircuitBreaker _breaker = CircuitBreaker();
  static const String _batchBaseUrl =
      'https://push2.eastmoney.com/api/qt/ulist.np/get';

  Future<void> fetchBatch(
    List<StockSearchResult> stocks,
    void Function(String secid, StockQuote quote) onQuote,
  ) async {
    if (stocks.isEmpty) return;
    if (_breaker.isInCooldown) {
      debugPrint('[东方财富] ⏸️ 冷却中，跳过批量');
      return;
    }

    debugPrint('[东方财富] 📊 批量查询: ${stocks.length}只');

    try {
      final secids = stocks.map((s) => s.secid).join(',');
      final client = Client();
      final uri = Uri.parse(
        '$_batchBaseUrl?secids=$secids'
        '&fields=f57,f58',
      );

      final response = await client
          .get(uri)
          .timeout(Duration(seconds: DevConfig.httpTimeoutSec));
      client.close();
      _breaker.onSuccess();

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>?;
        final rawData = body?['data'];
        final diffList = (rawData is Map ? rawData['diff'] : rawData) as List?;
        if (diffList != null) {
          for (int i = 0; i < stocks.length && i < diffList.length; i++) {
            final item = diffList[i];
            if (item is! Map<String, dynamic>) continue;
            final stock = stocks[i];
            final code = stock.code;
            final secid = stock.secid;

            final quote = _parseItem(item, stock);
            if (quote == null) continue;
            onQuote(secid, quote);
            debugPrint(
              '[东方财富] ✅ $code: USD${quote.currentPrice} (${quote.changePercent}%)',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[东方财富] ❌ 批量失败: $e');
      _breaker.onFailure();
    }
  }

  StockQuote? _parseItem(Map<String, dynamic> item, StockSearchResult? stock) {
    if (stock == null) return null;
    final rawPrice = _parseInt(item['f58']) / 1000 / 1000;
    if (rawPrice == 0) return null;

    final changePercent = _parseDouble(item['f57']);

    final market = stock.market;

    final logoUrl = market == DevConfig.searchMarketUS
        ? 'https://logos.stocktwits-cdn.com/${stock.code.toUpperCase()}.png?w=64'
        : null;

    return StockQuote(
      code: stock.code,
      name: stock.name,
      currentPrice: rawPrice,
      changePercent: changePercent,
      market: market,
      logoUrl: logoUrl,
    );
  }

  double _parseInt(dynamic value) {
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
}
