import 'package:flutter_test/flutter_test.dart';
import '../lib/features/ai/ai_chat_engine.dart';
import '../lib/features/progress/exercise_target.dart';
import '../lib/features/workout/workout_model.dart';

void main() {
  test('responde qué toca hoy usando la rutina del día', () {
    final plan = WorkoutPlan(id: '1', name: 'Piernas', dayOfWeek: DateTime.now().weekday, exercises: const [WorkoutExercise(exerciseName: 'Sentadilla', sets: 3, reps: 8)]);
    final answer = AiChatEngine.answer('¿Qué tengo hoy?', AiChatContext(plans: [plan], sessions: const [], targets: const [ExerciseTarget(exerciseName: 'Sentadilla', targetWeightKg: 80, minReps: 8, maxReps: 10, targetRir: 2)]));
    expect(answer, contains('Piernas'));
    expect(answer, contains('Sentadilla'));
    expect(answer, contains('80.0 kg'));
  });
}
