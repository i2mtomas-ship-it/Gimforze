import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'exercise_model.dart';
import 'exercise_repository.dart';
import '../workout/workout_model.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';

String _weekdayName(int day) => const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day.clamp(1, 7) - 1];

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final repository = ExerciseRepository();
  final search = TextEditingController();
  List<Exercise> all = const [];
  String? error;
  bool loading = true;
  String muscle = 'Todos';
  String equipment = 'Todo';
  bool onlyCustom = false;

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await repository.fetchCatalog();
      if (!mounted) return;
      final custom = AppStateScope.of(context).customExercises;
      final merged = [...custom, ...result.where((e) => !custom.any((c) => c.name.toLowerCase() == e.name.toLowerCase()))];
      setState(() { all = merged; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  List<Exercise> get filtered {
    final query = _normalize(search.text);
    return all.where((e) {
      final muscleOk = muscle == 'Todos' || e.primaryMuscles.contains(muscle) || e.secondaryMuscles.contains(muscle);
      final equipmentOk = equipment == 'Todo' || e.equipment == equipment;
      final isCustom = (e.category ?? '').toLowerCase() == 'personalizado' || (e.source ?? '').toLowerCase().contains('creado por ti');
      final customOk = !onlyCustom || isCustom;
      final text = _normalize('${e.name} ${e.primaryMuscles.join(' ')} ${e.equipment ?? ''}');
      return muscleOk && equipmentOk && customOk && (query.isEmpty || text.contains(query));
    }).toList();
  }

  List<String> get muscles {
    final values = <String>{};
    for (final e in all) values.addAll(e.primaryMuscles);
    return ['Todos', ...values.toList()..sort()];
  }

  List<String> get equipments {
    final values = <String>{};
    for (final e in all) if ((e.equipment ?? '').isNotEmpty) values.add(e.equipment!);
    return ['Todo', ...values.toList()..sort()];
  }

  Future<void> _createCustomExercise() async {
    final result = await _showCustomExerciseEditor(context);
    if (result == null || !mounted) return;
    await AppStateScope.of(context).saveCustomExercise(result);
    setState(() {
      all = [result, ...all.where((e) => e.name.toLowerCase() != result.name.toLowerCase())];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ejercicio «${result.name}» creado y guardado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Esta pantalla también se abre como una ruta independiente desde Rutinas.
    // Necesita su ancestro Material para que TextField y otros widgets
    // Material tengan un ancestro Material válido.
    return Material(
      type: MaterialType.transparency,
      child: CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Ejercicios'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: [
            IconButton(onPressed: _createCustomExercise, icon: const Icon(Icons.add_circle_outline), tooltip: 'Crear ejercicio'),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(delegate: SliverChildListDelegate([
              Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: _createCustomExercise, icon: const Icon(Icons.add), label: const Text('Crear mi ejercicio'))),
              const SizedBox(height: 8),
            TextField(
              controller: search,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Buscar ejercicio, músculo…'),
            ),
            const SizedBox(height: 12),
            if (loading) const LinearProgressIndicator(),
            if (error != null) _ErrorCard(message: error!, onRetry: _load),
            if (!loading && error == null) ...[
              _filterRow(),
              const SizedBox(height: 10),
              _catalogMode(),
              const SizedBox(height: 12),
              Text('${filtered.length} ejercicios', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (filtered.isEmpty) _EmptyExerciseState(onCreate: _createCustomExercise),
              for (final exercise in filtered.take(250)) _ExerciseTile(exercise: exercise, onChanged: _load),
              if (filtered.length > 250)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Mostrando los primeros 250 resultados. Usa el buscador para afinar.', style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ])),
        ),
      ],
      ),
    );
  }


  Widget _catalogMode() {
    final customCount = all.where((e) => (e.category ?? '').toLowerCase() == 'personalizado' || (e.source ?? '').toLowerCase().contains('creado por ti')).length;
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Todos'),
            selected: !onlyCustom,
            onSelected: (_) => setState(() => onlyCustom = false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            avatar: const Icon(Icons.person_rounded, size: 17),
            label: Text('Mis ejercicios ($customCount)'),
            selected: onlyCustom,
            onSelected: (_) => setState(() => onlyCustom = true),
          ),
        ),
      ],
    );
  }

  Widget _filterRow() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          DropdownButton<String>(value: muscle, items: muscles.map((v) => DropdownMenuItem(value: v, child: Text(_muscleLabel(v)))).toList(), onChanged: (v) => setState(() => muscle = v ?? 'Todos')),
          const SizedBox(width: 16),
          DropdownButton<String>(value: equipment, items: equipments.map((v) => DropdownMenuItem(value: v, child: Text(_equipmentLabel(v)))).toList(), onChanged: (v) => setState(() => equipment = v ?? 'Todo')),
        ]),
      );

  String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[áàäâ]'), 'a').replaceAll(RegExp(r'[éèëê]'), 'e').replaceAll(RegExp(r'[íìïî]'), 'i').replaceAll(RegExp(r'[óòöô]'), 'o').replaceAll(RegExp(r'[úùüû]'), 'u');

  String _muscleLabel(String value) => switch (value) {
        'abdominals' => 'Abdominales',
        'biceps' => 'Bíceps',
        'triceps' => 'Tríceps',
        'chest' => 'Pecho',
        'middle back' => 'Espalda media',
        'lower back' => 'Lumbar',
        'lats' => 'Dorsal',
        'shoulders' => 'Hombros',
        'quadriceps' => 'Cuádriceps',
        'hamstrings' => 'Isquios',
        'glutes' => 'Glúteos',
        'calves' => 'Gemelos',
        'forearms' => 'Antebrazo',
        'adductors' => 'Aductores',
        'abductors' => 'Abductores',
        'neck' => 'Cuello',
        'traps' => 'Trapecio',
        _ => value,
      };

  String _equipmentLabel(String value) => switch (value) {
        'body only' => 'Peso corporal',
        'barbell' => 'Barra',
        'dumbbell' => 'Mancuernas',
        'cable' => 'Polea',
        'machine' => 'Máquina',
        'kettlebells' => 'Kettlebell',
        'bands' => 'Bandas',
        'medicine ball' => 'Balón medicinal',
        'exercise ball' => 'Fitball',
        'foam roll' => 'Rodillo de espuma',
        _ => value,
      };

}


String _levelLabel(String? value) => switch (value) {
  'beginner' => 'Principiante',
  'intermediate' => 'Intermedio',
  'expert' => 'Avanzado',
  _ => value == null || value.isEmpty ? 'Nivel no indicado' : value,
};

String _mechanicLabel(String? value) => switch (value) {
  'compound' => 'Compuesto',
  'isolation' => 'Aislamiento',
  _ => value == null || value.isEmpty ? 'Tipo no indicado' : value,
};

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.onChanged});
  final Exercise exercise;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final custom = (exercise.category ?? '').toLowerCase() == 'personalizado' || (exercise.source ?? '').toLowerCase().contains('creado por ti');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => ExerciseDetailPage(exercise: exercise)),
            );
            if (changed == true) {
              await onChanged();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: exercise.imageUrl.isEmpty
                      ? Container(color: custom ? AppTheme.secondary.withOpacity(.12) : AppTheme.primary.withOpacity(.10), child: Icon(custom ? Icons.person_add_alt_1_rounded : Icons.fitness_center_rounded, color: custom ? AppTheme.secondary : AppTheme.primary))
                      : Image.network(exercise.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppTheme.primary.withOpacity(.10), child: const Icon(Icons.fitness_center_rounded, color: AppTheme.primary))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(exercise.name, style: Theme.of(context).textTheme.titleMedium)), if (custom) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(.12), borderRadius: BorderRadius.circular(9)), child: const Text('MÍO', style: TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.w900)))]),
                if ((exercise.englishName ?? '').trim().isNotEmpty &&
                    exercise.englishName!.trim().toLowerCase() != exercise.name.trim().toLowerCase()) ...[
                  const SizedBox(height: 2),
                  Text(
                    exercise.englishName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 5),
                Text('${exercise.primaryMuscles.join(', ')} · ${exercise.equipment ?? 'Sin equipamiento'}', maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
            ]),
          ),
        ),
      ),
    );
  }
}

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({super.key, required this.exercise});
  final Exercise exercise;

  Future<void> _addToRoutine(BuildContext context) async {
    final state = AppStateScope.of(context);
    if (state.workoutPlans.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero crea una rutina para poder añadir este ejercicio.')));
      }
      return;
    }
    final plan = await showModalBottomSheet<WorkoutPlan>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Añadir a una rutina', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            for (final routine in state.workoutPlans)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: AppTheme.softIndigo, child: Icon(Icons.fitness_center_rounded, color: AppTheme.primary)),
                  title: Text(routine.name),
                  subtitle: Text('${routine.exercises.length} ejercicios · ${_weekdayName(routine.dayOfWeek)}'),
                  trailing: const Icon(Icons.add_circle_outline_rounded),
                  onTap: () => Navigator.pop(sheetContext, routine),
                ),
              ),
          ],
        ),
      ),
    );
    if (plan == null || !context.mounted) return;
    final already = plan.exercises.any((item) => item.exerciseName.toLowerCase() == exercise.name.toLowerCase());
    if (already) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este ejercicio ya está en esa rutina.')));
      return;
    }
    final updated = plan.copyWith(exercises: [...plan.exercises, WorkoutExercise(exerciseName: exercise.name)]);
    await state.saveWorkoutPlan(updated, notify: false);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('«${exercise.name}» añadido a ${plan.name}.')));
  }

  Future<void> _tutorial() async {
    final query = Uri.encodeComponent('${exercise.name} tutorial técnica ejercicio');
    final uri = Uri.parse('https://www.youtube.com/results?search_query=$query');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final custom = (exercise.category ?? '').toLowerCase() == 'personalizado' || (exercise.source ?? '').toLowerCase().contains('creado por ti');
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del ejercicio'),
        actions: custom
            ? [
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final updated = await _showCustomExerciseEditor(context, initial: exercise);
                      if (updated == null || !context.mounted) return;
                      await AppStateScope.of(context).saveCustomExercise(updated);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Eliminar ejercicio'),
                          content: Text('¿Quieres eliminar «${exercise.name}» de tus ejercicios?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
                            FilledButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              style: FilledButton.styleFrom(backgroundColor: AppTheme.highlight),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        final state = AppStateScope.of(context);
                        await state.removeCustomExercise(exercise.name);
                        if (!context.mounted) return;
                        // Dejamos terminar el desmontaje del diálogo antes de
                        // cerrar la ruta del detalle. La pantalla de catálogo
                        // recargará la lista al recibir true.
                        await WidgetsBinding.instance.endOfFrame;
                        if (context.mounted) Navigator.of(context).pop(true);
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar ejercicio')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar ejercicio')),
                  ],
                ),
              ]
            : null,
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [custom ? AppTheme.secondary : AppTheme.primary, (custom ? AppTheme.secondary : AppTheme.primary).withOpacity(.76)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(17)), child: Icon(custom ? Icons.person_add_alt_1_rounded : Icons.fitness_center_rounded, color: Colors.white, size: 29)),
            const SizedBox(height: 18),
            Text(exercise.name, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 8),
            Text(exercise.primaryMuscles.isEmpty ? 'Ejercicio de entrenamiento' : exercise.primaryMuscles.join(' · '), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            if (custom) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(10)), child: const Text('EJERCICIO CREADO POR TI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _InfoChip(icon: Icons.signal_cellular_alt_rounded, label: _levelLabel(exercise.level)),
          _InfoChip(icon: Icons.fitness_center_rounded, label: exercise.equipment ?? 'Peso corporal'),
          _InfoChip(icon: Icons.bolt_rounded, label: _mechanicLabel(exercise.mechanic)),
        ]),
        const SizedBox(height: 18),
        if (exercise.imageUrl.isNotEmpty) ...[
          ClipRRect(borderRadius: BorderRadius.circular(20), child: AspectRatio(aspectRatio: 1.35, child: Image.network(exercise.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppTheme.softIndigo, child: const Icon(Icons.fitness_center_rounded, size: 58, color: AppTheme.primary))))),
          const SizedBox(height: 14),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: () => _addToRoutine(context),
            icon: const Icon(Icons.playlist_add_rounded),
            label: const Text('Añadir a una rutina'),
          ),
        ),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('¿Quieres ver cómo se hace?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text('Abre un tutorial en vídeo para ver la técnica y los puntos clave.'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _tutorial, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Ver tutorial en vídeo')),
          if (exercise.videoUrl != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse(exercise.videoUrl!), mode: LaunchMode.externalApplication), icon: const Icon(Icons.ondemand_video_rounded), label: const Text('Abrir vídeo asociado')),
          ],
        ]))),
        if (exercise.description != null && exercise.description!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Section(title: 'Descripción', value: exercise.description!),
        ],
        const SizedBox(height: 8),
        Text('Músculos', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        _Section(title: 'Principal', value: exercise.primaryMuscles.isEmpty ? 'No indicado' : exercise.primaryMuscles.join(', ')),
        if (exercise.secondaryMuscles.isNotEmpty) _Section(title: 'Secundarios', value: exercise.secondaryMuscles.join(', ')),
        const SizedBox(height: 4),
        Text('Cómo hacerlo', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        if (exercise.instructions.isEmpty)
          Card(color: AppTheme.softIndigo, child: const Padding(padding: EdgeInsets.all(16), child: Text('Todavía no hay instrucciones detalladas. Puedes añadirlas si este es un ejercicio personalizado.')))
        else
          for (var i = 0; i < exercise.instructions.length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: AppTheme.softIndigo, borderRadius: BorderRadius.circular(9)), child: Center(child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 10),
              Expanded(child: Text(exercise.instructions[i], style: theme.textTheme.bodyLarge)),
            ])),
      ]),
    );
  }
}


Future<Exercise?> _showCustomExerciseEditor(BuildContext context, {Exercise? initial}) async {
  final name = TextEditingController(text: initial?.name ?? '');
  final primary = ValueNotifier<String>((initial?.primaryMuscles.isNotEmpty ?? false) ? initial!.primaryMuscles.first : 'Pecho');
  final equipment = ValueNotifier<String>(initial?.equipment ?? 'Peso corporal');
  final description = TextEditingController(text: initial?.description ?? '');
  final instructions = TextEditingController(text: initial?.instructions.join('\n') ?? '');
  final editing = initial != null;

  try {
    return await showDialog<Exercise>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(editing ? 'Editar ejercicio' : 'Crear ejercicio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: !editing,
                decoration: const InputDecoration(
                  labelText: 'Nombre del ejercicio',
                  hintText: 'Ej. Press de pecho unilateral',
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: primary,
                builder: (_, value, __) => DropdownButtonFormField<String>(
                  initialValue: value,
                  decoration: const InputDecoration(labelText: 'Músculo principal'),
                  items: const [
                    'Pecho','Espalda','Hombros','Bíceps','Tríceps','Cuádriceps',
                    'Isquiosurales','Glúteos','Gemelos','Abdominales','Lumbar',
                    'Aductores','Abductores','Antebrazos',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) { if (v != null) primary.value = v; },
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: equipment,
                builder: (_, value, __) => DropdownButtonFormField<String>(
                  initialValue: value,
                  decoration: const InputDecoration(labelText: 'Equipamiento'),
                  items: const [
                    'Peso corporal','Barra','Mancuernas','Polea','Máquina',
                    'Kettlebell','Bandas elásticas','Fitball','Otro',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) { if (v != null) equipment.value = v; },
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción')),
              const SizedBox(height: 10),
              TextField(
                controller: instructions,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Cómo hacerlo',
                  hintText: 'Un paso por línea',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final n = name.text.trim();
              if (n.isEmpty) return;
              Navigator.pop(
                dialogContext,
                Exercise(
                  name: n,
                  force: initial?.force,
                  level: 'personalizado',
                  mechanic: initial?.mechanic,
                  equipment: equipment.value,
                  primaryMuscles: [primary.value],
                  secondaryMuscles: initial?.secondaryMuscles ?? const [],
                  instructions: instructions.text
                      .split('\n')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  category: 'Personalizado',
                  images: initial?.images ?? const [],
                  description: description.text.trim().isEmpty ? null : description.text.trim(),
                  source: 'Ejercicio creado por ti',
                  videoUrl: initial?.videoUrl,
                ),
              );
            },
            child: Text(editing ? 'Guardar cambios' : 'Crear ejercicio'),
          ),
        ],
      ),
    );
  } finally {
    // El diálogo debe terminar de desmontarse antes de liberar los controllers.
    // De lo contrario Flutter puede reconstruir un TextField que aún depende
    // de ellos y lanzar _dependents.isEmpty.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    name.dispose();
    description.dispose();
    instructions.dispose();
    primary.dispose();
    equipment.dispose();
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon; final String label;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF303748))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: AppTheme.primary), const SizedBox(width: 6), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]));
}

class _Section extends StatelessWidget { const _Section({required this.title, required this.value}); final String title; final String value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 4), Text(value)])); }
class _Chip extends StatelessWidget { const _Chip({required this.label}); final String label; @override Widget build(BuildContext context) => Chip(label: Text(label)); }
class _EmptyExerciseState extends StatelessWidget {
  const _EmptyExerciseState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF171A2A), Color(0xFF111D1C)]),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppTheme.primary.withValues(alpha: .25)),
    ),
    child: Column(children: [
      const Icon(Icons.search_off_rounded, size: 42, color: AppTheme.primaryBright),
      const SizedBox(height: 10),
      const Text('No encontramos ese ejercicio', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('Puedes crearlo tú mismo y quedará disponible para tus rutinas.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted, height: 1.35)),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Crear mi ejercicio')),
    ]),
  );
}

class _ErrorCard extends StatelessWidget { const _ErrorCard({required this.message, required this.onRetry}); final String message; final VoidCallback onRetry; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('No se pudo cargar el catálogo.'), const SizedBox(height: 6), Text(message), const SizedBox(height: 10), FilledButton(onPressed: onRetry, child: const Text('Reintentar'))]))); }
