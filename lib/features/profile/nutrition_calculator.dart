import 'profile_model.dart';

class NutritionTargets {
  const NutritionTargets({required this.bmr, required this.tdee, required this.calories, required this.protein, required this.fat, required this.carbs});
  final double bmr, tdee, calories, protein, fat, carbs;
}

class NutritionCalculator {
  static NutritionTargets calculate(Profile p) {
    if (!p.isComplete) return const NutritionTargets(bmr: 0, tdee: 0, calories: 0, protein: 0, fat: 0, carbs: 0);
    final bmr = p.sex == Sex.male
        ? (10 * p.weightKg) + (6.25 * p.heightCm) - (5 * p.age) + 5
        : (10 * p.weightKg) + (6.25 * p.heightCm) - (5 * p.age) - 161;
    final levelFactor = switch (p.trainingLevel) { TrainingLevel.beginner => 1.35, TrainingLevel.intermediate => 1.5, TrainingLevel.advanced => 1.65 };
    final activityAdjustment = ((p.daysPerWeek - 3).clamp(-2, 3) * 0.04).toDouble();
    final tdee = bmr * (levelFactor + activityAdjustment);
    final goalAdjustment = switch (p.goal) { Goal.loseFat => -0.15, Goal.maintain => 0.0, Goal.gainMuscle => 0.08 };
    final calories = (tdee * (1 + goalAdjustment)).roundToDouble();
    final protein = (p.weightKg * (p.goal == Goal.gainMuscle ? 1.8 : 1.6)).roundToDouble();
    final fat = (calories * 0.27 / 9).roundToDouble();
    final carbs = ((calories - protein * 4 - fat * 9) / 4).roundToDouble().clamp(0, double.infinity).toDouble();
    return NutritionTargets(bmr: bmr, tdee: tdee, calories: calories, protein: protein, fat: fat, carbs: carbs);
  }
}
