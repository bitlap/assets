import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProfitSnapshot {
  final DateTime time;
  final double totalProfit;

  ProfitSnapshot({required this.time, required this.totalProfit});

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'totalProfit': totalProfit,
  };

  factory ProfitSnapshot.fromJson(Map<String, dynamic> json) => ProfitSnapshot(
    time: DateTime.parse(json['time'] as String),
    totalProfit: (json['totalProfit'] as num).toDouble(),
  );
}

class ProfitHistoryService {
  static const _fileName = 'profit_history.json';

  static Future<List<ProfitSnapshot>> load() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      return list
          .map((e) => ProfitSnapshot.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<ProfitSnapshot> snapshots) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    final content = jsonEncode(snapshots.map((e) => e.toJson()).toList());
    await file.writeAsString(content);
  }

  static Future<void> recordIfNeeded(double totalProfit) async {
    final snapshots = await load();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todaySnapshot = snapshots.lastWhere(
      (s) =>
          s.time.year == today.year &&
          s.time.month == today.month &&
          s.time.day == today.day,
      orElse: () => ProfitSnapshot(time: today, totalProfit: totalProfit),
    );

    if (todaySnapshot.time == today &&
        todaySnapshot.totalProfit != totalProfit) {
      snapshots.removeWhere(
        (s) =>
            s.time.year == today.year &&
            s.time.month == today.month &&
            s.time.day == today.day,
      );
      snapshots.add(ProfitSnapshot(time: now, totalProfit: totalProfit));
    } else if (todaySnapshot.time != today) {
      snapshots.add(ProfitSnapshot(time: now, totalProfit: totalProfit));
    }

    snapshots.sort((a, b) => a.time.compareTo(b.time));
    await save(snapshots);
  }
}
