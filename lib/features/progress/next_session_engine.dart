import '../workout/workout_model.dart';
import 'exercise_target.dart';

class NextSessionRecommendation {
  const NextSessionRecommendation({required this.exerciseName, required this.weightKg, required this.reps, required this.rir, required this.message, required this.status});
  final String exerciseName;
  final double weightKg;
  final int reps;
  final int rir;
  final String message;
  final NextSessionStatus status;
}

enum NextSessionStatus { progress, repeat, reduce, firstSession }

NextSessionRecommendation recommendNextSession({required String exerciseName, required ExerciseTarget? target, required List<WorkoutSession> sessions}) {
  final previous = _latestExercise(exerciseName, sessions);
  if (previous == null || previous.sets.isEmpty) {
    final weight = target?.targetWeightKg ?? 0;
    final reps = target?.minReps ?? 8;
    final rir = target?.targetRir ?? 2;
    return NextSessionRecommendation(exerciseName: exerciseName, weightKg: weight, reps: reps, rir: rir, status: NextSessionStatus.firstSession, message: target == null ? 'No hay histórico suficiente. Registra la primera sesión para que Gimforze pueda ajustar la progresión.' : 'Primera sesión con objetivo definido: ${_fmt(weight)} kg, ${target.minReps}-${target.maxReps} repeticiones y RIR ${target.targetRir}.');
  }

  final best = previous.sets.reduce((a, b) => a.reps > b.reps ? a : b);
  final effectiveTarget = target ?? ExerciseTarget(exerciseName: exerciseName, targetWeightKg: best.weightKg, minReps: 6, maxReps: 10, targetRir: best.rir, incrementKg: 2.5);
  final allHitRange = previous.sets.every((s) => s.reps >= effectiveTarget.maxReps && s.rir <= effectiveTarget.targetRir + 1);
  final belowRange = previous.sets.where((s) => s.reps < effectiveTarget.minReps).length >= (previous.sets.length / 2).ceil();

  if (allHitRange) {
    final nextWeight = best.weightKg + effectiveTarget.incrementKg;
    return NextSessionRecommendation(exerciseName: exerciseName, weightKg: nextWeight, reps: effectiveTarget.minReps, rir: effectiveTarget.targetRir, status: NextSessionStatus.progress, message: 'Has completado el rango objetivo. Gimforze propone subir ${_fmt(effectiveTarget.incrementKg)} kg y volver al mínimo de repeticiones.');
  }
  if (belowRange) {
    final nextWeight = target == null ? best.weightKg : effectiveTarget.targetWeightKg;
    return NextSessionRecommendation(exerciseName: exerciseName, weightKg: nextWeight, reps: effectiveTarget.minReps, rir: effectiveTarget.targetRir + 1 > 4 ? 4 : effectiveTarget.targetRir + 1, status: NextSessionStatus.reduce, message: 'No has alcanzado el mínimo de repeticiones. Gimforze recomienda mantener la carga y trabajar con un RIR ligeramente mayor hasta consolidarla.');
  }
  return NextSessionRecommendation(exerciseName: exerciseName, weightKg: target?.targetWeightKg ?? best.weightKg, reps: effectiveTarget.minReps, rir: effectiveTarget.targetRir, status: NextSessionStatus.repeat, message: 'Mantén la carga y trata de completar el rango de repeticiones antes de subir peso.');
}

SessionExercise? _latestExercise(String name, List<WorkoutSession> sessions) {
  final normalized = _norm(name);
  for (final session in [...sessions]..sort((a, b) => b.date.compareTo(a.date))) {
    for (final exercise in session.exercises) {
      if (_norm(exercise.exerciseName) == normalized) return exercise;
    }
  }
  return null;
}

String _norm(String value) => value.toLowerCase().replaceAll(RegExp(r'[áàäâ]'), 'a').replaceAll(RegExp(r'[éèëê]'), 'e').replaceAll(RegExp(r'[íìïî]'), 'i').replaceAll(RegExp(r'[óòöô]'), 'o').replaceAll(RegExp(r'[úùüû]'), 'u').trim();
String _fmt(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
