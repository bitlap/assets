import '../config/app_config.dart';

enum AssetType { cash, timeDeposit, wealthProduct }

sealed class AssetBase {
  final String id;
  AssetType type;
  int sortOrder;
  String currency;
  String name;
  DateTime? createdAt;
  DateTime? updatedAt;

  AssetBase({
    required this.id,
    required this.type,
    this.sortOrder = 0,
    this.currency = DevConfig.defaultCurrency,
    this.name = '',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'sortOrder': sortOrder,
    'currency': currency,
    'name': name,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static AssetType _typeFromJson(String? s) => AssetType.values.firstWhere(
    (e) => e.name == s,
    orElse: () => AssetType.cash,
  );

  static AssetBase fromJson(Map<String, dynamic> json) {
    final type = _typeFromJson(json['type'] as String?);
    switch (type) {
      case AssetType.cash:
        return CashAccount.fromJson(json);
      case AssetType.timeDeposit:
        return TimeDeposit.fromJson(json);
      case AssetType.wealthProduct:
        return WealthProduct.fromJson(json);
    }
  }
}

class CashAccount extends AssetBase {
  double balance;

  CashAccount({
    required super.id,
    super.sortOrder = 0,
    super.currency = DevConfig.defaultCurrency,
    super.name = '',
    super.createdAt,
    super.updatedAt,
    this.balance = 0,
  }) : super(type: AssetType.cash);

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'balance': balance};

  static CashAccount fromJson(Map<String, dynamic> json) => CashAccount(
    id: json['id'] as String,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    currency: json['currency'] as String? ?? DevConfig.defaultCurrency,
    name: json['name'] as String? ?? '',
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
  );
}

class TimeDeposit extends AssetBase {
  double principal;
  double annualRate;
  DateTime startDate;
  int durationMonths;

  TimeDeposit({
    required super.id,
    super.sortOrder = 0,
    super.currency = DevConfig.defaultCurrency,
    super.name = '',
    super.createdAt,
    super.updatedAt,
    this.principal = 0,
    this.annualRate = 0,
    DateTime? startDate,
    this.durationMonths = 12,
  }) : startDate = startDate ?? DateTime.now(),
       super(type: AssetType.timeDeposit);

  DateTime get endDate =>
      DateTime(startDate.year, startDate.month + durationMonths, startDate.day);
  double get interest => principal * annualRate / 100 * durationMonths / 12;
  double get totalValue => principal + interest;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'principal': principal,
    'annualRate': annualRate,
    'startDate': startDate.toIso8601String(),
    'durationMonths': durationMonths,
  };

  static TimeDeposit fromJson(Map<String, dynamic> json) => TimeDeposit(
    id: json['id'] as String,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    currency: json['currency'] as String? ?? DevConfig.defaultCurrency,
    name: json['name'] as String? ?? '',
    principal: (json['principal'] as num?)?.toDouble() ?? 0,
    annualRate: (json['annualRate'] as num?)?.toDouble() ?? 0,
    startDate: json['startDate'] != null
        ? DateTime.parse(json['startDate'] as String)
        : DateTime.now(),
    durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 12,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
  );
}

class WealthProduct extends AssetBase {
  double shares;
  double nav;

  WealthProduct({
    required super.id,
    super.sortOrder = 0,
    super.currency = DevConfig.defaultCurrency,
    super.name = '',
    super.createdAt,
    super.updatedAt,
    this.shares = 0,
    this.nav = 0,
  }) : super(type: AssetType.wealthProduct);

  double get totalValue => shares * nav;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'shares': shares,
    'nav': nav,
  };

  static WealthProduct fromJson(Map<String, dynamic> json) => WealthProduct(
    id: json['id'] as String,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    currency: json['currency'] as String? ?? DevConfig.defaultCurrency,
    name: json['name'] as String? ?? '',
    shares: (json['shares'] as num?)?.toDouble() ?? 0,
    nav: (json['nav'] as num?)?.toDouble() ?? 0,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
  );
}
