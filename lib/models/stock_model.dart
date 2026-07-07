/// 股票数据模型
class StockModel {
  final String symbol;
  final String companyName;
  final double currentPrice; // USD价格
  final int shares;
  final double totalValue; // USD总值
  final double profitLossPercent;
  final double profitLossAmount; // USD盈亏
  final bool isPositive;
  final String? logoUrl; // Logo URL
  final String marketType; // 市场类型：美股、港股

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
    this.marketType = '美股',
  });

  /// 复制并修改
  StockModel copyWith({
    String? symbol,
    String? companyName,
    double? currentPrice,
    int? shares,
    double? totalValue,
    double? profitLossPercent,
    double? profitLossAmount,
    bool? isPositive,
    String? logoUrl,
    String? marketType,
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
    );
  }
}

/// 操作记录模型
class OperationRecord {
  final DateTime date;
  final String type;
  final String description;
  final double amount;
  final int shares;

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
