import '../models/asset_account.dart';
import 'currency_helper.dart';

/// 资产计算工具类
class AssetCalculator {
  /// 获取单个资产在目标货币下的价值
  static double getAssetValue(AssetBase asset, String targetCurrency) {
    switch (asset) {
      case CashAccount c:
        return CurrencyHelper.convertCurrency(
          c.balance,
          c.currency,
          targetCurrency,
        );
      case TimeDeposit t:
        return CurrencyHelper.convertCurrency(
          t.totalValue,
          t.currency,
          targetCurrency,
        );
      case WealthProduct w:
        return CurrencyHelper.convertCurrency(
          w.totalValue,
          w.currency,
          targetCurrency,
        );
    }
  }

  /// 计算总资产（含股票市值）
  static double calculateTotalAssets(
    List<AssetBase> assets,
    double stockTotalValue,
    String targetCurrency,
  ) {
    double sum = stockTotalValue;
    for (final a in assets) {
      sum += getAssetValue(a, targetCurrency);
    }
    return sum;
  }

  /// 排序资产列表
  static List<AssetBase> sortAssets(
    List<AssetBase> source,
    String? sortColumn,
    bool ascending,
    String targetCurrency,
  ) {
    if (sortColumn == null) return source;
    final sorted = List<AssetBase>.from(source);
    sorted.sort((a, b) {
      int cmp;
      switch (sortColumn) {
        case 'name':
          cmp = a.name.compareTo(b.name);
          break;
        case 'amount':
          cmp = getAssetValue(
            a,
            targetCurrency,
          ).compareTo(getAssetValue(b, targetCurrency));
          break;
        default:
          cmp = 0;
      }
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }
}
