import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/exercises/exercise_model.dart';

void main() {
  test('Exercise conserva los campos localizados', () {
    const exercise = Exercise(
      name: 'Press de banca con barra',
      force: null,
      level: 'Intermedio',
      mechanic: 'Compuesto',
      equipment: 'Barra',
      primaryMuscles: ['Pecho'],
      secondaryMuscles: ['Tríceps'],
      instructions: ['Túmbate en el banco.', 'Desciende la barra de forma controlada.'],
      category: 'Fuerza',
      images: [],
      source: 'wger · contenido traducido al español',
    );
    expect(exercise.name, contains('banca'));
    expect(exercise.primaryMuscles, contains('Pecho'));
    expect(exercise.instructions.length, 2);
    expect(exercise.source, contains('wger'));
  });
}
