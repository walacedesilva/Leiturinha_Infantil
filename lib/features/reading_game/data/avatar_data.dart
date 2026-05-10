// ═════════════════════════════════════════════════════════════════════════════
// AVATAR DATA — Itens de personalização do avatar
// Baseado no catálogo pedagógico da especificação Leiturinha Infantil
// ═════════════════════════════════════════════════════════════════════════════

import 'package:flutter/painting.dart';

enum AvatarCategory { style, hat, clothes, pet, effect }

class AvatarItem {
  final String id;
  final String name;
  final String emoji;
  final AvatarCategory category;
  final int cost;          // 0 = grátis por conquista ou sempre livre
  final String? badgeId;  // se não-nulo, precisa deste badge para desbloquear
  final String unlockHint; // texto exibido quando bloqueado
  final bool startsUnlocked; // sempre disponível desde o início
  final bool isNew;        // exibe tag "NOVO"
  final Color cardColor;   // cor de fundo do card

  const AvatarItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.cost = 0,
    this.badgeId,
    this.unlockHint = '',
    this.startsUnlocked = false,
    this.isNew = false,
    this.cardColor = const Color(0xFFDBEAFE),
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ESTILO / CABELO — determina o emoji base do avatar
// ─────────────────────────────────────────────────────────────────────────────
const kStyleItems = <AvatarItem>[
  AvatarItem(
    id: 'style_default',
    name: 'Padrão',
    emoji: '🧒',
    category: AvatarCategory.style,
    startsUnlocked: true,
    cardColor: Color(0xFFDBEAFE),
  ),
  AvatarItem(
    id: 'style_menina',
    name: 'Menina',
    emoji: '👧',
    category: AvatarCategory.style,
    startsUnlocked: true,
    cardColor: Color(0xFFFCE7F3),
  ),
  AvatarItem(
    id: 'style_curly',
    name: 'Cacheado',
    emoji: '👦',
    category: AvatarCategory.style,
    startsUnlocked: true,
    cardColor: Color(0xFFFEF9C3),
  ),
  AvatarItem(
    id: 'style_teen',
    name: 'Jovem',
    emoji: '🧑',
    category: AvatarCategory.style,
    startsUnlocked: true,
    cardColor: Color(0xFFF0FDF4),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// CHAPÉUS / ACESSÓRIOS
// ─────────────────────────────────────────────────────────────────────────────
const kHatItems = <AvatarItem>[
  AvatarItem(
    id: 'hat_none',
    name: 'Sem Chapéu',
    emoji: '✨',
    category: AvatarCategory.hat,
    startsUnlocked: true,
    cardColor: Color(0xFFF3F4F6),
  ),
  AvatarItem(
    id: 'hat_engineer',
    name: 'Capacete de Engenheiro',
    emoji: '⛑️',
    category: AvatarCategory.hat,
    cost: 25,
    unlockHint: 'Complete o Distrito Encontros e compre por 25 🪙',
    cardColor: Color(0xFFFFF7ED),
    isNew: true,
  ),
  AvatarItem(
    id: 'hat_alchemist',
    name: 'Chapéu de Alquimista',
    emoji: '🧙',
    category: AvatarCategory.hat,
    cost: 30,
    badgeId: 'colecionador',
    unlockHint: 'Complete o Distrito Dígrafos e compre por 30 🪙',
    cardColor: Color(0xFFF5F3FF),
  ),
  AvatarItem(
    id: 'hat_crown',
    name: 'Coroa de Leitor',
    emoji: '👑',
    category: AvatarCategory.hat,
    cost: 0,
    badgeId: 'velocista',
    unlockHint: 'Acerte 5 pronúncias de primeira (badge Velocista)',
    cardColor: Color(0xFFFEF9C3),
  ),
  AvatarItem(
    id: 'hat_explorer',
    name: 'Boné de Explorador',
    emoji: '🧢',
    category: AvatarCategory.hat,
    cost: 0,
    badgeId: 'leitor_semanal',
    unlockHint: 'Pratique 7 dias seguidos (badge Leitor Consistente)',
    cardColor: Color(0xFFDBEAFE),
  ),
  AvatarItem(
    id: 'hat_helmet',
    name: 'Elmo de Guerreiro',
    emoji: '⚔️',
    category: AvatarCategory.hat,
    cost: 20,
    unlockHint: 'Compre por 20 🪙',
    cardColor: Color(0xFFE2E8F0),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// ROUPAS — influencia a cor da borda/fundo do avatar
// ─────────────────────────────────────────────────────────────────────────────
const kClothesItems = <AvatarItem>[
  AvatarItem(
    id: 'clothes_default',
    name: 'Roupa Padrão',
    emoji: '👕',
    category: AvatarCategory.clothes,
    startsUnlocked: true,
    cardColor: Color(0xFFDBEAFE),
  ),
  AvatarItem(
    id: 'clothes_red',
    name: 'Camiseta Vermelha',
    emoji: '❤️',
    category: AvatarCategory.clothes,
    startsUnlocked: true,
    cardColor: Color(0xFFFEE2E2),
  ),
  AvatarItem(
    id: 'clothes_overalls',
    name: 'Macacão de Construtor',
    emoji: '🦺',
    category: AvatarCategory.clothes,
    cost: 20,
    unlockHint: 'Compre por 20 🪙',
    cardColor: Color(0xFFFEF9C3),
  ),
  AvatarItem(
    id: 'clothes_hero',
    name: 'Capa de Super-Herói',
    emoji: '🦸',
    category: AvatarCategory.clothes,
    cost: 0,
    badgeId: 'velocista',
    unlockHint: 'Acerte 5 pronúncias de primeira (badge Velocista)',
    cardColor: Color(0xFFFEE2E2),
  ),
  AvatarItem(
    id: 'clothes_pajama',
    name: 'Pijama de Estrelas',
    emoji: '🌙',
    category: AvatarCategory.clothes,
    cost: 15,
    unlockHint: 'Compre por 15 🪙',
    cardColor: Color(0xFFDBEAFE),
  ),
  AvatarItem(
    id: 'clothes_circus',
    name: 'Uniforme de Circo',
    emoji: '🎪',
    category: AvatarCategory.clothes,
    cost: 25,
    unlockHint: 'Compre por 25 🪙',
    isNew: true,
    cardColor: Color(0xFFFCE7F3),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// PETS
// ─────────────────────────────────────────────────────────────────────────────
const kPetItems = <AvatarItem>[
  AvatarItem(
    id: 'pet_none',
    name: 'Sem Pet',
    emoji: '🐾',
    category: AvatarCategory.pet,
    startsUnlocked: true,
    cardColor: Color(0xFFF3F4F6),
  ),
  AvatarItem(
    id: 'pet_turtle',
    name: 'Tartaruga Sábia',
    emoji: '🐢',
    category: AvatarCategory.pet,
    cost: 0,
    badgeId: 'primeira_palavra',
    unlockHint: 'Fale sua primeira palavra (badge Primeiros Sons)',
    cardColor: Color(0xFFF0FDF4),
  ),
  AvatarItem(
    id: 'pet_cat',
    name: 'Gato Leitor',
    emoji: '🐱',
    category: AvatarCategory.pet,
    cost: 30,
    unlockHint: 'Compre por 30 🪙',
    cardColor: Color(0xFFFFF7ED),
    isNew: true,
  ),
  AvatarItem(
    id: 'pet_dog',
    name: 'Cachorro Fiel',
    emoji: '🐶',
    category: AvatarCategory.pet,
    cost: 0,
    badgeId: 'combinador',
    unlockHint: 'Crie palavras com 2 famílias (badge Combinador Expert)',
    cardColor: Color(0xFFFEF9C3),
  ),
  AvatarItem(
    id: 'pet_dragon',
    name: 'Dragão de Fogo Suave',
    emoji: '🐉',
    category: AvatarCategory.pet,
    cost: 40,
    unlockHint: 'Compre por 40 🪙',
    cardColor: Color(0xFFFEE2E2),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// EFEITOS / FUNDOS (usados na grade de acessórios)
// ─────────────────────────────────────────────────────────────────────────────
const kEffectItems = <AvatarItem>[
  AvatarItem(
    id: 'effect_none',
    name: 'Sem Efeito',
    emoji: '⬜',
    category: AvatarCategory.effect,
    startsUnlocked: true,
    cardColor: Color(0xFFF3F4F6),
  ),
  AvatarItem(
    id: 'effect_rainbow',
    name: 'Aura Arco-Íris',
    emoji: '🌈',
    category: AvatarCategory.effect,
    cost: 0,
    badgeId: 'colecionador',
    unlockHint: 'Desbloqueie 5 conquistas (badge Colecionador)',
    cardColor: Color(0xFFF5F3FF),
    isNew: true,
  ),
  AvatarItem(
    id: 'effect_confetti',
    name: 'Trilha de Confete',
    emoji: '🎊',
    category: AvatarCategory.effect,
    cost: 15,
    unlockHint: 'Compre por 15 🪙',
    cardColor: Color(0xFFFCE7F3),
  ),
  AvatarItem(
    id: 'effect_space',
    name: 'Fundo Espacial',
    emoji: '🌌',
    category: AvatarCategory.effect,
    cost: 0,
    badgeId: 'explorador_familias',
    unlockHint: 'Jogue com 5 famílias diferentes (badge Explorador)',
    cardColor: Color(0xFF1E293B),
  ),
  AvatarItem(
    id: 'effect_forest',
    name: 'Fundo Floresta',
    emoji: '🌳',
    category: AvatarCategory.effect,
    cost: 0,
    badgeId: 'primeira_palavra',
    unlockHint: 'Fale sua primeira palavra (badge Primeiros Sons)',
    cardColor: Color(0xFFF0FDF4),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
const kAllAvatarItems = [
  ...kStyleItems,
  ...kHatItems,
  ...kClothesItems,
  ...kPetItems,
  ...kEffectItems,
];

AvatarItem? getAvatarItemById(String id) {
  try {
    return kAllAvatarItems.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
}

List<AvatarItem> itemsByCategory(AvatarCategory cat) =>
    kAllAvatarItems.where((i) => i.category == cat).toList();

/// Cor de borda do avatar baseada na roupa equipada
Color clothesBorderColor(String? clothesId) {
  switch (clothesId) {
    case 'clothes_red':
      return const Color(0xFFEF4444);
    case 'clothes_overalls':
      return const Color(0xFFF59E0B);
    case 'clothes_hero':
      return const Color(0xFF8B5CF6);
    case 'clothes_pajama':
      return const Color(0xFF3B82F6);
    case 'clothes_circus':
      return const Color(0xFFEC4899);
    default:
      return const Color(0xFF22C55E);
  }
}

/// Gradiente de fundo do avatar baseado no efeito equipado
List<Color> effectBgColors(String? effectId) {
  switch (effectId) {
    case 'effect_rainbow':
      return [const Color(0xFFFFE29A), const Color(0xFFFFA99F), const Color(0xFFB5FCCD)];
    case 'effect_space':
      return [const Color(0xFF0F172A), const Color(0xFF1E3A5F)];
    case 'effect_forest':
      return [const Color(0xFF86EFAC), const Color(0xFF4ADE80)];
    case 'effect_confetti':
      return [const Color(0xFFFCE7F3), const Color(0xFFEDE9FE)];
    default:
      return [const Color(0xFFDBEAFE), const Color(0xFFEFF6FF)];
  }
}
