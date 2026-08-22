import '../progress/muscle_volume.dart';
import '../workout/workout_model.dart';

class AiWeeklyAnalysis {
  const AiWeeklyAnalysis({
    required this.totalSessions,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.estimatedMinutes,
    required this.muscleSets,
    required this.recoveryWarnings,
    required this.recommendations,
  });

  final int totalSessions;
  final int totalSets;
  final double totalVolumeKg;
  final int estimatedMinutes;
  final Map<String, int> muscleSets;
  final List<String> recoveryWarnings;
  final List<String> recommendations;

  int get activeMuscles => muscleSets.values.where((v) => v > 0).length;
}

class AiWeeklyAnalyzer {
  static AiWeeklyAnalysis analyze(List<WorkoutPlan> plans, List<WorkoutSession> sessions) {
    final muscleSets = <String, int>{};
    for (final plan in plans) {
      for (final exercise in plan.exercises) {
        final group = muscleGroupForExercise(exercise.exerciseName);
        muscleSets[group] = (muscleSets[group] ?? 0) + exercise.sets;
      }
    }

    final totalSets = plans.fold<int>(0, (sum, plan) => sum + plan.exercises.fold<int>(0, (s, e) => s + e.sets));
    final estimatedMinutes = plans.fold<int>(0, (sum, plan) {
      final rest = plan.exercises.fold<int>(0, (s, e) => s + ((e.sets - 1).clamp(0, 20) * e.restSeconds));
      final work = plan.exercises.fold<int>(0, (s, e) => s + e.sets * 45);
      return sum + ((rest + work) / 60).ceil();
    });

    final sorted = [...plans]..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    final warnings = <String>[];
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].dayOfWeek - sorted[i - 1].dayOfWeek == 1) {
        final previous = _groups(sorted[i - 1]);
        final current = _groups(sorted[i]);
        final overlap = previous.intersection(current);
        if (overlap.isNotEmpty) warnings.add('Hay sesiones consecutivas con trabajo compartido de ${overlap.join(', ')}. Revisa la recuperación.');
      }
    }

    if (muscleSets.values.any((v) => v >= 20)) warnings.add('Hay al menos un grupo muscular con 20 o más series semanales planificadas. Conviene revisar el volumen y la recuperación.');
    if (plans.length >= 5 && sorted.any((p) => p.dayOfWeek == 7) && sorted.any((p) => p.dayOfWeek == 1)) warnings.add('Has planificado domingo y lunes consecutivos. Comprueba que la distribución encaja con tu recuperación.');

    final recommendations = <String>[];
    if (plans.isEmpty) {
      recommendations.add('Crea al menos una rutina semanal para poder analizar la distribución.');
    } else {
      final minSets = muscleSets.entries.where((e) => e.value > 0).fold<MapEntry<String, int>?>(null, (best, item) => best == null || item.value < best.value ? item : best);
      final maxSets = muscleSets.entries.where((e) => e.value > 0).fold<MapEntry<String, int>?>(null, (best, item) => best == null || item.value > best.value ? item : best);
      if (minSets != null && maxSets != null && maxSets.value >= minSets.value * 3) recommendations.add('La distribución semanal es muy desigual: ${maxSets.key} tiene ${maxSets.value} series frente a ${minSets.key} con ${minSets.value}.');
      if (estimatedMinutes / plans.length > 90) recommendations.add('La duración estimada supera 90 minutos de media. Considera reducir ejercicios o descansos si buscas sesiones más cortas.');
      if (sessions.length >= 3) recommendations.add('Se han usado también sesiones registradas para contextualizar el análisis, aunque la propuesta se basa principalmente en la rutina planificada.');
      if (recommendations.isEmpty) recommendations.add('La distribución semanal no presenta señales claras que requieran cambios automáticos.');
    }

    final recent = sessions.take(8).toList();
    final volume = recent.fold<double>(0, (sum, s) => sum + s.volumeKg);
    return AiWeeklyAnalysis(
      totalSessions: plans.length,
      totalSets: totalSets,
      totalVolumeKg: volume,
      estimatedMinutes: estimatedMinutes,
      muscleSets: Map.unmodifiable(muscleSets),
      recoveryWarnings: List.unmodifiable(warnings.toSet()),
      recommendations: List.unmodifiable(recommendations),
    );
  }

  static Set<String> _groups(WorkoutPlan plan) => plan.exercises.map((e) => muscleGroupForExercise(e.exerciseName)).toSet();
}
