import 'package:flutter_test/flutter_test.dart';
import '../lib/features/progress/achievement_engine.dart';
import '../lib/features/workout/workout_model.dart';

WorkoutSession session(String id, DateTime date, double weight) => WorkoutSession(
  id: id,
  planName: 'Rutina',
  date: date,
  startedAt: date,
  endedAt: date.add(const Duration(minutes: 45)),
  exercises: [
    SessionExercise(exerciseName: 'Press de banca con barra', sets: [LoggedSet(weightKg: weight, reps: 8, rir: 2)]),
  ],
);

void main() {
  test('primer entrenamiento desbloquea Primer paso', () {
    final summary = AchievementEngine.summarize([session('1', DateTime(2026, 8, 10), 60)]);
    expect(summary.unlocked.any((a) => a.id == 'first'), isTrue);
    expect(summary.level, greaterThanOrEqualTo(1));
  });

  test('detecta records personales por aumento de carga', () {
    final summary = AchievementEngine.summarize([
      session('1', DateTime(2026, 8, 10), 60),
      session('2', DateTime(2026, 8, 11), 62.5),
    ]);
    final pr = summary.achievements.firstWhere((a) => a.id == 'pr1');
    expect(pr.current, 2);
    expect(pr.unlocked, isTrue);
  });

  test('calcula racha de días consecutivos', () {
    final summary = AchievementEngine.summarize([
      session('1', DateTime(2026, 8, 10), 60),
      session('2', DateTime(2026, 8, 11), 60),
      session('3', DateTime(2026, 8, 12), 60),
    ]);
    final streak = summary.achievements.firstWhere((a) => a.id == 'streak3');
    expect(streak.current, 3);
    expect(streak.unlocked, isTrue);
  });
}
