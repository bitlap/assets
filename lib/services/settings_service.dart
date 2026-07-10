import 'package:shared_preferences/shared_preferences.dart';

/// 设置服务 - 持久化用户偏好设置
class SettingsService {
  static const String _keyDefaultCurrency = 'default_currency';

  /// 平仓后是否保留持仓股票（若选择删除，则清空数据，效果等同直接删除股票）
  static const String _keyKeepStockAfterClose = 'keep_stock_after_close';

  static const String _keySortColumn = 'sort_column';
  static const String _keySortAscending = 'sort_ascending';

  /// 读取保存的默认货币
  static Future<String?> getDefaultCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultCurrency);
  }

  /// 保存默认货币
  static Future<void> setDefaultCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultCurrency, currency);
  }

  /// 读取平仓后是否保留持仓股票，默认 false（删除）
  static Future<bool> getKeepStockAfterClose() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyKeepStockAfterClose) ?? false;
  }

  /// 保存平仓后是否保留持仓股票
  static Future<void> setKeepStockAfterClose(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKeepStockAfterClose, value);
  }

  /// 读取排序列，默认 'profit'
  static Future<String> getSortColumn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySortColumn) ?? 'profit';
  }

  /// 保存排序列
  static Future<void> setSortColumn(String column) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySortColumn, column);
  }

  /// 读取排序方向，默认 false（降序）
  static Future<bool> getSortAscending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySortAscending) ?? false;
  }

  /// 保存排序方向
  static Future<void> setSortAscending(bool ascending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySortAscending, ascending);
  }
}
