import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../workout/workout_model.dart';
import '../../core/app_state.dart';
import '../../core/widgets/section_card.dart';

class ExerciseProgressPage extends StatefulWidget {
  const ExerciseProgressPage({super.key});
  @override State<ExerciseProgressPage> createState() => _ExerciseProgressPageState();
}

class _ExerciseProgressPageState extends State<ExerciseProgressPage> {
  String? selected;
  @override Widget build(BuildContext context) {
    final sessions = AppStateScope.of(context).sessions;
    final names = <String>{for (final s in sessions) for (final e in s.exercises) e.exerciseName}.toList()..sort();
    selected ??= names.isEmpty ? null : names.first;
    final points = selected == null ? <_Point>[] : _buildPoints(sessions, selected!);
    return Scaffold(
      appBar: AppBar(title: const Text('Progresión por ejercicio')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (names.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Registra alguna sesión para ver la progresión de tus ejercicios.'))),
        if (names.isNotEmpty) ...[
          DropdownButtonFormField<String>(initialValue: selected, decoration: const InputDecoration(labelText: 'Ejercicio'), items: names.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(), onChanged: (v) => setState(() => selected = v)),
          const SizedBox(height: 16),
          if (points.isNotEmpty) SectionCard(title: 'Volumen por sesión', child: SizedBox(height: 220, child: CustomPaint(painter: _ProgressPainter(points)))),
          const SizedBox(height: 12),
          if (points.isNotEmpty) SectionCard(title: 'Últimas sesiones', child: Column(children: [for (final p in points.reversed.take(10)) ListTile(contentPadding: EdgeInsets.zero, title: Text('${p.volume.round()} kg de volumen'), subtitle: Text('${p.date.day.toString().padLeft(2, '0')}/${p.date.month.toString().padLeft(2, '0')}/${p.date.year} · mejor serie ${p.bestWeight.toStringAsFixed(1)} kg × ${p.bestReps}'))])),
        ],
      ]),
    );
  }
}

class _Point { const _Point(this.date, this.volume, this.bestWeight, this.bestReps); final DateTime date; final double volume; final double bestWeight; final int bestReps; }
List<_Point> _buildPoints(List<WorkoutSession> sessions, String name) {
  final list = <_Point>[];
  for (final session in sessions.reversed) {
    final matches = session.exercises.where((e) => e.exerciseName == name);
    if (matches.isEmpty) continue;
    final exercise = matches.first;
    if (exercise.sets.isEmpty) continue;
    final best = exercise.sets.reduce((a, b) => a.weightKg >= b.weightKg ? a : b);
    list.add(_Point(session.date, exercise.volumeKg, best.weightKg, best.reps));
  }
  return list;
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter(this.points); final List<_Point> points;
  @override void paint(Canvas canvas, Size size) {
    final max = points.fold<double>(0, (v, p) => math.max(v, p.volume));
    final min = points.fold<double>(double.infinity, (v, p) => math.min(v, p.volume));
    final range = (max - min).abs() < 0.01 ? 1 : max - min;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width / 2 : i * size.width / (points.length - 1);
      final y = size.height - 20 - ((points[i].volume - min) / range) * (size.height - 40);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
    final text = TextPainter(text: TextSpan(text: 'máx ${max.round()} kg', style: const TextStyle(fontSize: 12)), textDirection: ui.TextDirection.ltr)..layout();
    text.paint(canvas, Offset(0, 0));
  }
  @override bool shouldRepaint(covariant _ProgressPainter oldDelegate) => oldDelegate.points != points;
}
