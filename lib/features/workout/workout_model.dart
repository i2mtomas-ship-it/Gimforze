import 'dart:convert';

class WorkoutExercise {
  const WorkoutExercise({required this.exerciseName, this.sets = 3, this.reps = 10, this.rir = 2, this.restSeconds = 90, this.notes = ''});
  final String exerciseName;
  final int sets;
  final int reps;
  final int rir;
  final int restSeconds;
  final String notes;
  WorkoutExercise copyWith({int? sets, int? reps, int? rir, int? restSeconds, String? notes}) => WorkoutExercise(exerciseName: exerciseName, sets: sets ?? this.sets, reps: reps ?? this.reps, rir: rir ?? this.rir, restSeconds: restSeconds ?? this.restSeconds, notes: notes ?? this.notes);
  Map<String, dynamic> toJson() => {'name': exerciseName, 'sets': sets, 'reps': reps, 'rir': rir, 'restSeconds': restSeconds, 'notes': notes};
  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => WorkoutExercise(exerciseName: json['name'] as String? ?? 'Ejercicio', sets: (json['sets'] as num?)?.toInt() ?? 3, reps: (json['reps'] as num?)?.toInt() ?? 10, rir: (json['rir'] as num?)?.toInt() ?? 2, restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90, notes: json['notes'] as String? ?? '');
}

class WorkoutPlan {
  const WorkoutPlan({this.id = 'rutina-1', this.name = 'Rutina A', this.dayOfWeek = 1, this.exercises = const []});
  final String id;
  final String name;
  /// ISO weekday: 1 = lunes ... 7 = domingo.
  final int dayOfWeek;
  final List<WorkoutExercise> exercises;
  WorkoutPlan copyWith({String? id, String? name, int? dayOfWeek, List<WorkoutExercise>? exercises}) => WorkoutPlan(id: id ?? this.id, name: name ?? this.name, dayOfWeek: dayOfWeek ?? this.dayOfWeek, exercises: exercises ?? this.exercises);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'dayOfWeek': dayOfWeek, 'exercises': exercises.map((e) => e.toJson()).toList()};
  String encode() => jsonEncode(toJson());
  factory WorkoutPlan.fromJson(Map<String, dynamic> map) {
    final list = (map['exercises'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(WorkoutExercise.fromJson).toList();
    return WorkoutPlan(id: map['id'] as String? ?? 'rutina-1', name: map['name'] as String? ?? 'Rutina', dayOfWeek: ((map['dayOfWeek'] as num?)?.toInt() ?? 1).clamp(1, 7), exercises: list);
  }
  factory WorkoutPlan.decode(String raw) => WorkoutPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

class LoggedSet {
  const LoggedSet({required this.weightKg, required this.reps, required this.rir});
  final double weightKg;
  final int reps;
  final int rir;
  double get volumeKg => weightKg * reps;
  Map<String, dynamic> toJson() => {'weight': weightKg, 'reps': reps, 'rir': rir};
  factory LoggedSet.fromJson(Map<String, dynamic> json) => LoggedSet(weightKg: (json['weight'] as num?)?.toDouble() ?? 0, reps: (json['reps'] as num?)?.toInt() ?? 0, rir: (json['rir'] as num?)?.toInt() ?? 0);
}

class SessionExercise {
  const SessionExercise({required this.exerciseName, this.sets = const []});
  final String exerciseName;
  final List<LoggedSet> sets;
  double get volumeKg => sets.fold(0, (sum, set) => sum + set.volumeKg);
  Map<String, dynamic> toJson() => {'name': exerciseName, 'sets': sets.map((s) => s.toJson()).toList()};
  factory SessionExercise.fromJson(Map<String, dynamic> json) => SessionExercise(exerciseName: json['name'] as String? ?? 'Ejercicio', sets: (json['sets'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(LoggedSet.fromJson).toList());
}

class WorkoutSession {
  const WorkoutSession({required this.id, required this.planName, required this.date, required this.startedAt, required this.endedAt, this.exercises = const []});
  final String id;
  final String planName;
  final DateTime date;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<SessionExercise> exercises;
  Duration get duration => endedAt.difference(startedAt);
  double get volumeKg => exercises.fold(0, (sum, exercise) => sum + exercise.volumeKg);
  int get totalSets => exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
  int get totalReps => exercises.fold(0, (sum, exercise) => sum + exercise.sets.fold(0, (r, set) => r + set.reps));
  Map<String, dynamic> toJson() => {'id': id, 'planName': planName, 'date': date.toIso8601String(), 'startedAt': startedAt.toIso8601String(), 'endedAt': endedAt.toIso8601String(), 'exercises': exercises.map((e) => e.toJson()).toList()};
  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(id: json['id'] as String? ?? '', planName: json['planName'] as String? ?? 'Rutina', date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(), startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(), endedAt: DateTime.tryParse(json['endedAt'] as String? ?? '') ?? DateTime.now(), exercises: (json['exercises'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(SessionExercise.fromJson).toList());
}
