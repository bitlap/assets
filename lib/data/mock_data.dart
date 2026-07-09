import '../models/stock_model.dart';

/// 模拟数据生成器
/// 将所有 mock 数据集中管理，方便后续替换为真实数据
class MockDataGenerator {
  /// 生成模拟股票列表
  static List<StockModel> generateStocks() {
    return [
      StockModel(
        symbol: 'AAPL',
        companyName: 'Apple Inc.',
        currentPrice: 1795.52,
        shares: 100.0,
        totalValue: 179552.0,
        profitLossPercent: 18.5,
        profitLossAmount: 28019.0,
        isPositive: true,
        logoUrl: 'https://logos.stocktwits-cdn.com/AAPL.png?w=64',
        marketType: '美股',
      ),
      StockModel(
        symbol: 'TSLA',
        companyName: 'Tesla Inc.',
        currentPrice: 2200.96,
        shares: 50.0,
        totalValue: 110048.0,
        profitLossPercent: -5.2,
        profitLossAmount: -6009.0,
        isPositive: false,
        logoUrl: 'https://logos.stocktwits-cdn.com/TSLA.png?w=64',
        marketType: '美股',
      ),
    ];
  }

}

/// 股票详细数据（展开时展示）
class StockDetailData {
  final double avgCost;

  StockDetailData({
    required this.avgCost,
  });
}
