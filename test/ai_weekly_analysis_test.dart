import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/ai/ai_weekly_analysis.dart';
import 'package:gimforze/features/workout/workout_model.dart';

void main() {
  test('analiza series y duración estimada de la semana', () {
    const plans = [
      WorkoutPlan(dayOfWeek: 1, exercises: [WorkoutExercise(exerciseName: 'Press de banca con barra', sets: 4, reps: 8, restSeconds: 90)]),
      WorkoutPlan(dayOfWeek: 3, exercises: [WorkoutExercise(exerciseName: 'Sentadilla con barra', sets: 4, reps: 8, restSeconds: 120)]),
    ];
    final result = AiWeeklyAnalyzer.analyze(plans, const []);
    expect(result.totalSessions, 2);
    expect(result.totalSets, 8);
    expect(result.estimatedMinutes, greaterThan(0));
    expect(result.muscleSets['Pecho'], 4);
    expect(result.muscleSets['Piernas'], 4);
  });

  test('detecta sesiones consecutivas con grupos compartidos', () {
    const plans = [
      WorkoutPlan(dayOfWeek: 1, exercises: [WorkoutExercise(exerciseName: 'Press de banca con barra')]),
      WorkoutPlan(dayOfWeek: 2, exercises: [WorkoutExercise(exerciseName: 'Press inclinado con mancuernas')]),
    ];
    final result = AiWeeklyAnalyzer.analyze(plans, const []);
    expect(result.recoveryWarnings, isNotEmpty);
  });
}
