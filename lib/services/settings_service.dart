import 'package:shared_preferences/shared_preferences.dart';

/// 设置服务 - 持久化用户偏好设置
class SettingsService {
  static const String _keyDefaultCurrency = 'default_currency';

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
}
