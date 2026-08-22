import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../exercises/exercise_model.dart';
import '../exercises/exercise_repository.dart';
import 'workout_model.dart';
import '../progress/exercise_target.dart';
import '../progress/next_session_engine.dart';
import '../progress/achievement_engine.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key, required this.plan});
  final WorkoutPlan plan;
  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final repository = ExerciseRepository();
  List<Exercise> catalog = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final result = await repository.fetchCatalog();
      if (mounted) {
        final custom = AppStateScope.of(context).customExercises;
        final merged = [...custom, ...result.where((e) => !custom.any((c) => c.name.toLowerCase() == e.name.toLowerCase()))];
        setState(() { catalog = merged; loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { catalog = AppStateScope.of(context).customExercises; loading = false; });
    }
  }

  Future<void> _addExercise() async {
    if (catalog.isEmpty) {
      if (loading) return;
      return;
    }
    final selected = await showSearch<Exercise?>(
      context: context,
      delegate: _ExerciseSearchDelegate(catalog),
    );
    if (selected == null || !mounted) return;
    final state = AppStateScope.of(context);
    final currentPlan = state.workoutPlans.firstWhere((p) => p.id == widget.plan.id, orElse: () => widget.plan);
    final exists = currentPlan.exercises.any((e) => e.exerciseName == selected.name);
    if (exists) return;
    final configured = await _configureExercise(selected);
    if (configured == null || !mounted) return;
    final updated = currentPlan.copyWith(
      exercises: [...currentPlan.exercises, configured],
    );
    await state.saveWorkoutPlan(updated, notify: false);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final plan = state.workoutPlans.firstWhere((p) => p.id == widget.plan.id, orElse: () => widget.plan);
    return Scaffold(
      appBar: AppBar(title: Text(plan.name), actions: [IconButton(onPressed: () => _editPlan(plan), icon: const Icon(Icons.edit), tooltip: 'Editar rutina'), IconButton(onPressed: plan.exercises.isEmpty ? null : () => _startWorkout(plan), icon: const Icon(Icons.play_arrow), tooltip: 'Iniciar entrenamiento')]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Row(children: [const Icon(Icons.calendar_today_outlined, size: 20), const SizedBox(width: 8), Expanded(child: Text('Programada: ${_weekdayName(plan.dayOfWeek)}', style: Theme.of(context).textTheme.titleMedium)), TextButton(onPressed: _changeDay, child: const Text('Cambiar'))])),
        Expanded(child: plan.exercises.isEmpty
          ? _EmptyPlan(loading: loading, onAdd: _addExercise)
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: plan.exercises.length,
              onReorderItem: (oldIndex, newIndex) async {

                final items = [...plan.exercises];
                final item = items.removeAt(oldIndex);
                items.insert(newIndex, item);
                await state.saveWorkoutPlan(plan.copyWith(exercises: items), notify: false);
                if (mounted) setState(() {});
              },
              itemBuilder: (context, index) {
                final item = plan.exercises[index];
                return Card(
                  key: ValueKey('${item.exerciseName}-$index'),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(item.exerciseName),
                    subtitle: Text('${item.sets} series × ${item.reps} rep · RIR ${item.rir} · descanso ${item.restSeconds}s${item.notes.isEmpty ? '' : ' · ${item.notes}'}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'editar') await _editExercise(index, item);
                        if (value == 'objetivo') await _editProgressionTarget(item);
                        if (value == 'duplicar') {
                          final current = AppStateScope.of(context).workoutPlans.firstWhere((p) => p.id == plan.id, orElse: () => plan);
                          final copy = [...current.exercises]..insert(index + 1, item);
                          await AppStateScope.of(context).saveWorkoutPlan(current.copyWith(exercises: copy), notify: false);
                          if (mounted) setState(() {});
                        }
                        if (value == 'eliminar') {
                          final current = AppStateScope.of(context).workoutPlans.firstWhere((p) => p.id == plan.id, orElse: () => plan);
                          final copy = [...current.exercises]..removeAt(index);
                          await AppStateScope.of(context).saveWorkoutPlan(current.copyWith(exercises: copy), notify: false);
                          if (mounted) setState(() {});
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'duplicar', child: Text('Duplicar')),
                        PopupMenuItem(value: 'objetivo', child: Text('Objetivo de progresión')),
                        PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                      ],
                    ),
                    onTap: () => _editExercise(index, item),
                  ),
                );
              },
            )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: const Text('Añadir ejercicio'),
      ),
    );
  }

  Future<void> _editPlan(WorkoutPlan plan) async {
    final name = TextEditingController(text: plan.name);
    final selected = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Editar rutina'), content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, name.text.trim()), child: const Text('Guardar'))]));
    name.dispose();
    if (selected == null || selected.isEmpty || !mounted) return;
    await AppStateScope.of(context).saveWorkoutPlan(plan.copyWith(name: selected), notify: false);
    if (mounted) setState(() {});
  }

  Future<void> _changeDay() async {
    final plan = AppStateScope.of(context).workoutPlans.firstWhere((p) => p.id == widget.plan.id, orElse: () => widget.plan);
    final selected = await showDialog<int>(context: context, builder: (_) => SimpleDialog(title: const Text('Día de la semana'), children: [for (var day = 1; day <= 7; day++) SimpleDialogOption(onPressed: () => Navigator.pop(context, day), child: Text(_weekdayName(day)))]));
    if (selected == null || !mounted) return;
    await AppStateScope.of(context).saveWorkoutPlan(plan.copyWith(dayOfWeek: selected), notify: false);
    if (mounted) setState(() {});
  }

  Future<void> _startWorkout(WorkoutPlan plan) async {
    final result = await Navigator.of(context).push<List<Achievement>>(MaterialPageRoute(builder: (_) => WorkoutSessionPage(plan: plan)));
    if (!mounted || result == null || result.isEmpty) return;
    await showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: const Text('🏆 Nuevo logro'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final achievement in result.take(3)) ListTile(contentPadding: EdgeInsets.zero, leading: Text(achievement.icon, style: const TextStyle(fontSize: 28)), title: Text(achievement.title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(achievement.description)),
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('¡Genial!'))],
    ));
  }

  Future<WorkoutExercise?> _configureExercise(Exercise exercise) async {
    final sets = TextEditingController(text: '3');
    final reps = TextEditingController(text: '10');
    final rir = TextEditingController(text: '2');
    final rest = TextEditingController(text: '90');
    final notes = TextEditingController();
    final result = await showDialog<WorkoutExercise>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(exercise.name),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (exercise.primaryMuscles.isNotEmpty) Align(alignment: Alignment.centerLeft, child: Text('Músculo: ${exercise.primaryMuscles.join(', ')}')),
          const SizedBox(height: 12),
          TextField(controller: sets, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Series')),
          TextField(controller: reps, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeticiones')),
          TextField(controller: rir, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RIR')),
          TextField(controller: rest, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Descanso (segundos)')),
          TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notas')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, WorkoutExercise(exerciseName: exercise.name, sets: int.tryParse(sets.text)?.clamp(1, 20).toInt() ?? 3, reps: int.tryParse(reps.text)?.clamp(1, 100).toInt() ?? 10, rir: int.tryParse(rir.text)?.clamp(0, 5).toInt() ?? 2, restSeconds: int.tryParse(rest.text)?.clamp(0, 600).toInt() ?? 90, notes: notes.text.trim())), child: const Text('Añadir')),
        ],
      ),
    );
    // No disponer los controllers durante el desmontaje del diálogo.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    sets.dispose(); reps.dispose(); rir.dispose(); rest.dispose(); notes.dispose();
    return result;
  }

  Future<void> _editProgressionTarget(WorkoutExercise item) async {
    final state = AppStateScope.of(context);
    final existing = state.exerciseTargetFor(item.exerciseName);
    final targetWeight = TextEditingController(text: existing == null || existing.targetWeightKg == 0 ? '' : existing.targetWeightKg.toString());
    final minReps = TextEditingController(text: '${existing?.minReps ?? item.reps.clamp(1, 100)}');
    final maxReps = TextEditingController(text: '${existing?.maxReps ?? (item.reps + 2).clamp(1, 100)}');
    final targetRir = TextEditingController(text: '${existing?.targetRir ?? item.rir}');
    final increment = TextEditingController(text: '${existing?.incrementKg ?? 2.5}');
    final result = await showDialog<ExerciseTarget>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Objetivo de progresión'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Gimforze utilizará este objetivo para recomendar la siguiente sesión de forma progresiva.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(controller: targetWeight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Carga objetivo (kg)')),
          TextField(controller: minReps, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeticiones mínimas')),
          TextField(controller: maxReps, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeticiones máximas')),
          TextField(controller: targetRir, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RIR objetivo')),
          TextField(controller: increment, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Incremento al progresar (kg)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final weight = double.tryParse(targetWeight.text.replaceAll(',', '.'));
            final min = int.tryParse(minReps.text);
            final max = int.tryParse(maxReps.text);
            final rir = int.tryParse(targetRir.text);
            final inc = double.tryParse(increment.text.replaceAll(',', '.'));
            if (weight == null || min == null || max == null || rir == null || inc == null || weight < 0 || min < 1 || max < min) return;
            Navigator.pop(context, ExerciseTarget(exerciseName: item.exerciseName, targetWeightKg: weight, minReps: min.clamp(1, 100).toInt(), maxReps: max.clamp(min, 100).toInt(), targetRir: rir.clamp(0, 5).toInt(), incrementKg: inc.clamp(0, 20).toDouble()));
          }, child: const Text('Guardar objetivo')),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    targetWeight.dispose(); minReps.dispose(); maxReps.dispose(); targetRir.dispose(); increment.dispose();
    if (result == null || !mounted) return;
    await state.saveExerciseTarget(result);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Objetivo guardado para ${item.exerciseName}.')));
  }

  Future<void> _editExercise(int index, WorkoutExercise item) async {
    final sets = TextEditingController(text: '${item.sets}');
    final reps = TextEditingController(text: '${item.reps}');
    final rir = TextEditingController(text: '${item.rir}');
    final rest = TextEditingController(text: '${item.restSeconds}');
    final notes = TextEditingController(text: item.notes);
    final result = await showDialog<WorkoutExercise>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.exerciseName),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: sets, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Series')),
          TextField(controller: reps, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeticiones')),
          TextField(controller: rir, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RIR')),
          TextField(controller: rest, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Descanso (segundos)')),
          TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notas')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, item.copyWith(
            sets: int.tryParse(sets.text)?.clamp(1, 20).toInt(),
            reps: int.tryParse(reps.text)?.clamp(1, 100).toInt(),
            rir: int.tryParse(rir.text)?.clamp(0, 5).toInt(),
            restSeconds: int.tryParse(rest.text)?.clamp(0, 600).toInt(),
            notes: notes.text.trim(),
          )), child: const Text('Guardar')),
        ],
      ),
    );
    // No disponer los controllers durante el desmontaje del diálogo.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    sets.dispose(); reps.dispose(); rir.dispose(); rest.dispose(); notes.dispose();
    if (result == null || !mounted) return;
    final state = AppStateScope.of(context);
    final currentPlan = state.workoutPlans.firstWhere((p) => p.id == widget.plan.id, orElse: () => widget.plan);
    final items = [...currentPlan.exercises]..[index] = result;
    await state.saveWorkoutPlan(currentPlan.copyWith(exercises: items), notify: false);
    if (mounted) setState(() {});
  }
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.loading, required this.onAdd});
  final bool loading;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.fitness_center, size: 64),
    const SizedBox(height: 16),
    Text('Tu rutina todavía está vacía', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    Text(loading ? 'Cargando catálogo de ejercicios…' : 'Añade ejercicios y ajusta series, repeticiones y RIR.', textAlign: TextAlign.center),
    const SizedBox(height: 18),
    FilledButton.icon(onPressed: loading ? null : onAdd, icon: const Icon(Icons.add), label: const Text('Añadir ejercicio')),
  ])));
}

class _ExerciseSearchDelegate extends SearchDelegate<Exercise?> {
  _ExerciseSearchDelegate(this.items);
  final List<Exercise> items;
  @override
  List<Widget>? buildActions(BuildContext context) => [if (query.isNotEmpty) IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));
  @override
  Widget buildResults(BuildContext context) => _results(context);
  @override
  Widget buildSuggestions(BuildContext context) => _results(context);
  Widget _results(BuildContext context) {
    final q = query.trim().toLowerCase();
    final result = items.where((e) => q.isEmpty || e.name.toLowerCase().contains(q) || e.primaryMuscles.join(' ').toLowerCase().contains(q)).take(80).toList();
    return ListView.builder(itemCount: result.length, itemBuilder: (_, i) => ListTile(title: Text(result[i].name), subtitle: Text('${result[i].primaryMuscles.join(', ')}${result[i].equipment == null ? '' : ' · ${result[i].equipment}'}'), onTap: () => close(context, result[i])));
  }
}


String _weekdayName(int day) => const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day.clamp(1, 7) - 1];

class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({super.key, required this.plan});
  final WorkoutPlan plan;
  @override State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  late DateTime startedAt;
  late List<WorkoutExercise> sessionExercises;
  late List<List<LoggedSet>> logged;
  Timer? _ticker;
  Timer? _restTicker;
  Duration elapsed = Duration.zero;
  int restRemaining = 0;
  bool restoring = true;
  bool saving = false;
  String? saveMessage;

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    sessionExercises = List.of(widget.plan.exercises);
    logged = _emptyLog(sessionExercises);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreDraft();
    });
  }

  List<List<LoggedSet>> _emptyLog(List<WorkoutExercise> exercises) => List.generate(
    exercises.length,
    (i) => List.generate(exercises[i].sets, (_) => const LoggedSet(weightKg: 0, reps: 0, rir: 2)),
  );

  Future<void> _restoreDraft() async {
    final state = AppStateScope.of(context);
    final draft = state.workoutDraft(widget.plan.id);
    if (draft != null) {
      final parsedStarted = DateTime.tryParse(draft['startedAt'] as String? ?? '');
      final rawExercises = draft['exercises'];
      final rawLogged = draft['logged'];
      if (parsedStarted != null && rawLogged is List) {
        if (rawExercises is List) {
          final restoredExercises = rawExercises
              .whereType<Map<String, dynamic>>()
              .map(WorkoutExercise.fromJson)
              .toList();
          if (restoredExercises.isNotEmpty) sessionExercises = restoredExercises;
        }
        final restored = <List<LoggedSet>>[];
        for (final rawSets in rawLogged) {
          if (rawSets is List) {
            restored.add(rawSets.whereType<Map<String, dynamic>>().map(LoggedSet.fromJson).toList());
          }
        }
        while (restored.length < sessionExercises.length) restored.add(<LoggedSet>[]);
        if (restored.length > sessionExercises.length) restored.removeRange(sessionExercises.length, restored.length);
        for (var i = 0; i < sessionExercises.length; i++) {
          final expected = sessionExercises[i].sets;
          while (restored[i].length < expected) restored[i].add(const LoggedSet(weightKg: 0, reps: 0, rir: 2));
          if (restored[i].length > expected) restored[i] = restored[i].take(expected).toList();
        }
        startedAt = parsedStarted;
        logged = restored;
        elapsed = DateTime.now().difference(startedAt);
      }
    }
    if (!mounted) return;
    setState(() => restoring = false);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => elapsed = DateTime.now().difference(startedAt));
    });
  }

  Future<void> _persistDraft() async {
    await AppStateScope.of(context).saveWorkoutDraft(widget.plan.id, startedAt, logged, exercises: sessionExercises);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _restTicker?.cancel();
    super.dispose();
  }

  int get completedSets => logged.fold(0, (total, sets) => total + sets.where((s) => s.reps > 0).length);
  int get totalSets => logged.fold(0, (total, sets) => total + sets.length);
  double get sessionProgress => totalSets == 0 ? 0 : completedSets / totalSets;
  double get sessionVolume => logged.fold(0.0, (total, sets) => total + sets.fold(0.0, (sum, set) => sum + set.volumeKg));

  void _startRest(int seconds) {
    _restTicker?.cancel();
    setState(() => restRemaining = seconds.clamp(15, 600).toInt());
    _restTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (restRemaining <= 1) {
        timer.cancel();
        setState(() => restRemaining = 0);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descanso terminado · ¡vamos con la siguiente serie!')));
      } else {
        setState(() => restRemaining--);
      }
    });
  }

  double? _lastWeightFor(String exerciseName) {
    final sessions = AppStateScope.of(context).sessions;
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise.exerciseName.toLowerCase() != exerciseName.toLowerCase()) continue;
        for (final set in exercise.sets.reversed) {
          if (set.weightKg > 0 && set.reps > 0) return set.weightKg;
        }
      }
    }
    return null;
  }

  Future<void> _editSet(int exerciseIndex, int setIndex) async {
    final current = logged[exerciseIndex][setIndex];
    final state = AppStateScope.of(context);
    final configured = sessionExercises[exerciseIndex];
    final exerciseName = configured.exerciseName;
    final recommendation = recommendNextSession(
      exerciseName: exerciseName,
      target: state.exerciseTargetFor(exerciseName),
      sessions: state.sessions,
    );
    final lastWeight = _lastWeightFor(exerciseName);
    final weight = TextEditingController(
      text: current.weightKg == 0 && recommendation.weightKg > 0
          ? recommendation.weightKg.toString()
          : current.weightKg == 0 ? '' : current.weightKg.toString(),
    );
    final reps = TextEditingController(text: current.reps == 0 ? '${recommendation.reps}' : '${current.reps}');
    final rir = TextEditingController(text: current.reps == 0 ? '${recommendation.rir}' : '${current.rir}');
    final result = await showModalBottomSheet<LoggedSet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFDADCE8), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            Row(children: [Expanded(child: Text('Serie ${setIndex + 1}', style: Theme.of(context).textTheme.headlineSmall)), if (current.reps == 0) Text('Sugerencia ${recommendation.weightKg > 0 ? '${recommendation.weightKg} kg' : '—'} × ${recommendation.reps}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary))]),
            const SizedBox(height: 4),
            Text(exerciseName, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: TextField(
                controller: weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg'),
              )),
              const SizedBox(width: 10),
              Expanded(child: Column(children: [
                TextField(
                  controller: reps,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Repeticiones'),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    lastWeight != null
                        ? 'Última vez: ${_formatKg(lastWeight!)} kg'
                        : 'Sin registro anterior',
                    style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ])),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: rir,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'RIR'),
              )),
            ]),
            const SizedBox(height: 10),
            Text('Objetivo: ${configured.reps} rep · RIR ${configured.rir} · descanso ${configured.restSeconds}s', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () {
                final w = double.tryParse(weight.text.replaceAll(',', '.'));
                final r = int.tryParse(reps.text);
                final rr = int.tryParse(rir.text);
                if (w == null || r == null || rr == null) return;
                Navigator.pop(sheetContext, LoggedSet(weightKg: w.clamp(0, 1000).toDouble(), reps: r.clamp(0, 100).toInt(), rir: rr.clamp(0, 5).toInt()));
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Guardar serie'),
            )),
          ]),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    weight.dispose();
    reps.dispose();
    rir.dispose();
    if (result == null || !mounted) return;
    setState(() {
      logged[exerciseIndex][setIndex] = result;
      saving = true;
      saveMessage = null;
    });
    try {
      await _persistDraft();
      if (!mounted) return;
      setState(() { saving = false; saveMessage = '✓ Serie ${setIndex + 1} guardada'; });
      _startRest(configured.restSeconds);
    } catch (_) {
      if (!mounted) return;
      setState(() { saving = false; saveMessage = 'No se pudo guardar la serie. Inténtalo de nuevo.'; });
    }
  }

  Future<void> _addSeries(int exerciseIndex) async {
    setState(() {
      logged[exerciseIndex].add(const LoggedSet(weightKg: 0, reps: 0, rir: 2));
      saving = true;
      saveMessage = null;
    });
    await _persistDraft();
    if (!mounted) return;
    setState(() { saving = false; saveMessage = '✓ Serie añadida'; });
  }

  Future<void> _removeSeries(int exerciseIndex, int setIndex) async {
    if (logged[exerciseIndex].length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cada ejercicio debe conservar al menos una serie.')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar serie'),
        content: Text('¿Eliminar la serie ${setIndex + 1} de ${sessionExercises[exerciseIndex].exerciseName}?'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar'))],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      logged[exerciseIndex].removeAt(setIndex);
      saving = true;
      saveMessage = null;
    });
    await _persistDraft();
    if (!mounted) return;
    setState(() { saving = false; saveMessage = '✓ Serie eliminada'; });
  }

  Future<void> _editExercise(int index) async {
    final exercise = sessionExercises[index];
    final sets = TextEditingController(text: '${exercise.sets}');
    final reps = TextEditingController(text: '${exercise.reps}');
    final rir = TextEditingController(text: '${exercise.rir}');
    final rest = TextEditingController(text: '${exercise.restSeconds}');
    final notes = TextEditingController(text: exercise.notes);
    final result = await showDialog<WorkoutExercise>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Modificar ${exercise.exerciseName}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: TextField(controller: sets, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Series'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: reps, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeticiones objetivo'))),
            ]),
            TextField(controller: rir, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RIR objetivo')),
            TextField(controller: rest, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Descanso (segundos)')),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notas')),
            const SizedBox(height: 8),
            Text('Las series ya registradas se conservan al cambiar la cantidad.', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final s = int.tryParse(sets.text) ?? exercise.sets;
            final r = int.tryParse(reps.text) ?? exercise.reps;
            final rr = int.tryParse(rir.text) ?? exercise.rir;
            final rs = int.tryParse(rest.text) ?? exercise.restSeconds;
            Navigator.pop(context, exercise.copyWith(
              sets: s.clamp(1, 20),
              reps: r.clamp(1, 100),
              rir: rr.clamp(0, 5),
              restSeconds: rs.clamp(0, 1800),
              notes: notes.text.trim(),
            ));
          }, child: const Text('Guardar')),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    sets.dispose(); reps.dispose(); rir.dispose(); rest.dispose(); notes.dispose();
    if (result == null || !mounted) return;

    setState(() {
      sessionExercises[index] = result;
      final current = logged[index];

      // Conservamos las series registradas existentes. Si aumentamos series,
      // se añaden nuevas filas vacías; si reducimos, solo se eliminan las
      // filas que quedan fuera del nuevo número de series.
      if (result.sets > current.length) {
        current.addAll(List.generate(
          result.sets - current.length,
          (_) => const LoggedSet(weightKg: 0, reps: 0, rir: 2),
        ));
      } else if (result.sets < current.length) {
        current.removeRange(result.sets, current.length);
      }

      saving = true;
      saveMessage = null;
    });
    await _persistDraft();
    if (!mounted) return;
    setState(() { saving = false; saveMessage = '✓ Ejercicio actualizado'; });
  }

  Future<void> _changeExercise(int index) async {
    final catalog = await ExerciseRepository().fetchCatalog().catchError((_) => <Exercise>[]);
    if (!mounted || catalog.isEmpty) return;
    final selected = await showSearch<Exercise?>(context: context, delegate: _ExerciseSearchDelegate(catalog));
    if (selected == null || !mounted) return;
    if (sessionExercises.any((e) => e.exerciseName.toLowerCase() == selected.name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ese ejercicio ya está en la sesión.')));
      return;
    }
    final oldName = sessionExercises[index].exerciseName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar ejercicio'),
        content: Text('Se sustituirá "$oldName" por "${selected.name}". Las series registradas de este ejercicio se perderán porque pertenecen al ejercicio anterior.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cambiar'))],
      ),
    );
    if (ok != true || !mounted) return;
    final old = sessionExercises[index];
    setState(() {
      sessionExercises[index] = WorkoutExercise(exerciseName: selected.name, sets: old.sets, reps: old.reps, rir: old.rir, restSeconds: old.restSeconds, notes: old.notes);
      logged[index] = List.generate(old.sets, (_) => const LoggedSet(weightKg: 0, reps: 0, rir: 2));
      saving = true;
      saveMessage = null;
    });
    await _persistDraft();
    if (!mounted) return;
    setState(() { saving = false; saveMessage = '✓ Ejercicio cambiado'; });
  }

  Future<void> _removeExercise(int index) async {
    if (sessionExercises.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La sesión debe conservar al menos un ejercicio.')));
      return;
    }
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Quitar ejercicio'),
      content: Text('¿Quitar "${sessionExercises[index].exerciseName}" de esta sesión?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar'))],
    ));
    if (ok != true || !mounted) return;
    setState(() {
      sessionExercises.removeAt(index);
      logged.removeAt(index);
      saving = true;
      saveMessage = null;
    });
    await _persistDraft();
    if (!mounted) return;
    setState(() { saving = false; saveMessage = '✓ Ejercicio quitado'; });
  }

  Future<void> _reorderExercise(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final exercise = sessionExercises.removeAt(oldIndex);
      final sets = logged.removeAt(oldIndex);
      sessionExercises.insert(newIndex, exercise);
      logged.insert(newIndex, sets);
      saving = true;
      saveMessage = null;
    });
    await _persistDraft();
    if (!mounted) return;
    setState(() { saving = false; saveMessage = '✓ Orden actualizado'; });
  }

  Future<void> _finish() async {
    if (completedSets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registra al menos una serie antes de finalizar.')));
      return;
    }
    final beforeIds = AchievementEngine.unlockedIds(AppStateScope.of(context).sessions);
    final ended = DateTime.now();
    final exercises = <SessionExercise>[];
    for (var i = 0; i < sessionExercises.length; i++) {
      exercises.add(SessionExercise(exerciseName: sessionExercises[i].exerciseName, sets: logged[i].where((s) => s.reps > 0).toList()));
    }
    final session = WorkoutSession(id: startedAt.microsecondsSinceEpoch.toString(), planName: widget.plan.name, date: startedAt, startedAt: startedAt, endedAt: ended, exercises: exercises);
    await AppStateScope.of(context).addWorkoutSession(session);
    await AppStateScope.of(context).clearWorkoutDraft(widget.plan.id);
    final after = AchievementEngine.summarize(AppStateScope.of(context).sessions);
    final newAchievements = after.unlocked.where((a) => !beforeIds.contains(a.id)).toList();
    if (mounted) Navigator.pop(context, newAchievements);
  }

  Future<bool> _confirmExit() async {
    if (completedSets == 0) return true;
    await _persistDraft();
    if (!mounted) return true;
    final result = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Entrenamiento en curso'),
      content: const Text('Las series registradas y los cambios de orden se han guardado como borrador. Puedes volver y continuar el entrenamiento.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Seguir')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir y guardar'))],
    ));
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (restoring) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopScope(
      canPop: completedSets == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || completedSets == 0) return;
        final ok = await _confirmExit();
        if (ok && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Entrenamiento'),
          actions: [
            if (saving) const Padding(padding: EdgeInsets.only(right: 14), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
            Padding(padding: const EdgeInsets.only(right: 14), child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: scheme.primary.withOpacity(.09), borderRadius: BorderRadius.circular(14)), child: Text(_formatDuration(elapsed), style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800)))),)
          ],
        ),
        body: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          buildDefaultDragHandles: false,
          header: Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(children: [
            _SessionHero(plan: widget.plan, progress: sessionProgress, completed: completedSets, total: totalSets, volumeKg: sessionVolume),
            if (saveMessage != null) ...[
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: saveMessage!.startsWith('✓') ? const Color(0xFF103426) : AppTheme.softCoral, borderRadius: BorderRadius.circular(14)), child: Row(children: [Icon(saveMessage!.startsWith('✓') ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: saveMessage!.startsWith('✓') ? AppTheme.secondary : AppTheme.highlight, size: 19), const SizedBox(width: 8), Expanded(child: Text(saveMessage!, style: const TextStyle(fontWeight: FontWeight.w800)))])),
            ],
            if (restRemaining > 0) ...[const SizedBox(height: 12), _RestCard(seconds: restRemaining, onSkip: () => setState(() => restRemaining = 0))],
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: Text('Mantén pulsado ☰ para mover un ejercicio. Las series se mueven con él.', style: theme.textTheme.bodySmall)),
          ])),
          itemCount: sessionExercises.length,
          onReorder: _reorderExercise,
          itemBuilder: (context, i) {
            final exercise = sessionExercises[i];
            return Padding(
              key: ValueKey('${exercise.exerciseName}-$i-${exercise.hashCode}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: _SessionExerciseCard(
                exercise: exercise,
                sets: logged[i],
                index: i,
                lastWeight: _lastWeightFor(exercise.exerciseName),
                onEditSet: (setIndex) => _editSet(i, setIndex),
                onAddSet: () => _addSeries(i),
                onRemoveSet: (setIndex) => _removeSeries(i, setIndex),
                onEditExercise: () => _editExercise(i),
                onChangeExercise: () => _changeExercise(i),
                onRemoveExercise: () => _removeExercise(i),
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: FilledButton.icon(onPressed: _finish, icon: const Icon(Icons.check_circle_outline_rounded), label: Text(completedSets == totalSets && totalSets > 0 ? 'Finalizar entrenamiento' : 'Guardar y finalizar'))),
      ),
    );
  }
}

class _SessionHero extends StatelessWidget {
  const _SessionHero({required this.plan, required this.progress, required this.completed, required this.total, required this.volumeKg});
  final WorkoutPlan plan;
  final double progress;
  final int completed;
  final int total;
  final double volumeKg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [scheme.primary, const Color(0xFF7D78FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: scheme.primary.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(plan.name, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.5))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(12)), child: Text('$completed/$total series', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 12),
        Row(children: [const Icon(Icons.fitness_center_rounded, color: Colors.white70, size: 18), const SizedBox(width: 7), Text('Volumen actual', style: const TextStyle(color: Colors.white70)), const Spacer(), Text('${_formatKg(volumeKg)} kg', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 8),
        const Text('Puedes añadir, quitar, editar y reordenar ejercicios durante la sesión.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 18),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white.withOpacity(.18), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
      ]),
    );
  }
}

class _RestCard extends StatelessWidget {
  const _RestCard({required this.seconds, required this.onSkip});
  final int seconds;
  final VoidCallback onSkip;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(16, 14, 12, 14), decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(.10), borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(.16), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.timer_rounded, color: AppTheme.secondary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Descanso', style: TextStyle(fontWeight: FontWeight.w800)), Text('${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} · recupera y prepárate', style: Theme.of(context).textTheme.bodyMedium)])), TextButton(onPressed: onSkip, child: const Text('Saltar'))]));
}

class _SessionExerciseCard extends StatelessWidget {
  const _SessionExerciseCard({required this.exercise, required this.sets, required this.index, required this.lastWeight, required this.onEditSet, required this.onAddSet, required this.onRemoveSet, required this.onEditExercise, required this.onChangeExercise, required this.onRemoveExercise});
  final WorkoutExercise exercise;
  final List<LoggedSet> sets;
  final int index;
  final double? lastWeight;
  final ValueChanged<int> onEditSet;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final VoidCallback onEditExercise;
  final VoidCallback onChangeExercise;
  final VoidCallback onRemoveExercise;

  @override
  Widget build(BuildContext context) {
    final done = sets.where((s) => s.reps > 0).length;
    final theme = Theme.of(context);
    return Card(child: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ReorderableDragStartListener(index: index, child: Container(width: 38, height: 42, decoration: BoxDecoration(color: AppTheme.softIndigo, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.drag_handle_rounded, color: AppTheme.primary))),
        const SizedBox(width: 10),
        Container(width: 34, height: 42, decoration: BoxDecoration(color: AppTheme.softIndigo, borderRadius: BorderRadius.circular(14)), child: Center(child: Text('${index + 1}', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(exercise.exerciseName, style: theme.textTheme.titleMedium), const SizedBox(height: 3), Text('${exercise.reps} rep · RIR ${exercise.rir} · ${exercise.restSeconds}s', style: theme.textTheme.bodySmall), if (lastWeight != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Última vez: ${_formatKg(lastWeight!)} kg', style: TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)))])),
        Text('$done/${sets.length}', style: TextStyle(color: done == sets.length ? AppTheme.secondary : AppTheme.muted, fontWeight: FontWeight.w800)),
        PopupMenuButton<String>(onSelected: (value) { if (value == 'editar') onEditExercise(); if (value == 'cambiar') onChangeExercise(); if (value == 'serie') onAddSet(); if (value == 'eliminar') onRemoveExercise(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'editar', child: Text('Modificar ejercicio')), PopupMenuItem(value: 'cambiar', child: Text('Cambiar ejercicio')), PopupMenuItem(value: 'serie', child: Text('Añadir serie')), PopupMenuItem(value: 'eliminar', child: Text('Quitar ejercicio'))]),
      ]),
      const SizedBox(height: 8),
      for (var s = 0; s < sets.length; s++) _SetRow(number: s + 1, set: sets[s], lastWeight: lastWeight, onTap: () => onEditSet(s), onRemove: () => onRemoveSet(s)),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: onAddSet, icon: const Icon(Icons.add_rounded), label: const Text('Añadir serie')),
    ])));
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.number, required this.set, required this.lastWeight, required this.onTap, required this.onRemove});
  final int number;
  final LoggedSet set;
  final double? lastWeight;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final completed = set.reps > 0;
    return Padding(padding: const EdgeInsets.only(top: 4), child: Material(color: completed ? AppTheme.softMint : AppTheme.background, borderRadius: BorderRadius.circular(15), child: InkWell(borderRadius: BorderRadius.circular(15), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), child: Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: completed ? AppTheme.secondary : Colors.white, shape: BoxShape.circle), child: Center(child: completed ? const Icon(Icons.check, size: 16, color: Colors.white) : Text('$number', style: const TextStyle(fontWeight: FontWeight.w800)))), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text(completed ? '${_formatKg(set.weightKg)} kg × ${set.reps}' : 'Registrar serie', style: TextStyle(fontWeight: completed ? FontWeight.w800 : FontWeight.w700)),
  if (lastWeight != null) ...[
    const SizedBox(height: 2),
    Text('Última vez: ${_formatKg(lastWeight!)} kg', style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700)),
  ],
])), Text('RIR ${set.rir}', style: Theme.of(context).textTheme.bodySmall), const SizedBox(width: 2), IconButton(onPressed: onRemove, tooltip: 'Eliminar serie', icon: const Icon(Icons.remove_circle_outline_rounded, size: 20)), Icon(completed ? Icons.edit_outlined : Icons.add_circle_outline_rounded, size: 20, color: completed ? AppTheme.muted : AppTheme.primary)])))));
  }
}

String _formatKg(double kg) => kg % 1 == 0 ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
String _formatDuration(Duration d) { final m = d.inMinutes; final s = d.inSeconds % 60; return '${m} min ${s.toString().padLeft(2, '0')} s'; }
