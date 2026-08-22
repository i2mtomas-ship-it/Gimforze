import 'package:flutter_test/flutter_test.dart';
import '../lib/features/exercises/exercise_model.dart';

void main() {
  test('un ejercicio personalizado se serializa y recupera completo', () {
    const exercise = Exercise(
      name: 'Press unilateral en polea',
      force: null,
      level: 'personalizado',
      mechanic: null,
      equipment: 'Polea',
      primaryMuscles: ['Pecho'],
      secondaryMuscles: ['Tríceps'],
      instructions: ['Coloca la polea a la altura adecuada.', 'Empuja de forma controlada.'],
      category: 'Personalizado',
      images: [],
      description: 'Ejercicio creado por el usuario.',
      source: 'Ejercicio creado por ti',
    );
    final restored = Exercise.fromJson(exercise.toJson());
    expect(restored.name, exercise.name);
    expect(restored.equipment, 'Polea');
    expect(restored.primaryMuscles, ['Pecho']);
    expect(restored.instructions.length, 2);
    expect(restored.source, 'Ejercicio creado por ti');
  });

  test('un ejercicio personalizado no depende de imágenes ni vídeo', () {
    const exercise = Exercise(
      name: 'Plancha con apoyo',
      force: null,
      level: 'personalizado',
      mechanic: null,
      equipment: 'Peso corporal',
      primaryMuscles: ['Abdominales'],
      secondaryMuscles: [],
      instructions: ['Mantén el tronco alineado.'],
      category: 'Personalizado',
      images: [],
    );
    expect(exercise.imageUrl, isEmpty);
    expect(exercise.videoUrl, isNull);
  });
}
