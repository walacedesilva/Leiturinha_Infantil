/// Modelos de dados do sistema de gamificação.
/// XP, moedas, badges, níveis e adaptação dinâmica.

// ─────────────────────────────────────────────────────────────────────────────
// NÍVEIS DE XP
// ─────────────────────────────────────────────────────────────────────────────

class PlayerLevel {
  final int level;
  final String name;
  final String emoji;
  final int xpRequired;

  const PlayerLevel({
    required this.level,
    required this.name,
    required this.emoji,
    required this.xpRequired,
  });
}

const List<PlayerLevel> kLevels = [
  PlayerLevel(level: 1, name: 'Explorador',         emoji: '🌱', xpRequired: 0),
  PlayerLevel(level: 2, name: 'Aprendiz',            emoji: '📖', xpRequired: 50),
  PlayerLevel(level: 3, name: 'Leitor',              emoji: '📚', xpRequired: 150),
  PlayerLevel(level: 4, name: 'Contador',            emoji: '🎙️', xpRequired: 300),
  PlayerLevel(level: 5, name: 'Mestre das Palavras', emoji: '🏆', xpRequired: 600),
];

PlayerLevel getLevelForXp(int xp) {
  PlayerLevel current = kLevels.first;
  for (final lvl in kLevels) {
    if (xp >= lvl.xpRequired) current = lvl;
  }
  return current;
}

PlayerLevel? getNextLevel(int xp) {
  final current = getLevelForXp(xp);
  final idx = kLevels.indexWhere((l) => l.level == current.level);
  if (idx < kLevels.length - 1) return kLevels[idx + 1];
  return null;
}

// Progresso percentual dentro do nível atual (0.0 – 1.0)
double xpProgressInLevel(int xp) {
  final current = getLevelForXp(xp);
  final next = getNextLevel(xp);
  if (next == null) return 1.0;
  final range = next.xpRequired - current.xpRequired;
  final done = xp - current.xpRequired;
  return (done / range).clamp(0.0, 1.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGES / CONQUISTAS
// ─────────────────────────────────────────────────────────────────────────────

class GameBadge {
  final String id;
  final String name;
  final String description;
  final String emoji;

  const GameBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
  });
}

const List<GameBadge> kAllBadges = [
  GameBadge(
    id: 'primeira_palavra',
    name: 'Primeiros Sons',
    description: 'Falou sua primeira palavra!',
    emoji: '🌟',
  ),
  GameBadge(
    id: 'persistente',
    name: 'Nunca Desiste',
    description: 'Superou um desafio com 3+ tentativas',
    emoji: '💪',
  ),
  GameBadge(
    id: 'leitor_semanal',
    name: 'Leitor Consistente',
    description: 'Praticou 7 dias seguidos',
    emoji: '📅',
  ),
  GameBadge(
    id: 'combinador',
    name: 'Combinador Expert',
    description: 'Criou palavras usando 2 famílias',
    emoji: '🔗',
  ),
  GameBadge(
    id: 'velocista',
    name: 'Velocista',
    description: '5 palavras corretas na 1ª tentativa seguidas',
    emoji: '⚡',
  ),
  GameBadge(
    id: 'explorador_familias',
    name: 'Explorador de Famílias',
    description: 'Jogou com 5 famílias diferentes',
    emoji: '🗺️',
  ),
  GameBadge(
    id: 'mestre_b',
    name: 'Mestre do B',
    description: 'Completou toda a família B',
    emoji: '🅱️',
  ),
  GameBadge(
    id: 'mestre_c',
    name: 'Mestre do C',
    description: 'Completou toda a família C',
    emoji: '©️',
  ),
  GameBadge(
    id: 'mestre_m',
    name: 'Mestre do M',
    description: 'Completou toda a família M',
    emoji: 'Ⓜ️',
  ),
  GameBadge(
    id: 'colecionador',
    name: 'Colecionador',
    description: 'Desbloqueou 5 conquistas',
    emoji: '🎖️',
  ),
];

GameBadge? getBadgeById(String id) {
  try {
    return kAllBadges.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AÇÕES QUE GERAM RECOMPENSA
// ─────────────────────────────────────────────────────────────────────────────

class RewardEvent {
  final int coins;
  final int xp;
  final String label;
  final List<String> newBadgeIds; // badges desbloqueados neste evento

  const RewardEvent({
    required this.coins,
    required this.xp,
    required this.label,
    this.newBadgeIds = const [],
  });

  bool get hasReward => coins > 0 || xp > 0;
  bool get hasBadge => newBadgeIds.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// ESTADO DO JOGADOR (imutável – usado para notificações)
// ─────────────────────────────────────────────────────────────────────────────

class PlayerState {
  final int coins;
  final int xp;
  final Set<String> earnedBadgeIds;
  final int currentStreak;     // dias consecutivos
  final DateTime? lastPlayDate;
  final int totalWordsValidated;
  final int consecutiveFirstTry; // palavras corretas na 1ª tentativa seguidas
  final Set<String> familiesPlayed;

  const PlayerState({
    required this.coins,
    required this.xp,
    required this.earnedBadgeIds,
    required this.currentStreak,
    required this.lastPlayDate,
    required this.totalWordsValidated,
    required this.consecutiveFirstTry,
    required this.familiesPlayed,
  });

  factory PlayerState.empty() => const PlayerState(
        coins: 0,
        xp: 0,
        earnedBadgeIds: {},
        currentStreak: 0,
        lastPlayDate: null,
        totalWordsValidated: 0,
        consecutiveFirstTry: 0,
        familiesPlayed: {},
      );

  PlayerLevel get level => getLevelForXp(xp);
  PlayerLevel? get nextLevel => getNextLevel(xp);
  double get levelProgress => xpProgressInLevel(xp);

  List<GameBadge> get earnedBadges =>
      earnedBadgeIds.map((id) => getBadgeById(id)).whereType<GameBadge>().toList();

  PlayerState copyWith({
    int? coins,
    int? xp,
    Set<String>? earnedBadgeIds,
    int? currentStreak,
    DateTime? lastPlayDate,
    int? totalWordsValidated,
    int? consecutiveFirstTry,
    Set<String>? familiesPlayed,
  }) =>
      PlayerState(
        coins: coins ?? this.coins,
        xp: xp ?? this.xp,
        earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
        currentStreak: currentStreak ?? this.currentStreak,
        lastPlayDate: lastPlayDate ?? this.lastPlayDate,
        totalWordsValidated: totalWordsValidated ?? this.totalWordsValidated,
        consecutiveFirstTry: consecutiveFirstTry ?? this.consecutiveFirstTry,
        familiesPlayed: familiesPlayed ?? this.familiesPlayed,
      );
}
