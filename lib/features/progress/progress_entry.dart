import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressEntry {
  const ProgressEntry({required this.date, required this.weightKg, required this.waistCm});
  final DateTime date;
  final double weightKg;
  final double waistCm;

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'weight': weightKg, 'waist': waistCm};
  factory ProgressEntry.fromJson(Map<String, dynamic> j) => ProgressEntry(date: DateTime.parse(j['date'] as String), weightKg: (j['weight'] as num).toDouble(), waistCm: (j['waist'] as num).toDouble());

  static List<ProgressEntry> fromPrefs(SharedPreferences p) {
    final raw = p.getString('progress.entries'); if (raw == null) return [];
    try { return (jsonDecode(raw) as List).map((e) => ProgressEntry.fromJson(Map<String, dynamic>.from(e))).toList()..sort((a,b) => b.date.compareTo(a.date)); } catch (_) { return []; }
  }
  static Future<void> saveAll(SharedPreferences p, List<ProgressEntry> entries) async => p.setString('progress.entries', jsonEncode(entries.map((e) => e.toJson()).toList()));
}
