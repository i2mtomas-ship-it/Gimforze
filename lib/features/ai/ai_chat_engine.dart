import '../progress/muscle_volume.dart';
import '../progress/exercise_target.dart';
import '../progress/next_session_engine.dart';
import '../workout/workout_model.dart';

class AiChatContext {
  const AiChatContext({required this.plans, required this.sessions, this.targets = const []});
  final List<WorkoutPlan> plans;
  final List<WorkoutSession> sessions;
  final List<ExerciseTarget> targets;
}

ExerciseTarget? _targetFor(String name, List<ExerciseTarget> targets) {
  for (final target in targets) {
    if (target.exerciseName.toLowerCase() == name.toLowerCase()) return target;
  }
  return null;
}

String _normalize(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');
}

class AiChatEngine {
  static String answer(String question, AiChatContext context) {
    final q = _normalize(question);
    if (q.isEmpty) return 'Escribe una pregunta sobre tus rutinas, entrenamientos o progreso.';

    if (q.contains('hoy') || q.contains('que tengo')) {
      final weekday = DateTime.now().weekday;
      final today = context.plans.where((p) => p.dayOfWeek == weekday).toList();
      if (today.isEmpty) {
        final active = context.plans.isEmpty ? null : context.plans.first;
        if (active == null) return 'Hoy no tienes ninguna rutina programada y todavía no tienes rutinas guardadas.';
        return 'Hoy no tienes ninguna rutina programada. Tu rutina guardada más reciente es «${active.name}», que puedes iniciar manualmente desde Rutinas.';
      }
      final plan = today.first;
      final lines = <String>[];
      for (final exercise in plan.exercises) {
        final target = _targetFor(exercise.exerciseName, context.targets);
        final recommendation = recommendNextSession(exerciseName: exercise.exerciseName, target: target, sessions: context.sessions);
        final load = recommendation.weightKg > 0 ? '${recommendation.weightKg.toStringAsFixed(1)} kg · ' : '';
        lines.add('• ${exercise.exerciseName}: $load${recommendation.reps} rep · RIR ${recommendation.rir}');
      }
      if (lines.isEmpty) return 'Hoy tienes «${plan.name}», pero todavía no tiene ejercicios configurados.';
      return 'Hoy te toca «${plan.name}».\n\n${lines.join('\n')}';
    }

    if (q.contains('volumen')) {
      if (context.sessions.isEmpty) return 'Todavía no tengo sesiones registradas, así que no puedo calcular tu volumen real.';
      final recent = context.sessions.take(7).toList();
      final recentVolume = recent.fold<double>(0, (sum, session) => sum + session.volumeKg);
      final previous = context.sessions.skip(7).take(7).toList();
      final previousVolume = previous.fold<double>(0, (sum, session) => sum + session.volumeKg);
      final groups = <String, double>{};
      for (final session in recent) {
        for (final exercise in session.exercises) {
          final group = muscleGroupForExercise(exercise.exerciseName);
          groups[group] = (groups[group] ?? 0) + exercise.volumeKg;
        }
      }
      final ordered = groups.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final comparison = previous.isEmpty || previousVolume == 0
          ? 'Todavía no hay un bloque anterior suficiente para comparar.'
          : 'Frente a las 7 sesiones anteriores: ${((recentVolume / previousVolume - 1) * 100).toStringAsFixed(1)}%.';
      final leader = ordered.isEmpty ? '' : ' Grupo con más volumen: ${ordered.first.key} (${ordered.first.value.toStringAsFixed(0)} kg).';
      return 'En tus últimas ${recent.length} sesiones has acumulado ${recentVolume.toStringAsFixed(0)} kg de volumen.$leader\n$comparison';
    }

    if (q.contains('progres') || q.contains('mejor') || q.contains('evolucion')) {
      if (context.sessions.isEmpty) return 'Todavía no tengo sesiones registradas. Cuando registres entrenamientos podré comparar cargas, repeticiones y volumen sin inventar resultados.';
      final exerciseStats = <String, List<SessionExercise>>{};
      for (final session in context.sessions) {
        for (final exercise in session.exercises) {
          exerciseStats.putIfAbsent(exercise.exerciseName, () => []).add(exercise);
        }
      }
      final candidates = <String>[];
      for (final entry in exerciseStats.entries) {
        if (entry.value.length < 2) continue;
        final latest = entry.value.first.volumeKg;
        final previous = entry.value[1].volumeKg;
        if (latest > previous) candidates.add('${entry.key} (+${(latest - previous).toStringAsFixed(0)} kg de volumen en la última sesión)');
      }
      if (candidates.isEmpty) {
        return 'Tengo ${context.sessions.length} sesión${context.sessions.length == 1 ? '' : 'es'} registrada${context.sessions.length == 1 ? '' : 's'}, pero todavía no hay suficientes repeticiones del mismo ejercicio para afirmar una progresión clara.';
      }
      return 'Veo progresión reciente en: ${candidates.take(4).join('; ')}. La valoración se basa en tus datos guardados, no en estimaciones.';
    }

    if (q.contains('cuant') || q.contains('sesiones')) {
      return 'Tienes ${context.sessions.length} sesiones registradas y ${context.plans.length} rutinas guardadas.';
    }

    if (q.contains('rutina') || q.contains('entrenar')) {
      if (context.plans.isEmpty) return 'Todavía no tienes una rutina guardada. Puedes crearla manualmente desde Rutinas o generar una propuesta con Gimforze.';
      return 'Tienes ${context.plans.length} rutinas guardadas. Puedo ayudarte a revisar el entrenamiento, el volumen y la progresión utilizando las sesiones registradas.';
    }

    return 'Puedo analizar tu día de entrenamiento, volumen, progresión, sesiones y rutinas. Prueba con «¿qué tengo hoy?», «¿cómo progreso?» o «¿cómo va mi volumen?».';
  }
}
