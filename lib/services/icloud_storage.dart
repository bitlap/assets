import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/stock_model.dart';

/// iCloud 数据同步服务（带本地 fallback）
class IcloudStorage {
  static const _channel = MethodChannel('org.bitlap.assets/icloud');
  static const _stocksFile = 'stocks.json';
  static const _recordsFile = 'records.json';
  static const _settingsFile = 'settings.json';

  static String? _cloudPath;
  static String? _localPath;

  /// 初始化（获取 iCloud / 本地路径）
  static Future<void> ensureInit() async {
    if (_cloudPath != null) return;

    // 本地路径
    final localDir = await getApplicationDocumentsDirectory();
    _localPath = localDir.path;

    // 尝试获取 iCloud 路径
    try {
      final cloudPath = await _channel.invokeMethod<String>('getContainerUrl');
      if (cloudPath != null && cloudPath.isNotEmpty) {
        final dir = Directory(cloudPath);
        if (!await dir.exists()) await dir.create(recursive: true);
        _cloudPath = cloudPath;
      }
    } catch (_) {}
  }

  /// 当前使用的存储路径（iCloud → 本地 fallback）
  static String get _storagePath => _cloudPath ?? _localPath!;

  static String _filePath(String name) => '$_storagePath/$name';

  /// 保存股票和记录到 iCloud（本地兜底）
  static Future<void> saveAll(
    List<StockModel> stocks,
    Map<String, List<OperationRecord>> records,
  ) async {
    await ensureInit();
    await _writeJson(_stocksFile, _stocksToJson(stocks));
    await _writeJson(_recordsFile, _recordsToJson(records));
  }

  /// 加载股票和记录（优先 iCloud）
  static Future<
    (List<StockModel> stocks, Map<String, List<OperationRecord>> records)
  >
  loadAll() async {
    await ensureInit();

    final stocks = _stocksFromJson(await _readJson(_stocksFile));
    final records = _recordsFromJson(await _readJson(_recordsFile));

    // 首次启动：若 iCloud 为空，尝试从本地迁移
    if (stocks.isEmpty && records.isEmpty && _cloudPath != null) {
      final localStocks = _stocksFromJson(await _readLocalJson(_stocksFile));
      final localRecords = _recordsFromJson(await _readLocalJson(_recordsFile));
      if (localStocks.isNotEmpty || localRecords.isNotEmpty) {
        await saveAll(localStocks, localRecords);
        return (localStocks, localRecords);
      }
    }

    return (stocks, records);
  }

  /// 保存设置到 iCloud
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await ensureInit();
    final file = File(_filePath(_settingsFile));
    await file.writeAsString(jsonEncode(settings));
  }

  /// 加载设置（优先 iCloud）
  static Future<Map<String, dynamic>> loadSettings() async {
    await ensureInit();
    final file = File(_filePath(_settingsFile));
    if (!await file.exists()) return {};
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeJson(String name, List<Map> data) async {
    final file = File(_filePath(name));
    await file.writeAsString(jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>> _readJson(String name) async {
    final file = File(_filePath(name));
    if (!await file.exists()) return [];
    try {
      final list = jsonDecode(await file.readAsString()) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _readLocalJson(String name) async {
    final file = File('$_localPath/$name');
    if (!await file.exists()) return [];
    try {
      final list = jsonDecode(await file.readAsString()) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ========== 序列化 ==========

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
            marketType: j['marketType'] as String,
            changePercent: (j['changePercent'] as num).toDouble(),
            currency: j['currency'] as String,
            secid: j['secid'] as String,
          ),
        )
        .toList();
  }

  static List<Map<String, dynamic>> _recordsToJson(
    Map<String, List<OperationRecord>> records,
  ) {
    return records.entries
        .map(
          (e) => {
            'symbol': e.key,
            'records': e.value
                .map(
                  (r) => {
                    'date': r.date.toIso8601String(),
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
              date: DateTime.parse(r['date'] as String),
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
}
