import '../workout/workout_model.dart';
import 'exercise_target.dart';

class TargetProgressPoint {
  const TargetProgressPoint({required this.date, required this.actualVolumeKg, required this.targetVolumeKg, required this.actualWeightKg, required this.targetWeightKg, required this.actualReps, required this.targetMinReps, required this.targetMaxReps, required this.actualRir, required this.targetRir, required this.compliance});
  final DateTime date;
  final double actualVolumeKg;
  final double targetVolumeKg;
  final double actualWeightKg;
  final double targetWeightKg;
  final int actualReps;
  final int targetMinReps;
  final int targetMaxReps;
  final double actualRir;
  final int targetRir;
  final double compliance;
}

enum TargetStatus { cumple, parcial, porDebajo, sinDatos }

class TargetProgressReport {
  const TargetProgressReport({required this.exerciseName, required this.target, required this.points});
  final String exerciseName;
  final ExerciseTarget? target;
  final List<TargetProgressPoint> points;

  TargetStatus get status {
    if (points.isEmpty) return TargetStatus.sinDatos;
    final last = points.last;
    if (last.compliance >= 1) return TargetStatus.cumple;
    if (last.compliance >= .75) return TargetStatus.parcial;
    return TargetStatus.porDebajo;
  }

  double get averageCompliance => points.isEmpty ? 0 : points.fold<double>(0, (sum, p) => sum + p.compliance) / points.length;
}

TargetProgressReport buildTargetProgress({required String exerciseName, required ExerciseTarget? target, required List<WorkoutSession> sessions}) {
  if (target == null) return TargetProgressReport(exerciseName: exerciseName, target: null, points: const []);
  final normalized = _normalize(exerciseName);
  final ordered = [...sessions]..sort((a, b) => a.date.compareTo(b.date));
  final points = <TargetProgressPoint>[];
  for (final session in ordered) {
    for (final exercise in session.exercises.where((e) => _normalize(e.exerciseName) == normalized)) {
      final valid = exercise.sets.where((s) => s.weightKg > 0 && s.reps > 0).toList();
      if (valid.isEmpty) continue;
      final actualVolume = valid.fold<double>(0, (sum, set) => sum + set.volumeKg);
      final targetMidReps = (target.minReps + target.maxReps) / 2;
      final targetVolume = valid.length * target.targetWeightKg * targetMidReps;
      final avgRir = valid.fold<double>(0, (sum, set) => sum + set.rir) / valid.length;
      final repsInRange = valid.where((s) => s.reps >= target.minReps && s.reps <= target.maxReps).length / valid.length;
      final weightScore = target.targetWeightKg <= 0 ? 1.0 : (valid.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b) / target.targetWeightKg).clamp(0.0, 1.0);
      final rirScore = (1 - (avgRir - target.targetRir).abs() / 3).clamp(0.0, 1.0);
      final compliance = (repsInRange * .55 + weightScore * .30 + rirScore * .15).clamp(0.0, 1.0);
      points.add(TargetProgressPoint(date: session.date, actualVolumeKg: actualVolume, targetVolumeKg: targetVolume, actualWeightKg: valid.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b), targetWeightKg: target.targetWeightKg, actualReps: valid.fold<int>(0, (sum, s) => sum + s.reps), targetMinReps: target.minReps, targetMaxReps: target.maxReps, actualRir: avgRir, targetRir: target.targetRir, compliance: compliance));
    }
  }
  return TargetProgressReport(exerciseName: exerciseName, target: target, points: points);
}

String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[áàäâ]'), 'a').replaceAll(RegExp(r'[éèëê]'), 'e').replaceAll(RegExp(r'[íìïî]'), 'i').replaceAll(RegExp(r'[óòöô]'), 'o').replaceAll(RegExp(r'[úùüû]'), 'u').trim();
