import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../config/app_config.dart';
import '../config/stock_config.dart';
import '../models/stock_search_models.dart';
import '../utils/stock_calculator.dart';
import 'stock_quote_service.dart';
import 'settings_service.dart';
import 'icloud_storage.dart';

const String backgroundTaskName = 'profitSnapshotTask';

@pragma('vm:entry-point')
void profitSnapshotBackgroundTask() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[后台] 开始收益快照后台任务...');
    try {
      final data = await IcloudStorage.loadStocks();
      final cloudStocks = data.$1;
      final cloudRecords = data.$2;
      final cloudDivRecords = data.$3;
      if (cloudStocks.isEmpty) {
        debugPrint('[后台] 无股票数据，跳过');
        return true;
      }

      final currency =
          await SettingsService.getDefaultCurrency() ??
          AppConfig.defaultCurrency;
      final searchResults = cloudStocks
          .map(
            (stock) => StockSearchResult(
              code: stock.symbol,
              name: stock.companyName,
              market: stock.marketType,
              secid:
                  stock.secid ??
                  '${stock.marketType == StockConfig.searchMarketUS ? '105' : '116'}.${stock.symbol}',
            ),
          )
          .toList();
      final quotes = await StockQuoteService().getStockQuotesBatch(
        searchResults,
      );

      for (int i = 0; i < cloudStocks.length; i++) {
        final secid =
            cloudStocks[i].secid ??
            '${cloudStocks[i].marketType == StockConfig.searchMarketUS ? '105' : '116'}.${cloudStocks[i].symbol}';
        final quote = quotes[secid];
        if (quote != null) {
          cloudStocks[i] = cloudStocks[i].copyWith(
            currentPrice: quote.currentPrice,
            changePercent: quote.changePercent,
          );
        }
      }

      final summary = StockCalculator.calculateAssetSummary(
        cloudStocks,
        cloudRecords,
        cloudDivRecords,
        currency,
      );
      await IcloudStorage.recordProfitIfNeeded(summary.totalProfit, currency);
      debugPrint('[后台] 收益快照记录完成: ${summary.totalProfit}');
    } catch (e) {
      debugPrint('[后台] 收益快照任务失败: $e');
    }
    return true;
  });
}
