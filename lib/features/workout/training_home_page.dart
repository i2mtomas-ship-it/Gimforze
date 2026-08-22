import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import 'workout_page.dart';
import 'workout_model.dart';

class TrainingHomePage extends StatelessWidget {
  const TrainingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final today = DateTime.now().weekday;
    final todayPlans = state.workoutPlans.where((plan) => plan.dayOfWeek == today).toList();
    final upcomingPlans = state.workoutPlans.where((plan) => plan.dayOfWeek != today).take(6).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Entrenar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          Text('Hoy · ${_weekday(today)}', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 14),
          if (todayPlans.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
              child: Column(children: [
                Container(width: 68, height: 68, decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(.12), borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.self_improvement_rounded, size: 34, color: AppTheme.secondary)),
                const SizedBox(height: 14),
                Text('Hoy toca recuperar', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('No tienes una rutina programada. Puedes descansar o preparar tu próxima sesión.', textAlign: TextAlign.center),
              ]),
            ),
          for (final plan in todayPlans) ...[
            _TodayWorkoutCard(plan: plan),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Text('Próximas rutinas', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (upcomingPlans.isEmpty) const Text('No hay más rutinas programadas.'),
          for (final plan in upcomingPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutPage(plan: plan))),
                  child: ListTile(leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(.10), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.calendar_today_rounded, size: 19, color: AppTheme.primary)), title: Text(plan.name), subtitle: Text(_weekday(plan.dayOfWeek)), trailing: const Icon(Icons.chevron_right_rounded)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({required this.plan});
  final WorkoutPlan plan;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(.82)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(.18), blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.fitness_center_rounded, color: Colors.white)), const Spacer(), Text('${plan.exercises.length} ejercicios', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 18),
      Text(plan.name, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.5)),
      const SizedBox(height: 5),
      Text('Tu sesión de hoy está lista', style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutSessionPage(plan: plan))), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Empezar entrenamiento'))),
    ]),
  );
}

String _weekday(int day) => const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day.clamp(1, 7) - 1];
