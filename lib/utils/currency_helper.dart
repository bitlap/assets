/// 汇率与货币转换工具类
class CurrencyHelper {
  /// 汇率映射表（以 USD 为基准，1 USD = X 目标货币）
  /// 初始为硬编码默认值，获取实时汇率后会动态更新
  static Map<String, double> exchangeRates = {
    'CNY': 7.24,
    'USD': 1.0,
    'HKD': 7.78,
    'EUR': 0.92,
    'JPY': 149.0,
    'GBP': 0.79,
    'AUD': 1.52,
    'CAD': 1.36,
    'CHF': 0.88,
    'KRW': 1320.0,
    'SGD': 1.34,
  };

  /// 支持的币种列表（用于过滤 API 返回的多余币种）
  static const Set<String> supportedCurrencies = {
    'CNY',
    'USD',
    'HKD',
    'EUR',
    'JPY',
    'GBP',
    'AUD',
    'CAD',
    'CHF',
    'KRW',
    'SGD',
  };

  /// 使用 API 返回的实时汇率更新
  static void updateRates(Map<String, double> rates) {
    for (final currency in supportedCurrencies) {
      if (rates.containsKey(currency)) {
        exchangeRates[currency] = rates[currency]!;
      }
    }
  }

  /// 获取货币符号
  static String getSymbol(String currency) {
    switch (currency) {
      case 'CNY':
        return '¥';
      case 'USD':
        return '\$';
      case 'HKD':
        return 'HK\$';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  /// 根据货币获取汇率
  static double getExchangeRate(String currency) {
    return exchangeRates[currency] ?? 1.0;
  }

  /// 格式化汇率显示
  static String formatRate(double rate) {
    return rate.toStringAsFixed(rate < 1 ? 4 : 2);
  }

  /// 根据市场类型返回对应币种
  static String currencyForMarket(String marketType) {
    switch (marketType) {
      case '港股':
        return 'HKD';
      default:
        return 'USD';
    }
  }

  /// 格式化股数：整数不显示小数点，小数保留原样
  static String formatShares(double shares) {
    if (shares == shares.toInt()) {
      return shares.toInt().toString();
    }
    return shares
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  /// 将金额从源币种转换为目标币种（以 USD 为中间货币）
  static double convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    final amountInUSD = amount / getExchangeRate(fromCurrency);
    return amountInUSD * getExchangeRate(toCurrency);
  }
}
