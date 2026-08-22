import '../workout/workout_model.dart';

/// Clasificación funcional en español para agrupar el volumen de las sesiones.
/// Se mantiene basada en el nombre para que las sesiones antiguas sigan siendo compatibles.
String muscleGroupForExercise(String name) {
  final n = _normalize(name);
  if (_hasAny(n, ['sentadilla', 'prensa de piernas', 'extension de piernas', 'zancada', 'peso muerto rumano', 'curl femoral', 'gemelo'])) return 'Piernas';
  if (_hasAny(n, ['press de banca', 'press inclinado', 'aperturas', 'fondos', 'pectoral'])) return 'Pecho';
  if (_hasAny(n, ['remo', 'jalon', 'dominada', 'pull over', 'pullover', 'espalda'])) return 'Espalda';
  if (_hasAny(n, ['press militar', 'elevaciones laterales', 'elevacion lateral', 'deltoides', 'face pull'])) return 'Hombros';
  if (_hasAny(n, ['curl de biceps', 'curl de bíceps', 'biceps'])) return 'Bíceps';
  if (_hasAny(n, ['extension de triceps', 'extensión de tríceps', 'triceps', 'tríceps'])) return 'Tríceps';
  if (_hasAny(n, ['abdominal', 'plancha', 'crunch', 'core'])) return 'Core';
  return 'General';
}

Map<String, double> volumeByMuscle(List<WorkoutSession> sessions) {
  final result = <String, double>{};
  for (final session in sessions) {
    for (final exercise in session.exercises) {
      final group = muscleGroupForExercise(exercise.exerciseName);
      result[group] = (result[group] ?? 0) + exercise.volumeKg;
    }
  }
  return result;
}

Map<String, double> averageVolumeByMuscle(List<WorkoutSession> sessions) {
  final totals = volumeByMuscle(sessions);
  if (sessions.isEmpty) return totals;
  return {for (final e in totals.entries) e.key: e.value / sessions.length};
}

bool _hasAny(String value, List<String> terms) => terms.any(value.contains);

String _normalize(String value) => value.toLowerCase()
    .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
    .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ü', 'u');
