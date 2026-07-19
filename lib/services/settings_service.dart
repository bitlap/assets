import 'package:shared_preferences/shared_preferences.dart';

/// 设置服务 - SharedPreferences 为主，iCloud 为可选镜像
class SettingsService {
  static const String keyDefaultCurrency = 'default_currency';
  static const String keyKeepStockAfterClose = 'keep_stock_after_close';
  static const String keySortColumn = 'sort_column';
  static const String keySortAscending = 'sort_ascending';
  static const String keySyncSettings = 'sync_settings';

  /// 读取保存的默认货币
  static Future<String?> getDefaultCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyDefaultCurrency);
  }

  /// 保存默认货币
  static Future<void> setDefaultCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDefaultCurrency, currency);
  }

  /// 读取平仓后是否保留持仓股票，默认 true（保留）
  static Future<bool> getKeepStockAfterClose() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyKeepStockAfterClose) ?? true;
  }

  /// 保存平仓后是否保留持仓股票
  static Future<void> setKeepStockAfterClose(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyKeepStockAfterClose, value);
  }

  /// 读取排序列，默认 'profit'
  static Future<String> getSortColumn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keySortColumn) ?? 'profit';
  }

  /// 保存排序列
  static Future<void> setSortColumn(String column) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySortColumn, column);
  }

  /// 读取排序方向，默认 false（降序）
  static Future<bool> getSortAscending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keySortAscending) ?? false;
  }

  /// 保存排序方向
  static Future<void> setSortAscending(bool ascending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySortAscending, ascending);
  }

  // 手续费设置
  static const String keyDefaultFeeType = 'default_fee_type';
  static const String keyDefaultFeeValue = 'default_fee_value';

  static const String feeTypePercentage = 'percentage';
  static const String feeTypeFixed = 'fixed';

  /// 读取默认手续费类型（percentage 或 fixed）
  static Future<String> getDefaultFeeType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyDefaultFeeType) ?? feeTypeFixed;
  }

  /// 保存默认手续费类型
  static Future<void> setDefaultFeeType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDefaultFeeType, type);
  }

  /// 读取默认手续费值（费率百分比值或固定金额）
  static Future<double> getDefaultFeeValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keyDefaultFeeValue) ?? 0.0;
  }

  /// 保存默认手续费值
  static Future<void> setDefaultFeeValue(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyDefaultFeeValue, value);
  }

  /// 总同步开关：开启后持仓和操作记录一起同步，关闭则不同步
  static Future<bool> getSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keySyncSettings) ?? true;
  }

  static Future<void> setSyncSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySyncSettings, value);
  }
}
