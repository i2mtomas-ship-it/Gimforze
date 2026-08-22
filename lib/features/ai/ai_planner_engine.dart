import '../exercises/exercise_model.dart';
import '../profile/profile_model.dart';
import '../workout/workout_model.dart';

class AiWeeklyPlan {
  const AiWeeklyPlan({required this.plans, required this.reason, required this.warnings});
  final List<WorkoutPlan> plans;
  final String reason;
  final List<String> warnings;
}

class AiPlannerEngine {
  static AiWeeklyPlan build({
    required Profile profile,
    required int days,
    required int minutes,
    required String goal,
    required List<Exercise> catalog,
    List<WorkoutSession> sessions = const [],
  }) {
    final requestedDays = days.clamp(2, 5);
    final focus = _splitFor(requestedDays, goal);
    final recentNames = _recentExerciseNames(sessions, const Duration(days: 28));
    final warnings = <String>[];
    final plans = <WorkoutPlan>[];

    for (var i = 0; i < requestedDays; i++) {
      final chosen = _chooseExercises(
        catalog: catalog,
        focus: focus[i],
        profile: profile,
        goal: goal,
        recentNames: recentNames,
        maxExercises: minutes <= 45 ? 4 : 5,
      );
      final exercises = chosen.isEmpty ? _fallbackExercises(focus[i], goal, minutes) : chosen;
      if (chosen.isEmpty && catalog.isEmpty) warnings.add('El catálogo no estaba disponible; se ha usado una selección local de respaldo.');
      plans.add(WorkoutPlan(
        id: 'ia-plan-${DateTime.now().microsecondsSinceEpoch}-$i',
        name: focus[i].name,
        dayOfWeek: i + 1,
        exercises: exercises,
      ));
    }

    final repeated = _repeatedNames(plans);
    if (repeated.isNotEmpty) warnings.add('Se han detectado ejercicios repetidos y se han mantenido solo cuando ayudan a cubrir el objetivo semanal.');
    if (sessions.length >= 3) warnings.add('El historial reciente se ha usado para evitar priorizar ejercicios entrenados repetidamente durante las últimas 4 semanas.');

    final equipmentText = profile.equipment.trim().isEmpty ? 'equipamiento no limitado' : 'equipamiento disponible: ${profile.equipment.trim()}';
    return AiWeeklyPlan(
      plans: plans,
      reason: 'Plan de $requestedDays días para $goal, sesiones de hasta $minutes minutos, nivel ${_levelLabel(profile.trainingLevel)} y $equipmentText. La selección prioriza cobertura muscular, variedad y compatibilidad con el catálogo.',
      warnings: warnings.toSet().toList(),
    );
  }


  static List<int> scheduleForDays(int days) => switch (days.clamp(2, 5)) {
        2 => const [1, 4],
        3 => const [1, 3, 5],
        4 => const [1, 2, 4, 5],
        _ => const [1, 2, 3, 5, 6],
      };

  static List<_Focus> _splitFor(int days, String goal) {
    if (days == 2) return const [_Focus('Cuerpo completo A', ['pecho', 'espalda', 'piernas']), _Focus('Cuerpo completo B', ['hombros', 'piernas', 'espalda'])];
    if (days == 3) return const [_Focus('Tren superior', ['pecho', 'espalda', 'hombros']), _Focus('Piernas', ['cuádriceps', 'isquios', 'glúteos']), _Focus('Cuerpo completo', ['pecho', 'espalda', 'piernas'])];
    if (days == 4) return const [_Focus('Pecho y tríceps', ['pecho', 'tríceps']), _Focus('Espalda y bíceps', ['espalda', 'bíceps']), _Focus('Piernas', ['piernas', 'cuádriceps', 'isquios', 'glúteos']), _Focus('Hombros y brazos', ['hombros', 'bíceps', 'tríceps'])];
    return const [_Focus('Pecho y hombros', ['pecho', 'hombros']), _Focus('Espalda y bíceps', ['espalda', 'bíceps']), _Focus('Piernas', ['piernas', 'cuádriceps', 'isquios', 'glúteos']), _Focus('Torso', ['pecho', 'espalda']), _Focus('Piernas y brazos', ['piernas', 'bíceps', 'tríceps'])];
  }

  static List<WorkoutExercise> _chooseExercises({
    required List<Exercise> catalog,
    required _Focus focus,
    required Profile profile,
    required String goal,
    required Set<String> recentNames,
    required int maxExercises,
  }) {
    if (catalog.isEmpty) return const [];
    final excluded = _normalize(profile.exerciseAvoidances);
    final equipment = _normalize(profile.equipment);
    final candidates = catalog.where((e) {
      final name = _normalize(e.name);
      if (excluded.isNotEmpty && excluded.split(RegExp(r'[,;]')).any((x) => x.trim().isNotEmpty && name.contains(x.trim()))) return false;
      return true;
    }).toList();

    final selected = <Exercise>[];
    final covered = <String>{};
    for (final target in focus.muscles) {
      final ranked = candidates.where((e) => _matchesMuscle(e, target)).toList()
        ..sort((a, b) => _score(b, target, equipment, goal, recentNames, covered).compareTo(_score(a, target, equipment, goal, recentNames, covered)));
      for (final item in ranked) {
        if (selected.any((x) => _normalize(x.name) == _normalize(item.name))) continue;
        selected.add(item);
        covered.add(target);
        break;
      }
    }
    final extras = candidates.where((e) => !selected.any((x) => _normalize(x.name) == _normalize(e.name))).toList()
      ..sort((a, b) => _score(b, focus.muscles.first, equipment, goal, recentNames, covered).compareTo(_score(a, focus.muscles.first, equipment, goal, recentNames, covered)));
    for (final item in extras) {
      if (selected.length >= maxExercises) break;
      selected.add(item);
    }

    return [
      for (var i = 0; i < selected.length && i < maxExercises; i++)
        _prescribe(selected[i], goal, i, profile.trainingLevel),
    ];
  }

  static double _score(Exercise e, String target, String equipment, String goal, Set<String> recentNames, Set<String> covered) {
    var score = 0.0;
    if (_matchesMuscle(e, target)) score += 100;
    final mechanic = _normalize(e.mechanic ?? '');
    if (mechanic == 'compound' || mechanic == 'compuesto') score += 12;
    if (equipment.isEmpty || equipment == 'todo') score += 4;
    else if (_normalize(e.equipment ?? '').split(',').any((x) => equipment.contains(x.trim()) || x.trim().contains(equipment))) score += 20;
    if (recentNames.contains(_normalize(e.name))) score -= 12;
    if (goal.toLowerCase().contains('fuerza') && mechanic.contains('compound')) score += 10;
    if (goal.toLowerCase().contains('músculo') && mechanic.contains('isolation')) score += 5;
    if (covered.contains(target)) score -= 4;
    return score;
  }

  static bool _matchesMuscle(Exercise e, String target) {
    final text = _normalize('${e.name} ${e.primaryMuscles.join(' ')} ${e.secondaryMuscles.join(' ')}');
    final aliases = <String, List<String>>{
      'pecho': ['pecho', 'chest', 'pectoral'],
      'espalda': ['espalda', 'back', 'dorsal', 'lats'],
      'piernas': ['pierna', 'quadriceps', 'cuadriceps', 'hamstring', 'isquio', 'glute', 'glúteo'],
      'cuádriceps': ['cuadriceps', 'quadriceps'],
      'isquios': ['isquio', 'hamstring'],
      'glúteos': ['glute', 'glúteo'],
      'hombros': ['hombro', 'shoulder', 'deltoid'],
      'bíceps': ['biceps', 'bíceps'],
      'tríceps': ['triceps', 'tríceps'],
    };
    return (aliases[target] ?? [target]).any(text.contains);
  }

  static WorkoutExercise _prescribe(Exercise e, String goal, int index, TrainingLevel level) {
    final strength = goal.toLowerCase().contains('fuerza');
    final hypertrophy = goal.toLowerCase().contains('músculo');
    final compound = (e.mechanic ?? '').toLowerCase().contains('compound') || index == 0;
    final sets = strength && compound ? 4 : hypertrophy ? (compound ? 3 : 3) : 3;
    final reps = strength && compound ? 6 : hypertrophy ? (compound ? 8 : 12) : 10;
    final rir = level == TrainingLevel.beginner ? 3 : 2;
    final rest = compound ? (strength ? 150 : 120) : 90;
    return WorkoutExercise(exerciseName: e.name, sets: sets, reps: reps, rir: rir, restSeconds: rest);
  }

  static List<WorkoutExercise> _fallbackExercises(_Focus focus, String goal, int minutes) {
    final map = <String, List<String>>{
      'pecho': ['Press de banca con barra', 'Press inclinado con mancuernas', 'Aperturas con mancuernas'],
      'espalda': ['Remo con barra', 'Jalón al pecho', 'Remo con mancuerna'],
      'piernas': ['Sentadilla con barra', 'Peso muerto rumano', 'Prensa de piernas'],
      'hombros': ['Press militar', 'Elevaciones laterales', 'Pájaros con mancuernas'],
      'bíceps': ['Curl de bíceps con mancuernas', 'Curl con barra'],
      'tríceps': ['Extensión de tríceps', 'Press cerrado'],
      'cuádriceps': ['Sentadilla con barra', 'Prensa de piernas'],
      'isquios': ['Peso muerto rumano', 'Curl femoral'],
      'glúteos': ['Hip thrust', 'Sentadilla con barra'],
    };
    final names = <String>[];
    for (final muscle in focus.muscles) {
      for (final name in map[muscle] ?? const []) {
        if (!names.contains(name)) names.add(name);
        if (names.length >= (minutes <= 45 ? 4 : 5)) break;
      }
      if (names.length >= (minutes <= 45 ? 4 : 5)) break;
    }
    return [for (var i = 0; i < names.length; i++) WorkoutExercise(exerciseName: names[i], sets: i == 0 ? 4 : 3, reps: goal.toLowerCase().contains('fuerza') && i == 0 ? 6 : 10, rir: 2, restSeconds: i == 0 ? 120 : 90)];
  }

  static Set<String> _recentExerciseNames(List<WorkoutSession> sessions, Duration period) {
    if (sessions.isEmpty) return <String>{};
    final cutoff = DateTime.now().subtract(period);
    return {for (final s in sessions.where((s) => s.date.isAfter(cutoff))) for (final e in s.exercises) _normalize(e.exerciseName)};
  }

  static List<String> _repeatedNames(List<WorkoutPlan> plans) {
    final counts = <String, int>{};
    for (final p in plans) for (final e in p.exercises) counts[_normalize(e.exerciseName)] = (counts[_normalize(e.exerciseName)] ?? 0) + 1;
    return counts.entries.where((e) => e.value > 1).map((e) => e.key).toList();
  }

  static String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[áàäâ]'), 'a').replaceAll(RegExp(r'[éèëê]'), 'e').replaceAll(RegExp(r'[íìïî]'), 'i').replaceAll(RegExp(r'[óòöô]'), 'o').replaceAll(RegExp(r'[úùüû]'), 'u').trim();
  static String _levelLabel(TrainingLevel value) => switch (value) { TrainingLevel.beginner => 'Principiante', TrainingLevel.intermediate => 'Intermedio', TrainingLevel.advanced => 'Avanzado' };
}

class _Focus {
  const _Focus(this.name, this.muscles);
  final String name;
  final List<String> muscles;
}
