import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import '../config/app_config.dart';

/// 汇率服务 - 使用免费 API 获取实时汇率
/// 单例模式，带缓存和熔断机制
class ExchangeRateService {
  static final ExchangeRateService _instance = ExchangeRateService._internal();
  factory ExchangeRateService() => _instance;
  ExchangeRateService._internal();

  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  /// 汇率缓存
  Map<String, double>? _cachedRates;
  DateTime? _lastFetchTime;
  static const Duration _cacheTTL = Duration(
    minutes: AppConfig.exchangeRateCacheTTLMin,
  );

  /// 熔断机制（与股票服务独立，互不影响）
  int _consecutiveFailures = 0;
  DateTime? _cooldownUntil;
  static const int _failureThreshold = AppConfig.failureThreshold;
  static const Duration _cooldownDuration = Duration(
    minutes: AppConfig.cooldownDurationMin,
  );

  bool get _isInCooldown {
    if (_cooldownUntil == null) return false;
    if (DateTime.now().isAfter(_cooldownUntil!)) {
      _cooldownUntil = null;
      _consecutiveFailures = 0;
      return false;
    }
    return true;
  }

  int get cooldownRemainingSeconds {
    if (_cooldownUntil == null) return 0;
    final remaining = _cooldownUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void _onRequestSuccess() {
    _consecutiveFailures = 0;
    _cooldownUntil = null;
  }

  void _onRequestFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _failureThreshold) {
      _cooldownUntil = DateTime.now().add(_cooldownDuration);
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][汇率] ===> 连续失败$_consecutiveFailures次，进入冷却期${_cooldownDuration.inMinutes}分钟',
      );
    } else {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][汇率] ===> 请求失败 ($_consecutiveFailures/$_failureThreshold)',
      );
    }
  }

  /// 获取当前汇率（优先用缓存，无缓存返回 null）
  Map<String, double>? get currentRates => _cachedRates;

  /// 是否已有有效缓存
  bool get hasValidCache =>
      _cachedRates != null &&
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < _cacheTTL;

  /// 获取实时汇率，返回各币种对 USD 的汇率
  /// 1 USD = X 目标货币
  Future<Map<String, double>?> fetchRates() async {
    // 缓存有效，直接返回
    if (hasValidCache) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][汇率] ===> 缓存有效，跳过请求',
      );
      return _cachedRates;
    }

    // 熔断中
    if (_isInCooldown) {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][汇率] ===> 冷却期中，跳过请求 (剩余${cooldownRemainingSeconds}秒)',
      );
      return _cachedRates; // 返回旧缓存
    }

    debugPrint(
      '[${DateTime.now().toString().substring(11, 19)}][汇率] ===> 开始请求汇率...',
    );
    Client? client;
    try {
      client = Client();
      final response = await client
          .get(Uri.parse(_apiUrl))
          .timeout(Duration(seconds: AppConfig.httpTimeoutSec));
      client.close();
      client = null;

      if (response.statusCode == 200) {
        _onRequestSuccess();
        final data = json.decode(response.body);
        final rates = <String, double>{};
        final rawRates = data['rates'] as Map<String, dynamic>;

        for (final entry in rawRates.entries) {
          rates[entry.key] = (entry.value as num).toDouble();
        }

        _cachedRates = rates;
        _lastFetchTime = DateTime.now();
        debugPrint(
          '[${DateTime.now().toString().substring(11, 19)}][汇率] ===> 更新成功: USD=${rates['USD']}, CNY=${rates['CNY']}, HKD=${rates['HKD']}',
        );
        return rates;
      }
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][汇率] ===> HTTP ${response.statusCode}',
      );
      return _cachedRates;
    } catch (e) {
      client?.close();
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][汇率] ===> 请求失败: $e',
      );
      _onRequestFailure();
      return _cachedRates; // 失败时返回旧缓存
    }
  }
}
