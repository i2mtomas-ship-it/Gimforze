import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/progress/progression_engine.dart';
import 'package:gimforze/features/workout/workout_model.dart';

WorkoutSession session(String id, DateTime date, double weight, int reps) => WorkoutSession(
  id: id,
  planName: 'Rutina',
  date: date,
  startedAt: date,
  endedAt: date.add(const Duration(minutes: 50)),
  exercises: [
    SessionExercise(
      exerciseName: 'Press de banca con barra',
      sets: [LoggedSet(weightKg: weight, reps: reps, rir: 2)],
    ),
  ],
);

void main() {
  test('calcula 1RM estimado', () {
    expect(estimated1Rm(60, 10), closeTo(80, 0.001));
    expect(estimated1Rm(80, 1), 80);
  });

  test('detecta progresión ascendente', () {
    final sessions = [
      session('1', DateTime(2026, 7, 1), 60, 8),
      session('2', DateTime(2026, 7, 8), 62.5, 8),
      session('3', DateTime(2026, 7, 15), 65, 8),
    ];
    final result = analyseExercise(sessions, 'Press de banca con barra');
    expect(result.sessions, 3);
    expect(result.trend, ProgressTrend.ascending);
    expect(result.bestWeightKg, 65);
  });

  test('detecta posible estancamiento', () {
    final sessions = [
      session('1', DateTime(2026, 7, 1), 60, 8),
      session('2', DateTime(2026, 7, 8), 60, 8),
      session('3', DateTime(2026, 7, 15), 60, 8),
    ];
    final result = analyseExercise(sessions, 'Press de banca con barra');
    expect(result.stagnant, isTrue);
    expect(result.trend, ProgressTrend.stable);
  });
}
