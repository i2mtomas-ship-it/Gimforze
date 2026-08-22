import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import 'profile_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController name, age, height, weight, days, minutes, equipment, foodPrefs, foodAvoid, exerciseAvoid;
  late Sex sex; late Goal goal; late TrainingLevel level;
  bool _initialized = false;
  bool editing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final p = AppStateScope.of(context).profile;
    name = TextEditingController(text: p.name);
    age = TextEditingController(text: p.age == 0 ? '' : '${p.age}');
    height = TextEditingController(text: p.heightCm == 0 ? '' : p.heightCm.toString());
    weight = TextEditingController(text: p.weightKg == 0 ? '' : p.weightKg.toString());
    days = TextEditingController(text: '${p.daysPerWeek}');
    minutes = TextEditingController(text: '${p.minutesPerSession}');
    equipment = TextEditingController(text: p.equipment);
    foodPrefs = TextEditingController(text: p.foodPreferences);
    foodAvoid = TextEditingController(text: p.foodAvoidances);
    exerciseAvoid = TextEditingController(text: p.exerciseAvoidances);
    sex = p.sex; goal = p.goal; level = p.trainingLevel;
    _initialized = true;
  }

  @override void dispose() { for (final c in [name, age, height, weight, days, minutes, equipment, foodPrefs, foodAvoid, exerciseAvoid]) c.dispose(); super.dispose(); }

  Future<void> save() async {
    final parsedAge = int.tryParse(age.text.trim());
    final parsedHeight = double.tryParse(height.text.replaceAll(',', '.').trim());
    final parsedWeight = double.tryParse(weight.text.replaceAll(',', '.').trim());
    final parsedDays = int.tryParse(days.text.trim());
    final parsedMinutes = int.tryParse(minutes.text.trim());
    final missing = <String>[];
    if (parsedAge == null || parsedAge < 13 || parsedAge > 100) missing.add('una edad válida (13–100)');
    if (parsedHeight == null || parsedHeight < 100 || parsedHeight > 250) missing.add('una altura válida (100–250 cm)');
    if (parsedWeight == null || parsedWeight < 30 || parsedWeight > 350) missing.add('un peso válido (30–350 kg)');
    if (parsedDays == null || parsedDays < 1 || parsedDays > 7) missing.add('días de entrenamiento entre 1 y 7');
    if (parsedMinutes == null || parsedMinutes < 15 || parsedMinutes > 240) missing.add('duración entre 15 y 240 minutos');
    if (missing.isNotEmpty) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Revisa: ${missing.join(', ')}.'))); return; }
    final p = Profile(name: name.text.trim(), age: parsedAge!, sex: sex, heightCm: parsedHeight!, weightKg: parsedWeight!, goal: goal, trainingLevel: level, daysPerWeek: parsedDays!, minutesPerSession: parsedMinutes!, equipment: equipment.text.trim(), foodPreferences: foodPrefs.text.trim(), foodAvoidances: foodAvoid.text.trim(), exerciseAvoidances: exerciseAvoid.text.trim());
    await AppStateScope.of(context).saveProfile(p);
    if (mounted) { setState(() => editing = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil guardado correctamente.'))); }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppStateScope.of(context).profile;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)), title: const Text('Perfil'), actions: [if (!editing) IconButton(tooltip: 'Editar perfil', onPressed: () => setState(() => editing = true), icon: const Icon(Icons.edit_rounded))]),
      body: Material(
        color: Colors.transparent,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: editing ? _editForm(key: const ValueKey('edit')) : _summary(p, key: const ValueKey('summary')),
        ),
      ),
    );
  }

  Widget _summary(Profile p, {Key? key}) {
    final complete = [p.name.isNotEmpty, p.age > 0, p.heightCm > 0, p.weightKg > 0, p.daysPerWeek > 0].where((v) => v).length;
    final pct = complete / 5;
    final goalLabel = switch (p.goal) { Goal.loseFat => 'Definición', Goal.maintain => 'Mantener', Goal.gainMuscle => 'Ganar músculo' };
    final levelLabel = switch (p.trainingLevel) { TrainingLevel.beginner => 'Principiante', TrainingLevel.intermediate => 'Intermedio', TrainingLevel.advanced => 'Avanzado' };
    return SingleChildScrollView(
      key: key, padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF15182A), Color(0xFF111D1C)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.primary.withValues(alpha: .35))), child: Column(children: [
          Row(children: [
            Container(width: 76, height: 76, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryBright]), boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: .25), blurRadius: 24)]), child: const Icon(Icons.person_rounded, size: 42, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name.isEmpty ? 'Hola 👋' : 'Hola, ${p.name}', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)), const SizedBox(height: 5), const Text('Cuanto mejor te conozca Gimforze, mejor podrá adaptarse a ti.', style: TextStyle(color: AppTheme.muted, height: 1.35))])),
          ]),
          const SizedBox(height: 22),
          Row(children: [Text('Perfil completado', style: TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.w800)), const Spacer(), Text('${(pct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900))]),
          const SizedBox(height: 9),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: const Color(0xFF292D3B), valueColor: const AlwaysStoppedAnimation(AppTheme.primary))),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: _stat(Icons.fitness_center_rounded, '${p.daysPerWeek}', 'días/semana')), Expanded(child: _stat(Icons.bar_chart_rounded, levelLabel, 'nivel actual')), Expanded(child: _stat(Icons.track_changes_rounded, goalLabel, 'objetivo'))]),
        ])),
        const SizedBox(height: 26),
        _sectionTitle('Información personal', 'Editar', () => setState(() => editing = true)),
        _infoCard([_row(Icons.cake_outlined, 'Edad', p.age > 0 ? '${p.age} años' : 'Sin completar'), _row(Icons.height_rounded, 'Altura', p.heightCm > 0 ? '${p.heightCm.toStringAsFixed(0)} cm' : 'Sin completar'), _row(Icons.monitor_weight_outlined, 'Peso actual', p.weightKg > 0 ? '${p.weightKg.toStringAsFixed(1)} kg' : 'Sin completar'), _row(Icons.flag_outlined, 'Objetivo principal', goalLabel)]),
        const SizedBox(height: 24),
        _sectionTitle('Experiencia y entrenamiento', null, null),
        _infoCard([_row(Icons.fitness_center_rounded, 'Días disponibles', '${p.daysPerWeek} días/semana'), _row(Icons.schedule_rounded, 'Duración sesiones', '${p.minutesPerSession} min'), _row(Icons.stacked_bar_chart_rounded, 'Nivel actual', levelLabel, accent: true)]),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.softIndigo, borderRadius: BorderRadius.circular(18)), child: const Row(children: [Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBright), SizedBox(width: 12), Expanded(child: Text('Gimforze utilizará estos datos para adaptar tus rutinas, progresión y recomendaciones.', style: TextStyle(height: 1.35)))])),
      ]),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(children: [Icon(icon, color: AppTheme.primaryBright, size: 22), const SizedBox(height: 5), Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 11))]));
  Widget _sectionTitle(String title, String? action, VoidCallback? onTap) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const Spacer(), if (action != null) TextButton.icon(onPressed: onTap, icon: const Icon(Icons.edit_rounded, size: 17), label: Text(action))]));
  Widget _infoCard(List<Widget> rows) => Container(decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF282E3D))), child: Column(children: rows));
  Widget _row(IconData icon, String label, String value, {bool accent = false}) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF252B39)))), child: Row(children: [Icon(icon, color: AppTheme.primaryBright, size: 21), const SizedBox(width: 13), Expanded(child: Text(label, style: const TextStyle(color: Color(0xFFD6D8E0)))), Text(value, style: TextStyle(color: accent ? AppTheme.primaryBright : AppTheme.text, fontWeight: FontWeight.w800))]));

  Widget _editForm({Key? key}) => SingleChildScrollView(key: key, padding: const EdgeInsets.fromLTRB(16, 8, 16, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Editar perfil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('Completa tus datos para que Gimforze pueda personalizar mejor tus entrenamientos.', style: TextStyle(color: AppTheme.muted, height: 1.35)), const SizedBox(height: 22),
    _field(name, 'Nombre', TextInputType.name), _field(age, 'Edad', TextInputType.number), _field(height, 'Altura (cm)', const TextInputType.numberWithOptions(decimal: true)), _field(weight, 'Peso (kg)', const TextInputType.numberWithOptions(decimal: true)),
    DropdownButtonFormField<Sex>(initialValue: sex, decoration: const InputDecoration(labelText: 'Sexo'), items: const [DropdownMenuItem(value: Sex.male, child: Text('Hombre')), DropdownMenuItem(value: Sex.female, child: Text('Mujer'))], onChanged: (v) => setState(() => sex = v!)), const SizedBox(height: 12),
    DropdownButtonFormField<Goal>(initialValue: goal, decoration: const InputDecoration(labelText: 'Objetivo'), items: const [DropdownMenuItem(value: Goal.loseFat, child: Text('Definición / perder grasa')), DropdownMenuItem(value: Goal.maintain, child: Text('Mantener')), DropdownMenuItem(value: Goal.gainMuscle, child: Text('Ganar músculo'))], onChanged: (v) => setState(() => goal = v!)), const SizedBox(height: 12),
    DropdownButtonFormField<TrainingLevel>(initialValue: level, decoration: const InputDecoration(labelText: 'Nivel'), items: const [DropdownMenuItem(value: TrainingLevel.beginner, child: Text('Principiante')), DropdownMenuItem(value: TrainingLevel.intermediate, child: Text('Intermedio')), DropdownMenuItem(value: TrainingLevel.advanced, child: Text('Avanzado'))], onChanged: (v) => setState(() => level = v!)), const SizedBox(height: 12),
    Row(children: [Expanded(child: _field(days, 'Días/semana', TextInputType.number)), const SizedBox(width: 12), Expanded(child: _field(minutes, 'Minutos/sesión', TextInputType.number))]), _field(equipment, 'Equipamiento', TextInputType.text), _field(foodPrefs, 'Preferencias alimentarias', TextInputType.text), _field(foodAvoid, 'Alimentos que no consumes', TextInputType.text), _field(exerciseAvoid, 'Ejercicios que quieres evitar', TextInputType.text), const SizedBox(height: 8),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: save, icon: const Icon(Icons.check_rounded), label: const Text('Guardar cambios'))), const SizedBox(height: 8), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => setState(() => editing = false), child: const Text('Cancelar'))),
  ]));
  Widget _field(TextEditingController c, String label, TextInputType type) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: c, keyboardType: type, decoration: InputDecoration(labelText: label)));
}
