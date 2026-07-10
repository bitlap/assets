import 'package:shared_preferences/shared_preferences.dart';

/// 设置服务 - 持久化用户偏好设置
class SettingsService {
  static const String _keyDefaultCurrency = 'default_currency';

  /// 平仓后是否保留持仓股票（若选择删除，则清空数据，效果等同直接删除股票）
  static const String _keyKeepStockAfterClose = 'keep_stock_after_close';

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
}
