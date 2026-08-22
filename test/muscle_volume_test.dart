import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/progress/muscle_volume.dart';
import 'package:gimforze/features/workout/workout_model.dart';

void main() {
  test('clasifica ejercicios en grupos musculares en español', () {
    expect(muscleGroupForExercise('Press de banca con barra'), 'Pecho');
    expect(muscleGroupForExercise('Remo con barra'), 'Espalda');
    expect(muscleGroupForExercise('Sentadilla con barra'), 'Piernas');
    expect(muscleGroupForExercise('Press militar'), 'Hombros');
  });

  test('calcula volumen por grupo muscular', () {
    final session = WorkoutSession(
      id: '1', planName: 'A', date: DateTime(2026, 8, 10),
      startedAt: DateTime(2026, 8, 10, 18), endedAt: DateTime(2026, 8, 10, 19),
      exercises: [
        SessionExercise(exerciseName: 'Press de banca con barra', sets: const [LoggedSet(weightKg: 50, reps: 10, rir: 2)]),
        SessionExercise(exerciseName: 'Sentadilla con barra', sets: const [LoggedSet(weightKg: 80, reps: 5, rir: 2)]),
      ],
    );
    final values = volumeByMuscle([session]);
    expect(values['Pecho'], 500);
    expect(values['Piernas'], 400);
  });
}
