import '../progress/progression_engine.dart';
import '../progress/muscle_volume.dart';
import '../workout/workout_model.dart';

class AiPlanRecommendation {
  const AiPlanRecommendation({required this.title, required this.reason, required this.changes, required this.confidence});
  final String title;
  final String reason;
  final List<String> changes;
  final String confidence;
}

class AiPlanProposal {
  const AiPlanProposal({required this.plan, required this.recommendations});
  final WorkoutPlan plan;
  final List<AiPlanRecommendation> recommendations;
}

class AiDecisionEngine {
  static AiPlanProposal propose(WorkoutPlan plan, List<WorkoutSession> sessions) {
    if (sessions.length < 3 || plan.exercises.isEmpty) {
      return AiPlanProposal(
        plan: plan,
        recommendations: const [AiPlanRecommendation(
          title: 'Aún no modificaría la rutina',
          reason: 'Gimforze necesita al menos 3 sesiones registradas y ejercicios con datos antes de proponer cambios de entrenamiento.',
          changes: ['Continúa registrando peso, repeticiones y RIR en cada serie.'],
          confidence: 'Baja',
        )],
      );
    }

    final progress = {for (final item in analyseExercises(sessions)) item.exerciseName: item};
    final volume = volumeByMuscle(sessions);
    final changed = <WorkoutExercise>[];
    final recommendations = <AiPlanRecommendation>[];

    for (final exercise in plan.exercises) {
      final p = progress[exercise.exerciseName];
      if (p == null || p.sessions < 3) {
        changed.add(exercise);
        continue;
      }

      if (p.stagnant) {
        final newRir = exercise.rir < 3 ? exercise.rir + 1 : exercise.rir;
        final newSets = exercise.sets > 2 ? exercise.sets - 1 : exercise.sets;
        changed.add(exercise.copyWith(sets: newSets, rir: newRir));
        recommendations.add(AiPlanRecommendation(
          title: '${exercise.exerciseName}: posible estancamiento',
          reason: 'No se observa una mejora suficiente en el rendimiento estimado durante las últimas sesiones.',
          changes: ['Reducir ${exercise.sets - newSets} serie${exercise.sets - newSets == 1 ? '' : 's'} temporalmente.', 'Trabajar a RIR $newRir para controlar la fatiga.'],
          confidence: 'Media',
        ));
      } else if (p.trend == ProgressTrend.ascending && p.weightChangePercent != null && p.weightChangePercent! > 5) {
        final newReps = exercise.reps < 15 ? exercise.reps + 1 : exercise.reps;
        changed.add(exercise.copyWith(reps: newReps));
        recommendations.add(AiPlanRecommendation(
          title: '${exercise.exerciseName}: progresión positiva',
          reason: 'La carga registrada está evolucionando favorablemente.',
          changes: ['Añadir 1 repetición objetivo manteniendo el RIR previsto.'],
          confidence: 'Media',
        ));
      } else {
        changed.add(exercise);
      }
    }

    final highest = volume.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (highest.length >= 2 && highest.first.value > 0 && highest.last.value > 0 && highest.first.value / highest.last.value >= 3) {
      recommendations.add(AiPlanRecommendation(
        title: 'Volumen muscular desequilibrado',
        reason: 'El grupo con mayor volumen registrado acumula al menos tres veces el volumen del grupo con menor volumen.',
        changes: ['Revisar el reparto semanal antes de añadir más series.', 'No aumentar volumen automáticamente hasta disponer de más contexto.'],
        confidence: 'Baja',
      ));
    }

    if (recommendations.isEmpty) {
      recommendations.add(const AiPlanRecommendation(
        title: 'Mantener la rutina',
        reason: 'No hay una señal suficientemente clara para modificar la programación actual.',
        changes: ['Mantén las cargas y registra las próximas sesiones.', 'Gimforze volverá a analizar la rutina cuando haya nuevos datos.'],
        confidence: 'Media',
      ));
    }

    return AiPlanProposal(plan: plan.copyWith(exercises: changed), recommendations: recommendations);
  }
}
