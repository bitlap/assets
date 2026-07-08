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
        logoUrl: 'https://logo.clearbit.com/apple.com',
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
        logoUrl: 'https://logo.clearbit.com/tesla.com',
        marketType: '美股',
      ),
    ];
  }

  /// 生成模拟操作记录
  static List<OperationRecord> generateOperationRecords(String symbol) {
    final records = <OperationRecord>[];
    for (int i = 0; i < 35; i++) {
      records.add(OperationRecord(
        date: DateTime.now().subtract(Duration(days: i * 3)),
        type: i % 3 == 0 ? '买入' : '卖出',
        description: '${i % 3 == 0 ? "建仓" : "减仓"} $symbol',
        amount: 1000.0 + i * 50,
        shares: 10.0 + i * 2,
      ));
    }
    return records;
  }

  /// 生成模拟派息记录
  static List<DividendRecord> generateDividendRecords() {
    final records = <DividendRecord>[];
    for (int i = 0; i < 25; i++) {
      records.add(DividendRecord(
        date: DateTime.now().subtract(Duration(days: i * 90)),
        amount: 100.0 + i * 10,
        currency: 'CNY',
      ));
    }
    return records;
  }

  /// 模拟股票详细数据
  static StockDetailData generateStockDetail(StockModel stock) {
    final avgCost = stock.currentPrice * 0.85;
    final dividendPerShare = stock.currentPrice * 0.025;
    const dividendYield = 2.5;
    const peRatio = 28.5;
    final marketCap = stock.currentPrice * stock.shares * 150;
    final annualDividend = dividendPerShare * stock.shares;
    const lastDividendDate = '2025-06-15';

    return StockDetailData(
      avgCost: avgCost,
      dividendPerShare: dividendPerShare,
      dividendYield: dividendYield,
      peRatio: peRatio,
      marketCap: marketCap,
      annualDividend: annualDividend,
      lastDividendDate: lastDividendDate,
    );
  }
}

/// 股票详细数据（展开时展示）
class StockDetailData {
  final double avgCost;
  final double dividendPerShare;
  final double dividendYield;
  final double peRatio;
  final double marketCap;
  final double annualDividend;
  final String lastDividendDate;

  StockDetailData({
    required this.avgCost,
    required this.dividendPerShare,
    required this.dividendYield,
    required this.peRatio,
    required this.marketCap,
    required this.annualDividend,
    required this.lastDividendDate,
  });
}
