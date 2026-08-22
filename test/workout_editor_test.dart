import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/workout/workout_model.dart';

void main() {
  test('WorkoutExercise conserva descanso y notas', () {
    const item = WorkoutExercise(exerciseName: 'Press de banca con barra', sets: 4, reps: 8, rir: 2, restSeconds: 120, notes: 'Controlar la bajada');
    final decoded = WorkoutExercise.fromJson(item.toJson());
    expect(decoded.restSeconds, 120);
    expect(decoded.notes, 'Controlar la bajada');
  });

  test('WorkoutExercise antiguo mantiene valores por defecto', () {
    final decoded = WorkoutExercise.fromJson({'name': 'Sentadilla', 'sets': 3, 'reps': 8, 'rir': 2});
    expect(decoded.restSeconds, 90);
    expect(decoded.notes, '');
  });
}
