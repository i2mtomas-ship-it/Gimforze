import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import 'workout_model.dart';
import 'workout_page.dart';
import 'routine_editor_page.dart';
import '../progress/calendar_page.dart';
import '../exercises/exercise_page.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis rutinas'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExercisePage())),
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Catálogo de ejercicios',
          ),
        ],
      ),
      body: state.workoutPlans.isEmpty
          ? _EmptyRoutines(onCreate: () => _create(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              children: [
                _SectionHeader(
                  title: 'Plan semanal',
                  action: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrainingCalendarPage())),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Calendario'),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(7, (index) {
                  final day = index + 1;
                  final plans = state.workoutPlans.where((p) => p.dayOfWeek == day).toList();
                  final active = plans.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: active ? () => _open(context, plans.first) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: active ? AppTheme.primary.withOpacity(.11) : const Color(0xFF1A1F2B),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text('$day', style: TextStyle(fontWeight: FontWeight.w900, color: active ? AppTheme.primary : AppTheme.muted)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(_weekdayName(day), style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 2),
                                  Text(active ? plans.map((p) => p.name).join(' · ') : 'Descanso', style: theme.textTheme.bodyMedium),
                                ]),
                              ),
                              Icon(active ? Icons.chevron_right_rounded : Icons.hotel_outlined, color: active ? AppTheme.primary : AppTheme.muted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                _SectionHeader(title: 'Tus rutinas'),
                const SizedBox(height: 8),
                ...state.workoutPlans.map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _edit(context, plan),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(.13), borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.fitness_center_rounded, color: AppTheme.secondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(plan.name, style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text('${_weekdayName(plan.dayOfWeek)} · ${plan.exercises.length} ejercicios', style: theme.textTheme.bodyMedium),
                              ])),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'editar') _edit(context, plan);
                                  if (value == 'entrenar') _start(context, plan);
                                  if (value == 'borrar') await _delete(context, plan);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'editar', child: Text('Editar rutina')),
                                  PopupMenuItem(value: 'entrenar', child: Text('Iniciar entrenamiento')),
                                  PopupMenuItem(value: 'borrar', child: Text('Eliminar rutina')),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Crear rutina'),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final name = TextEditingController();
    final day = ValueNotifier<int>(DateTime.now().weekday);
    final result = await showDialog<WorkoutPlan>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva rutina'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre de la rutina', hintText: 'Ej. Fuerza cuerpo completo')),
          const SizedBox(height: 12),
          ValueListenableBuilder<int>(valueListenable: day, builder: (_, value, __) => DropdownButtonFormField<int>(initialValue: value, decoration: const InputDecoration(labelText: 'Día de la semana'), items: [for (var d = 1; d <= 7; d++) DropdownMenuItem(value: d, child: Text(_weekdayName(d)))], onChanged: (v) { if (v != null) day.value = v; })),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () { final n = name.text.trim(); if (n.isEmpty) return; Navigator.pop(context, WorkoutPlan(id: 'rutina-${DateTime.now().microsecondsSinceEpoch}', name: n, dayOfWeek: day.value)); }, child: const Text('Crear')),
        ],
      ),
    );
    // showDialog termina su Future al hacer Navigator.pop, pero el árbol del
    // diálogo todavía puede estar desmontándose durante ese frame. No debemos
    // disponer los controllers inmediatamente: Flutter puede tener aún un
    // TextField dependiente de ellos.
    // Esperamos a que termine completamente la transición del diálogo antes de
    // liberar sus controllers. El Future de showDialog puede resolverse antes
    // de que Flutter haya terminado de desmontar todos sus dependientes.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    name.dispose();
    day.dispose();
    if (result == null || !context.mounted) return;
    final state = AppStateScope.of(context);
    // Persistimos sin notificar mientras se inicia la transición al editor.
    // La notificación se programa cuando el editor haya terminado de volver.
    await state.saveWorkoutPlan(result, notify: false);
    if (!context.mounted) return;
    await _edit(context, result);
    if (!context.mounted) return;
    AppStateScope.of(context).notifyAfterFrame();
  }

  Future<void> _open(BuildContext context, WorkoutPlan plan) async => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutPage(plan: plan)));
  Future<void> _edit(BuildContext context, WorkoutPlan plan) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoutineEditorPage(plan: plan)));
    if (!context.mounted) return;
    // Al volver del editor, la ruta anterior ya está estable. Programamos
    // la notificación fuera del frame de transición para refrescar el listado
    // inmediatamente sin provocar reconstrucciones durante Navigator.
    AppStateScope.of(context).notifyAfterFrame();
  }
  Future<void> _start(BuildContext context, WorkoutPlan plan) async => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutSessionPage(plan: plan)));
  Future<void> _delete(BuildContext context, WorkoutPlan plan) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Eliminar rutina'), content: Text('¿Quieres eliminar «${plan.name}»?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar'))]));
    if (ok == true && context.mounted) {
      // El diálogo acaba de cerrarse. Esperamos a que Navigator complete el
      // frame antes de notificar el cambio para que la lista se actualice
      // inmediatamente y sin reconstruir widgets durante la transición.
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) return;
      await AppStateScope.of(context).removeWorkoutPlan(plan.id);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)), if (action != null) action!]);
}

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 78, height: 78, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(.10), borderRadius: BorderRadius.circular(26)), child: const Icon(Icons.calendar_month_rounded, size: 38, color: AppTheme.primary)), const SizedBox(height: 18), Text('Todavía no tienes rutinas', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center), const SizedBox(height: 8), const Text('Crea tu primera rutina o deja que Gimforze te ayude a diseñar la semana.', textAlign: TextAlign.center), const SizedBox(height: 20), FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Crear rutina'))])));
}

String _weekdayName(int day) => const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day.clamp(1, 7) - 1];
