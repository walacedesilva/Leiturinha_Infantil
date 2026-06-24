import 'dart:convert';
import 'package:flutter/services.dart';

// ═════════════════════════════════════════════════════════════════════════════
// MODELOS DE HISTÓRIAS INTERATIVAS
// Parseados a partir de assets/stories/stories_pack_v1.json
// ═════════════════════════════════════════════════════════════════════════════

class StoryModel {
  final String id;
  final StoryMetadata metadata;
  final List<StoryCharacter> characters;
  final List<StoryAct> acts;
  final StoryRewards rewards;

  const StoryModel({
    required this.id,
    required this.metadata,
    required this.characters,
    required this.acts,
    required this.rewards,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      metadata: StoryMetadata.fromJson(json['metadata'] as Map<String, dynamic>? ?? {}),
      characters: (json['characters'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StoryCharacter.fromJson)
          .toList(),
      acts: (json['acts'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StoryAct.fromJson)
          .toList(),
      rewards: StoryRewards.fromJson(json['rewards'] as Map<String, dynamic>? ?? {}),
    );
  }

  static Future<List<StoryModel>> loadAll() async {
    final raw = await rootBundle.loadString('assets/stories/stories_pack_v1.json');
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(StoryModel.fromJson)
        .toList();
  }

  StoryCharacter? findCharacter(String id) {
    try {
      return characters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  StoryAct? findAct(String id) {
    try {
      return acts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class StoryMetadata {
  final String title;
  final String subtitle;
  final String difficulty;
  final int estimatedDuration;
  final List<String> tags;
  final int ageMin;
  final int ageMax;

  const StoryMetadata({
    required this.title,
    required this.subtitle,
    required this.difficulty,
    required this.estimatedDuration,
    required this.tags,
    required this.ageMin,
    required this.ageMax,
  });

  factory StoryMetadata.fromJson(Map<String, dynamic> json) {
    final age = json['ageRange'] as Map<String, dynamic>? ?? {};
    return StoryMetadata(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      estimatedDuration: json['estimatedDuration'] as int? ?? 300,
      tags: (json['tags'] as List? ?? []).map((t) => t.toString()).toList(),
      ageMin: (age['min'] as num?)?.toInt() ?? 4,
      ageMax: (age['max'] as num?)?.toInt() ?? 7,
    );
  }

  String get difficultyLabel => switch (difficulty) {
        'beginner' => 'Iniciante',
        'intermediate' => 'Intermediário',
        'advanced' => 'Avançado',
        _ => difficulty,
      };

  String get durationLabel {
    final mins = (estimatedDuration / 60).ceil();
    return '~$mins min';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class StoryCharacter {
  final String id;
  final String name;
  final String description;

  const StoryCharacter({
    required this.id,
    required this.name,
    required this.description,
  });

  factory StoryCharacter.fromJson(Map<String, dynamic> json) {
    return StoryCharacter(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  String get emoji {
    final low = id.toLowerCase();
    if (low.contains('narrator')) return '📖';
    if (low.contains('leao')) return '🦁';
    if (low.contains('sapo')) return '🐸';
    if (low.contains('passaro') || low.contains('piu')) return '🐦';
    if (low.contains('chef')) return '👨‍🍳';
    if (low.contains('colher')) return '🥄';
    if (low.contains('astronaut') || low.contains('nova')) return '👩‍🚀';
    if (low.contains('robot')) return '🤖';
    if (low.contains('diretor') || low.contains('cena')) return '🎭';
    if (low.contains('feliz')) return '😄';
    if (low.contains('triste')) return '😢';
    if (low.contains('guide') || low.contains('safari') || low.contains('tico')) return '🧭';
    return '🎤';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class StoryAct {
  final String id;
  final String title;
  final StoryBackground background;
  final StoryText text;
  final List<StoryDialogue> dialogue;
  final StoryInteraction interaction;

  const StoryAct({
    required this.id,
    required this.title,
    required this.background,
    required this.text,
    required this.dialogue,
    required this.interaction,
  });

  factory StoryAct.fromJson(Map<String, dynamic> json) {
    return StoryAct(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      background: StoryBackground.fromJson(
          json['background'] as Map<String, dynamic>? ?? {}),
      text: StoryText.fromJson(json['text'] as Map<String, dynamic>? ?? {}),
      dialogue: (json['dialogue'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StoryDialogue.fromJson)
          .toList(),
      interaction: StoryInteraction.fromJson(
          json['interaction'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class StoryBackground {
  final String? image;
  final String? ambientAudio;

  const StoryBackground({this.image, this.ambientAudio});

  factory StoryBackground.fromJson(Map<String, dynamic> json) {
    return StoryBackground(
      image: json['image'] as String?,
      ambientAudio: json['ambientAudio'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class StoryText {
  final String narrative;
  final List<String> highlightWords;

  const StoryText({required this.narrative, required this.highlightWords});

  factory StoryText.fromJson(Map<String, dynamic> json) {
    return StoryText(
      narrative: json['narrative'] as String? ?? '',
      highlightWords: (json['highlightWords'] as List? ?? [])
          .map((w) => w.toString())
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class StoryDialogue {
  final String character;
  final String text;
  final String emotion;
  final int duration;
  final String? spoken;

  const StoryDialogue({
    required this.character,
    required this.text,
    required this.emotion,
    required this.duration,
    this.spoken,
  });

  factory StoryDialogue.fromJson(Map<String, dynamic> json) {
    return StoryDialogue(
      character: json['character'] as String? ?? 'narrator',
      text: json['text'] as String? ?? '',
      emotion: json['emotion'] as String? ?? 'neutral',
      duration: (json['duration'] as num?)?.toInt() ?? 3,
      spoken: json['spoken'] as String?,
    );
  }

  /// Som de animal derivado do id do personagem (ex.: 'animal_leao' -> 'leao').
  String? get animalSound =>
      character.startsWith('animal_') ? character.substring(7) : null;

  /// Texto a ser FALADO pelo TTS. Em falas de animal, remove a onomatopeia
  /// em CAIXA ALTA do inicio (ela vira o clipe de som). 'spoken' tem prioridade.
  String get spokenText {
    if (spoken != null) return spoken!;
    if (animalSound == null) return text;
    final cleaned = text
        .replaceFirst(RegExp(r'^(?:[A-ZAEIOUAEOAOC]{2,}[\s!?.,-]*)+'), '')
        .trim();
    return cleaned;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTION — wrapper genérico com acessores tipados para cada subtipo
// ─────────────────────────────────────────────────────────────────────────────
class StoryInteraction {
  final String type;
  final String instruction;
  final int maxAttempts;
  final Map<String, dynamic> raw;

  const StoryInteraction({
    required this.type,
    required this.instruction,
    required this.maxAttempts,
    required this.raw,
  });

  factory StoryInteraction.fromJson(Map<String, dynamic> json) {
    return StoryInteraction(
      type: json['type'] as String? ?? 'branching_choice',
      instruction: json['instruction'] as String? ?? '',
      maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 3,
      raw: json,
    );
  }

  // ── voice_trigger ──
  String get targetPhrase => raw['targetPhrase'] as String? ?? '';
  double get tolerance => (raw['tolerance'] as num?)?.toDouble() ?? 0.7;

  // ── touch_drag ──
  List<Map<String, dynamic>> get items =>
      (raw['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();

  List<Map<String, dynamic>> get targets =>
      (raw['targets'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  List<Map<String, dynamic>> get pathNodes =>
      (raw['pathNodes'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  int get targetSlots => (raw['targetSlots'] as num?)?.toInt() ?? 0;

  /// items com correctOrder → sequência; pathNodes → tracing de caminho
  bool get isDragSequence =>
      items.isNotEmpty && items.first.containsKey('correctOrder');
  bool get isDragPath => pathNodes.isNotEmpty;

  // ── branching_choice ──
  List<Map<String, dynamic>> get options =>
      (raw['options'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  // ── creative_resolution ──
  String get subtype => raw['subtype'] as String? ?? 'voice_recording';
  String get prompt => raw['prompt'] as String? ?? '';
  int get maxDuration => (raw['maxDuration'] as num?)?.toInt() ?? 30;
  Map<String, dynamic>? get canvas =>
      raw['canvas'] as Map<String, dynamic>?;
  List<String> get brushColors =>
      (canvas?['brushColors'] as List? ?? []).map((c) => c.toString()).toList();

  // ── outcomes ──
  Map<String, dynamic>? get _onSuccess =>
      raw['onSuccess'] as Map<String, dynamic>?;

  String? get nextActOnSuccess => _onSuccess?['nextAct'] as String?;

  List<StoryDialogue> get successDialogue =>
      (_onSuccess?['dialogue'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StoryDialogue.fromJson)
          .toList();

  Map<String, dynamic>? get _onSkip => raw['onSkip'] as Map<String, dynamic>?;
  String? get nextActOnSkip =>
      (_onSkip?['nextAct'] as String?) ?? nextActOnSuccess;

  List<StoryDialogue> get skipDialogue =>
      (_onSkip?['dialogue'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StoryDialogue.fromJson)
          .toList();

  List<Map<String, dynamic>> get _onFail =>
      (raw['onFail'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  Map<String, dynamic>? _failForAttempt(int attempt) {
    try {
      return _onFail.firstWhere(
        (f) => f['attempt'] == attempt,
        orElse: () => _onFail.isNotEmpty ? _onFail.last : {},
      );
    } catch (_) {
      return null;
    }
  }

  bool isFallback(int attempt) =>
      _failForAttempt(attempt)?['fallback'] as bool? ?? false;

  List<StoryDialogue> getFailDialogue(int attempt) =>
      (_failForAttempt(attempt)?['feedback']?['dialogue'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StoryDialogue.fromJson)
          .toList();

  String? getFailNextAct(int attempt) =>
      _failForAttempt(attempt)?['feedback']?['nextAct'] as String?;
}

// ─────────────────────────────────────────────────────────────────────────────
class StoryRewards {
  final int coins;
  final int xp;
  final List<String> badges;
  final String? unlockNextStory;

  const StoryRewards({
    required this.coins,
    required this.xp,
    required this.badges,
    this.unlockNextStory,
  });

  factory StoryRewards.fromJson(Map<String, dynamic> json) {
    final c = json['completion'] as Map<String, dynamic>? ?? {};
    return StoryRewards(
      coins: (c['coins'] as num?)?.toInt() ?? 0,
      xp: (c['xp'] as num?)?.toInt() ?? 0,
      badges: (c['badges'] as List? ?? []).map((b) => b.toString()).toList(),
      unlockNextStory: c['unlockNextStory'] as String?,
    );
  }
}
