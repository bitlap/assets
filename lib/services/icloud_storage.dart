import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/stock_model.dart';
import 'settings_service.dart';

/// 本地持久化 + 配置 iCloud 同步服务
class IcloudStorage {
  static const _channel = MethodChannel('org.bitlap.assets/icloud');
  static const _stocksFile = 'stocks.json';
  static const _recordsFile = 'records.json';
  static const _dividendRecordsFile = 'dividend_records.json';
  static const _profitHistoryFile = 'profit_history.json';
  static const _dailyProfitFile = 'profit_history_daily.json';
  static const _intradayProfitFile = 'profit_history_intraday.json';
  static const _settingsFile = 'settings.json';

  static String? _cloudPath;
  static String? _localPath;

  /// 初始化（获取本地 / iCloud 路径）
  static Future<void> ensureInit() async {
    if (_localPath != null) return;

    // 本地路径
    final localDir = await getApplicationDocumentsDirectory();
    _localPath = localDir.path;

    // 尝试获取 iCloud 路径（后台 isolate 无 MethodChannel，静默跳过）
    try {
      final cloudPath = await _channel.invokeMethod<String>('getContainerUrl');
      if (cloudPath != null && cloudPath.isNotEmpty) {
        final dir = Directory(cloudPath);
        if (!await dir.exists()) await dir.create(recursive: true);
        _cloudPath = cloudPath;
      }
    } catch (e) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][iCloud] 获取 iCloud 路径失败: $e，使用本地 fallback',
      );
    }
  }

  /// 当前使用的存储路径
  static String _localFilePath(String name) => '$_localPath/$name';

  /// 保存股票和记录到本地
  static Future<void> saveStocks(
    List<StockModel> stocks,
    Map<String, List<OperationRecord>>? records,
    Map<String, List<DividendRecord>>? dividendRecords,
  ) async {
    await ensureInit();
    await _writeJson(_stocksFile, _stocksToJson(stocks));
    if (records != null) {
      await _writeJson(_recordsFile, _recordsToJson(records));
    }
    if (dividendRecords != null) {
      await _writeJson(
        _dividendRecordsFile,
        _dividendRecordsToJson(dividendRecords),
      );
    }
    unawaited(_syncToCloud(_stocksFile));
    if (records != null) {
      unawaited(_syncToCloud(_recordsFile));
    }
    if (dividendRecords != null) {
      unawaited(_syncToCloud(_dividendRecordsFile));
    }
    debugPrint(
      '[${DateTime.now().toString().substring(11, 19)}][本地] 股票记录保存完成: ${stocks.length} 只股票, ${records?.length} 个股票记录, ${dividendRecords?.length} 个派息记录',
    );
  }

  /// 从本地加载股票和记录
  static Future<
    (
      List<StockModel> stocks,
      Map<String, List<OperationRecord>> records,
      Map<String, List<DividendRecord>> dividendRecords,
    )
  >
  loadStocks() async {
    await ensureInit();
    // 先尝试从 iCloud 拉取更新
    await _syncFromCloud(_stocksFile);
    await _syncFromCloud(_recordsFile);
    await _syncFromCloud(_dividendRecordsFile);
    // 再读本地（此时已包含 iCloud 最新数据）
    final stocks = _stocksFromJson(await _readJson(_stocksFile));
    final records = _recordsFromJson(await _readJson(_recordsFile));
    final dividendRecords = _dividendRecordsFromJson(
      await _readJson(_dividendRecordsFile),
    );
    debugPrint(
      '[${DateTime.now().toString().substring(11, 19)}][本地] 加载完成: ${stocks.length} 只股票, ${records.length} 个股票记录, ${dividendRecords.length} 个派息记录',
    );

    return (stocks, records, dividendRecords);
  }

  /// 保存设置到本地 + 同步 iCloud
  static Future<void> pushSettingsToCloud(Map<String, dynamic> settings) async {
    await ensureInit();
    final localFile = File(_localFilePath(_settingsFile));
    await localFile.writeAsString(jsonEncode(settings));
    unawaited(_syncToCloud(_settingsFile));
  }

  /// 加载设置（拉取 iCloud 更新后读本地）
  static Future<Map<String, dynamic>> pullSettingsFromCloud() async {
    await ensureInit();
    await _syncFromCloud(_settingsFile);
    final local = File(_localFilePath(_settingsFile));
    if (!await local.exists()) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][本地] 设置文件不存在: $_settingsFile',
      );
      return {};
    }
    try {
      return jsonDecode(await local.readAsString()) as Map<String, dynamic>;
    } catch (e) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][本地] 设置读取失败: $e',
      );
      return {};
    }
  }

  /// 从本地 + iCloud 加载设置覆盖 SharedPreferences
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
    if (cloud.containsKey(SettingsService.keyDefaultFeeType)) {
      await prefs.setString(
        SettingsService.keyDefaultFeeType,
        cloud[SettingsService.keyDefaultFeeType],
      );
    }
    if (cloud.containsKey(SettingsService.keyDefaultFeeValue)) {
      await prefs.setDouble(
        SettingsService.keyDefaultFeeValue,
        (cloud[SettingsService.keyDefaultFeeValue] as num).toDouble(),
      );
    }
  }

  /// 把 SharedPreferences 上传到本地 + iCloud
  static Future<void> saveSettings() async {
    final enabled = await SettingsService.getSyncSettings();
    if (!enabled) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await pushSettingsToCloud({
      SettingsService.keyDefaultCurrency:
          prefs.getString(SettingsService.keyDefaultCurrency) ??
          DevConfig.defaultCurrency,
      SettingsService.keyKeepStockAfterClose:
          prefs.getBool(SettingsService.keyKeepStockAfterClose) ?? false,
      SettingsService.keySortColumn:
          prefs.getString(SettingsService.keySortColumn) ?? 'profit',
      SettingsService.keySortAscending:
          prefs.getBool(SettingsService.keySortAscending) ?? false,
      SettingsService.keyDefaultFeeType:
          prefs.getString(SettingsService.keyDefaultFeeType) ??
          SettingsService.feeTypeFixed,
      SettingsService.keyDefaultFeeValue:
          prefs.getDouble(SettingsService.keyDefaultFeeValue) ?? 0.0,
    });
  }

  static Future<void> _writeJson(String name, List<Map> data) async {
    final file = File(_localFilePath(name));
    try {
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][iCloud] 写入文件失败: $name - $e',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> _readJson(String name) async {
    final file = File(_localFilePath(name));
    if (!await file.exists()) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][本地] 文件不存在: $name',
      );
      return [];
    }
    try {
      final list = jsonDecode(await file.readAsString()) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][本地] 读取文件失败: $name - $e',
      );
      return [];
    }
  }

  /// 将本地文件同步到 iCloud（若开启了同步且有 iCloud 路径）
  static Future<void> _syncToCloud(String name) async {
    if (_cloudPath == null) return;
    final enabled = await SettingsService.getSyncSettings();
    if (!enabled) return;
    final local = File(_localFilePath(name));
    if (!await local.exists()) return;
    final cloud = File('$_cloudPath/$name');
    try {
      await cloud.writeAsString(await local.readAsString());
    } catch (e) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][iCloud] 同步到 iCloud 失败: $name - $e',
      );
    }
  }

  /// 从 iCloud 拉取更新到本地（若 iCloud 文件更新）
  static Future<void> _syncFromCloud(String name) async {
    if (_cloudPath == null) return;
    final enabled = await SettingsService.getSyncSettings();
    if (!enabled) return;
    final cloud = File('$_cloudPath/$name');
    if (!await cloud.exists()) return;
    try {
      final cloudTime = await cloud.lastModified();
      final local = File(_localFilePath(name));
      final localTime = await local.exists()
          ? await local.lastModified()
          : DateTime(0);
      if (cloudTime.isAfter(localTime)) {
        await local.writeAsString(await cloud.readAsString());
        debugPrint(
          '[${DateTime.now().toString().substring(11, 19)}][iCloud] 从 iCloud 同步到本地: $name',
        );
      }
    } catch (e) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][iCloud] 从 iCloud 拉取失败: $name - $e',
      );
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
                    'fee': r.fee,
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
              fee: (r['fee'] as num?)?.toDouble() ?? 0.0,
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

  // 收益快照 - 天粒度（历史）
  static Future<List<ProfitSnapshot>> loadDailyProfitHistory() async {
    await _migrateOldProfitData();
    await ensureInit();
    await _syncFromCloud(_dailyProfitFile);
    final data = await _readJson(_dailyProfitFile);
    debugPrint(
      '[${DateTime.now().toString().substring(11, 19)}][快照] 加载天级: ${data.length} 条',
    );
    return data.map((e) => ProfitSnapshot.fromJson(e)).toList();
  }

  static Future<void> saveDailyProfitHistory(
    List<ProfitSnapshot> snapshots,
  ) async {
    await ensureInit();
    debugPrint(
      '[${DateTime.now().toString().substring(11, 19)}][快照] 保存天级: ${snapshots.length} 条',
    );
    final data = snapshots.map((e) => e.toJson()).toList();
    await _writeJson(_dailyProfitFile, data);
    unawaited(_syncToCloud(_dailyProfitFile));
  }

  // 收益快照 - 10分钟粒度（仅当天）
  static Future<List<ProfitSnapshot>> loadIntradayProfitHistory() async {
    await _migrateOldProfitData();
    await ensureInit();
    await _syncFromCloud(_intradayProfitFile);
    final data = await _readJson(_intradayProfitFile);
    debugPrint(
      '[${DateTime.now().toString().substring(11, 19)}][快照] 加载10分钟: ${data.length} 条',
    );
    return data.map((e) => ProfitSnapshot.fromJson(e)).toList();
  }

  static Future<void> saveIntradayProfitHistory(
    List<ProfitSnapshot> snapshots,
  ) async {
    await ensureInit();
    final data = snapshots.map((e) => e.toJson()).toList();
    await _writeJson(_intradayProfitFile, data);
    unawaited(_syncToCloud(_intradayProfitFile));
  }

  /// 迁移旧的 profit_history.json 到双文件（只执行一次）
  static Future<void> _migrateOldProfitData() async {
    // 新文件已存在，跳过迁移
    if (await File(_localFilePath(_dailyProfitFile)).exists() &&
        await File(_localFilePath(_intradayProfitFile)).exists()) {
      return;
    }

    final file = File(_localFilePath(_profitHistoryFile));
    if (!await file.exists()) {
      // 本地没有旧文件时尝试从云端拉取
      await ensureInit();
      if (_cloudPath != null) {
        final cloudFile = File('$_cloudPath/$_profitHistoryFile');
        try {
          if (await cloudFile.exists()) {
            await cloudFile.copy(file.path);
            debugPrint(
              '[${DateTime.now().toString().substring(11, 19)}][迁移] 从云端拉取旧文件',
            );
          }
        } catch (e) {
          debugPrint(
            '[${DateTime.now().toString().substring(11, 19)}][迁移] 拉取失败: $e',
          );
        }
      }
      if (!await file.exists()) return;
    }

    await ensureInit();
    final data = await _readJson(_profitHistoryFile);

    if (data.isEmpty) {
      await file.delete();
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all = data.map((e) => ProfitSnapshot.fromJson(e)).toList();
    final daily = <ProfitSnapshot>[];
    final intraday = <ProfitSnapshot>[];

    // 按天分组，取每天最后一条
    final Map<String, ProfitSnapshot> lastPerDay = {};
    for (final s in all) {
      final day = DateTime(s.time.year, s.time.month, s.time.day);
      if (day == today) {
        intraday.add(s);
        continue;
      }
      final key = day.toIso8601String();
      final existing = lastPerDay[key];
      if (existing == null || s.time.isAfter(existing.time)) {
        lastPerDay[key] = s;
      }
    }
    daily.addAll(lastPerDay.values);
    daily.sort((a, b) => a.time.compareTo(b.time));
    daily.removeWhere((s) => now.difference(s.time).inDays > 365);

    await saveDailyProfitHistory(daily);
    intraday.sort((a, b) => a.time.compareTo(b.time));
    await saveIntradayProfitHistory(intraday);

    // 删除本地旧文件，避免重复迁移
    try {
      if (await file.exists()) {
        await file.delete();
      }
      // 同步删除云端旧文件
      if (_cloudPath != null) {
        final cloudFile = File('$_cloudPath/$_profitHistoryFile');
        if (await cloudFile.exists()) {
          await cloudFile.delete();
        }
      }
    } catch (_) {}
    debugPrint(
      '[${DateTime.now().toString().substring(11, 19)}][迁移] 完成: 天级 ${daily.length} 条, 当日 ${intraday.length} 条',
    );
  }

  /// 强制同步收益快照到 iCloud
  static Future<void> syncProfitToCloud() async {
    await ensureInit();
    unawaited(_syncToCloud(_dailyProfitFile));
    unawaited(_syncToCloud(_intradayProfitFile));
  }

  static Future<void> recordProfitIfNeeded(double totalProfit) async {
    await _migrateOldProfitData();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var daily = await loadDailyProfitHistory();
    var intraday = await loadIntradayProfitHistory();

    debugPrint(
      '[${now.toString().substring(11, 19)}][快照] 记录 profit=$totalProfit, 天级=${daily.length}, 10分钟=${intraday.length}',
    );

    // 检查是否跨天：将昨天最后一条转存为天级
    if (intraday.isNotEmpty) {
      final last = intraday.last;
      final lastDay = DateTime(last.time.year, last.time.month, last.time.day);
      if (lastDay.isBefore(today)) {
        debugPrint(
          '[${now.toString().substring(11, 19)}][快照] 跨天: 最后一条 ${last.time.toString().substring(0, 19)} → 转存为天级',
        );
        daily.add(
          ProfitSnapshot(time: last.time, totalProfit: last.totalProfit),
        );
        daily.sort((a, b) => a.time.compareTo(b.time));
        daily.removeWhere((s) => now.difference(s.time).inDays > 365);
        await saveDailyProfitHistory(daily);
        intraday.clear();
      }
    }

    // 去重：相同值且10分钟内不重复记录
    if (intraday.isNotEmpty) {
      final last = intraday.last;
      if (last.totalProfit == totalProfit &&
          now.difference(last.time).inMinutes < 10) {
        debugPrint(
          '[${now.toString().substring(11, 19)}][快照] 跳过: 相同值 $totalProfit，距上次 ${now.difference(last.time).inMinutes} 分钟',
        );
        return;
      }
    }

    intraday.add(ProfitSnapshot(time: now, totalProfit: totalProfit));
    await saveIntradayProfitHistory(intraday);

    debugPrint(
      '[${now.toString().substring(11, 19)}][快照] 已保存: 10分钟=${intraday.length} 条',
    );
  }
}
