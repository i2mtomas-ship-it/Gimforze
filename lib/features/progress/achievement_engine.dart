import '../workout/workout_model.dart';

class Achievement {
  const Achievement({required this.id, required this.title, required this.description, required this.icon, required this.threshold, required this.current});
  final String id;
  final String title;
  final String description;
  final String icon;
  final int threshold;
  final int current;
  bool get unlocked => current >= threshold;
  double get progress => threshold <= 0 ? 1 : (current / threshold).clamp(0, 1).toDouble();
}

class AchievementSummary {
  const AchievementSummary({required this.achievements, required this.xp, required this.level});
  final List<Achievement> achievements;
  final int xp;
  final int level;
  List<Achievement> get unlocked => achievements.where((a) => a.unlocked).toList();
}

class AchievementEngine {
  static AchievementSummary summarize(List<WorkoutSession> sessions) {
    final ordered = [...sessions]..sort((a, b) => a.date.compareTo(b.date));
    final workoutCount = ordered.length;
    final volume = ordered.fold<double>(0, (sum, s) => sum + s.volumeKg).round();
    final streak = _currentStreak(ordered);
    final prs = _personalRecordCount(ordered);
    final achievements = <Achievement>[
      Achievement(id: 'first', title: 'Primer paso', description: 'Completa tu primer entrenamiento.', icon: '🏋️', threshold: 1, current: workoutCount),
      Achievement(id: 'sessions10', title: 'Constante', description: 'Completa 10 entrenamientos.', icon: '🥉', threshold: 10, current: workoutCount),
      Achievement(id: 'sessions25', title: 'Disciplina', description: 'Completa 25 entrenamientos.', icon: '🥈', threshold: 25, current: workoutCount),
      Achievement(id: 'sessions50', title: 'Guerrero', description: 'Completa 50 entrenamientos.', icon: '🥇', threshold: 50, current: workoutCount),
      Achievement(id: 'sessions100', title: 'Centurión', description: 'Completa 100 entrenamientos.', icon: '🏆', threshold: 100, current: workoutCount),
      Achievement(id: 'streak3', title: 'En marcha', description: 'Consigue una racha de 3 días con entrenamiento.', icon: '🔥', threshold: 3, current: streak),
      Achievement(id: 'streak7', title: 'Racha de acero', description: 'Consigue una racha de 7 días.', icon: '🔥', threshold: 7, current: streak),
      Achievement(id: 'streak14', title: 'Imparable', description: 'Consigue una racha de 14 días.', icon: '⚡', threshold: 14, current: streak),
      Achievement(id: 'streak30', title: 'Máquina', description: 'Consigue una racha de 30 días.', icon: '💜', threshold: 30, current: streak),
      Achievement(id: 'pr1', title: 'Nuevo récord', description: 'Consigue tu primer récord personal de carga.', icon: '🏆', threshold: 1, current: prs),
      Achievement(id: 'pr5', title: 'Superación', description: 'Consigue 5 récords personales.', icon: '🚀', threshold: 5, current: prs),
      Achievement(id: 'pr10', title: 'Nivel atleta', description: 'Consigue 10 récords personales.', icon: '💪', threshold: 10, current: prs),
      Achievement(id: 'volume10k', title: '10 toneladas', description: 'Mueve 10.000 kg acumulados.', icon: '⚙️', threshold: 10000, current: volume),
      Achievement(id: 'volume50k', title: '50 toneladas', description: 'Mueve 50.000 kg acumulados.', icon: '🔥', threshold: 50000, current: volume),
      Achievement(id: 'volume100k', title: '100 toneladas', description: 'Mueve 100.000 kg acumulados.', icon: '🏆', threshold: 100000, current: volume),
    ];
    final xp = workoutCount * 50 + prs * 75 + achievements.where((a) => a.unlocked).length * 100 + (volume / 100).floor();
    final level = 1 + xp ~/ 500;
    return AchievementSummary(achievements: achievements, xp: xp, level: level);
  }

  static Set<String> unlockedIds(List<WorkoutSession> sessions) => summarize(sessions).unlocked.map((a) => a.id).toSet();

  static int _currentStreak(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;
    final days = sessions.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet().toList()..sort();
    if (days.isEmpty) return 0;
    var streak = 1;
    for (var i = days.length - 1; i > 0; i--) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) streak++; else break;
    }
    return streak;
  }

  static int _personalRecordCount(List<WorkoutSession> sessions) {
    final best = <String, double>{};
    var records = 0;
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          if (set.reps <= 0 || set.weightKg <= 0) continue;
          final key = exercise.exerciseName.toLowerCase();
          final previous = best[key] ?? 0;
          if (set.weightKg > previous) {
            best[key] = set.weightKg;
            records++;
          }
        }
      }
    }
    return records;
  }
}
