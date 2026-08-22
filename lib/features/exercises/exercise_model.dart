class Exercise {
  const Exercise({
    required this.name,
    required this.force,
    required this.level,
    required this.mechanic,
    required this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    required this.category,
    required this.images,
    this.videoUrl,
    this.englishName,
    this.description,
    this.source = 'Catálogo abierto',
  });

  final String name;
  final String? force;
  final String? level;
  final String? mechanic;
  final String? equipment;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final String? category;
  final List<String> images;
  final String? videoUrl;
  /// Nombre habitual en inglés, cuando existe. Se muestra como referencia secundaria.
  final String? englishName;
  final String? description;
  final String source;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: (json['name'] as String?) ?? 'Sin nombre',
        force: json['force'] as String?,
        level: json['level'] as String?,
        mechanic: json['mechanic'] as String?,
        equipment: json['equipment'] as String?,
        primaryMuscles: _strings(json['primaryMuscles']),
        secondaryMuscles: _strings(json['secondaryMuscles']),
        instructions: _strings(json['instructions']),
        category: json['category'] as String?,
        images: _strings(json['images']),
        videoUrl: json['videoUrl'] as String? ?? json['video'] as String?,
        englishName: json['englishName'] as String?,
        description: json['description'] as String?,
        source: json['source'] as String? ?? 'Catálogo abierto',
      );

  String get imageUrl => images.isEmpty
      ? ''
      : 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$namePath/${images.first.split('/').last}';

  String get namePath => images.isEmpty ? _slug(name) : images.first.split('/').first;

  Map<String, dynamic> toJson() => {
        'name': name,
        'force': force,
        'level': level,
        'mechanic': mechanic,
        'equipment': equipment,
        'primaryMuscles': primaryMuscles,
        'secondaryMuscles': secondaryMuscles,
        'instructions': instructions,
        'category': category,
        'images': images,
        'videoUrl': videoUrl,
        'englishName': englishName,
        'description': description,
        'source': source,
      };

  static List<String> _strings(dynamic value) => value is List
      ? value.whereType<String>().where((e) => e.trim().isNotEmpty).toList()
      : const [];

  static String _slug(String value) => value.replaceAll(' ', '_');
}
