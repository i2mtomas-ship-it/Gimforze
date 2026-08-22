import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/widgets/section_card.dart';
import '../../core/theme/app_theme.dart';
import '../profile/nutrition_calculator.dart';
import '../workout/workout_model.dart';
import '../workout/workout_page.dart';
import '../progress/achievement_engine.dart';
import '../progress/achievements_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.onOpenProfile, this.onOpenAi, this.onOpenExercises, this.onOpenRoutines, this.onOpenTraining, this.onOpenProgress, this.onOpenNutrition, this.onOpenAchievements});
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenAi;
  final VoidCallback? onOpenExercises;
  final VoidCallback? onOpenRoutines;
  final VoidCallback? onOpenTraining;
  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenNutrition;
  final VoidCallback? onOpenAchievements;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final p = state.profile;
    final n = NutritionCalculator.calculate(p);
    final now = DateTime.now();
    final todayPlans = state.workoutPlans.where((plan) => plan.dayOfWeek == now.weekday).toList();
    final todaySessions = state.sessions.where((s) => _sameDay(s.date, now)).toList();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekSessions = state.sessions
        .where((s) => !s.date.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day)))
        .where((s) => s.date.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day + 7)))
        .toList();
    final weekVolume = weekSessions.fold<double>(0, (sum, session) => sum + session.volumeKg);
    final weekDuration = weekSessions.fold<Duration>(Duration.zero, (sum, session) => sum + session.duration);
    final name = p.isComplete ? '¡A entrenar!' : 'Bienvenido a Gimforze';
    final achievementSummary = AchievementEngine.summarize(state.sessions);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(name),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton.filledTonal(
                tooltip: 'Mi perfil',
                onPressed: onOpenProfile,
                icon: const Icon(Icons.person_outline_rounded),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Center(child: Image.asset('assets/gimforze_logo.png', width: 210, fit: BoxFit.contain))),
              if (!p.isComplete) ...[
                _SetupCard(onOpenProfile: onOpenProfile),
                const SizedBox(height: 14),
                _QuickAccessCard(
                  onOpenExercises: onOpenExercises,
                  onOpenRoutines: onOpenRoutines,
                  onOpenTraining: onOpenTraining,
                  onOpenProgress: onOpenProgress,
                  onOpenNutrition: onOpenNutrition,
                  onOpenAi: onOpenAi,
                ),
              ],
              if (p.isComplete) ...[
                _HeroTodayCard(plans: todayPlans, sessions: todaySessions),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Tu semana',
                  accent: Theme.of(context).colorScheme.secondary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Metric(value: '${weekSessions.length}', label: 'sesiones', icon: Icons.fitness_center),
                      _Metric(value: _formatVolume(weekVolume), label: 'volumen', icon: Icons.bolt),
                      _Metric(value: _formatDuration(weekDuration), label: 'tiempo', icon: Icons.timer_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Objetivo nutricional',
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    runSpacing: 16,
                    spacing: 16,
                    children: [
                      _Metric(value: '${n.calories.round()}', label: 'kcal', icon: Icons.local_fire_department_outlined),
                      _Metric(value: '${n.protein.round()} g', label: 'proteína', icon: Icons.egg_alt_outlined),
                      _Metric(value: '${n.carbs.round()} g', label: 'carbohidratos', icon: Icons.grain),
                      _Metric(value: '${n.fat.round()} g', label: 'grasas', icon: Icons.water_drop_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _CompleteQuickAccess(
                  onOpenExercises: onOpenExercises,
                  onOpenRoutines: onOpenRoutines,
                  onOpenTraining: onOpenTraining,
                  onOpenProgress: onOpenProgress,
                  onOpenNutrition: onOpenNutrition,
                  onOpenProfile: onOpenProfile,
                ),
                const SizedBox(height: 14),
                _AchievementHomeCard(summary: achievementSummary, onOpen: onOpenAchievements),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Gimforze Coach',
                  accent: AppTheme.primary,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gimforze analiza tus objetivos, entrenamientos y progresión para ayudarte a mejorar.', style: TextStyle(height: 1.35)),
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: onOpenAi,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Hablar con Gimforze'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _AchievementHomeCard extends StatelessWidget {
  const _AchievementHomeCard({required this.summary, this.onOpen});
  final AchievementSummary summary;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) {
    final unlocked = summary.unlocked.length;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppTheme.primary.withOpacity(.25))),
        child: Row(children: [
          Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(.13), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.emoji_events_rounded, color: AppTheme.primary, size: 27)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nivel ${summary.level} · ${summary.xp} XP', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('$unlocked logros desbloqueados · sigue superándote', style: Theme.of(context).textTheme.bodySmall),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
        ]),
      ),
    );
  }
}

class _HeroTodayCard extends StatelessWidget {
  const _HeroTodayCard({required this.plans, required this.sessions});
  final List<WorkoutPlan> plans;
  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (plans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(.08),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          CircleAvatar(backgroundColor: scheme.primary.withOpacity(.14), foregroundColor: scheme.primary, child: const Icon(Icons.self_improvement)),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hoy toca recuperar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 3),
            Text('No tienes ninguna rutina programada. Descansa y vuelve con energía.', style: TextStyle(height: 1.3)),
          ])),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, Color.alphaBlend(const Color(0xFF7C83F5), scheme.primary)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: scheme.primary.withOpacity(.20), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ENTRENAMIENTO DE HOY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        for (final plan in plans) ...[
          Text(plan.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.4)),
          const SizedBox(height: 4),
          Text('${plan.exercises.length} ejercicios  ·  ${sessions.isNotEmpty ? 'Completado hoy' : 'Listo para empezar'}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: scheme.primary),
            onPressed: plan.exercises.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutPage(plan: plan))),
            child: Text(sessions.isNotEmpty ? 'Repetir entrenamiento' : 'Empezar entrenamiento'),
          )),
          if (plan != plans.last) const SizedBox(height: 12),
        ],
      ]),
    );
  }
}


class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({this.onOpenExercises, this.onOpenRoutines, this.onOpenTraining, this.onOpenProgress, this.onOpenNutrition, this.onOpenAi});
  final VoidCallback? onOpenExercises;
  final VoidCallback? onOpenRoutines;
  final VoidCallback? onOpenTraining;
  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenNutrition;
  final VoidCallback? onOpenAi;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Explora Gimforze', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.25,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _QuickAction(icon: Icons.fitness_center_rounded, label: 'Ejercicios', color: AppTheme.primary, onTap: onOpenExercises),
          _QuickAction(icon: Icons.calendar_month_rounded, label: 'Rutinas', color: AppTheme.secondary, onTap: onOpenRoutines),
          _QuickAction(icon: Icons.play_arrow_rounded, label: 'Entrenar', color: AppTheme.highlight, onTap: onOpenTraining),
          _QuickAction(icon: Icons.show_chart_rounded, label: 'Progreso', color: AppTheme.primaryBright, onTap: onOpenProgress),
          _QuickAction(icon: Icons.restaurant_menu_rounded, label: 'Nutrición', color: AppTheme.secondary, onTap: onOpenNutrition),
        ],
      ),
      const SizedBox(height: 10),
      Card(
        color: AppTheme.softIndigo,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onOpenAi,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBright),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gimforze Coach', style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 3),
                Text('Completa tu perfil para recibir recomendaciones personalizadas.', style: TextStyle(fontSize: 13)),
              ])),
              Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _CompleteQuickAccess extends StatelessWidget {
  const _CompleteQuickAccess({this.onOpenExercises, this.onOpenRoutines, this.onOpenTraining, this.onOpenProgress, this.onOpenNutrition, this.onOpenProfile});
  final VoidCallback? onOpenExercises;
  final VoidCallback? onOpenRoutines;
  final VoidCallback? onOpenTraining;
  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenNutrition;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Accesos rápidos', style: Theme.of(context).textTheme.titleLarge)),
        Text('Todo a mano', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted)),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 92,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _DashboardShortcut(icon: Icons.fitness_center_rounded, label: 'Ejercicios', color: AppTheme.primary, onTap: onOpenExercises),
            _DashboardShortcut(icon: Icons.calendar_month_rounded, label: 'Rutinas', color: AppTheme.secondary, onTap: onOpenRoutines),
            _DashboardShortcut(icon: Icons.play_arrow_rounded, label: 'Entrenar', color: AppTheme.highlight, onTap: onOpenTraining),
            _DashboardShortcut(icon: Icons.show_chart_rounded, label: 'Progreso', color: AppTheme.primaryBright, onTap: onOpenProgress),
            _DashboardShortcut(icon: Icons.restaurant_menu_rounded, label: 'Nutrición', color: AppTheme.secondary, onTap: onOpenNutrition),
            _DashboardShortcut(icon: Icons.person_rounded, label: 'Perfil', color: AppTheme.primaryBright, onTap: onOpenProfile),
          ],
        ),
      ),
    ]);
  }
}

class _DashboardShortcut extends StatelessWidget {
  const _DashboardShortcut({required this.icon, required this.label, required this.color, this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: SizedBox(
      width: 112,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 19)),
              const Spacer(),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ]),
          ),
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted, size: 19),
        ]),
      ),
    ),
  );
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({this.onOpenProfile});
  final VoidCallback? onOpenProfile;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withOpacity(.10), Theme.of(context).colorScheme.secondary.withOpacity(.08)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tu plan empieza aquí', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Completa tu perfil para que Gimforze adapte tus entrenamientos y objetivos a ti.', style: TextStyle(height: 1.35)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onOpenProfile, icon: const Icon(Icons.person_outline), label: const Text('Crear mi perfil')),
        ]),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 5),
    Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
    const SizedBox(height: 2),
    Text(label, style: Theme.of(context).textTheme.bodySmall),
  ]);
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
String _formatVolume(double value) => value >= 1000 ? '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)} t' : '${value.toStringAsFixed(0)} kg';
String _formatDuration(Duration duration) => duration.inHours > 0 ? '${duration.inHours} h ${duration.inMinutes.remainder(60)} min' : '${duration.inMinutes} min';
