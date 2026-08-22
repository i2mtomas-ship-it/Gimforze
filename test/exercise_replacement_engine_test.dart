import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/ai/exercise_replacement_engine.dart';
import 'package:gimforze/features/exercises/exercise_model.dart';
import 'package:gimforze/features/workout/workout_model.dart';

void main() {
  test('prioriza una alternativa que comparte grupo muscular', () {
    const target = WorkoutExercise(exerciseName: 'Press de banca con barra');
    const catalog = [
      Exercise(name: 'Press de pecho en máquina', force: 'push', level: 'intermediate', mechanic: 'compound', equipment: 'machine', primaryMuscles: ['pecho'], secondaryMuscles: ['tríceps'], instructions: ['Empuja de forma controlada.'], category: 'strength', images: []),
      Exercise(name: 'Curl de bíceps', force: 'pull', level: 'beginner', mechanic: 'isolation', equipment: 'dumbbell', primaryMuscles: ['bíceps'], secondaryMuscles: [], instructions: ['Flexiona el codo.'], category: 'strength', images: []),
    ];
    final result = ExerciseReplacementEngine.findAlternatives(target: target, catalog: catalog);
    expect(result, isNotEmpty);
    expect(result.first.replacement.name, 'Press de pecho en máquina');
  });

  test('no recomienda un ejercicio que ya está en la rutina', () {
    const target = WorkoutExercise(exerciseName: 'Press de banca con barra');
    const catalog = [
      Exercise(name: 'Press inclinado', force: 'push', level: 'intermediate', mechanic: 'compound', equipment: 'barbell', primaryMuscles: ['pecho'], secondaryMuscles: [], instructions: ['Empuja.'], category: 'strength', images: []),
    ];
    final result = ExerciseReplacementEngine.findAlternatives(target: target, catalog: catalog, excludedNames: const ['Press inclinado']);
    expect(result, isEmpty);
  });
}
