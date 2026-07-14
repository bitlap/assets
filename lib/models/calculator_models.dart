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
  final double totalAfterTaxDividends; // 总税后股息（目标币种）

  const AssetSummary({
    this.totalAssets = 0,
    this.totalCost = 0,
    this.totalProfit = 0,
    this.totalProfitPercent = 0,
    this.totalAfterTaxDividends = 0,
  });
}
