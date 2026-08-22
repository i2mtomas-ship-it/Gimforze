import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/ai/ai_decision_engine.dart';
import 'package:gimforze/features/workout/workout_model.dart';

WorkoutSession _session(String id, DateTime date, double weight, int reps) => WorkoutSession(
  id: id,
  planName: 'Rutina',
  date: date,
  startedAt: date,
  endedAt: date.add(const Duration(minutes: 50)),
  exercises: [SessionExercise(
    exerciseName: 'Press de banca con barra',
    sets: [LoggedSet(weightKg: weight, reps: reps, rir: 2)],
  )],
);

void main() {
  test('no modifica una rutina sin historial suficiente', () {
    const plan = WorkoutPlan(name: 'Push', exercises: [WorkoutExercise(exerciseName: 'Press de banca con barra', sets: 4, reps: 8, rir: 2)]);
    final result = AiDecisionEngine.propose(plan, const []);
    expect(result.plan.exercises.single.sets, 4);
    expect(result.recommendations.single.confidence, 'Baja');
  });

  test('propone descargar volumen ante estancamiento', () {
    const plan = WorkoutPlan(name: 'Push', exercises: [WorkoutExercise(exerciseName: 'Press de banca con barra', sets: 4, reps: 8, rir: 2)]);
    final sessions = [
      _session('1', DateTime(2026, 7, 1), 60, 8),
      _session('2', DateTime(2026, 7, 8), 60, 8),
      _session('3', DateTime(2026, 7, 15), 60, 8),
    ];
    final result = AiDecisionEngine.propose(plan, sessions);
    expect(result.plan.exercises.single.sets, 3);
    expect(result.plan.exercises.single.rir, 3);
    expect(result.recommendations.any((r) => r.title.contains('estancamiento')), isTrue);
  });
}
