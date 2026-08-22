import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/widgets/section_card.dart';
import '../profile/nutrition_calculator.dart';

class NutritionPage extends StatelessWidget { const NutritionPage({super.key}); @override Widget build(BuildContext context) { final p = AppStateScope.of(context).profile; final n = NutritionCalculator.calculate(p); return CustomScrollView(slivers: [SliverAppBar.large(title: const Text('Nutrición'), backgroundColor: Theme.of(context).scaffoldBackgroundColor), SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList(delegate: SliverChildListDelegate([
  SectionCard(title: 'Objetivos estimados', child: p.isComplete ? Column(children: [ _row('Metabolismo basal', '${n.bmr.round()} kcal'), _row('Gasto estimado', '${n.tdee.round()} kcal'), _row('Objetivo diario', '${n.calories.round()} kcal'), _row('Proteína', '${n.protein.round()} g'), _row('Grasas', '${n.fat.round()} g'), _row('Carbohidratos', '${n.carbs.round()} g') ]) : const Text('Completa primero tu perfil.')),
  const SizedBox(height: 12), const SectionCard(title: 'Comidas', child: Text('El registro de alimentos y menús personalizados será el siguiente bloque de nutrición.')),
])))]); }
Widget _row(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text(a)), Text(b, style: const TextStyle(fontWeight: FontWeight.w700))])); }
