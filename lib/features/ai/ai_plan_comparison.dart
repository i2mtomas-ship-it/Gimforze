import '../workout/workout_model.dart';

class PlanExerciseChange {
  const PlanExerciseChange({required this.index, required this.before, required this.after});
  final int index;
  final WorkoutExercise before;
  final WorkoutExercise after;

  bool get changed => before.sets != after.sets || before.reps != after.reps || before.rir != after.rir || before.restSeconds != after.restSeconds || before.notes != after.notes;
  int get beforeWork => before.sets * before.reps;
  int get afterWork => after.sets * after.reps;
}

class AiPlanComparison {
  const AiPlanComparison({required this.before, required this.after, required this.changes});
  final WorkoutPlan before;
  final WorkoutPlan after;
  final List<PlanExerciseChange> changes;

  factory AiPlanComparison.fromPlans(WorkoutPlan before, WorkoutPlan after) {
    final max = before.exercises.length > after.exercises.length ? before.exercises.length : after.exercises.length;
    final changes = <PlanExerciseChange>[];
    for (var i = 0; i < max; i++) {
      if (i >= before.exercises.length || i >= after.exercises.length) continue;
      final change = PlanExerciseChange(index: i, before: before.exercises[i], after: after.exercises[i]);
      if (change.changed) changes.add(change);
    }
    return AiPlanComparison(before: before, after: after, changes: changes);
  }

  int get beforeWork => before.exercises.fold(0, (sum, e) => sum + e.sets * e.reps);
  int get afterWork => after.exercises.fold(0, (sum, e) => sum + e.sets * e.reps);
}
