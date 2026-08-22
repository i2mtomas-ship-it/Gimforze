import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../workout/workout_model.dart';

class TrainingCalendarPage extends StatefulWidget {
  const TrainingCalendarPage({super.key});
  @override State<TrainingCalendarPage> createState() => _TrainingCalendarPageState();
}

class _TrainingCalendarPageState extends State<TrainingCalendarPage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  void _move(int delta) => setState(() => month = DateTime(month.year, month.month + delta));

  @override
  Widget build(BuildContext context) {
    final sessions = AppStateScope.of(context).sessions;
    final first = DateTime(month.year, month.month, 1);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = first.weekday - 1;
    final cells = leading + days;
    final rows = (cells / 7).ceil();
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de entrenamiento')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          IconButton(onPressed: () => _move(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(child: Center(child: Text(DateFormat('MMMM yyyy', 'es_ES').format(month), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)))),
          IconButton(onPressed: () => _move(1), icon: const Icon(Icons.chevron_right)),
        ]),
        const SizedBox(height: 8),
        Row(children: [for (final label in const ['L', 'M', 'X', 'J', 'V', 'S', 'D']) Expanded(child: Center(child: Text(label, style: Theme.of(context).textTheme.labelLarge)))]),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows * 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.9),
          itemBuilder: (_, index) {
            final dayNumber = index - leading + 1;
            if (dayNumber < 1 || dayNumber > days) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, dayNumber);
            final daySessions = sessions.where((s) => _sameDay(s.date, date)).toList();
            final hasTraining = daySessions.isNotEmpty;
            final volume = daySessions.fold<double>(0, (v, s) => v + s.volumeKg);
            final isToday = _sameDay(DateTime.now(), date);
            return Padding(padding: const EdgeInsets.all(3), child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: hasTraining ? () => _showDay(context, date, daySessions) : null,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isToday ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor), color: hasTraining ? Theme.of(context).colorScheme.primaryContainer : null),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$dayNumber', style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (hasTraining) const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.check_circle, size: 15)),
                  if (hasTraining) Text('${volume.round()} kg', style: Theme.of(context).textTheme.labelSmall),
                ]),
              ),
            ));
          },
        ),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          const Icon(Icons.info_outline), const SizedBox(width: 10), Expanded(child: Text('Los días con entrenamiento aparecen marcados. Toca un día para consultar sus sesiones, duración y volumen.')),
        ]))),
      ]),
    );
  }

  Future<void> _showDay(BuildContext context, DateTime date, List<WorkoutSession> sessions) async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      Text(DateFormat('EEEE d MMMM', 'es_ES').format(date), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      for (final session in sessions) ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.fitness_center)), title: Text(session.planName), subtitle: Text('${_duration(session.duration)} · ${session.totalSets} series · ${session.totalReps} repeticiones'), trailing: Text('${session.volumeKg.round()} kg')),
    ])));
  }
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
String _duration(Duration d) => '${d.inHours > 0 ? '${d.inHours} h ' : ''}${d.inMinutes.remainder(60)} min';
