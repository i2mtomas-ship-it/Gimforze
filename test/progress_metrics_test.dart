import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/progress/progress_metrics.dart';
import 'package:gimforze/features/workout/workout_model.dart';

void main() {
  test('calcula métricas de un periodo', () {
    final date = DateTime(2026, 8, 10);
    final session = WorkoutSession(
      id: '1', planName: 'Fuerza', date: date,
      startedAt: date, endedAt: date.add(const Duration(minutes: 60)),
      exercises: const [SessionExercise(exerciseName: 'Press', sets: [LoggedSet(weightKg: 50, reps: 10, rir: 2)])],
    );
    final result = metricsFor([session], DateTime(2026, 8), DateTime(2026, 9));
    expect(result.sessions, 1);
    expect(result.volumeKg, 500);
    expect(result.duration, const Duration(minutes: 60));
    expect(result.sets, 1);
    expect(result.reps, 10);
  });

  test('calcula porcentaje de cambio', () {
    expect(percentageChange(120, 100), 20);
    expect(percentageChange(80, 100), -20);
    expect(percentageChange(0, 0), 0);
    expect(percentageChange(10, 0), isNull);
  });
}
