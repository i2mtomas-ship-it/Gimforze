import '../workout/workout_model.dart';

class PeriodMetrics {
  const PeriodMetrics({required this.sessions, required this.volumeKg, required this.duration, required this.sets, required this.reps});
  final int sessions;
  final double volumeKg;
  final Duration duration;
  final int sets;
  final int reps;

  double get averageVolume => sessions == 0 ? 0 : volumeKg / sessions;
  double get averageDurationMinutes => sessions == 0 ? 0 : duration.inMinutes / sessions;
}

PeriodMetrics metricsFor(List<WorkoutSession> sessions, DateTime start, DateTime endExclusive) {
  final selected = sessions.where((s) => !s.date.isBefore(start) && s.date.isBefore(endExclusive));
  var volume = 0.0;
  var seconds = 0;
  var sets = 0;
  var reps = 0;
  var count = 0;
  for (final session in selected) {
    count++;
    volume += session.volumeKg;
    seconds += session.duration.inSeconds;
    sets += session.totalSets;
    reps += session.totalReps;
  }
  return PeriodMetrics(sessions: count, volumeKg: volume, duration: Duration(seconds: seconds), sets: sets, reps: reps);
}

double? percentageChange(double current, double previous) {
  if (previous == 0) return current == 0 ? 0 : null;
  return ((current - previous) / previous) * 100;
}
