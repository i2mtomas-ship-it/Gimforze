import 'package:flutter_test/flutter_test.dart';
import '../lib/features/progress/exercise_target.dart';
import '../lib/features/progress/next_session_engine.dart';
import '../lib/features/workout/workout_model.dart';

void main() {
  test('propone subir carga cuando se completa el rango', () {
    final session = WorkoutSession(
      id: '1', planName: 'A', date: DateTime(2026, 8, 1), startedAt: DateTime(2026, 8, 1), endedAt: DateTime(2026, 8, 1, 0, 45),
      exercises: [SessionExercise(exerciseName: 'Press banca', sets: [
        const LoggedSet(weightKg: 60, reps: 10, rir: 2),
        const LoggedSet(weightKg: 60, reps: 10, rir: 2),
      ])],
    );
    final result = recommendNextSession(exerciseName: 'Press banca', target: const ExerciseTarget(exerciseName: 'Press banca', targetWeightKg: 60, minReps: 8, maxReps: 10, targetRir: 2, incrementKg: 2.5), sessions: [session]);
    expect(result.status, NextSessionStatus.progress);
    expect(result.weightKg, 62.5);
  });

  test('recomienda mantener carga si no se completa el mínimo', () {
    final session = WorkoutSession(
      id: '1', planName: 'A', date: DateTime(2026, 8, 1), startedAt: DateTime(2026, 8, 1), endedAt: DateTime(2026, 8, 1, 0, 45),
      exercises: [SessionExercise(exerciseName: 'Press banca', sets: [
        const LoggedSet(weightKg: 70, reps: 5, rir: 1),
        const LoggedSet(weightKg: 70, reps: 5, rir: 1),
      ])],
    );
    final result = recommendNextSession(exerciseName: 'Press banca', target: const ExerciseTarget(exerciseName: 'Press banca', targetWeightKg: 70, minReps: 8, maxReps: 10, targetRir: 2), sessions: [session]);
    expect(result.status, NextSessionStatus.reduce);
    expect(result.weightKg, 70);
  });
}
