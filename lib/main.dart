import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/app_state.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/workout/routines_page.dart';
import 'features/exercises/exercise_page.dart';
import 'features/workout/training_home_page.dart';
import 'features/progress/progress_page.dart';
import 'features/ai/ai_coach_page.dart';
import 'features/profile/profile_page.dart';
import 'features/nutrition/nutrition_page.dart';
import 'features/progress/achievements_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  final state = await AppState.create();
  runApp(GimforzeApp(state: state));
}

class GimforzeApp extends StatelessWidget {
  const GimforzeApp({super.key, required this.state});
  final AppState state;
  @override Widget build(BuildContext context) => AppStateScope(state: state, child: MaterialApp(title: 'Gimforze', debugShowCheckedModeBanner: false, theme: AppTheme.dark, home: const AppShell()));
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int index = 0;
  @override Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onOpenProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
        onOpenAi: () => setState(() => index = 5),
        onOpenExercises: () => setState(() => index = 1),
        onOpenRoutines: () => setState(() => index = 2),
        onOpenTraining: () => setState(() => index = 3),
        onOpenProgress: () => setState(() => index = 4),
        onOpenNutrition: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NutritionPage())),
        onOpenAchievements: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AchievementsPage())),
      ),
      const ExercisePage(),
      const RoutinesPage(),
      const TrainingHomePage(),
      const ProgressPage(),
      const AiCoachPage(),
    ];
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: _EvolvBottomNav(
        selectedIndex: index,
        onSelected: (value) => setState(() => index = value),
      ),
    );
  }
}

class _EvolvBottomNav extends StatelessWidget {
  const _EvolvBottomNav({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Inicio'),
    (Icons.fitness_center_rounded, Icons.fitness_center_outlined, 'Ejercicios'),
    (Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Rutinas'),
    (Icons.play_circle_fill_rounded, Icons.play_circle_outline_rounded, 'Entrenar'),
    (Icons.show_chart_rounded, Icons.show_chart_outlined, 'Progreso'),
    (Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Gimforze'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(5, 6, 5, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF10131D),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xFF292E3C)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 22, offset: Offset(0, 8))],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final selected = selectedIndex == i;
          final isCenter = i == 3;
          return Expanded(
            flex: isCenter ? 12 : 10,
            child: Semantics(
              button: true,
              selected: selected,
              label: item.$3,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelected(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: isCenter ? 46 : 33,
                        height: isCenter ? 46 : 31,
                        decoration: BoxDecoration(
                          shape: isCenter ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: isCenter ? null : BorderRadius.circular(14),
                          gradient: selected && isCenter
                              ? const LinearGradient(colors: [AppTheme.primaryBright, AppTheme.primary])
                              : null,
                          color: selected && !isCenter ? (i == 5 ? AppTheme.secondary.withValues(alpha: .18) : AppTheme.primary.withValues(alpha: .18)) : Colors.transparent,
                          boxShadow: selected && isCenter
                              ? const [BoxShadow(color: Color(0x559B5CFF), blurRadius: 16, offset: Offset(0, 5))]
                              : null,
                        ),
                        child: Icon(
                          selected ? item.$1 : item.$2,
                          size: isCenter ? 22 : 18,
                          color: selected && isCenter
                              ? Colors.white
                              : selected
                                  ? (i == 5 ? AppTheme.secondary : AppTheme.primaryBright)
                                  : AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        style: TextStyle(
                          color: selected ? AppTheme.text : AppTheme.muted,
                          fontSize: 8.5,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
