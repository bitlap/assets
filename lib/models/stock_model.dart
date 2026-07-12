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
  final DateTime date; // 创建时间
  final DateTime operationTime; // 操作时间（含时分秒，编辑时更新）
  final String type;
  final String description;
  final double amount;
  final double shares;

  OperationRecord({
    required this.date,
    DateTime? operationTime,
    required this.type,
    required this.description,
    required this.amount,
    required this.shares,
  }) : operationTime = operationTime ?? DateTime.now();

  /// 复制并修改
  OperationRecord copyWith({
    DateTime? date,
    DateTime? operationTime,
    String? type,
    String? description,
    double? amount,
    double? shares,
  }) {
    return OperationRecord(
      date: date ?? this.date,
      operationTime: operationTime ?? DateTime.now(),
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      shares: shares ?? this.shares,
    );
  }
}

/// 股息记录模型
class DividendRecord {
  final DateTime date; // 派息日期（仅日期）
  final DateTime operationTime; // 操作时间（含时分秒，编辑时更新）
  final double amount; // 每股派息金额
  final double shares; // 持仓股数
  final double taxRate; // 税率（0~1，如 0.1 表示 10%）
  final String currency;

  DividendRecord({
    required this.date,
    DateTime? operationTime,
    required this.amount,
    required this.shares,
    this.taxRate = 0.1,
    required this.currency,
  }) : operationTime = operationTime ?? DateTime.now();

  /// 总派息金额（税前）
  double get totalAmount => amount * shares;

  /// 税后金额
  double get afterTaxAmount => totalAmount * (1 - taxRate);

  /// 复制并修改
  DividendRecord copyWith({
    DateTime? date,
    DateTime? operationTime,
    double? amount,
    double? shares,
    double? taxRate,
    String? currency,
  }) {
    return DividendRecord(
      date: date ?? this.date,
      operationTime: operationTime ?? DateTime.now(),
      amount: amount ?? this.amount,
      shares: shares ?? this.shares,
      taxRate: taxRate ?? this.taxRate,
      currency: currency ?? this.currency,
    );
  }
}
