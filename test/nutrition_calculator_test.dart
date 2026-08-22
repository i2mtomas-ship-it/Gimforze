import 'package:flutter_test/flutter_test.dart';
import 'package:gimforze/features/profile/nutrition_calculator.dart';
import 'package:gimforze/features/profile/profile_model.dart';

void main() {
  test('calculates positive nutrition targets for a complete profile', () {
    const profile = Profile(
      age: 44,
      sex: Sex.male,
      heightCm: 180,
      weightKg: 80,
      goal: Goal.loseFat,
      trainingLevel: TrainingLevel.intermediate,
      daysPerWeek: 4,
      minutesPerSession: 60,
    );
    final result = NutritionCalculator.calculate(profile);
    expect(result.bmr, greaterThan(0));
    expect(result.tdee, greaterThan(result.bmr));
    expect(result.calories, greaterThan(0));
    expect(result.protein, greaterThan(0));
    expect(result.fat, greaterThan(0));
    expect(result.carbs, greaterThan(0));
  });

  test('profile is incomplete until core measurements are provided', () {
    const profile = Profile();
    expect(profile.isComplete, isFalse);
  });
}
