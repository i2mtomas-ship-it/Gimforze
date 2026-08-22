import 'package:flutter_test/flutter_test.dart';
import '../lib/features/progress/exercise_target.dart';
import '../lib/features/progress/target_progress.dart';
import '../lib/features/workout/workout_model.dart';

void main() {
  test('calcula cumplimiento de un objetivo', () {
    final session = WorkoutSession(
      id: '1', planName: 'A', date: DateTime(2026, 8, 10), startedAt: DateTime(2026, 8, 10), endedAt: DateTime(2026, 8, 10, 0, 45),
      exercises: [SessionExercise(exerciseName: 'Press banca', sets: [
        const LoggedSet(weightKg: 60, reps: 10, rir: 2),
        const LoggedSet(weightKg: 60, reps: 10, rir: 2),
      ])],
    );
    final report = buildTargetProgress(exerciseName: 'Press banca', target: const ExerciseTarget(exerciseName: 'Press banca', targetWeightKg: 60, minReps: 8, maxReps: 10, targetRir: 2), sessions: [session]);
    expect(report.points.length, 1);
    expect(report.points.first.compliance, greaterThan(.95));
    expect(report.status, TargetStatus.cumple);
  });

  test('sin objetivo no inventa resultados', () {
    final report = buildTargetProgress(exerciseName: 'Sentadilla', target: null, sessions: const []);
    expect(report.target, isNull);
    expect(report.points, isEmpty);
    expect(report.status, TargetStatus.sinDatos);
  });
}
