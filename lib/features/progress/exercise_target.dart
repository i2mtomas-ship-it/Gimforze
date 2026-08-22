import 'dart:convert';

class ExerciseTarget {
  const ExerciseTarget({
    required this.exerciseName,
    required this.targetWeightKg,
    this.minReps = 6,
    this.maxReps = 10,
    this.targetRir = 2,
    this.incrementKg = 2.5,
  });

  final String exerciseName;
  final double targetWeightKg;
  final int minReps;
  final int maxReps;
  final int targetRir;
  final double incrementKg;

  ExerciseTarget copyWith({double? targetWeightKg, int? minReps, int? maxReps, int? targetRir, double? incrementKg}) => ExerciseTarget(
    exerciseName: exerciseName,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    minReps: minReps ?? this.minReps,
    maxReps: maxReps ?? this.maxReps,
    targetRir: targetRir ?? this.targetRir,
    incrementKg: incrementKg ?? this.incrementKg,
  );

  Map<String, dynamic> toJson() => {
    'exerciseName': exerciseName,
    'targetWeightKg': targetWeightKg,
    'minReps': minReps,
    'maxReps': maxReps,
    'targetRir': targetRir,
    'incrementKg': incrementKg,
  };

  factory ExerciseTarget.fromJson(Map<String, dynamic> json) => ExerciseTarget(
    exerciseName: json['exerciseName'] as String? ?? 'Ejercicio',
    targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 0,
    minReps: (json['minReps'] as num?)?.toInt() ?? 6,
    maxReps: (json['maxReps'] as num?)?.toInt() ?? 10,
    targetRir: (json['targetRir'] as num?)?.toInt() ?? 2,
    incrementKg: (json['incrementKg'] as num?)?.toDouble() ?? 2.5,
  );

  static List<ExerciseTarget> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.whereType<Map<String, dynamic>>().map(ExerciseTarget.fromJson).toList();
  }

  static String encodeList(List<ExerciseTarget> values) => jsonEncode(values.map((e) => e.toJson()).toList());
}
