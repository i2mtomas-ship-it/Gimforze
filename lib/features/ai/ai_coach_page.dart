import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../workout/workout_model.dart';
import 'ai_analysis.dart';
import 'ai_decision_engine.dart';
import 'ai_planner_engine.dart';
import '../exercises/exercise_model.dart';
import '../exercises/exercise_page.dart';
import '../exercises/exercise_repository.dart';
import 'exercise_replacement_engine.dart';
import 'ai_plan_comparison.dart';
import 'ai_weekly_analysis.dart';
import 'ai_chat_engine.dart';

class AiCoachPage extends StatefulWidget {
  const AiCoachPage({super.key});
  @override State<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends State<AiCoachPage> {
  int days = 4;
  int minutes = 60;
  String goal = 'Ganar fuerza';
  String level = 'Intermedio';
  bool generated = false;
  AiAnalysis? analysis;
  List<_SuggestedDay> suggestion = const [];
  AiPlanProposal? planProposal;
  AiPlanComparison? planComparison;
  final Set<int> _selectedChanges = <int>{};
  final ExerciseRepository _exerciseRepository = ExerciseRepository();
  bool _loadingAlternatives = false;
  String? _selectedExercise;
  List<ExerciseReplacement> _alternatives = const [];
  AiWeeklyPlan? smartPlan;
  bool _loadingSmartPlan = false;
  AiWeeklyAnalysis? weeklyAnalysis;
  final TextEditingController _chatController = TextEditingController();
  String? _chatAnswer;

  void analyzeWeek() {
    final state = AppStateScope.of(context);
    setState(() => weeklyAnalysis = AiWeeklyAnalyzer.analyze(state.workoutPlans, state.sessions));
  }

  void askGimforze() {
    final state = AppStateScope.of(context);
    setState(() => _chatAnswer = AiChatEngine.answer(_chatController.text, AiChatContext(plans: state.workoutPlans, sessions: state.sessions, targets: state.exerciseTargets)));
  }

  Future<void> generateSmartPlan() async {
    final state = AppStateScope.of(context);
    setState(() => _loadingSmartPlan = true);
    try {
      final online = await _exerciseRepository.fetchCatalog();
      final custom = state.customExercises;
      final catalog = <String, Exercise>{for (final e in [...online, ...custom]) e.name.toLowerCase(): e}.values.toList();
      final result = AiPlannerEngine.build(
        profile: state.profile,
        days: days,
        minutes: minutes,
        goal: goal,
        catalog: catalog,
        sessions: state.sessions,
      );
      if (!mounted) return;
      setState(() { smartPlan = result; _loadingSmartPlan = false; });
    } catch (_) {
      if (!mounted) return;
      final result = AiPlannerEngine.build(
        profile: state.profile, days: days, minutes: minutes, goal: goal, catalog: const [], sessions: state.sessions,
      );
      setState(() { smartPlan = result; _loadingSmartPlan = false; });
    }
  }

  Future<void> applySmartPlan() async {
    final result = smartPlan;
    if (result == null || result.plans.isEmpty) return;
    final state = AppStateScope.of(context);
    final schedule = AiPlannerEngine.scheduleForDays(result.plans.length);
    final plans = [
      for (var i = 0; i < result.plans.length; i++)
        result.plans[i].copyWith(dayOfWeek: schedule[i]),
    ];
    await state.saveWorkoutPlans([...state.workoutPlans, ...plans], activeId: plans.first.id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan inteligente creado. Puedes revisarlo y modificarlo antes de entrenar.')));
  }

  void generate() {
    final names = switch (days) {
      2 => const ['Cuerpo completo A', 'Cuerpo completo B'],
      3 => const ['Tren superior', 'Piernas', 'Cuerpo completo'],
      4 => const ['Pecho y tríceps', 'Espalda y bíceps', 'Piernas', 'Hombros y brazos'],
      _ => const ['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos'],
    };
    setState(() {
      suggestion = [for (var i = 0; i < days; i++) _SuggestedDay(day: i + 1, name: names[i])];
      generated = true;
    });
  }

  Future<void> apply() async {
    final state = AppStateScope.of(context);
    final base = DateTime.now().weekday;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final plans = [
      for (var i = 0; i < suggestion.length; i++)
        WorkoutPlan(
          id: 'ia-$stamp-$i',
          name: suggestion[i].name,
          dayOfWeek: ((base - 1 + i) % 7) + 1,
          exercises: _exerciseTemplate(suggestion[i].name),
        ),
    ];
    await state.saveWorkoutPlans([...state.workoutPlans, ...plans], activeId: plans.first.id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rutinas creadas por Gimforze. Puedes editarlas antes de entrenar.')));
  }

  void analyse() {
    final state = AppStateScope.of(context);
    setState(() => analysis = AiCoachEngine.analyse(state.sessions));
  }

  void optimizeCurrentRoutine() {
    final state = AppStateScope.of(context);
    final plan = state.activeWorkoutPlan;
    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero crea o selecciona una rutina.')));
      return;
    }
    final proposal = AiDecisionEngine.propose(plan, state.sessions);
    final comparison = AiPlanComparison.fromPlans(plan, proposal.plan);
    setState(() {
      planProposal = proposal;
      planComparison = comparison;
      _selectedChanges..clear()..addAll(comparison.changes.map((change) => change.index));
    });
  }

  Future<void> findExerciseAlternatives() async {
    final state = AppStateScope.of(context);
    final plan = state.activeWorkoutPlan;
    if (plan == null || plan.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero crea una rutina con ejercicios.')));
      return;
    }
    final targetName = _selectedExercise ?? plan.exercises.first.exerciseName;
    final target = plan.exercises.firstWhere((e) => e.exerciseName == targetName, orElse: () => plan.exercises.first);
    setState(() { _loadingAlternatives = true; });
    try {
      final online = await _exerciseRepository.fetchCatalog();
      final catalog = <String, Exercise>{for (final e in [...online, ...state.customExercises]) e.name.toLowerCase(): e}.values.toList();
      final alternatives = ExerciseReplacementEngine.findAlternatives(target: target, catalog: catalog, excludedNames: plan.exercises.map((e) => e.exerciseName).toList());
      if (!mounted) return;
      setState(() { _alternatives = alternatives; _loadingAlternatives = false; });
    } catch (_) {
      if (mounted) setState(() { _alternatives = const []; _loadingAlternatives = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo consultar el catálogo de ejercicios.')));
    }
  }

  Future<void> applyReplacement(ExerciseReplacement replacement) async {
    final state = AppStateScope.of(context);
    final plan = state.activeWorkoutPlan;
    if (plan == null) return;
    final index = plan.exercises.indexWhere((e) => e.exerciseName == replacement.original);
    if (index < 0) return;
    final old = plan.exercises[index];
    final updated = [...plan.exercises];
    updated[index] = WorkoutExercise(exerciseName: replacement.replacement.name, sets: old.sets, reps: old.reps, rir: old.rir, restSeconds: old.restSeconds, notes: old.notes);
    await state.saveWorkoutPlan(plan.copyWith(exercises: updated));
    if (mounted) setState(() { _alternatives = const []; _selectedExercise = null; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${replacement.original} sustituido por ${replacement.replacement.name}.')));
  }

  Future<void> applyOptimization() async {
    final comparison = planComparison;
    if (comparison == null) return;
    final state = AppStateScope.of(context);
    final updated = [...comparison.before.exercises];
    for (final change in comparison.changes) {
      if (_selectedChanges.contains(change.index)) updated[change.index] = change.after;
    }
    if (_selectedChanges.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos un cambio para aplicar.')));
      return;
    }
    await state.saveWorkoutPlan(comparison.before.copyWith(exercises: updated));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_selectedChanges.length} cambio${_selectedChanges.length == 1 ? '' : 's'} aplicado${_selectedChanges.length == 1 ? '' : 's'}.')));
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gimforze'), actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Icon(Icons.auto_awesome, color: AppTheme.primary))]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      _AiHero(),
      const SizedBox(height: 12),
      Text('Crear una rutina con Gimforze', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(initialValue: goal, decoration: const InputDecoration(labelText: 'Objetivo'), items: const [DropdownMenuItem(value: 'Ganar fuerza', child: Text('Ganar fuerza')), DropdownMenuItem(value: 'Ganar músculo', child: Text('Ganar músculo')), DropdownMenuItem(value: 'Perder grasa', child: Text('Perder grasa')), DropdownMenuItem(value: 'Mejorar condición física', child: Text('Mejorar condición física'))], onChanged: (v) => setState(() => goal = v ?? goal)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(initialValue: level, decoration: const InputDecoration(labelText: 'Nivel'), items: const [DropdownMenuItem(value: 'Principiante', child: Text('Principiante')), DropdownMenuItem(value: 'Intermedio', child: Text('Intermedio')), DropdownMenuItem(value: 'Avanzado', child: Text('Avanzado'))], onChanged: (v) => setState(() => level = v ?? level)),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(initialValue: days, decoration: const InputDecoration(labelText: 'Días por semana'), items: [for (var d = 2; d <= 5; d++) DropdownMenuItem(value: d, child: Text('$d días'))], onChanged: (v) => setState(() => days = v ?? days)),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(initialValue: minutes, decoration: const InputDecoration(labelText: 'Duración máxima por sesión'), items: const [DropdownMenuItem(value: 45, child: Text('45 minutos')), DropdownMenuItem(value: 60, child: Text('60 minutos')), DropdownMenuItem(value: 75, child: Text('75 minutos')), DropdownMenuItem(value: 90, child: Text('90 minutos'))], onChanged: (v) => setState(() => minutes = v ?? minutes)),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: generate, icon: const Icon(Icons.auto_awesome), label: const Text('Generar propuesta')),
      if (generated) ...[
        const SizedBox(height: 20),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Propuesta de Gimforze', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6), Text('$goal · $level · $days días · hasta $minutes min'),
          const Divider(height: 24),
          for (final s in suggestion) ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text('${s.day}')), title: Text(s.name), subtitle: Text('${_weekdayName(s.day)} · ${_exerciseTemplate(s.name).length} ejercicios')),
        ]))),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: apply, icon: const Icon(Icons.check), label: const Text('Crear estas rutinas')),
      ],
      const SizedBox(height: 24),
      FilledButton.tonalIcon(onPressed: analyse, icon: const Icon(Icons.insights), label: const Text('Analizar mi progreso')),
      if (analysis != null) ...[
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(analysis!.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(analysis!.summary),
          if (analysis!.metrics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final item in analysis!.metrics.entries) Chip(label: Text('${item.key}: ${item.value}'))]),
          ],
          const SizedBox(height: 12),
          const Text('Recomendaciones', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final action in analysis!.actions) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• '), Expanded(child: Text(action))])),
        ]))),
      ],
      const SizedBox(height: 24),
      Text('Plan inteligente de Gimforze', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Gimforze combina tu objetivo, disponibilidad, nivel, equipamiento, catálogo e historial reciente para construir una semana de entrenamiento. La propuesta se revisa antes de guardarla.'),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _loadingSmartPlan ? null : generateSmartPlan,
        icon: _loadingSmartPlan ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
        label: const Text('Generar plan inteligente'),
      ),
      if (smartPlan != null) ...[
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Propuesta semanal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(smartPlan!.reason),
          const SizedBox(height: 12),
          for (final plan in smartPlan!.plans) ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('${plan.dayOfWeek}')),
            title: Text(plan.name),
            subtitle: Text(plan.exercises.map((e) => '${e.exerciseName} · ${e.sets}×${e.reps} · RIR ${e.rir}').join('\n')),
            isThreeLine: true,
          ),
          if (smartPlan!.warnings.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Avisos', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final warning in smartPlan!.warnings) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $warning')),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: applySmartPlan, icon: const Icon(Icons.check), label: const Text('Crear este plan')),
        ]))),
      ],
      const SizedBox(height: 12),
      Builder(builder: (context) {
        final state = AppStateScope.of(context);
        final sessions = state.sessions;
        final recent = sessions.take(7).toList();
        final volume = recent.fold<double>(0, (sum, item) => sum + item.volumeKg);
        final last = sessions.isEmpty ? null : sessions.first;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF282E3D))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.softMint, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.insights_rounded, color: AppTheme.secondary)),
              const SizedBox(width: 11),
              const Expanded(child: Text('Tu estado actual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
              Text('${recent.length} sesiones', style: Theme.of(context).textTheme.bodySmall),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _AiMiniMetric(value: volume >= 1000 ? '${(volume / 1000).toStringAsFixed(1)} t' : '${volume.round()} kg', label: 'volumen reciente')),
              Expanded(child: _AiMiniMetric(value: last == null ? '—' : '${last.totalSets}', label: 'última sesión: series')),
              Expanded(child: _AiMiniMetric(value: last == null ? '—' : '${last.duration.inMinutes} min', label: 'duración')),
            ]),
          ]),
        );
      }),
      const SizedBox(height: 12),
      const Text('Gimforze utiliza tus datos registrados para analizar, comparar y proponer. No inventa cargas ni resultados y no cambia una rutina sin tu confirmación.'),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ActionChip(avatar: const Icon(Icons.today_rounded, size: 17), label: const Text('¿Qué tengo hoy?'), onPressed: () { _chatController.text = '¿Qué tengo hoy?'; askGimforze(); }),
        ActionChip(avatar: const Icon(Icons.show_chart_rounded, size: 17), label: const Text('¿Cómo progreso?'), onPressed: () { _chatController.text = '¿Cómo progreso?'; askGimforze(); }),
        ActionChip(avatar: const Icon(Icons.bolt_rounded, size: 17), label: const Text('¿Cómo va mi volumen?'), onPressed: () { _chatController.text = '¿Cómo va mi volumen?'; askGimforze(); }),
      ]),
      if (_chatAnswer != null) ...[
        const SizedBox(height: 12),
        Card(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBright),
              const SizedBox(width: 10),
              Expanded(child: Text(_chatAnswer!, style: const TextStyle(height: 1.4))),
            ]),
          ),
        ),
      ],
      const SizedBox(height: 14),
      const SizedBox(height: 24),
      Text('Optimizar mi rutina actual', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Gimforze analiza el historial real y propone cambios conservadores cuando encuentra señales claras. No modifica la rutina automáticamente.'),
      const SizedBox(height: 12),
      FilledButton.tonalIcon(onPressed: optimizeCurrentRoutine, icon: const Icon(Icons.auto_fix_high), label: const Text('Analizar y proponer ajustes')),
      if (planProposal != null) ...[
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Propuesta para tu rutina', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final recommendation in planProposal!.recommendations) ...[
            Text(recommendation.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(recommendation.reason),
            const SizedBox(height: 4),
            Text('Confianza: ${recommendation.confidence}'),
            const SizedBox(height: 6),
            for (final change in recommendation.changes) Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• '), Expanded(child: Text(change))])),
            const Divider(height: 20),
          ],
          if (planComparison != null) ...[
            Text('Comparación antes de aplicar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Trabajo estimado: ${planComparison!.beforeWork} → ${planComparison!.afterWork} series-repeticiones'),
            const SizedBox(height: 8),
            if (planComparison!.changes.isEmpty)
              const Text('No hay cambios concretos que aplicar.')
            else
              for (final change in planComparison!.changes)
                CheckboxListTile(
                  value: _selectedChanges.contains(change.index),
                  onChanged: (selected) => setState(() { if (selected == true) { _selectedChanges.add(change.index); } else { _selectedChanges.remove(change.index); } }),
                  contentPadding: EdgeInsets.zero,
                  title: Text(change.before.exerciseName),
                  subtitle: Text('${change.before.sets}×${change.before.reps} · RIR ${change.before.rir}  →  ${change.after.sets}×${change.after.reps} · RIR ${change.after.rir}'),
                  secondary: Icon(change.after.sets * change.after.reps < change.before.sets * change.before.reps ? Icons.trending_down : Icons.trending_up),
                ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: planComparison?.changes.isEmpty == true ? null : applyOptimization, icon: const Icon(Icons.check), label: const Text('Aplicar cambios seleccionados')),
          const SizedBox(height: 4),
          const Text('Gimforze no modifica una rutina sin que tú confirmes los cambios.', style: TextStyle(fontSize: 12)),
        ]))),
      ],
      const SizedBox(height: 24),
      Text('Sustituir un ejercicio', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Gimforze busca alternativas del catálogo compatibles con el ejercicio seleccionado. Puedes revisar la ficha antes de sustituirlo.'),
      const SizedBox(height: 12),
      Builder(builder: (context) {
        final plan = AppStateScope.of(context).activeWorkoutPlan;
        final exercises = plan?.exercises ?? const <WorkoutExercise>[];
        if (exercises.isEmpty) return const Text('Tu rutina activa no tiene ejercicios todavía.');
        return Column(children: [
          DropdownButtonFormField<String>(initialValue: _selectedExercise ?? exercises.first.exerciseName, decoration: const InputDecoration(labelText: 'Ejercicio a sustituir'), items: exercises.map((e) => DropdownMenuItem(value: e.exerciseName, child: Text(e.exerciseName))).toList(), onChanged: (v) => setState(() => _selectedExercise = v)),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(onPressed: _loadingAlternatives ? null : findExerciseAlternatives, icon: _loadingAlternatives ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.swap_horiz), label: const Text('Buscar alternativas')),
          if (_alternatives.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final alternative in _alternatives) Card(child: ListTile(
              title: Text(alternative.replacement.name),
              subtitle: Text('${alternative.replacement.primaryMuscles.join(', ')} · ${alternative.replacement.equipment ?? 'Sin equipamiento'}\n${alternative.reason}'),
              isThreeLine: true,
              trailing: FilledButton(onPressed: () => applyReplacement(alternative), child: const Text('Usar')),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailPage(exercise: alternative.replacement))),
            )),
          ],
        ]);
      }),
      const SizedBox(height: 24),
      const SizedBox(height: 24),
      Text('Análisis semanal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Revisa la distribución de la semana antes de aplicar una propuesta.'),
      const SizedBox(height: 12),
      FilledButton.tonalIcon(onPressed: analyzeWeek, icon: const Icon(Icons.calendar_view_week), label: const Text('Analizar mi semana')),
      if (weeklyAnalysis != null) ...[
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${weeklyAnalysis!.totalSessions} días · ${weeklyAnalysis!.totalSets} series · ${weeklyAnalysis!.estimatedMinutes} min estimados', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (weeklyAnalysis!.muscleSets.isNotEmpty) ...[
            const Text('Series planificadas por grupo muscular', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final item in weeklyAnalysis!.muscleSets.entries) Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Expanded(child: Text(item.key)), Text('${item.value} series')]))
          ],
          if (weeklyAnalysis!.recoveryWarnings.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Recuperación', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final warning in weeklyAnalysis!.recoveryWarnings) Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $warning')),
          ],
          const Divider(height: 24),
          const Text('Recomendaciones', style: TextStyle(fontWeight: FontWeight.w700)),
          for (final item in weeklyAnalysis!.recommendations) Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $item')),
        ]))),
      ],
      const SizedBox(height: 24),
      Text('Habla con Gimforze', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Consulta tus datos de entrenamiento. Esta versión utiliza únicamente la información local registrada.'),
      const SizedBox(height: 12),
      TextField(controller: _chatController, textInputAction: TextInputAction.send, onSubmitted: (_) => askGimforze(), decoration: const InputDecoration(labelText: 'Pregunta a Gimforze', hintText: 'Ej.: ¿cómo va mi volumen?')),
      const SizedBox(height: 8),
      FilledButton.tonalIcon(onPressed: askGimforze, icon: const Icon(Icons.send), label: const Text('Consultar')),
      const SizedBox(height: 24),
      const SizedBox(height: 24),
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('La conexión con un modelo de IA externo se añadirá después. Esta capa local permite probar primero el flujo y utilizar datos reales del historial.'))),
    ]),
  );
}

class _AiHero extends StatelessWidget {
  const _AiHero();
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF777BF4)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(27), boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(.16), blurRadius: 22, offset: const Offset(0, 9))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: const Text('INTELIGENTE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .8)))]),
      const SizedBox(height: 17),
      const Text('Tu entrenador inteligente', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.5)),
      const SizedBox(height: 5),
      const Text('Analiza tu historial y convierte tus datos en decisiones para el siguiente entrenamiento.', style: TextStyle(color: Colors.white70, height: 1.35)),
    ]),
  );
}

class _AiMiniMetric extends StatelessWidget {
  const _AiMiniMetric({required this.value, required this.label});
  final String value, label;
  @override Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)]);
}

class _SuggestedDay { const _SuggestedDay({required this.day, required this.name}); final int day; final String name; }

List<WorkoutExercise> _exerciseTemplate(String name) {
  final n = name.toLowerCase();
  if (n.contains('pierna')) return const [WorkoutExercise(exerciseName: 'Sentadilla con barra', sets: 4, reps: 6, rir: 2), WorkoutExercise(exerciseName: 'Peso muerto rumano', sets: 3, reps: 8, rir: 2), WorkoutExercise(exerciseName: 'Prensa de piernas', sets: 3, reps: 10, rir: 2)];
  if (n.contains('espalda')) return const [WorkoutExercise(exerciseName: 'Remo con barra', sets: 4, reps: 8, rir: 2), WorkoutExercise(exerciseName: 'Jalón al pecho', sets: 3, reps: 10, rir: 2), WorkoutExercise(exerciseName: 'Curl de bíceps con mancuernas', sets: 3, reps: 10, rir: 2)];
  if (n.contains('pecho')) return const [WorkoutExercise(exerciseName: 'Press de banca con barra', sets: 4, reps: 6, rir: 2), WorkoutExercise(exerciseName: 'Press inclinado con mancuernas', sets: 3, reps: 8, rir: 2), WorkoutExercise(exerciseName: 'Extensión de tríceps', sets: 3, reps: 10, rir: 2)];
  if (n.contains('hombros') || n.contains('brazos')) return const [WorkoutExercise(exerciseName: 'Press militar', sets: 4, reps: 8, rir: 2), WorkoutExercise(exerciseName: 'Elevaciones laterales', sets: 3, reps: 12, rir: 2), WorkoutExercise(exerciseName: 'Curl de bíceps', sets: 3, reps: 10, rir: 2), WorkoutExercise(exerciseName: 'Extensión de tríceps', sets: 3, reps: 10, rir: 2)];
  return const [WorkoutExercise(exerciseName: 'Sentadilla con barra', sets: 3, reps: 8, rir: 2), WorkoutExercise(exerciseName: 'Press de banca con barra', sets: 3, reps: 8, rir: 2), WorkoutExercise(exerciseName: 'Remo con barra', sets: 3, reps: 8, rir: 2)];
}

String _weekdayName(int day) => const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day.clamp(1, 7) - 1];
