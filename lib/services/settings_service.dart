import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'icloud_storage.dart';

/// 设置服务 - SharedPreferences 为主，iCloud 为可选镜像
class SettingsService {
  static const String _keyDefaultCurrency = 'default_currency';
  static const String _keyKeepStockAfterClose = 'keep_stock_after_close';
  static const String _keySortColumn = 'sort_column';
  static const String _keySortAscending = 'sort_ascending';
  static const String _keySyncSettings = 'sync_settings';
  static const String _keySyncStocks = 'sync_stocks';
  static const String _keySyncRecords = 'sync_records';

  /// 从 iCloud 下载覆盖 SharedPreferences
  static Future<void> pullFromCloud() async {
    final enabled = await getSyncSettings();
    if (!enabled) {
      debugPrint('[设置] ⏸️ 同步未启用，跳过下拉同步');
      return;
    }
    debugPrint('[设置] 📥 开始从 iCloud 拉取设置...');
    final cloud = await IcloudStorage.loadSettings();
    if (cloud.isEmpty) {
      debugPrint('[设置] ⚠️ iCloud 无数据，跳过覆盖');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    if (cloud.containsKey(_keyDefaultCurrency)) {
      await prefs.setString(_keyDefaultCurrency, cloud[_keyDefaultCurrency]);
      count++;
    }
    if (cloud.containsKey(_keyKeepStockAfterClose)) {
      await prefs.setBool(
        _keyKeepStockAfterClose,
        cloud[_keyKeepStockAfterClose],
      );
      count++;
    }
    if (cloud.containsKey(_keySortColumn)) {
      await prefs.setString(_keySortColumn, cloud[_keySortColumn]);
      count++;
    }
    if (cloud.containsKey(_keySortAscending)) {
      await prefs.setBool(_keySortAscending, cloud[_keySortAscending]);
      count++;
    }
    debugPrint('[设置] ✅ 从 iCloud 拉取完成: ${cloud.length}项设置');
  }

  /// 把 SharedPreferences 上传到 iCloud
  static Future<void> pushToCloud() async {
    final enabled = await getSyncSettings();
    if (!enabled) {
      debugPrint('[设置] ⏸️ 同步未启用，跳过上传');
      return;
    }
    debugPrint('[设置] 📤 开始上传设置到 iCloud...');
    final prefs = await SharedPreferences.getInstance();
    await IcloudStorage.saveSettings({
      _keyDefaultCurrency: prefs.getString(_keyDefaultCurrency) ?? 'CNY',
      _keyKeepStockAfterClose: prefs.getBool(_keyKeepStockAfterClose) ?? false,
      _keySortColumn: prefs.getString(_keySortColumn) ?? 'profit',
      _keySortAscending: prefs.getBool(_keySortAscending) ?? false,
    });
    debugPrint('[设置] ✅ 设置上传完成');
  }

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

  // ========== iCloud 同步开关 ==========

  static Future<bool> getSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySyncSettings) ?? false;
  }

  static Future<void> setSyncSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySyncSettings, value);
  }

  static Future<bool> getSyncStocks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySyncStocks) ?? false;
  }

  static Future<void> setSyncStocks(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySyncStocks, value);
  }

  static Future<bool> getSyncRecords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySyncRecords) ?? false;
  }

  static Future<void> setSyncRecords(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySyncRecords, value);
  }
}
