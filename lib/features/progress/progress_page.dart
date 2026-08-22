import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_card.dart';
import '../workout/workout_model.dart';
import 'progress_entry.dart';
import 'exercise_progress_page.dart';
import 'target_progress_page.dart';
import 'progress_metrics.dart';
import 'muscle_volume.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});
  @override State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final weight = TextEditingController();
  final waist = TextEditingController();
  int _periodDays = 30;

  @override
  void dispose() { weight.dispose(); waist.dispose(); super.dispose(); }

  Future<void> add() async {
    final w = double.tryParse(weight.text.replaceAll(',', '.'));
    final c = double.tryParse(waist.text.replaceAll(',', '.'));
    if (w == null || c == null || w <= 0 || c <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Introduce un peso y una cintura válidos.')));
      return;
    }
    await AppStateScope.of(context).addProgress(ProgressEntry(date: DateTime.now(), weightKg: w, waistCm: c));
    weight.clear(); waist.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro guardado.')));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: _periodDays - 1));
    final periodSessions = state.sessions.where((s) => !s.date.isBefore(start)).toList();
    final currentStart = DateTime(now.year, now.month);
    final nextStart = DateTime(now.year, now.month + 1);
    final previousStart = DateTime(now.year, now.month - 1);
    final currentMonth = metricsFor(state.sessions, currentStart, nextStart);
    final previousMonth = metricsFor(state.sessions, previousStart, currentStart);
    final volume = periodSessions.fold<double>(0, (v, s) => v + s.volumeKg);
    final totalSeconds = periodSessions.fold<int>(0, (v, s) => v + s.duration.inSeconds);

    return CustomScrollView(slivers: [
      SliverAppBar.large(title: const Text('Progreso'), backgroundColor: Theme.of(context).scaffoldBackgroundColor),
      SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), sliver: SliverList(delegate: SliverChildListDelegate([
        _ProgressHero(sessions: periodSessions, volume: volume),
        const SizedBox(height: 12),
        _PeriodSelector(value: _periodDays, onChanged: (value) => setState(() => _periodDays = value)),
        const SizedBox(height: 12),
        _SummaryCard(sessions: periodSessions, volume: volume, totalSeconds: totalSeconds),
        const SizedBox(height: 12),
        _PeriodComparison(current: currentMonth, previous: previousMonth),
        const SizedBox(height: 12),
        _MuscleVolumeCard(sessions: periodSessions),
        const SizedBox(height: 12),
        _TrendChart(sessions: periodSessions),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton.tonalIcon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExerciseProgressPage())), icon: const Icon(Icons.trending_up_rounded), label: const Text('Por ejercicio'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.tonalIcon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TargetProgressPage())), icon: const Icon(Icons.track_changes_rounded), label: const Text('Objetivos'))),
        ]),
        const SizedBox(height: 12),
        SectionCard(title: 'Histórico mensual', accent: AppTheme.secondary, child: _MonthlyHistory(sessions: state.sessions)),
        const SizedBox(height: 12),
        SectionCard(title: 'Registro corporal', accent: AppTheme.highlight, child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: waist, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cintura (cm)', prefixIcon: Icon(Icons.straighten_rounded)))),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: add, icon: const Icon(Icons.add_rounded), label: const Text('Guardar registro'))),
        ])),
        const SizedBox(height: 12),
        SectionCard(title: 'Últimas sesiones', child: state.sessions.isEmpty
          ? const Text('Todavía no hay entrenamientos registrados.')
          : Column(children: [for (final s in state.sessions.take(10)) ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.planName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(s.date)} · ${_duration(s.duration)} · ${s.totalSets} series'),
              trailing: Text('${s.volumeKg.round()} kg', style: const TextStyle(fontWeight: FontWeight.w800)),
              leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.softIndigo, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.fitness_center_rounded, color: AppTheme.primary)),
            )])),
      ]))),
    ]);
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.sessions, required this.volume});
  final List<WorkoutSession> sessions;
  final double volume;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF7478F6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(.16), blurRadius: 22, offset: const Offset(0, 9))]),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TU PROGRESO', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 7),
        Text('${sessions.length} sesiones', style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -.7)),
        const SizedBox(height: 4),
        Text('${_formatVolume(volume)} acumulados en el período', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
      ])),
      Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(19)), child: const Icon(Icons.insights_rounded, color: Colors.white, size: 31)),
    ]),
  );
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override Widget build(BuildContext context) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
    for (final item in const [(7, '7 días'), (30, 'Mes'), (90, '3 meses'), (365, 'Año')]) ...[
      ChoiceChip(label: Text(item.$2), selected: value == item.$1, onSelected: (_) => onChanged(item.$1)),
      const SizedBox(width: 8),
    ],
  ]));
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.sessions, required this.volume, required this.totalSeconds});
  final List<WorkoutSession> sessions; final double volume; final int totalSeconds;
  @override Widget build(BuildContext context) {
    final sets = sessions.fold<int>(0, (v, s) => v + s.totalSets);
    final reps = sessions.fold<int>(0, (v, s) => v + s.totalReps);
    return SectionCard(title: 'Resumen del período', child: Wrap(alignment: WrapAlignment.spaceAround, runSpacing: 18, children: [
      _Metric('${sessions.length}', 'sesiones', Icons.fitness_center_rounded),
      _Metric(_duration(Duration(seconds: totalSeconds)), 'tiempo', Icons.timer_outlined),
      _Metric(_formatVolume(volume), 'volumen', Icons.bolt_rounded),
      _Metric('$sets', 'series', Icons.view_list_rounded),
      _Metric('$reps', 'repeticiones', Icons.repeat_rounded),
    ]));
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.icon); final String value, label; final IconData icon;
  @override Widget build(BuildContext context) => SizedBox(width: 92, child: Column(children: [
    Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 5),
    Text(value, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
    const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
  ]));
}

class _PeriodComparison extends StatelessWidget {
  const _PeriodComparison({required this.current, required this.previous});
  final PeriodMetrics current, previous;
  @override Widget build(BuildContext context) => SectionCard(title: 'Este mes vs. anterior', accent: AppTheme.secondary, child: Column(children: [
    _ComparisonRow('Sesiones', '${current.sessions}', '${previous.sessions}', percentageChange(current.sessions.toDouble(), previous.sessions.toDouble())),
    _ComparisonRow('Volumen', '${current.volumeKg.round()} kg', '${previous.volumeKg.round()} kg', percentageChange(current.volumeKg, previous.volumeKg)),
    _ComparisonRow('Tiempo', _duration(current.duration), _duration(previous.duration), percentageChange(current.duration.inMinutes.toDouble(), previous.duration.inMinutes.toDouble())),
    _ComparisonRow('Series', '${current.sets}', '${previous.sets}', percentageChange(current.sets.toDouble(), previous.sets.toDouble())),
  ]));
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow(this.label, this.current, this.previous, this.change);
  final String label, current, previous; final double? change;
  @override Widget build(BuildContext context) {
    final positive = change != null && change! > 0;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
      Expanded(child: Text(label)), SizedBox(width: 76, child: Text(current, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800))),
      SizedBox(width: 76, child: Text(previous, textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall)),
      const SizedBox(width: 10),
      SizedBox(width: 62, child: Text(change == null ? '—' : '${change! >= 0 ? '+' : ''}${change!.toStringAsFixed(0)}%', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, color: change == null ? AppTheme.muted : positive ? AppTheme.secondary : AppTheme.highlight))),
    ]));
  }
}

class _MuscleVolumeCard extends StatelessWidget {
  const _MuscleVolumeCard({required this.sessions}); final List<WorkoutSession> sessions;
  @override Widget build(BuildContext context) {
    final totals = volumeByMuscle(sessions); final ordered = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (ordered.isEmpty) return const SectionCard(title: 'Volumen por grupo muscular', child: Text('Registra entrenamientos para ver cómo se distribuye tu volumen.'));
    final max = ordered.first.value;
    return SectionCard(title: 'Volumen por grupo muscular', accent: AppTheme.primary, child: Column(children: [
      for (final item in ordered.take(8)) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(item.key)), Text('${item.value.round()} kg', style: const TextStyle(fontWeight: FontWeight.w800))]),
        const SizedBox(height: 5), ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: max == 0 ? 0 : item.value / max, minHeight: 7)),
      ])),
    ]));
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.sessions}); final List<WorkoutSession> sessions;
  @override Widget build(BuildContext context) {
    final days = sessions.isEmpty ? 14 : 30;
    return SectionCard(title: 'Tendencia de volumen', accent: AppTheme.highlight, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 170, child: CustomPaint(size: const Size(double.infinity, 170), painter: _TrendPainter(data: _dailyValues(sessions, days)))),
      const SizedBox(height: 8),
      Text('Cada punto representa el volumen acumulado de ese día. Usa el selector superior para cambiar el período.', style: Theme.of(context).textTheme.bodySmall),
    ]));
  }
}

List<double> _dailyValues(List<WorkoutSession> sessions, int days) {
  final now = DateTime.now(); final values = <double>[];
  for (var i = days - 1; i >= 0; i--) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
    values.add(sessions.where((s) => s.date.year == day.year && s.date.month == day.month && s.date.day == day.day).fold<double>(0, (v, s) => v + s.volumeKg));
  }
  return values;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.data}); final List<double> data;
  @override void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxValue = data.fold<double>(0, (value, item) => math.max(value, item).toDouble());
    final range = maxValue <= 0 ? 1 : maxValue;
    final grid = Paint()..color = const Color(0xFFE9EAF2)..strokeWidth = 1;
    for (var i = 0; i < 4; i++) { final y = 14 + i * (size.height - 42) / 3; canvas.drawLine(Offset(0, y), Offset(size.width, y), grid); }
    final line = Paint()..color = AppTheme.primary..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = AppTheme.primary.withOpacity(.08)..style = PaintingStyle.fill;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1 ? size.width / 2 : i * size.width / (data.length - 1);
      final y = size.height - 24 - (data[i] / range) * (size.height - 54);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    final fillPath = Path.from(path)..lineTo(size.width, size.height - 24)..lineTo(0, size.height - 24)..close();
    canvas.drawPath(fillPath, fill); canvas.drawPath(path, line);
    final last = data.last; final tp = TextPainter(text: TextSpan(text: 'Actual ${last.round()} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)), textDirection: ui.TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(math.max(0, size.width - tp.width), 0));
  }
  @override bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.data != data;
}

class _MonthlyHistory extends StatelessWidget {
  const _MonthlyHistory({required this.sessions}); final List<WorkoutSession> sessions;
  @override Widget build(BuildContext context) {
    final groups = <String, List<WorkoutSession>>{};
    for (final s in sessions) { final key = DateFormat('yyyy-MM').format(s.date); groups.putIfAbsent(key, () => []).add(s); }
    if (groups.isEmpty) return const Text('El histórico aparecerá cuando registres entrenamientos.');
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(children: [for (final key in keys.take(12)) Builder(builder: (context) {
      final list = groups[key]!; final vol = list.fold<double>(0, (v, s) => v + s.volumeKg); final seconds = list.fold<int>(0, (v, s) => v + s.duration.inSeconds);
      return ListTile(contentPadding: EdgeInsets.zero, leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.softMint, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.calendar_month_rounded, color: AppTheme.secondary)), title: Text(DateFormat('MMMM yyyy', 'es_ES').format(DateTime.parse('$key-01')), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${list.length} sesiones · ${_duration(Duration(seconds: seconds))}'), trailing: Text('${vol.round()} kg', style: const TextStyle(fontWeight: FontWeight.w800)));
    })]);
  }
}

String _duration(Duration d) => '${d.inHours > 0 ? '${d.inHours} h ' : ''}${d.inMinutes.remainder(60)} min';
String _formatVolume(double value) => value >= 1000 ? '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)} t' : '${value.round()} kg';
