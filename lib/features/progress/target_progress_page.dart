import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/widgets/section_card.dart';
import 'target_progress.dart';

class TargetProgressPage extends StatefulWidget {
  const TargetProgressPage({super.key});
  @override State<TargetProgressPage> createState() => _TargetProgressPageState();
}

class _TargetProgressPageState extends State<TargetProgressPage> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final names = <String>{for (final t in state.exerciseTargets) t.exerciseName, for (final s in state.sessions) for (final e in s.exercises) e.exerciseName}.toList()..sort();
    selected ??= names.isEmpty ? null : names.first;
    final report = selected == null ? null : buildTargetProgress(exerciseName: selected!, target: state.exerciseTargetFor(selected!), sessions: state.sessions);
    return Scaffold(
      appBar: AppBar(title: const Text('Objetivo vs. resultado')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (names.isEmpty) const SectionCard(title: 'Sin datos', child: Text('Define un objetivo o registra un entrenamiento para empezar a comparar resultados.')),
        if (names.isNotEmpty) ...[
          DropdownButtonFormField<String>(initialValue: selected, decoration: const InputDecoration(labelText: 'Ejercicio'), items: names.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(), onChanged: (v) => setState(() => selected = v)),
          const SizedBox(height: 12),
          if (report != null && report.target == null) const SectionCard(title: 'Objetivo no definido', child: Text('Este ejercicio tiene histórico, pero todavía no tiene un objetivo de progresión. Puedes definirlo desde la rutina.')),
          if (report != null && report.target != null) ...[
            _TargetSummary(report: report),
            const SizedBox(height: 12),
            if (report.points.isNotEmpty) SectionCard(title: 'Cumplimiento por sesión', child: SizedBox(height: 220, child: CustomPaint(painter: _CompliancePainter(report.points)))),
            const SizedBox(height: 12),
            SectionCard(title: 'Detalle de las sesiones', child: Column(children: [for (final p in report.points.reversed.take(12)) ListTile(contentPadding: EdgeInsets.zero, title: Text('${_date(p.date)} · ${p.actualWeightKg.toStringAsFixed(1)} kg'), subtitle: Text('${p.actualReps} repeticiones · RIR ${p.actualRir.toStringAsFixed(1)} · objetivo ${p.targetMinReps}-${p.targetMaxReps} · ${p.targetWeightKg.toStringAsFixed(1)} kg'), trailing: _StatusChip(compliance: p.compliance))])),
          ],
        ],
      ]),
    );
  }
}

class _TargetSummary extends StatelessWidget {
  const _TargetSummary({required this.report});
  final TargetProgressReport report;
  @override Widget build(BuildContext context) {
    final target = report.target!;
    final latest = report.points.isEmpty ? null : report.points.last;
    final status = latest == null ? 'Sin datos' : latest.compliance >= 1 ? 'Cumplido' : latest.compliance >= .75 ? 'Parcial' : 'Por debajo';
    return SectionCard(title: report.exerciseName, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        Chip(label: Text('${_fmt(target.targetWeightKg)} kg')),
        Chip(label: Text('${target.minReps}-${target.maxReps} rep')),
        Chip(label: Text('RIR ${target.targetRir}')),
        Chip(label: Text('Media ${report.points.isEmpty ? '—' : '${(report.averageCompliance * 100).toStringAsFixed(0)}%'}')),
      ]),
      const SizedBox(height: 8),
      Text(latest == null ? 'Todavía no hay una sesión registrada.' : 'Última sesión: $status. ${_message(latest)}'),
    ]));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.compliance});
  final double compliance;
  @override Widget build(BuildContext context) => Chip(label: Text('${(compliance * 100).round()}%'));
}

class _CompliancePainter extends CustomPainter {
  const _CompliancePainter(this.points);
  final List<TargetProgressPoint> points;
  @override void paint(Canvas canvas, Size size) {
    final grid = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 22), Offset(size.width, size.height - 22), grid);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width / 2 : i * size.width / (points.length - 1);
      final y = size.height - 24 - points[i].compliance * (size.height - 48);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawPath(path, line);
    final label = TextPainter(text: const TextSpan(text: '100%', style: TextStyle(fontSize: 12)), textDirection: ui.TextDirection.ltr)..layout();
    label.paint(canvas, Offset(0, 0));
    final zero = TextPainter(text: const TextSpan(text: '0%', style: TextStyle(fontSize: 12)), textDirection: ui.TextDirection.ltr)..layout();
    zero.paint(canvas, Offset(0, size.height - 20));
  }
  @override bool shouldRepaint(covariant _CompliancePainter oldDelegate) => oldDelegate.points != points;
}

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _fmt(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
String _message(TargetProgressPoint p) {
  if (p.compliance >= 1) return 'Has cumplido el objetivo de esta sesión. Gimforze puede valorar una progresión en la siguiente.';
  if (p.compliance >= .75) return 'El resultado está cerca del objetivo. Mantén la carga hasta consolidarlo.';
  return 'El resultado queda por debajo del objetivo. Prioriza consolidar la carga antes de progresar.';
}
