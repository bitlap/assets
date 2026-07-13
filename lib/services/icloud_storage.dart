import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_model.dart';
import 'settings_service.dart';

/// iCloud 数据同步服务（带本地 fallback）
class IcloudStorage {
  static const _channel = MethodChannel('org.bitlap.assets/icloud');
  static const _stocksFile = 'stocks.json';
  static const _recordsFile = 'records.json';
  static const _dividendRecordsFile = 'dividend_records.json';
  static const _settingsFile = 'settings.json';

  static String? _cloudPath;
  static String? _localPath;

  /// 初始化（获取 iCloud / 本地路径）
  static Future<void> ensureInit() async {
    if (_cloudPath != null) return;

    // 本地路径
    final localDir = await getApplicationDocumentsDirectory();
    _localPath = localDir.path;
    debugPrint('[iCloud] 本地路径: $_localPath');

    // 尝试获取 iCloud 路径
    try {
      final cloudPath = await _channel.invokeMethod<String>('getContainerUrl');
      if (cloudPath != null && cloudPath.isNotEmpty) {
        final dir = Directory(cloudPath);
        if (!await dir.exists()) await dir.create(recursive: true);
        _cloudPath = cloudPath;
        debugPrint('[iCloud] ✅ iCloud 路径获取成功: $_cloudPath');
      } else {
        debugPrint('[iCloud] ⚠️ iCloud 路径为空，使用本地 fallback');
      }
    } catch (e) {
      debugPrint('[iCloud] ❌ 获取 iCloud 路径失败: $e，使用本地 fallback');
    }
  }

  /// 当前使用的存储路径（iCloud → 本地 fallback）
  static String get _storagePath => _cloudPath ?? _localPath!;

  static String _filePath(String name) => '$_storagePath/$name';

  /// 保存股票和记录到 iCloud（本地兜底）
  static Future<void> pushStocksToCloud(
    List<StockModel> stocks,
    Map<String, List<OperationRecord>> records, [
    Map<String, List<DividendRecord>>? dividendRecords,
  ]) async {
    await ensureInit();
    debugPrint(
      '[iCloud] 💾 开始保存: ${stocks.length} 只股票, ${records.length} 个股票记录 -> ${_cloudPath != null ? "iCloud" : "本地"}',
    );
    await _writeJson(_stocksFile, _stocksToJson(stocks));
    debugPrint('[iCloud] 💾 股票保存完成: $_stocksFile');
    await _writeJson(_recordsFile, _recordsToJson(records));
    debugPrint('[iCloud] 💾 记录保存完成: $_recordsFile');
    if (dividendRecords != null) {
      await _writeJson(
        _dividendRecordsFile,
        _dividendRecordsToJson(dividendRecords),
      );
      debugPrint('[iCloud] 💾 派息记录保存完成: $_dividendRecordsFile');
    }
  }

  /// 加载股票和记录（优先 iCloud）
  static Future<
    (
      List<StockModel> stocks,
      Map<String, List<OperationRecord>> records,
      Map<String, List<DividendRecord>> dividendRecords,
    )
  >
  pullStocksFromCloud() async {
    await ensureInit();
    debugPrint(
      '[iCloud] 📖 开始加载数据 from: ${_cloudPath != null ? "iCloud" : "本地"}',
    );

    final stocks = _stocksFromJson(await _readJson(_stocksFile));
    final records = _recordsFromJson(await _readJson(_recordsFile));
    final dividendRecords = _dividendRecordsFromJson(
      await _readJson(_dividendRecordsFile),
    );
    debugPrint(
      '[iCloud] 📖 加载完成: ${stocks.length} 只股票, ${records.length} 个股票记录, ${dividendRecords.length} 个派息记录',
    );

    // 首次启动：若 iCloud 为空，尝试从本地迁移
    if (stocks.isEmpty && records.isEmpty && _cloudPath != null) {
      debugPrint('[iCloud] 🔄 iCloud 数据为空，尝试从本地迁移...');
      final localStocks = _stocksFromJson(await _readLocalJson(_stocksFile));
      final localRecords = _recordsFromJson(await _readLocalJson(_recordsFile));
      final localDivRecords = _dividendRecordsFromJson(
        await _readLocalJson(_dividendRecordsFile),
      );
      debugPrint(
        '[iCloud] 🔄 本地数据: ${localStocks.length} 只股票, ${localRecords.length} 个记录',
      );
      if (localStocks.isNotEmpty || localRecords.isNotEmpty) {
        await pushStocksToCloud(localStocks, localRecords, localDivRecords);
        debugPrint('[iCloud] ✅ 本地数据迁移到 iCloud 完成');
        return (localStocks, localRecords, localDivRecords);
      } else {
        debugPrint('[iCloud] ⚠️ 本地也无数据，无需迁移');
      }
    }

    return (stocks, records, dividendRecords);
  }

  /// 保存设置到 iCloud
  static Future<void> pushSettingsToCloud(Map<String, dynamic> settings) async {
    await ensureInit();
    debugPrint(
      '[设置] 📝 保存设置: $_settingsFile -> ${_cloudPath != null ? "iCloud" : "本地"}',
    );
    final file = File(_filePath(_settingsFile));
    await file.writeAsString(jsonEncode(settings));
    debugPrint('[设置] 📝 设置保存完成: $_settingsFile');
  }

  /// 加载设置（优先 iCloud）
  static Future<Map<String, dynamic>> pullSettingsFromCloud() async {
    await ensureInit();
    debugPrint(
      '[设置] 📝 加载设置: $_settingsFile from ${_cloudPath != null ? "iCloud" : "本地"}',
    );
    final file = File(_filePath(_settingsFile));
    if (!await file.exists()) {
      debugPrint('[设置] 📝 设置文件不存在: $_settingsFile');
      return {};
    }
    try {
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      debugPrint('[设置] 📝 读取文件成功: $_settingsFile (${data.length} 项)');
      return data;
    } catch (e) {
      debugPrint('[设置] ❌ 读取文件失败: $_settingsFile - $e');
      return {};
    }
  }

  /// 从 iCloud 下载设置覆盖 SharedPreferences
  static Future<void> loadSettings() async {
    final enabled = await SettingsService.getSyncSettings();
    if (!enabled) {
      return;
    }
    final cloud = await pullSettingsFromCloud();
    if (cloud.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (cloud.containsKey(SettingsService.keyDefaultCurrency)) {
      await prefs.setString(
        SettingsService.keyDefaultCurrency,
        cloud[SettingsService.keyDefaultCurrency],
      );
    }
    if (cloud.containsKey(SettingsService.keyKeepStockAfterClose)) {
      await prefs.setBool(
        SettingsService.keyKeepStockAfterClose,
        cloud[SettingsService.keyKeepStockAfterClose],
      );
    }
    if (cloud.containsKey(SettingsService.keySortColumn)) {
      await prefs.setString(
        SettingsService.keySortColumn,
        cloud[SettingsService.keySortColumn],
      );
    }
    if (cloud.containsKey(SettingsService.keySortAscending)) {
      await prefs.setBool(
        SettingsService.keySortAscending,
        cloud[SettingsService.keySortAscending],
      );
    }
    debugPrint('[设置] ✅ 从 iCloud 拉取完成: ${cloud.length}项设置');
  }

  /// 把 SharedPreferences 上传到 iCloud
  static Future<void> saveSettings() async {
    final enabled = await SettingsService.getSyncSettings();
    if (!enabled) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await pushSettingsToCloud({
      SettingsService.keyDefaultCurrency:
          prefs.getString(SettingsService.keyDefaultCurrency) ?? 'CNY',
      SettingsService.keyKeepStockAfterClose:
          prefs.getBool(SettingsService.keyKeepStockAfterClose) ?? false,
      SettingsService.keySortColumn:
          prefs.getString(SettingsService.keySortColumn) ?? 'profit',
      SettingsService.keySortAscending:
          prefs.getBool(SettingsService.keySortAscending) ?? false,
    });
  }

  static Future<void> _writeJson(String name, List<Map> data) async {
    final file = File(_filePath(name));
    try {
      await file.writeAsString(jsonEncode(data));
      debugPrint('[iCloud] 📝 写入文件成功: $name (${data.length} 条)');
    } catch (e) {
      debugPrint('[iCloud] ❌ 写入文件失败: $name - $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _readJson(String name) async {
    final file = File(_filePath(name));
    if (!await file.exists()) {
      debugPrint('[iCloud] 📝 文件不存在: $name');
      return [];
    }
    try {
      final list = jsonDecode(await file.readAsString()) as List;
      debugPrint('[iCloud] 📝 读取文件成功: $name (${list.length} 条)');
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[iCloud] ❌ 读取文件失败: $name - $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _readLocalJson(String name) async {
    final file = File('$_localPath/$name');
    if (!await file.exists()) {
      debugPrint('[iCloud] 📝 本地文件不存在: $name');
      return [];
    }
    try {
      final list = jsonDecode(await file.readAsString()) as List;
      debugPrint('[iCloud] 📝 读取本地文件成功: $name (${list.length} 条)');
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[iCloud] ❌ 读取本地文件失败: $name - $e');
      return [];
    }
  }

  // 序列化
  static List<Map<String, dynamic>> _stocksToJson(List<StockModel> stocks) {
    return stocks
        .map(
          (s) => {
            'symbol': s.symbol,
            'companyName': s.companyName,
            'currentPrice': s.currentPrice,
            'shares': s.shares,
            'totalValue': s.totalValue,
            'profitLossPercent': s.profitLossPercent,
            'profitLossAmount': s.profitLossAmount,
            'isPositive': s.isPositive,
            'logoUrl': s.logoUrl,
            'marketType': s.marketType,
            'changePercent': s.changePercent,
            'currency': s.currency,
            'secid': s.secid,
          },
        )
        .toList();
  }

  static List<StockModel> _stocksFromJson(List<Map<String, dynamic>> json) {
    return json
        .map(
          (j) => StockModel(
            symbol: j['symbol'] as String,
            companyName: j['companyName'] as String,
            currentPrice: (j['currentPrice'] as num).toDouble(),
            shares: (j['shares'] as num).toDouble(),
            totalValue: (j['totalValue'] as num).toDouble(),
            profitLossPercent: (j['profitLossPercent'] as num).toDouble(),
            profitLossAmount: (j['profitLossAmount'] as num).toDouble(),
            isPositive: j['isPositive'] as bool,
            logoUrl: j['logoUrl'] as String?,
            marketType: j['marketType'] as String,
            changePercent: (j['changePercent'] as num).toDouble(),
            currency: j['currency'] as String?,
            secid: j['secid'] as String?,
          ),
        )
        .toList();
  }

  static List<Map<String, dynamic>> _recordsToJson(
    Map<String, List<OperationRecord>> records,
  ) {
    return records.entries
        .where((e) => e.value.isNotEmpty)
        .map(
          (e) => {
            'symbol': e.key,
            'records': e.value
                .map(
                  (r) => {
                    'date': r.date.toIso8601String(),
                    'operationTime': r.operationTime.toIso8601String(),
                    'type': r.type,
                    'description': r.description,
                    'amount': r.amount,
                    'shares': r.shares,
                  },
                )
                .toList(),
          },
        )
        .toList();
  }

  static Map<String, List<OperationRecord>> _recordsFromJson(
    List<Map<String, dynamic>> json,
  ) {
    final map = <String, List<OperationRecord>>{};
    for (final entry in json) {
      map[entry['symbol'] as String] = (entry['records'] as List)
          .map(
            (r) => OperationRecord(
              date: r.containsKey('date')
                  ? DateTime.parse(r['date'] as String)
                  : DateTime.now(),
              operationTime: r.containsKey('operationTime')
                  ? DateTime.parse(r['operationTime'] as String)
                  : DateTime.parse(r['date'] as String),
              type: r['type'] as String,
              description: r['description'] as String,
              amount: (r['amount'] as num).toDouble(),
              shares: (r['shares'] as num).toDouble(),
            ),
          )
          .toList();
    }
    return map;
  }

  // 派息记录序列化
  static List<Map<String, dynamic>> _dividendRecordsToJson(
    Map<String, List<DividendRecord>> records,
  ) {
    return records.entries
        .where((e) => e.value.isNotEmpty)
        .map(
          (e) => {
            'symbol': e.key,
            'records': e.value
                .map(
                  (r) => {
                    'date': r.date.toIso8601String(),
                    'operationTime': r.operationTime.toIso8601String(),
                    'amount': r.amount,
                    'shares': r.shares,
                    'taxRate': r.taxRate,
                    'currency': r.currency,
                  },
                )
                .toList(),
          },
        )
        .toList();
  }

  static Map<String, List<DividendRecord>> _dividendRecordsFromJson(
    List<Map<String, dynamic>> json,
  ) {
    final map = <String, List<DividendRecord>>{};
    for (final entry in json) {
      map[entry['symbol'] as String] = (entry['records'] as List)
          .map(
            (r) => DividendRecord(
              date: r.containsKey('date')
                  ? DateTime.parse(r['date'] as String)
                  : DateTime.now(),
              operationTime: r.containsKey('operationTime')
                  ? DateTime.parse(r['operationTime'] as String)
                  : DateTime.parse(r['date'] as String),
              amount: (r['amount'] as num).toDouble(),
              shares: (r['shares'] as num).toDouble(),
              taxRate: r.containsKey('taxRate')
                  ? (r['taxRate'] as num).toDouble()
                  : 0.0,
              currency: r['currency'] as String? ?? 'USD',
            ),
          )
          .toList();
    }
    return map;
  }
}
