import '../workout/workout_model.dart';

class ExerciseProgress {
  const ExerciseProgress({
    required this.exerciseName,
    required this.sessions,
    required this.bestWeightKg,
    required this.bestReps,
    required this.bestEstimated1RmKg,
    required this.firstVolumeKg,
    required this.lastVolumeKg,
    required this.volumeChangePercent,
    required this.weightChangePercent,
    required this.trend,
    required this.stagnant,
  });

  final String exerciseName;
  final int sessions;
  final double bestWeightKg;
  final int bestReps;
  final double bestEstimated1RmKg;
  final double firstVolumeKg;
  final double lastVolumeKg;
  final double? volumeChangePercent;
  final double? weightChangePercent;
  final ProgressTrend trend;
  final bool stagnant;
}

enum ProgressTrend { ascending, stable, descending, insufficientData }

List<ExerciseProgress> analyseExercises(List<WorkoutSession> sessions) {
  final names = <String>{
    for (final session in sessions)
      for (final exercise in session.exercises)
        exercise.exerciseName,
  };
  return names.map((name) => analyseExercise(sessions, name)).toList()
    ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
}

ExerciseProgress analyseExercise(List<WorkoutSession> sessions, String name) {
  final points = <_ExercisePoint>[];
  for (final session in sessions) {
    for (final exercise in session.exercises.where((e) => e.exerciseName == name)) {
      if (exercise.sets.isEmpty) continue;
      final volume = exercise.volumeKg;
      final best = exercise.sets.reduce((a, b) => a.weightKg >= b.weightKg ? a : b);
      final best1Rm = exercise.sets
          .map((s) => estimated1Rm(s.weightKg, s.reps))
          .fold<double>(0, (v, x) => x > v ? x : v);
      points.add(_ExercisePoint(session.date, volume, best.weightKg, best1Rm));
    }
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  if (points.isEmpty) {
    return ExerciseProgress(
      exerciseName: name,
      sessions: 0,
      bestWeightKg: 0,
      bestReps: 0,
      bestEstimated1RmKg: 0,
      firstVolumeKg: 0,
      lastVolumeKg: 0,
      volumeChangePercent: null,
      weightChangePercent: null,
      trend: ProgressTrend.insufficientData,
      stagnant: false,
    );
  }

  final bestWeight = points.map((p) => p.weight).fold<double>(0, (v, x) => x > v ? x : v);
  final bestPoint = points.reduce((a, b) => a.weight > b.weight || (a.weight == b.weight && a.estimated1Rm >= b.estimated1Rm) ? a : b);
  final bestReps = _bestRepsForWeight(sessions, name, bestWeight);
  final firstVolume = points.first.volume;
  final lastVolume = points.last.volume;
  final volumeChange = percentageChange(lastVolume, firstVolume);
  final firstWeight = points.first.weight;
  final lastWeight = points.last.weight;
  final weightChange = percentageChange(lastWeight, firstWeight);

  final recent = points.length >= 3 ? points.sublist(points.length - 3) : points;
  final trend = _trend(recent);
  final stagnant = points.length >= 3 && _isStagnant(points);

  return ExerciseProgress(
    exerciseName: name,
    sessions: points.length,
    bestWeightKg: bestWeight,
    bestReps: bestReps,
    bestEstimated1RmKg: bestPoint.estimated1Rm,
    firstVolumeKg: firstVolume,
    lastVolumeKg: lastVolume,
    volumeChangePercent: volumeChange,
    weightChangePercent: weightChange,
    trend: trend,
    stagnant: stagnant,
  );
}

double estimated1Rm(double weightKg, int reps) {
  if (weightKg <= 0 || reps <= 0) return 0;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30.0);
}

double? percentageChange(double current, double previous) {
  if (previous == 0) return current == 0 ? 0 : null;
  return ((current - previous) / previous) * 100;
}

ProgressTrend _trend(List<_ExercisePoint> points) {
  if (points.length < 2) return ProgressTrend.insufficientData;
  final first = points.first.estimated1Rm;
  final last = points.last.estimated1Rm;
  if (first == 0) return ProgressTrend.insufficientData;
  final change = (last - first) / first;
  if (change > 0.03) return ProgressTrend.ascending;
  if (change < -0.03) return ProgressTrend.descending;
  return ProgressTrend.stable;
}

bool _isStagnant(List<_ExercisePoint> points) {
  final recent = points.sublist(points.length - 3);
  final first = recent.first.estimated1Rm;
  final last = recent.last.estimated1Rm;
  if (first == 0) return false;
  return ((last - first).abs() / first) < 0.02;
}

int _bestRepsForWeight(List<WorkoutSession> sessions, String name, double weight) {
  var best = 0;
  for (final session in sessions) {
    for (final exercise in session.exercises.where((e) => e.exerciseName == name)) {
      for (final set in exercise.sets) {
        if ((set.weightKg - weight).abs() < 0.001 && set.reps > best) best = set.reps;
      }
    }
  }
  return best;
}

class _ExercisePoint {
  const _ExercisePoint(this.date, this.volume, this.weight, this.estimated1Rm);
  final DateTime date;
  final double volume;
  final double weight;
  final double estimated1Rm;
}
