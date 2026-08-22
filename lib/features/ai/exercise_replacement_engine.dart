import '../exercises/exercise_model.dart';
import '../workout/workout_model.dart';

class ExerciseReplacement {
  const ExerciseReplacement({required this.original, required this.replacement, required this.reason, required this.score});
  final String original;
  final Exercise replacement;
  final String reason;
  final int score;
}

class ExerciseReplacementEngine {
  static List<ExerciseReplacement> findAlternatives({
    required WorkoutExercise target,
    required List<Exercise> catalog,
    List<String> preferredEquipment = const [],
    List<String> excludedNames = const [],
    int limit = 5,
  }) {
    final targetText = target.exerciseName.toLowerCase();
    final excluded = excludedNames.map((e) => e.toLowerCase()).toSet();
    final scored = <ExerciseReplacement>[];
    for (final exercise in catalog) {
      if (exercise.name.trim().isEmpty || exercise.name.toLowerCase() == targetText) continue;
      if (excluded.contains(exercise.name.toLowerCase())) continue;
      var score = 0;
      final targetMuscle = _inferMuscle(targetText);
      if (targetMuscle != null && _matchesMuscle(exercise, targetMuscle)) score += 50;
      if (preferredEquipment.isNotEmpty && exercise.equipment != null && preferredEquipment.any((e) => e.toLowerCase() == exercise.equipment!.toLowerCase())) score += 20;
      if (exercise.primaryMuscles.isNotEmpty) score += 10;
      if (exercise.instructions.isNotEmpty) score += 10;
      if (exercise.videoUrl != null || exercise.images.isNotEmpty) score += 5;
      final targetCategory = _categoryHint(targetText);
      if (targetCategory != null && _categoryHint(exercise.name.toLowerCase()) == targetCategory) score += 10;
      if (score > 0) {
        final muscleLabel = exercise.primaryMuscles.isEmpty ? 'músculo compatible' : exercise.primaryMuscles.first;
        scored.add(ExerciseReplacement(original: target.exerciseName, replacement: exercise, reason: 'Alternativa para trabajar $muscleLabel manteniendo un perfil de movimiento similar.', score: score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).toList();
  }

  static bool _matchesMuscle(Exercise e, String muscle) {
    final all = [...e.primaryMuscles, ...e.secondaryMuscles].join(' ').toLowerCase();
    return all.contains(muscle);
  }

  static String? _inferMuscle(String text) {
    const groups = {
      'pecho': ['pecho', 'banca', 'pectoral'],
      'espalda': ['espalda', 'remo', 'jalón', 'jalon', 'dorsal'],
      'piernas': ['sentadilla', 'prensa', 'pierna', 'cuádriceps', 'cuadriceps', 'isquio', 'femoral', 'glúteo', 'gluteo'],
      'hombros': ['hombro', 'militar', 'elevación lateral', 'elevaciones laterales'],
      'bíceps': ['bíceps', 'biceps', 'curl'],
      'tríceps': ['tríceps', 'triceps', 'extensión de tríceps', 'extension de triceps'],
    };
    for (final entry in groups.entries) {
      if (entry.value.any(text.contains)) return entry.key;
    }
    return null;
  }

  static String? _categoryHint(String text) {
    if (text.contains('press') || text.contains('empuje')) return 'empuje';
    if (text.contains('remo') || text.contains('jalón') || text.contains('jalon') || text.contains('tirón') || text.contains('tiron')) return 'tirón';
    if (text.contains('curl')) return 'curl';
    if (text.contains('sentadilla') || text.contains('prensa')) return 'pierna';
    return null;
  }
}
