import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/workout/workout_model.dart';

void main() {
  test('workout plan round trips through JSON', () {
    const plan = WorkoutPlan(name: 'Fuerza A', dayOfWeek: 2, exercises: [WorkoutExercise(exerciseName: 'Sentadilla', sets: 4, reps: 6, rir: 2)]);
    final decoded = WorkoutPlan.decode(plan.encode());
    expect(decoded.name, 'Fuerza A');
    expect(decoded.dayOfWeek, 2);
    expect(decoded.exercises.single.exerciseName, 'Sentadilla');
    expect(decoded.exercises.single.sets, 4);
    expect(decoded.exercises.single.reps, 6);
    expect(decoded.exercises.single.rir, 2);
  });

  test('WorkoutSession calculates volume, sets and reps', () {
    final now = DateTime(2026, 8, 10, 10);
    final session = WorkoutSession(id: '1', planName: 'Push', date: now, startedAt: now, endedAt: now.add(const Duration(minutes: 55)), exercises: const [SessionExercise(exerciseName: 'Press', sets: [LoggedSet(weightKg: 50, reps: 10, rir: 2), LoggedSet(weightKg: 55, reps: 8, rir: 1)])]);
    expect(session.volumeKg, 940);
    expect(session.totalSets, 2);
    expect(session.totalReps, 18);
    expect(session.duration, const Duration(minutes: 55));
  });
}
