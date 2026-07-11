import '../config/app_config.dart';

/// 股票数据模型
class StockModel {
  final String symbol;
  final String companyName;
  final double currentPrice; // 股票自身币种价格
  final double shares;
  final double totalValue; // 股票自身币种总值
  final double profitLossPercent;
  final double profitLossAmount; // 股票自身币种盈亏
  final bool isPositive;
  final String? logoUrl; // Logo URL
  final String marketType; // 市场类型：美股、港股
  final double changePercent; // 日涨跌幅（%）
  final String? _currency; // 股票币种（美股=USD，港股=HKD）
  String get currency =>
      _currency ?? (marketType == DevConfig.searchMarketHK ? 'HKD' : 'USD');
  final String? secid; // 东方财富 secid（用于获取行情）

  StockModel({
    required this.symbol,
    required this.companyName,
    required this.currentPrice,
    required this.shares,
    required this.totalValue,
    required this.profitLossPercent,
    required this.profitLossAmount,
    required this.isPositive,
    this.logoUrl,
    this.marketType = DevConfig.searchMarketUS,
    this.changePercent = 0.0,
    String? currency,
    this.secid,
  }) : _currency = currency;

  /// 复制并修改
  StockModel copyWith({
    String? symbol,
    String? companyName,
    double? currentPrice,
    double? shares,
    double? totalValue,
    double? profitLossPercent,
    double? profitLossAmount,
    bool? isPositive,
    String? logoUrl,
    String? marketType,
    double? changePercent,
    String? currency,
    String? secid,
  }) {
    return StockModel(
      symbol: symbol ?? this.symbol,
      companyName: companyName ?? this.companyName,
      currentPrice: currentPrice ?? this.currentPrice,
      shares: shares ?? this.shares,
      totalValue: totalValue ?? this.totalValue,
      profitLossPercent: profitLossPercent ?? this.profitLossPercent,
      profitLossAmount: profitLossAmount ?? this.profitLossAmount,
      isPositive: isPositive ?? this.isPositive,
      logoUrl: logoUrl ?? this.logoUrl,
      marketType: marketType ?? this.marketType,
      changePercent: changePercent ?? this.changePercent,
      currency: currency ?? this.currency,
      secid: secid ?? this.secid,
    );
  }
}

/// 操作记录模型
class OperationRecord {
  final DateTime date;
  final String type;
  final String description;
  final double amount;
  final double shares;

  OperationRecord({
    required this.date,
    required this.type,
    required this.description,
    required this.amount,
    required this.shares,
  });
}

/// 股息记录模型
class DividendRecord {
  final DateTime date;
  final double amount;
  final String currency;

  DividendRecord({
    required this.date,
    required this.amount,
    required this.currency,
  });
}
