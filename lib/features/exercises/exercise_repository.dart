import 'dart:convert';
import 'package:http/http.dart' as http;
import 'exercise_model.dart';

/// Catálogo de ejercicios con prioridad al contenido en español de wger.
/// Si el servicio no está disponible, se mantiene el catálogo anterior como respaldo.
class ExerciseRepository {
  static const wgerUrl = 'https://wger.de/api/v2/exerciseinfo/?language=4&limit=200';
  static const legacyUrl = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';

  Future<List<Exercise>> fetchCatalog() async {
    // Siempre partimos de un catálogo local amplio para que las rutinas no dependan
    // de internet. Después enriquecemos con los catálogos abiertos disponibles.
    final merged = <String, Exercise>{
      for (final exercise in _coreCatalog()) exercise.name.toLowerCase(): exercise,
    };
    try {
      final spanish = await _fetchWgerSpanish();
      for (final exercise in spanish) {
        merged[exercise.name.toLowerCase()] = exercise;
      }
    } catch (_) {
      try {
        final legacy = await _fetchLegacy();
        for (final exercise in legacy) {
          merged[exercise.name.toLowerCase()] = exercise;
        }
      } catch (_) {
        // El catálogo local permite seguir usando la aplicación sin red.
      }
    }
    return merged.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<Exercise> _coreCatalog() => const [
    Exercise(name: 'Press de banca con barra', force: 'Empuje', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Barra', primaryMuscles: ['Pecho'], secondaryMuscles: ['Tríceps', 'Hombros'], instructions: [], category: 'Pecho', images: []),
    Exercise(name: 'Press inclinado con barra', force: 'Empuje', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Barra', primaryMuscles: ['Pecho'], secondaryMuscles: ['Hombros', 'Tríceps'], instructions: [], category: 'Pecho', images: []),
    Exercise(name: 'Press de banca con mancuernas', force: 'Empuje', level: 'Principiante', mechanic: 'Compuesto', equipment: 'Mancuernas', primaryMuscles: ['Pecho'], secondaryMuscles: ['Tríceps', 'Hombros'], instructions: [], category: 'Pecho', images: []),
    Exercise(name: 'Press inclinado con mancuernas', force: 'Empuje', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Mancuernas', primaryMuscles: ['Pecho'], secondaryMuscles: ['Hombros', 'Tríceps'], instructions: [], category: 'Pecho', images: []),
    Exercise(name: 'Aperturas con mancuernas', force: 'Empuje', level: 'Principiante', mechanic: 'Aislado', equipment: 'Mancuernas', primaryMuscles: ['Pecho'], secondaryMuscles: [], instructions: [], category: 'Pecho', images: []),
    Exercise(name: 'Cruce de poleas', force: 'Empuje', level: 'Principiante', mechanic: 'Aislado', equipment: 'Polea', primaryMuscles: ['Pecho'], secondaryMuscles: [], instructions: [], category: 'Pecho', images: []),
    Exercise(name: 'Fondos en paralelas', force: 'Empuje', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Peso corporal', primaryMuscles: ['Pecho', 'Tríceps'], secondaryMuscles: ['Hombros'], instructions: [], category: 'Pecho', images: []),
    Exercise(name: 'Sentadilla con barra', force: 'Piernas', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Barra', primaryMuscles: ['Cuádriceps', 'Glúteos'], secondaryMuscles: ['Isquiosurales', 'Core'], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Sentadilla frontal', force: 'Piernas', level: 'Avanzado', mechanic: 'Compuesto', equipment: 'Barra', primaryMuscles: ['Cuádriceps'], secondaryMuscles: ['Glúteos', 'Core'], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Prensa de piernas', force: 'Piernas', level: 'Principiante', mechanic: 'Compuesto', equipment: 'Máquina', primaryMuscles: ['Cuádriceps'], secondaryMuscles: ['Glúteos', 'Isquiosurales'], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Peso muerto convencional', force: 'Tirón', level: 'Avanzado', mechanic: 'Compuesto', equipment: 'Barra', primaryMuscles: ['Isquiosurales', 'Glúteos', 'Espalda'], secondaryMuscles: ['Core', 'Trapecio'], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Peso muerto rumano', force: 'Tirón', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Barra', primaryMuscles: ['Isquiosurales', 'Glúteos'], secondaryMuscles: ['Espalda', 'Core'], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Empuje de cadera', force: 'Piernas', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Barra', primaryMuscles: ['Glúteos'], secondaryMuscles: ['Isquiosurales'], instructions: [], category: 'Glúteos', images: []),
    Exercise(name: 'Zancadas con mancuernas', force: 'Piernas', level: 'Principiante', mechanic: 'Compuesto', equipment: 'Mancuernas', primaryMuscles: ['Cuádriceps', 'Glúteos'], secondaryMuscles: ['Isquiosurales'], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Sentadilla búlgara', force: 'Piernas', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Mancuernas', primaryMuscles: ['Cuádriceps', 'Glúteos'], secondaryMuscles: ['Isquiosurales'], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Extensión de cuádriceps', force: 'Piernas', level: 'Principiante', mechanic: 'Aislado', equipment: 'Máquina', primaryMuscles: ['Cuádriceps'], secondaryMuscles: [], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Curl femoral tumbado', force: 'Piernas', level: 'Principiante', mechanic: 'Aislado', equipment: 'Máquina', primaryMuscles: ['Isquiosurales'], secondaryMuscles: [], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Curl femoral sentado', force: 'Piernas', level: 'Principiante', mechanic: 'Aislado', equipment: 'Máquina', primaryMuscles: ['Isquiosurales'], secondaryMuscles: [], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Elevaciones de gemelos de pie', force: 'Piernas', level: 'Principiante', mechanic: 'Aislado', equipment: 'Máquina', primaryMuscles: ['Gemelos'], secondaryMuscles: [], instructions: [], category: 'Piernas', images: []),
    Exercise(name: 'Dominadas', force: 'Tirón', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Peso corporal', primaryMuscles: ['Dorsales'], secondaryMuscles: ['Bíceps', 'Espalda'], instructions: [], category: 'Espalda', images: []),
    Exercise(name: 'Jalón al pecho', force: 'Tirón', level: 'Principiante', mechanic: 'Compuesto', equipment: 'Polea', primaryMuscles: ['Dorsales'], secondaryMuscles: ['Bíceps'], instructions: [], category: 'Espalda', images: []),
    Exercise(name: 'Remo con barra', force: 'Tirón', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Barra', primaryMuscles: ['Espalda'], secondaryMuscles: ['Dorsales', 'Bíceps'], instructions: [], category: 'Espalda', images: []),
    Exercise(name: 'Remo con mancuerna', force: 'Tirón', level: 'Principiante', mechanic: 'Compuesto', equipment: 'Mancuernas', primaryMuscles: ['Espalda'], secondaryMuscles: ['Dorsales', 'Bíceps'], instructions: [], category: 'Espalda', images: []),
    Exercise(name: 'Remo sentado en polea', force: 'Tirón', level: 'Principiante', mechanic: 'Compuesto', equipment: 'Polea', primaryMuscles: ['Espalda'], secondaryMuscles: ['Dorsales', 'Bíceps'], instructions: [], category: 'Espalda', images: []),
    Exercise(name: 'Pullover en polea', force: 'Tirón', level: 'Intermedio', mechanic: 'Aislado', equipment: 'Polea', primaryMuscles: ['Dorsales'], secondaryMuscles: ['Core'], instructions: [], category: 'Espalda', images: []),
    Exercise(name: 'Press militar con barra', force: 'Empuje', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Barra', primaryMuscles: ['Hombros'], secondaryMuscles: ['Tríceps'], instructions: [], category: 'Hombros', images: []),
    Exercise(name: 'Press de hombros con mancuernas', force: 'Empuje', level: 'Principiante', mechanic: 'Compuesto', equipment: 'Mancuernas', primaryMuscles: ['Hombros'], secondaryMuscles: ['Tríceps'], instructions: [], category: 'Hombros', images: []),
    Exercise(name: 'Elevaciones laterales con mancuernas', force: 'Empuje', level: 'Principiante', mechanic: 'Aislado', equipment: 'Mancuernas', primaryMuscles: ['Hombros'], secondaryMuscles: [], instructions: [], category: 'Hombros', images: []),
    Exercise(name: 'Elevaciones laterales en polea', force: 'Empuje', level: 'Intermedio', mechanic: 'Aislado', equipment: 'Polea', primaryMuscles: ['Hombros'], secondaryMuscles: [], instructions: [], category: 'Hombros', images: []),
    Exercise(name: 'Jalón a la cara', force: 'Tirón', level: 'Principiante', mechanic: 'Aislado', equipment: 'Polea', primaryMuscles: ['Hombros'], secondaryMuscles: ['Espalda'], instructions: [], category: 'Hombros', images: []),
    Exercise(name: 'Curl de bíceps con barra', force: 'Tirón', level: 'Principiante', mechanic: 'Aislado', equipment: 'Barra', primaryMuscles: ['Bíceps'], secondaryMuscles: ['Antebrazos'], instructions: [], category: 'Bíceps', images: []),
    Exercise(name: 'Curl de bíceps con mancuernas', force: 'Tirón', level: 'Principiante', mechanic: 'Aislado', equipment: 'Mancuernas', primaryMuscles: ['Bíceps'], secondaryMuscles: ['Antebrazos'], instructions: [], category: 'Bíceps', images: []),
    Exercise(name: 'Curl martillo', force: 'Tirón', level: 'Principiante', mechanic: 'Aislado', equipment: 'Mancuernas', primaryMuscles: ['Bíceps'], secondaryMuscles: ['Antebrazos'], instructions: [], category: 'Bíceps', images: []),
    Exercise(name: 'Curl en polea', force: 'Tirón', level: 'Principiante', mechanic: 'Aislado', equipment: 'Polea', primaryMuscles: ['Bíceps'], secondaryMuscles: [], instructions: [], category: 'Bíceps', images: []),
    Exercise(name: 'Press francés', force: 'Empuje', level: 'Intermedio', mechanic: 'Aislado', equipment: 'Barra', primaryMuscles: ['Tríceps'], secondaryMuscles: [], instructions: [], category: 'Tríceps', images: []),
    Exercise(name: 'Extensión de tríceps en polea', force: 'Empuje', level: 'Principiante', mechanic: 'Aislado', equipment: 'Polea', primaryMuscles: ['Tríceps'], secondaryMuscles: [], instructions: [], category: 'Tríceps', images: []),
    Exercise(name: 'Extensión de tríceps por encima de la cabeza', force: 'Empuje', level: 'Principiante', mechanic: 'Aislado', equipment: 'Polea', primaryMuscles: ['Tríceps'], secondaryMuscles: [], instructions: [], category: 'Tríceps', images: []),
    Exercise(name: 'Plancha', force: 'Estabilización', level: 'Principiante', mechanic: 'Isométrico', equipment: 'Peso corporal', primaryMuscles: ['Abdominales'], secondaryMuscles: ['Core'], instructions: [], category: 'Core', images: []),
    Exercise(name: 'Crunch en polea', force: 'Flexión', level: 'Intermedio', mechanic: 'Aislado', equipment: 'Polea', primaryMuscles: ['Abdominales'], secondaryMuscles: [], instructions: [], category: 'Core', images: []),
    Exercise(name: 'Elevaciones de piernas', force: 'Flexión', level: 'Intermedio', mechanic: 'Compuesto', equipment: 'Peso corporal', primaryMuscles: ['Abdominales'], secondaryMuscles: ['Flexores de cadera'], instructions: [], category: 'Core', images: []),
  ];

  Future<List<Exercise>> _fetchWgerSpanish() async {
    final output = <Exercise>[];
    String? next = wgerUrl;
    final seen = <String>{};
    while (next != null && seen.add(next) && output.length < 2000) {
      final response = await http.get(Uri.parse(next), headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw Exception('wger HTTP ${response.statusCode}');
      final root = jsonDecode(response.body);
      if (root is! Map<String, dynamic>) throw Exception('Respuesta wger no válida');
      final results = root['results'];
      if (results is List) {
        for (final raw in results.whereType<Map<String, dynamic>>()) {
          final exercise = _fromWger(raw);
          if (exercise != null) output.add(exercise);
        }
      }
      next = root['next'] as String?;
    }
    final unique = <String, Exercise>{};
    for (final e in output) {
      final key = e.name.trim().toLowerCase();
      if (key.isNotEmpty) unique[key] = e;
    }
    return unique.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Exercise? _fromWger(Map<String, dynamic> raw) {
    final translations = raw['translations'] is List ? (raw['translations'] as List).whereType<Map<String, dynamic>>().toList() : const <Map<String, dynamic>>[];
    Map<String, dynamic>? translation;
    Map<String, dynamic>? englishTranslation;
    for (final item in translations) {
      final language = item['language']?.toString();
      if (language == '4') {
        translation = item;
      } else if (language == '2') {
        englishTranslation = item;
      }
    }
    // Solo aceptamos una traducción realmente española. Si la API no la
    // devuelve, descartamos ese ejercicio en vez de mostrar el nombre original
    // (que puede ser inglés, anatómico o latino).
    final name = (translation?['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    final localizedName = _exerciseName(name);
    if (_isLatinExerciseName(name) || (_isLikelyEnglishExerciseName(name) && localizedName == name)) return null;

    final muscles = <String>[];
    final secondary = <String>[];
    for (final item in (raw['muscles'] as List? ?? const [])) {
      if (item is Map<String, dynamic>) {
        final common = (item['name_common'] ?? item['name'] ?? item['name_en'])?.toString();
        if (common != null && common.isNotEmpty) muscles.add(_muscle(common));
      }
    }
    for (final item in (raw['muscles_secondary'] as List? ?? const [])) {
      if (item is Map<String, dynamic>) {
        final common = (item['name_common'] ?? item['name'] ?? item['name_en'])?.toString();
        if (common != null && common.isNotEmpty) secondary.add(_muscle(common));
      }
    }

    final equipment = <String>[];
    for (final item in (raw['equipment'] as List? ?? const [])) {
      if (item is Map<String, dynamic>) {
        final value = (item['name'] ?? item['name_en'])?.toString();
        if (value != null && value.isNotEmpty) equipment.add(_equipment(value));
      }
    }

    final images = <String>[];
    for (final item in (raw['images'] as List? ?? const [])) {
      if (item is Map<String, dynamic>) {
        final url = item['image']?.toString();
        if (url != null && url.isNotEmpty) images.add(url);
      }
    }
    final videos = raw['videos'] as List? ?? const [];
    String? video;
    if (videos.isNotEmpty && videos.first is Map<String, dynamic>) video = (videos.first as Map<String, dynamic>)['video']?.toString();

    final rawDescription = (translation?['description'] as String?)?.trim();
    final instructions = _htmlToSteps(rawDescription);
    return Exercise(
      name: localizedName,
      // El segundo nombre solo procede de nuestro diccionario controlado.
      // Nunca mostramos nombres anatómicos/latinos de la API.
      englishName: _englishExerciseNames[localizedName],
      force: null,
      level: null,
      mechanic: null,
      equipment: equipment.isEmpty ? null : equipment.join(', '),
      primaryMuscles: muscles,
      secondaryMuscles: secondary,
      instructions: instructions,
      category: (raw['category'] is Map ? (raw['category'] as Map)['name']?.toString() : null),
      images: images,
      videoUrl: video,
      description: rawDescription == null ? null : _cleanHtml(rawDescription),
      source: 'wger · contenido traducido al español',
    );
  }

  List<String> _htmlToSteps(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    final clean = _cleanHtml(value);
    final parts = clean.split(RegExp(r'(?<=[.!?])\s+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts;
  }

  String _cleanHtml(String value) => value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .trim();

  Future<List<Exercise>> _fetchLegacy() async {
    final response = await http.get(Uri.parse(legacyUrl)).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) throw Exception('No se pudo descargar el catálogo (${response.statusCode}).');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw Exception('Formato de catálogo no válido.');
    return decoded.whereType<Map<String, dynamic>>().map((json) {
      final base = Exercise.fromJson(json);
      return base.copyWithLocalized();
    }).where((exercise) => _isSpanishDisplayName(exercise.name) && !_isLatinExerciseName(exercise.name)).toList();
  }

  // El catálogo remoto de respaldo puede contener nombres originales en inglés.
  // Gimforze muestra únicamente el nombre en español; nunca añadimos el nombre
  // original como segunda línea ni lo dejamos pasar si no está traducido.
  bool _isSpanishDisplayName(String value) {
    final name = value.trim();
    if (name.isEmpty) return false;
    final lower = name.toLowerCase();
    const englishMarkers = <String>[
      'barbell', 'dumbbell', 'bench press', 'squat', 'deadlift', 'row',
      'curl', 'lunge', 'pulldown', 'pull up', 'pullup', 'push up',
      'pushup', 'shoulder press', 'lateral raise', 'fly', 'flies',
      'extension', 'triceps', 'biceps', 'calf raise', 'leg press',
      'leg extension', 'leg curl', 'bulgarian split', 'face pull',
      'cable crossover', 'hip thrust', 'plank', 'crunch',
    ];
    return !englishMarkers.any(lower.contains);
  }


  bool _looksLikeEnglishExerciseName(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final lower = value.trim().toLowerCase();
    const latinMarkers = <String>[
      'brachii', 'brachialis', 'deltoideus', 'pectoralis', 'latissimus',
      'trapezius', 'quadriceps femoris', 'rectus abdominis', 'soleus',
      'gastrocnemius', 'gluteus maximus', 'gluteus medius', 'adductor',
      'abductor', 'sternocleidomastoid', 'iliopsoas', 'teres major',
      'teres minor', 'infraspinatus', 'supraspinatus', 'subscapularis',
    ];
    if (latinMarkers.any(lower.contains)) return false;
    const exerciseMarkers = <String>[
      'press', 'bench', 'squat', 'deadlift', 'row', 'curl', 'raise',
      'lunge', 'pulldown', 'pull-up', 'pull up', 'push-up', 'push up',
      'extension', 'fly', 'crossover', 'thrust', 'plank', 'crunch',
      'dip', 'pullover', 'calf', 'leg ', 'shoulder', 'face pull',
      'overhead', 'hip ', 'cable', 'dumbbell', 'barbell', 'machine',
    ];
    return exerciseMarkers.any(lower.contains);
  }
  bool _isLatinExerciseName(String value) {
    final lower = value.trim().toLowerCase();
    const markers = <String>[
      'brachii', 'brachialis', 'deltoideus', 'pectoralis', 'latissimus',
      'trapezius', 'quadriceps femoris', 'rectus abdominis', 'soleus',
      'gastrocnemius', 'gluteus maximus', 'gluteus medius', 'adductor',
      'abductor', 'sternocleidomastoid', 'iliopsoas', 'teres major',
      'teres minor', 'infraspinatus', 'supraspinatus', 'subscapularis',
    ];
    return markers.any(lower.contains);
  }

  bool _isLikelyEnglishExerciseName(String value) {
    final lower = value.trim().toLowerCase();
    const markers = <String>[
      'barbell', 'dumbbell', 'bench press', 'squat', 'deadlift', 'row',
      'curl', 'lunge', 'pulldown', 'pull up', 'pullup', 'push up',
      'pushup', 'shoulder press', 'lateral raise', 'fly', 'flies',
      'extension', 'triceps', 'biceps', 'calf raise', 'leg press',
      'leg extension', 'leg curl', 'bulgarian split', 'face pull',
      'cable crossover', 'hip thrust', 'plank', 'crunch',
    ];
    return markers.any(lower.contains);
  }

  String _exerciseName(String value) => _exerciseNames[value.trim().toLowerCase()] ?? value;
  String _muscle(String value) => _muscleNames[value.trim().toLowerCase()] ?? value;
  String _equipment(String value) => _equipmentNames[value.trim().toLowerCase()] ?? value;
}

extension on Exercise {
  Exercise copyWithLocalized() => Exercise(
        name: _exerciseNames[name.trim().toLowerCase()] ?? name,
        force: force,
        englishName: _englishExerciseNames[_exerciseNames[name.trim().toLowerCase()] ?? name],
        level: level,
        mechanic: mechanic,
        equipment: equipment == null ? null : _equipmentNames[equipment!.trim().toLowerCase()] ?? equipment,
        primaryMuscles: primaryMuscles.map((e) => _muscleNames[e.trim().toLowerCase()] ?? e).toList(),
        secondaryMuscles: secondaryMuscles.map((e) => _muscleNames[e.trim().toLowerCase()] ?? e).toList(),
        instructions: instructions.map((e) => _instructionText(e)).toList(),
        category: category,
        images: images,
        videoUrl: videoUrl,
        description: description == null ? null : _instructionText(description!),
        source: 'Catálogo abierto · traducción local',
      );
}

String _instructionText(String value) {
  var v = value;
  const replacements = <String, String>{
    'Lie down': 'Túmbate', 'Stand with': 'Colócate de pie con', 'Stand ': 'Colócate de pie ', 'Hold ': 'Sujeta ', 'Grab ': 'Agarra ',
    'Keep your': 'Mantén tus', 'Keeping your': 'Manteniendo tus', 'Lower ': 'Desciende ', 'Raise ': 'Eleva ', 'Lift ': 'Eleva ',
    'Push ': 'Empuja ', 'Pull ': 'Tira ', 'Bend ': 'Flexiona ', 'Extend ': 'Extiende ', 'Return ': 'Vuelve ', 'Slowly': 'De forma controlada',
    'Repeat': 'Repite', 'feet': 'pies', 'knees': 'rodillas', 'back': 'espalda', 'chest': 'pecho', 'shoulders': 'hombros',
  };
  for (final entry in replacements.entries) v = v.replaceAll(entry.key, entry.value);
  return v;
}

const _englishExerciseNames = <String, String>{
  'Press militar': 'Overhead Press',
  'Extensión de tríceps': 'Triceps Extension',
  'Elevaciones laterales': 'Lateral Raise',
  'Curl de bíceps': 'Biceps Curl',
  'Peso muerto': 'Deadlift',
  'Sentadilla copa': 'Goblet Squat',
  'Press de banca con barra': 'Barbell Bench Press',
  'Press inclinado con barra': 'Incline Barbell Bench Press',
  'Press de banca con mancuernas': 'Dumbbell Bench Press',
  'Press inclinado con mancuernas': 'Incline Dumbbell Bench Press',
  'Aperturas con mancuernas': 'Dumbbell Fly',
  'Cruce de poleas': 'Cable Crossover',
  'Fondos en paralelas': 'Parallel Bar Dips',
  'Sentadilla con barra': 'Barbell Squat',
  'Sentadilla frontal': 'Front Squat',
  'Prensa de piernas': 'Leg Press',
  'Peso muerto convencional': 'Conventional Deadlift',
  'Peso muerto rumano': 'Romanian Deadlift',
  'Empuje de cadera': 'Hip Thrust',
  'Zancadas con mancuernas': 'Dumbbell Lunges',
  'Sentadilla búlgara': 'Bulgarian Split Squat',
  'Extensión de cuádriceps': 'Leg Extension',
  'Curl femoral tumbado': 'Lying Leg Curl',
  'Curl femoral sentado': 'Seated Leg Curl',
  'Elevaciones de gemelos de pie': 'Standing Calf Raise',
  'Dominadas': 'Pull-Up',
  'Jalón al pecho': 'Lat Pulldown',
  'Remo con barra': 'Barbell Row',
  'Remo con mancuerna': 'Dumbbell Row',
  'Remo sentado en polea': 'Seated Cable Row',
  'Pullover en polea': 'Cable Pullover',
  'Press militar con barra': 'Barbell Overhead Press',
  'Press de hombros con mancuernas': 'Dumbbell Shoulder Press',
  'Elevaciones laterales con mancuernas': 'Dumbbell Lateral Raise',
  'Elevaciones laterales en polea': 'Cable Lateral Raise',
  'Jalón a la cara': 'Face Pull',
  'Curl de bíceps con barra': 'Barbell Biceps Curl',
  'Curl de bíceps con mancuernas': 'Dumbbell Biceps Curl',
  'Curl martillo': 'Hammer Curl',
  'Curl en polea': 'Cable Biceps Curl',
  'Press francés': 'Skull Crusher / French Press',
};

const _exerciseNames = <String, String>{
  'barbell bench press - medium grip': 'Press de banca con barra',
  'barbell squat': 'Sentadilla con barra',
  'deadlift': 'Peso muerto',
  'romanian deadlift': 'Peso muerto rumano',
  'barbell row': 'Remo con barra',
  'pullups': 'Dominadas',
  'pull up': 'Dominadas',
  'lat pulldown': 'Jalón al pecho',
  'dumbbell biceps curl': 'Curl de bíceps con mancuernas',
  'barbell biceps curl': 'Curl de bíceps con barra',
  'military press': 'Press militar',
  'dumbbell lateral raise': 'Elevaciones laterales con mancuernas',
  'leg press': 'Prensa de piernas',
  'leg extension': 'Extensión de cuádriceps',
  'lying leg curls': 'Curl femoral tumbado',
  'calf raises': 'Elevaciones de gemelos',
  'tricep pushdown': 'Extensión de tríceps en polea',
  'dumbbell bench press': 'Press de banca con mancuernas',
  'incline dumbbell bench press': 'Press inclinado con mancuernas',
  'dumbbell shoulder press': 'Press de hombros con mancuernas',
  'cable crossover': 'Cruce de poleas',
  'dumbbell flyes': 'Aperturas con mancuernas',
  'plank': 'Plancha',
  'bulgarian split squat': 'Sentadilla búlgara',
  'hip thrust': 'Empuje de cadera',
  'face pull': 'Jalón a la cara',
  'incline barbell bench press': 'Press inclinado con barra',
  'barbell bench press': 'Press de banca con barra',
  'seated cable row': 'Remo sentado en polea',
  'cable row': 'Remo en polea',
  'cable triceps extension': 'Extensión de tríceps en polea',
  'overhead triceps extension': 'Extensión de tríceps por encima de la cabeza',
  'hammer curl': 'Curl martillo',
  'standing calf raise': 'Elevaciones de gemelos de pie',
  'seated calf raise': 'Elevaciones de gemelos sentado',
  'lunges': 'Zancadas',
  'walking lunges': 'Zancadas caminando',
  'front squat': 'Sentadilla frontal',
  'goblet squat': 'Sentadilla copa',
  'chest fly': 'Aperturas de pecho',
  'cable fly': 'Aperturas en polea',
};

const _muscleNames = <String, String>{
  'chest': 'Pecho', 'pectorals': 'Pecho', 'biceps': 'Bíceps', 'triceps': 'Tríceps', 'shoulders': 'Hombros',
  'deltoids': 'Hombros', 'lats': 'Dorsales', 'latissimus dorsi': 'Dorsales', 'middle back': 'Espalda media',
  'lower back': 'Lumbar', 'traps': 'Trapecio', 'quadriceps': 'Cuádriceps', 'hamstrings': 'Isquiosurales',
  'glutes': 'Glúteos', 'calves': 'Gemelos', 'abdominals': 'Abdominales', 'forearms': 'Antebrazos',
  'adductors': 'Aductores', 'abductors': 'Abductores', 'neck': 'Cuello',
};

const _equipmentNames = <String, String>{
  'barbell': 'Barra', 'dumbbell': 'Mancuernas', 'cable': 'Polea', 'machine': 'Máquina', 'body weight': 'Peso corporal',
  'body only': 'Peso corporal', 'kettlebell': 'Kettlebell', 'kettlebells': 'Kettlebell', 'bands': 'Bandas elásticas',
  'medicine ball': 'Balón medicinal', 'exercise ball': 'Fitball', 'foam roll': 'Rodillo de espuma',
};
