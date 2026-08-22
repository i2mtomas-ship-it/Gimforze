import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/ai/ai_planner_engine.dart';
import 'package:gimforze/features/exercises/exercise_model.dart';
import 'package:gimforze/features/profile/profile_model.dart';

const catalog = [
  Exercise(name: 'Press de banca con barra', force: 'push', level: 'intermediate', mechanic: 'compound', equipment: 'barbell', primaryMuscles: ['pecho'], secondaryMuscles: ['tríceps'], instructions: ['Empuja la barra.'], category: 'strength', images: []),
  Exercise(name: 'Remo con barra', force: 'pull', level: 'intermediate', mechanic: 'compound', equipment: 'barbell', primaryMuscles: ['espalda'], secondaryMuscles: ['bíceps'], instructions: ['Tira de la barra.'], category: 'strength', images: []),
  Exercise(name: 'Sentadilla con barra', force: 'push', level: 'intermediate', mechanic: 'compound', equipment: 'barbell', primaryMuscles: ['piernas'], secondaryMuscles: ['glúteos'], instructions: ['Desciende y sube.'], category: 'strength', images: []),
  Exercise(name: 'Elevaciones laterales', force: 'push', level: 'beginner', mechanic: 'isolation', equipment: 'dumbbell', primaryMuscles: ['hombros'], secondaryMuscles: [], instructions: ['Eleva los brazos.'], category: 'strength', images: []),
  Exercise(name: 'Curl de bíceps con mancuernas', force: 'pull', level: 'beginner', mechanic: 'isolation', equipment: 'dumbbell', primaryMuscles: ['bíceps'], secondaryMuscles: [], instructions: ['Flexiona el codo.'], category: 'strength', images: []),
  Exercise(name: 'Extensión de tríceps', force: 'push', level: 'beginner', mechanic: 'isolation', equipment: 'cable', primaryMuscles: ['tríceps'], secondaryMuscles: [], instructions: ['Extiende el codo.'], category: 'strength', images: []),
];

void main() {
  const profile = Profile(age: 44, heightCm: 180, weightKg: 80, daysPerWeek: 3, minutesPerSession: 60, trainingLevel: TrainingLevel.intermediate, equipment: 'barra, mancuernas');

  test('genera el número de días solicitado y usa ejercicios del catálogo', () {
    final result = AiPlannerEngine.build(profile: profile, days: 3, minutes: 60, goal: 'Ganar músculo', catalog: catalog);
    expect(result.plans, hasLength(3));
    expect(result.plans.every((p) => p.exercises.isNotEmpty), isTrue);
    expect(result.plans.expand((p) => p.exercises).every((e) => catalog.any((c) => c.name == e.exerciseName)), isTrue);
  });

  test('respeta ejercicios excluidos del perfil', () {
    const excluded = Profile(age: 44, heightCm: 180, weightKg: 80, exerciseAvoidances: 'Press de banca con barra');
    final result = AiPlannerEngine.build(profile: excluded, days: 2, minutes: 45, goal: 'Ganar fuerza', catalog: catalog);
    expect(result.plans.expand((p) => p.exercises).any((e) => e.exerciseName == 'Press de banca con barra'), isFalse);
  });

  test('usa respaldo local si no hay catálogo', () {
    final result = AiPlannerEngine.build(profile: profile, days: 2, minutes: 45, goal: 'Ganar fuerza', catalog: const []);
    expect(result.plans, hasLength(2));
    expect(result.plans.expand((p) => p.exercises), isNotEmpty);
    expect(result.warnings, isNotEmpty);
  });
}
