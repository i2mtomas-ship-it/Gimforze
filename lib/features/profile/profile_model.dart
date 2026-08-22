import 'package:shared_preferences/shared_preferences.dart';

enum Sex { male, female }
enum Goal { loseFat, maintain, gainMuscle }
enum TrainingLevel { beginner, intermediate, advanced }

class Profile {
  const Profile({
    this.name = '',
    this.age = 0,
    this.sex = Sex.male,
    this.heightCm = 0,
    this.weightKg = 0,
    this.goal = Goal.loseFat,
    this.trainingLevel = TrainingLevel.beginner,
    this.daysPerWeek = 3,
    this.minutesPerSession = 45,
    this.equipment = '',
    this.foodPreferences = '',
    this.foodAvoidances = '',
    this.exerciseAvoidances = '',
  });

  final String name;
  final int age;
  final Sex sex;
  final double heightCm;
  final double weightKg;
  final Goal goal;
  final TrainingLevel trainingLevel;
  final int daysPerWeek;
  final int minutesPerSession;
  final String equipment;
  final String foodPreferences;
  final String foodAvoidances;
  final String exerciseAvoidances;

  bool get isComplete => age > 0 && heightCm > 0 && weightKg > 0;

  Profile copyWith({String? name, int? age, Sex? sex, double? heightCm, double? weightKg, Goal? goal, TrainingLevel? trainingLevel, int? daysPerWeek, int? minutesPerSession, String? equipment, String? foodPreferences, String? foodAvoidances, String? exerciseAvoidances}) => Profile(
        name: name ?? this.name,
        age: age ?? this.age, sex: sex ?? this.sex, heightCm: heightCm ?? this.heightCm, weightKg: weightKg ?? this.weightKg,
        goal: goal ?? this.goal, trainingLevel: trainingLevel ?? this.trainingLevel, daysPerWeek: daysPerWeek ?? this.daysPerWeek,
        minutesPerSession: minutesPerSession ?? this.minutesPerSession, equipment: equipment ?? this.equipment,
        foodPreferences: foodPreferences ?? this.foodPreferences, foodAvoidances: foodAvoidances ?? this.foodAvoidances,
        exerciseAvoidances: exerciseAvoidances ?? this.exerciseAvoidances,
      );

  Future<void> save(SharedPreferences p) async {
    await p.setString('profile.name', name);
    await p.setInt('profile.age', age); await p.setString('profile.sex', sex.name); await p.setDouble('profile.height', heightCm);
    await p.setDouble('profile.weight', weightKg); await p.setString('profile.goal', goal.name); await p.setString('profile.level', trainingLevel.name);
    await p.setInt('profile.days', daysPerWeek); await p.setInt('profile.minutes', minutesPerSession);
    await p.setString('profile.equipment', equipment); await p.setString('profile.foodPrefs', foodPreferences);
    await p.setString('profile.foodAvoid', foodAvoidances); await p.setString('profile.exerciseAvoid', exerciseAvoidances);
  }

  factory Profile.fromPrefs(SharedPreferences p) => Profile(
        name: p.getString('profile.name') ?? '',
        age: p.getInt('profile.age') ?? 0,
        sex: Sex.values.firstWhere((e) => e.name == p.getString('profile.sex'), orElse: () => Sex.male),
        heightCm: p.getDouble('profile.height') ?? 0,
        weightKg: p.getDouble('profile.weight') ?? 0,
        goal: Goal.values.firstWhere((e) => e.name == p.getString('profile.goal'), orElse: () => Goal.loseFat),
        trainingLevel: TrainingLevel.values.firstWhere((e) => e.name == p.getString('profile.level'), orElse: () => TrainingLevel.beginner),
        daysPerWeek: p.getInt('profile.days') ?? 3, minutesPerSession: p.getInt('profile.minutes') ?? 45,
        equipment: p.getString('profile.equipment') ?? '', foodPreferences: p.getString('profile.foodPrefs') ?? '',
        foodAvoidances: p.getString('profile.foodAvoid') ?? '', exerciseAvoidances: p.getString('profile.exerciseAvoid') ?? '',
      );
}
