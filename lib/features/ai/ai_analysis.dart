import '../workout/workout_model.dart';
import '../progress/progression_engine.dart';

class AiAnalysis {
  const AiAnalysis({required this.title, required this.summary, required this.actions, required this.metrics});
  final String title;
  final String summary;
  final List<String> actions;
  final Map<String, String> metrics;
}

class AiCoachEngine {
  static AiAnalysis analyse(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return const AiAnalysis(
        title: 'Aún no hay suficiente historial',
        summary: 'Registra al menos una sesión para que Gimforze pueda analizar volumen, duración y progresión. No se inventarán datos.',
        actions: ['Completa tu primera sesión', 'Registra peso, repeticiones y RIR en cada serie'],
        metrics: {},
      );
    }

    final recent = sessions.take(4).toList();
    final recentVolume = recent.fold<double>(0, (sum, s) => sum + s.volumeKg);
    final avgDuration = recent.fold<int>(0, (sum, s) => sum + s.duration.inMinutes) / recent.length;
    final previous = sessions.skip(4).take(4).toList();
    final previousVolume = previous.fold<double>(0, (sum, s) => sum + s.volumeKg);
    final change = previousVolume == 0 ? null : ((recentVolume - previousVolume) / previousVolume) * 100;

    final progress = analyseExercises(sessions);
    final stagnant = progress.where((p) => p.stagnant).toList();
    final descending = progress.where((p) => p.trend == ProgressTrend.descending).toList();
    final ascending = progress.where((p) => p.trend == ProgressTrend.ascending).toList();

    final actions = <String>[];
    if (stagnant.isNotEmpty) {
      actions.add('Hay ${stagnant.length} ejercicio(s) con posible estancamiento en las últimas sesiones: ${stagnant.take(3).map((p) => p.exerciseName).join(', ')}. Revisa carga, técnica, descanso y recuperación antes de aumentar el volumen.');
    }
    if (descending.isNotEmpty) {
      actions.add('Se observa una tendencia descendente en ${descending.length} ejercicio(s). Conviene revisar fatiga y recuperación antes de seguir aumentando la carga.');
    }
    if (ascending.isNotEmpty) {
      actions.add('Hay progresión positiva en ${ascending.length} ejercicio(s). Mantén la progresión mientras completes el rango de repeticiones con el RIR previsto.');
    }
    if (change != null && change < -10) {
      actions.add('El volumen reciente ha caído más de un 10 % respecto al bloque anterior. Comprueba si se debe a menos sesiones o a una reducción intencionada de carga.');
    } else if (change != null && change > 15) {
      actions.add('El volumen reciente ha aumentado más de un 15 %. Evita incrementar volumen e intensidad simultáneamente si no es necesario.');
    }
    if (avgDuration > 75) actions.add('Tus sesiones recientes superan 75 minutos de media; podemos reorganizar descansos y ejercicios.');
    if (recent.length < 3) actions.add('Registra más sesiones para detectar tendencias con mayor confianza.');
    if (actions.isEmpty) actions.add('La tendencia general es estable. Continúa registrando todas las series para que Gimforze pueda afinar las recomendaciones.');

    return AiAnalysis(
      title: 'Análisis de tu progreso',
      summary: 'Gimforze utiliza únicamente entrenamientos registrados. Las recomendaciones son orientativas y se recalculan cuando añades nuevas sesiones.',
      actions: actions,
      metrics: {
        'Sesiones analizadas': '${recent.length}',
        'Volumen reciente': '${recentVolume.round()} kg',
        'Duración media': '${avgDuration.round()} min',
        'Ejercicios en progresión': '${ascending.length}',
        'Ejercicios estancados': '${stagnant.length}',
        if (change != null) 'Cambio de volumen': '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
      },
    );
  }
}
