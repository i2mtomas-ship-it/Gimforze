import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/ai/ai_plan_comparison.dart';
import 'package:gimforze/features/workout/workout_model.dart';

void main() {
  test('detecta cambios y calcula trabajo antes y después', () {
    const before = WorkoutPlan(exercises: [
      WorkoutExercise(exerciseName: 'Press banca', sets: 4, reps: 8, rir: 2),
      WorkoutExercise(exerciseName: 'Remo', sets: 3, reps: 10, rir: 2),
    ]);
    const after = WorkoutPlan(exercises: [
      WorkoutExercise(exerciseName: 'Press banca', sets: 3, reps: 8, rir: 3),
      WorkoutExercise(exerciseName: 'Remo', sets: 3, reps: 10, rir: 2),
    ]);

    final comparison = AiPlanComparison.fromPlans(before, after);

    expect(comparison.changes, hasLength(1));
    expect(comparison.changes.single.index, 0);
    expect(comparison.beforeWork, 62);
    expect(comparison.afterWork, 54);
  });

  test('no crea cambios cuando las rutinas son iguales', () {
    const plan = WorkoutPlan(exercises: [WorkoutExercise(exerciseName: 'Sentadilla', sets: 3, reps: 8)]);
    final comparison = AiPlanComparison.fromPlans(plan, plan);
    expect(comparison.changes, isEmpty);
  });
}
