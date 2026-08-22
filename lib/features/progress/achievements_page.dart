import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import 'achievement_engine.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final summary = AchievementEngine.summarize(AppStateScope.of(context).sessions);
    final unlocked = summary.unlocked.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 110), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF6C4DFF)]), borderRadius: BorderRadius.circular(26)),
          child: Row(children: [
            Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(19)), child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tu progreso', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              Text('Nivel ${summary.level}', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
              Text('${summary.xp} XP · $unlocked/${summary.achievements.length} logros', style: const TextStyle(color: Colors.white70)),
            ])),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [Expanded(child: Text('Medallas', style: Theme.of(context).textTheme.titleLarge)), Text('$unlocked desbloqueadas', style: Theme.of(context).textTheme.bodySmall)]),
        const SizedBox(height: 10),
        for (final achievement in summary.achievements) Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
              Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: achievement.unlocked ? AppTheme.primary.withOpacity(.16) : const Color(0xFF1A1E29), borderRadius: BorderRadius.circular(17)), child: Text(achievement.unlocked ? achievement.icon : '🔒', style: const TextStyle(fontSize: 25))),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(achievement.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(achievement.description, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: achievement.progress, minHeight: 6)),
                const SizedBox(height: 4),
                Text('${achievement.current} / ${achievement.threshold}', style: Theme.of(context).textTheme.bodySmall),
              ])),
            ])),
          ),
        ),
      ]),
    );
  }
}
