import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../exercises/exercise_model.dart';
import '../exercises/exercise_repository.dart';
import 'workout_model.dart';

class RoutineEditorPage extends StatefulWidget {
  const RoutineEditorPage({super.key, required this.plan});
  final WorkoutPlan plan;

  @override
  State<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends State<RoutineEditorPage> {
  late String name;
  late final TextEditingController nameController;
  late int dayOfWeek;
  late List<WorkoutExercise> exercises;

  @override
  void initState() {
    super.initState();
    name = widget.plan.name;
    nameController = TextEditingController(text: name);
    dayOfWeek = widget.plan.dayOfWeek;
    exercises = [...widget.plan.exercises];
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final selected = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const _ExercisePickerPage()),
    );
    if (selected == null || !mounted) return;
    setState(() => exercises.add(WorkoutExercise(exerciseName: selected.name)));
  }

  Future<void> _editExercise(int index) async {
    final current = exercises[index];
    final result = await showModalBottomSheet<WorkoutExercise>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExerciseSettingsSheet(exercise: current),
    );
    if (result == null || !mounted) return;
    setState(() => exercises[index] = result);
  }

  Future<void> _save() async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pon un nombre a la rutina.')));
      return;
    }
    final updated = widget.plan.copyWith(name: cleanName, dayOfWeek: dayOfWeek, exercises: exercises);
    final state = AppStateScope.of(context);
    // Persistimos mientras el editor sigue montado, pero no notificamos al
    // InheritedNotifier durante la transición. La pantalla de rutinas notifica
    // cuando la ruta del editor ya se ha desmontado.
    await state.saveWorkoutPlan(updated, notify: false);
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar rutina'),
        actions: [
          TextButton.icon(onPressed: _save, icon: const Icon(Icons.check_rounded), label: const Text('Guardar')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(.78)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 27)),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Diseña tu sesión', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${exercises.length} ejercicios · ${_estimatedMinutes(exercises)} min aprox.', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            onChanged: (value) => name = value,
            decoration: const InputDecoration(labelText: 'Nombre de la rutina', prefixIcon: Icon(Icons.edit_rounded)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: dayOfWeek,
            decoration: const InputDecoration(labelText: 'Día de entrenamiento', prefixIcon: Icon(Icons.calendar_today_rounded)),
            items: [for (var day = 1; day <= 7; day++) DropdownMenuItem(value: day, child: Text(_weekdayName(day)))],
            onChanged: (value) => setState(() => dayOfWeek = value ?? dayOfWeek),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: Text('Ejercicios', style: theme.textTheme.titleLarge)),
            Text('${exercises.length}', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.primary)),
          ]),
          const SizedBox(height: 8),
          if (exercises.isEmpty)
            Card(
              color: AppTheme.softIndigo,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Icon(Icons.fitness_center_rounded, size: 36, color: AppTheme.primary),
                  const SizedBox(height: 10),
                  Text('Añade los ejercicios de tu sesión', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 5),
                  const Text('Puedes elegir del catálogo o de tus ejercicios personalizados.', textAlign: TextAlign.center),
                ]),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercises.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = exercises.removeAt(oldIndex);
                  exercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final item = exercises[index];
                return Card(
                  key: ValueKey('${item.exerciseName}-$index'),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.softIndigo, borderRadius: BorderRadius.circular(13)), child: Center(child: Text('${index + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.exerciseName, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('${item.sets} series · ${item.reps} rep · RIR ${item.rir} · ${item.restSeconds}s descanso', style: theme.textTheme.bodyMedium),
                      ])),
                      IconButton(onPressed: () => _editExercise(index), icon: const Icon(Icons.tune_rounded), tooltip: 'Configurar'),
                      ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_indicator_rounded, color: AppTheme.muted)),
                    ]),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _addExercise, icon: const Icon(Icons.add_rounded), label: const Text('Añadir ejercicio')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('Guardar rutina')),
        ],
      ),
    );
  }
}


int _estimatedMinutes(List<WorkoutExercise> items) {
  var seconds = 0;
  for (final e in items) {
    seconds += e.sets * (e.restSeconds + 35);
  }
  return (seconds / 60).ceil();
}

class _ExerciseSettingsSheet extends StatefulWidget {
  const _ExerciseSettingsSheet({required this.exercise});
  final WorkoutExercise exercise;
  @override
  State<_ExerciseSettingsSheet> createState() => _ExerciseSettingsSheetState();
}

class _ExerciseSettingsSheetState extends State<_ExerciseSettingsSheet> {
  late final TextEditingController sets;
  late final TextEditingController reps;
  late final TextEditingController rir;
  late final TextEditingController rest;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    sets = TextEditingController(text: '${widget.exercise.sets}');
    reps = TextEditingController(text: '${widget.exercise.reps}');
    rir = TextEditingController(text: '${widget.exercise.rir}');
    rest = TextEditingController(text: '${widget.exercise.restSeconds}');
    notes = TextEditingController(text: widget.exercise.notes);
  }

  @override
  void dispose() { sets.dispose(); reps.dispose(); rir.dispose(); rest.dispose(); notes.dispose(); super.dispose(); }

  int _int(TextEditingController c, int fallback) => int.tryParse(c.text.trim()) ?? fallback;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 20),
    child: ListView(shrinkWrap: true, children: [
      Text(widget.exercise.exerciseName, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 18),
      Row(children: [Expanded(child: _num('Series', sets)), const SizedBox(width: 10), Expanded(child: _num('Repeticiones', reps))]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: _num('RIR', rir)), const SizedBox(width: 10), Expanded(child: _num('Descanso (s)', rest))]),
      const SizedBox(height: 10),
      TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notas', prefixIcon: Icon(Icons.notes_rounded))),
      const SizedBox(height: 16),
      FilledButton(onPressed: () => Navigator.pop(context, widget.exercise.copyWith(sets: _int(sets, 3), reps: _int(reps, 10), rir: _int(rir, 2), restSeconds: _int(rest, 90), notes: notes.text.trim())), child: const Text('Guardar ajustes')),
    ]),
  );

  Widget _num(String label, TextEditingController controller) => TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label));
}

class _ExercisePickerPage extends StatefulWidget {
  const _ExercisePickerPage();
  @override
  State<_ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<_ExercisePickerPage> {
  final repository = ExerciseRepository();
  final search = TextEditingController();
  List<Exercise> catalog = [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); _load(); search.addListener(() => setState(() {})); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final online = await repository.fetchCatalog();
      if (!mounted) return;
      final custom = AppStateScope.of(context).customExercises;
      final merged = <String, Exercise>{for (final e in [...online, ...custom]) e.name.toLowerCase(): e};
      setState(() { catalog = merged.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); loading = false; error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { catalog = AppStateScope.of(context).customExercises; loading = false; error = 'No se pudo cargar el catálogo. Puedes elegir tus ejercicios personalizados.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final visible = catalog.where((e) => e.name.toLowerCase().contains(query) || e.primaryMuscles.any((m) => m.toLowerCase().contains(query))).take(150).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir ejercicio')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 30), children: [
        TextField(controller: search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Buscar ejercicio o músculo')),
        const SizedBox(height: 12),
        if (loading) const LinearProgressIndicator(),
        if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(error!, style: const TextStyle(color: AppTheme.muted))),
        for (final exercise in visible)
          Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: CircleAvatar(backgroundColor: AppTheme.softIndigo, child: const Icon(Icons.fitness_center_rounded, color: AppTheme.primary)), title: Text(exercise.name), subtitle: Text(exercise.primaryMuscles.isEmpty ? 'Músculo no indicado' : exercise.primaryMuscles.join(' · ')), trailing: const Icon(Icons.add_circle_outline_rounded), onTap: () => Navigator.pop(context, exercise))),
        if (!loading && visible.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No hemos encontrado ese ejercicio.'))),
      ]),
    );
  }
}

String _weekdayName(int day) => const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day.clamp(1, 7) - 1];
