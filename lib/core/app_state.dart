import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/profile/profile_model.dart';
import '../features/progress/progress_entry.dart';
import '../features/workout/workout_model.dart';
import '../features/progress/exercise_target.dart';
import '../features/exercises/exercise_model.dart';

class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.profile, this.entries, this.workoutPlans, this.sessions, this.activeWorkoutPlanId, this.exerciseTargets, this.customExercises);
  final SharedPreferences _prefs;
  Profile profile;
  final List<ProgressEntry> entries;
  List<WorkoutPlan> workoutPlans;
  final List<WorkoutSession> sessions;
  String activeWorkoutPlanId;
  List<ExerciseTarget> exerciseTargets;
  List<Exercise> customExercises;
  bool _notifyScheduled = false;

  WorkoutPlan? get activeWorkoutPlan => workoutPlans.cast<WorkoutPlan?>().firstWhere((p) => p?.id == activeWorkoutPlanId, orElse: () => workoutPlans.isEmpty ? null : workoutPlans.first);

  static Future<AppState> create() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPlans = prefs.getString('workout.plans');
    final legacy = prefs.getString('workout.plan');
    List<WorkoutPlan> plans;
    if (rawPlans != null) {
      final decoded = jsonDecode(rawPlans) as List<dynamic>;
      plans = decoded.whereType<Map<String, dynamic>>().map(WorkoutPlan.fromJson).toList();
    } else if (legacy != null) {
      plans = [WorkoutPlan.decode(legacy)];
    } else {
      plans = const [];
    }
    final rawSessions = prefs.getString('workout.sessions');
    final sessions = rawSessions == null ? <WorkoutSession>[] : (jsonDecode(rawSessions) as List<dynamic>).whereType<Map<String, dynamic>>().map(WorkoutSession.fromJson).toList();
    sessions.sort((a, b) => b.date.compareTo(a.date));
    final active = prefs.getString('workout.active') ?? (plans.isEmpty ? '' : plans.first.id);
    final rawTargets = prefs.getString('progress.exerciseTargets');
    final targets = rawTargets == null ? <ExerciseTarget>[] : ExerciseTarget.decodeList(rawTargets);
    final rawCustomExercises = prefs.getString('exercise.custom');
    final customExercises = rawCustomExercises == null
        ? <Exercise>[]
        : (jsonDecode(rawCustomExercises) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(Exercise.fromJson)
            .toList();
    return AppState._(prefs, Profile.fromPrefs(prefs), ProgressEntry.fromPrefs(prefs), plans, sessions, active, targets, customExercises); 
  }

  /// Notifica siempre fuera de una transición de ruta/build. Esto evita que
  /// un guardado disparado desde un diálogo que acaba de cerrarse intente
  /// reconstruir un InheritedNotifier mientras sus dependientes se desactivan.
  void _safeNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (hasListeners) notifyListeners();
    });
  }

  /// Útil después de cerrar una pantalla de edición: los datos ya están
  /// persistidos y el refresco se produce cuando la ruta anterior está estable.
  void notifyAfterFrame() => _safeNotify();

  Future<void> saveProfile(Profile value) async { profile = value; await profile.save(_prefs); _safeNotify(); }
  Future<void> saveWorkoutPlans(List<WorkoutPlan> value, {String? activeId, bool notify = true}) async {
    workoutPlans = List.of(value);
    if (activeId != null) activeWorkoutPlanId = activeId;
    if (workoutPlans.isNotEmpty && !workoutPlans.any((p) => p.id == activeWorkoutPlanId)) activeWorkoutPlanId = workoutPlans.first.id;
    await _prefs.setString('workout.plans', jsonEncode(workoutPlans.map((p) => p.toJson()).toList()));
    await _prefs.setString('workout.active', activeWorkoutPlanId);
    if (notify) _safeNotify();
  }
  Future<void> saveWorkoutPlan(WorkoutPlan value, {bool notify = true}) async {
    final plans = [...workoutPlans];
    final index = plans.indexWhere((p) => p.id == value.id);
    if (index >= 0) plans[index] = value; else plans.add(value);
    await saveWorkoutPlans(plans, activeId: value.id, notify: notify);
  }
  Future<void> removeWorkoutPlan(String id) async {
    final plans = workoutPlans.where((p) => p.id != id).toList();
    await saveWorkoutPlans(plans, activeId: plans.isEmpty ? '' : plans.first.id);
  }
  Future<void> addProgress(ProgressEntry entry) async {
    entries.add(entry); entries.sort((a, b) => b.date.compareTo(a.date)); await ProgressEntry.saveAll(_prefs, entries);
    if (profile.weightKg != entry.weightKg) { profile = profile.copyWith(weightKg: entry.weightKg); await profile.save(_prefs); }
    _safeNotify();
  }
  Future<void> addWorkoutSession(WorkoutSession session) async {
    sessions.removeWhere((s) => s.id == session.id); sessions.add(session); sessions.sort((a, b) => b.date.compareTo(a.date));
    await _prefs.setString('workout.sessions', jsonEncode(sessions.map((s) => s.toJson()).toList())); _safeNotify();
  }

  Future<void> saveExerciseTarget(ExerciseTarget target) async {
    final updated = [...exerciseTargets];
    final index = updated.indexWhere((item) => item.exerciseName.toLowerCase() == target.exerciseName.toLowerCase());
    if (index >= 0) { updated[index] = target; } else { updated.add(target); }
    exerciseTargets = updated;
    await _prefs.setString('progress.exerciseTargets', ExerciseTarget.encodeList(exerciseTargets));
    _safeNotify();
  }


  Future<void> saveCustomExercise(Exercise exercise) async {
    final updated = [...customExercises];
    final index = updated.indexWhere((item) => item.name.toLowerCase() == exercise.name.toLowerCase());
    if (index >= 0) {
      updated[index] = exercise;
    } else {
      updated.add(exercise);
    }
    updated.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    customExercises = updated;
    await _prefs.setString('exercise.custom', jsonEncode(customExercises.map((e) => e.toJson()).toList()));
    _safeNotify();
  }

  Future<void> removeCustomExercise(String name) async {
    customExercises = customExercises.where((e) => e.name.toLowerCase() != name.toLowerCase()).toList();
    await _prefs.setString('exercise.custom', jsonEncode(customExercises.map((e) => e.toJson()).toList()));
    _safeNotify();
  }

  Future<void> saveWorkoutDraft(String planId, DateTime startedAt, List<List<LoggedSet>> logged, {List<WorkoutExercise>? exercises}) async {
    final payload = {
      'planId': planId,
      'startedAt': startedAt.toIso8601String(),
      'logged': logged.map((sets) => sets.map((set) => set.toJson()).toList()).toList(),
      if (exercises != null) 'exercises': exercises.map((e) => e.toJson()).toList(),
    };
    await _prefs.setString('workout.draft.$planId', jsonEncode(payload));
  }

  Map<String, dynamic>? workoutDraft(String planId) {
    final raw = _prefs.getString('workout.draft.$planId');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearWorkoutDraft(String planId) async {
    await _prefs.remove('workout.draft.$planId');
  }

  ExerciseTarget? exerciseTargetFor(String exerciseName) {
    for (final target in exerciseTargets) {
      if (target.exerciseName.toLowerCase() == exerciseName.toLowerCase()) return target;
    }
    return null;
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required AppState state, required Widget child}) : super(notifier: state, child: child);
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope no encontrado en el árbol de widgets.');
    return scope!.notifier!;
  }
}
