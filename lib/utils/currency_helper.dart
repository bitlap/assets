/// 汇率与货币转换工具类
class CurrencyHelper {
  /// 汇率映射表
  static const Map<String, double> exchangeRates = {
    'CNY': 7.24,
    'USD': 1.0,
    'HKD': 0.128,
    'EUR': 1.08,
    'JPY': 0.0062,
    'GBP': 1.26,
    'AUD': 0.66,
    'CAD': 0.74,
    'CHF': 1.12,
    'KRW': 0.00074,
    'SGD': 0.75,
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
}
