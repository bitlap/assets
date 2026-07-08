/// 汇率与货币转换工具类
class CurrencyHelper {
  /// 汇率映射表（以 USD 为基准，1 USD = X 目标货币）
  static const Map<String, double> exchangeRates = {
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

  /// 将 USD 金额转换为目标货币
  static double convertFromUSD(double amountInUSD, String currency) {
    return amountInUSD * getExchangeRate(currency);
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

  /// 将大数字格式化为紧凑形式（万/亿/万亿）
  /// 例：12345 → 1.23万，123456789 → 1.23亿
  static String formatCompact(double value) {
    final abs = value.abs();
    if (abs >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(2)}万亿';
    } else if (abs >= 1e8) {
      return '${(value / 1e8).toStringAsFixed(2)}亿';
    } else if (abs >= 1e4) {
      return '${(value / 1e4).toStringAsFixed(2)}万';
    }
    return value.toStringAsFixed(2);
  }

  /// 格式化带货币符号的紧凑金额（先转换货币再格式化）
  /// 用于市值、总资产等大金额显示
  static String formatCompactCurrency(double amountInUSD, String currency) {
    final converted = convertFromUSD(amountInUSD, currency);
    return '${getSymbol(currency)}${formatCompact(converted)}';
  }
}
