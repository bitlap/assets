import '../config/app_config.dart';
import '../models/stock_model.dart';
import 'currency_helper.dart';

/// 操作记录统计结果
class RecordStats {
  final double currentShares; // 当前持股数
  final double totalBuyAmount; // 买入总金额
  final double totalSellAmount; // 卖出ong总金额
  final int buyCount; // 买入次数
  final int sellCount; // 卖出次数
  final double maxBuyPrice; // 最高买入价
  final double minBuyPrice; // 最低买入价
  final double avgBuyPrice; // 买入均价

  const RecordStats({
    this.currentShares = 0,
    this.totalBuyAmount = 0,
    this.totalSellAmount = 0,
    this.buyCount = 0,
    this.sellCount = 0,
    this.maxBuyPrice = 0,
    this.minBuyPrice = 0,
    this.avgBuyPrice = 0,
  });
}

/// 资产汇总结果
class AssetSummary {
  final double totalAssets; // 总资产（目标币种）
  final double totalCost; // 总成本（目标币种）
  final double totalProfit; // 总盈亏（目标币种）
  final double totalProfitPercent; // 总盈亏百分比
  final double totalDividends; // 总股息（目标币种）

  const AssetSummary({
    this.totalAssets = 0,
    this.totalCost = 0,
    this.totalProfit = 0,
    this.totalProfitPercent = 0,
    this.totalDividends = 0,
  });
}

/// 持仓计算工具类 - 所有与操作记录相关的计算逻辑
class StockCalculator {
  /// 紧凑格式化：超过1万时使用"xx万"格式
  /// [value] 要格式化的数值
  /// [formatBase] 基础数字格式化函数，默认保留2位小数
  static String formatCompact(
    double value, {
    String Function(double)? formatBase,
  }) {
    final fmt = formatBase ?? (v) => v.toStringAsFixed(2);
    if (value.abs() >= 10000) {
      return '${fmt(value / 10000)}万';
    }
    return fmt(value);
  }

  /// 从操作记录计算完整统计信息
  static RecordStats calculateRecordStats(List<OperationRecord> records) {
    if (records.isEmpty) return const RecordStats();

    double currentShares = 0;
    double totalBuyAmount = 0.0;
    double totalSellAmount = 0.0;
    double maxBuyPrice = 0.0;
    double minBuyPrice = double.infinity;
    int buyCount = 0;
    int sellCount = 0;

    for (final record in records) {
      if (record.type == DevConfig.opBuy) {
        currentShares += record.shares;
        totalBuyAmount += record.amount * record.shares;
        buyCount++;
        if (record.amount > maxBuyPrice) maxBuyPrice = record.amount;
        if (record.amount < minBuyPrice) minBuyPrice = record.amount;
      } else if (record.type == DevConfig.opSell) {
        currentShares -= record.shares;
        totalSellAmount += record.amount * record.shares;
        sellCount++;
      }
    }

    // 防止浮点误差导致负数
    if (currentShares < 0) currentShares = 0;
    if (minBuyPrice == double.infinity) minBuyPrice = 0.0;

    // 持仓均价 = 净成本 ÷ 当前持股数（考虑卖出）
    final avgBuyPrice = currentShares > 0
        ? (totalBuyAmount - totalSellAmount) / currentShares
        : 0.0;

    return RecordStats(
      currentShares: currentShares,
      totalBuyAmount: totalBuyAmount,
      totalSellAmount: totalSellAmount,
      buyCount: buyCount,
      sellCount: sellCount,
      maxBuyPrice: maxBuyPrice,
      minBuyPrice: minBuyPrice,
      avgBuyPrice: avgBuyPrice,
    );
  }

  /// 从操作记录计算持仓均价（考虑卖出，净成本均摊到剩余股份）
  static double calculateAvgBuyPrice(List<OperationRecord> records) {
    double totalBuyAmount = 0.0;
    double totalSellAmount = 0.0;
    double currentShares = 0.0;
    for (final r in records) {
      if (r.type == DevConfig.opBuy) {
        totalBuyAmount += r.amount * r.shares;
        currentShares += r.shares;
      } else if (r.type == DevConfig.opSell) {
        totalSellAmount += r.amount * r.shares;
        currentShares -= r.shares;
      }
    }
    if (currentShares <= 0) return 0.0;
    return (totalBuyAmount - totalSellAmount) / currentShares;
  }

  /// 计算资产汇总（所有金额转换为目标币种）
  static AssetSummary calculateAssetSummary(
    List<StockModel> stocks,
    Map<String, List<OperationRecord>> operationRecords,
    String targetCurrency,
  ) {
    // 总资产
    final totalAssets = stocks.fold(
      0.0,
      (sum, stock) =>
          sum +
          CurrencyHelper.convertCurrency(
            stock.totalValue,
            stock.currency,
            targetCurrency,
          ),
    );

    // 总盈亏
    final totalProfit = stocks.fold(
      0.0,
      (sum, stock) =>
          sum +
          CurrencyHelper.convertCurrency(
            stock.profitLossAmount,
            stock.currency,
            targetCurrency,
          ),
    );

    // 总成本
    final totalCost = stocks.fold(0.0, (sum, stock) {
      final records = operationRecords[stock.symbol] ?? [];
      final stats = calculateRecordStats(records);
      final cost = stats.totalBuyAmount - stats.totalSellAmount;
      return sum +
          CurrencyHelper.convertCurrency(cost, stock.currency, targetCurrency);
    });

    // 总股息（目前为 0）
    const totalDividends = 0.0;

    // 总盈亏百分比 = 总盈亏 / (总资产 - 总盈亏) * 100
    final totalProfitPercent = totalAssets > 0
        ? (totalProfit / (totalAssets - totalProfit) * 100)
        : 0.0;

    return AssetSummary(
      totalAssets: totalAssets,
      totalCost: totalCost,
      totalProfit: totalProfit,
      totalProfitPercent: totalProfitPercent,
      totalDividends: totalDividends,
    );
  }

  /// 根据操作记录重算股票的持仓数据
  /// 返回更新后的 StockModel，如果无记录则返回原股票
  static StockModel recalculateFromRecords(
    StockModel stock,
    List<OperationRecord> records,
  ) {
    if (records.isEmpty) return stock;

    final stats = calculateRecordStats(records);

    // 当前总持仓金额 = 当前价格 × 当前数量
    final totalValue = stock.currentPrice * stats.currentShares;

    // 如果当前没有持股，直接归零
    if (stats.currentShares == 0) {
      return stock.copyWith(
        shares: 0,
        totalValue: 0,
        profitLossAmount: 0,
        profitLossPercent: 0,
        isPositive: true,
      );
    }

    // 持仓均价 = 净成本 ÷ 当前持股数（考虑卖出）
    final avgCost = stats.avgBuyPrice;

    // 盈亏 = 当前总价值 - (持仓均价 × 当前持股数)
    final profitLossAmount = totalValue - avgCost * stats.currentShares;

    // 盈亏百分比 = (当前价 - 持仓均价) ÷ 持仓均价 × 100%
    final profitLossPercent = avgCost > 0
        ? ((stock.currentPrice - avgCost) / avgCost * 100.0)
        : 0.0;
    // 盈亏方向：持仓均价 <= 当前价 = 盈利
    final isPositive = avgCost <= stock.currentPrice;

    return stock.copyWith(
      shares: stats.currentShares,
      totalValue: totalValue,
      profitLossAmount: profitLossAmount,
      profitLossPercent: profitLossPercent,
      isPositive: isPositive,
    );
  }
}
