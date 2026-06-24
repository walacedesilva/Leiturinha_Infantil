import 'package:flutter/painting.dart';

enum AvatarCategory { style, hat, clothes, pet, effect }

// 1. Enum para evitar strings mágicas nos Badges de conquista
enum AchievementBadge {
  colecionador,
  velocista,
  leitorSemanal,
  primeiraPalavra,
  combinador,
  exploradorFamilias,
}

class AvatarItem {
  final String id;
  final String name;
  final String emoji;
  final AvatarCategory category;
  final int cost; 
  final AchievementBadge? badge;      // Alterado para o Enum seguro
  final String unlockHint; 
  final bool startsUnlocked; 
  final bool isNew; 
  final Color cardColor; 
  
  // 2. Centralizando os atributos visuais específicos aqui dentro
  final Color? borderColor;           // Usado primariamente em Roupas
  final List<Color>? backgroundGradient; // Usado primariamente em Efeitos

  const AvatarItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.cost = 0,
    this.badge,
    this.unlockHint = '',
    this.startsUnlocked = false,
    this.isNew = false,
    this.cardColor = const Color(0xFFDBEAFE),
    this.borderColor,
    this.backgroundGradient,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EXEMPLO DE DATA CONFIGURADA (ROUPAS E EFEITOS REORGANIZADOS)
// ─────────────────────────────────────────────────────────────────────────────

const kClothesItems = <AvatarItem>[
  AvatarItem(
    id: 'clothes_default',
    name: 'Roupa Padrão',
    emoji: '👕',
    category: AvatarCategory.clothes,
    startsUnlocked: true,
    borderColor: Color(0xFF22C55E), // Cor padrão agora fica direto no item
  ),
  AvatarItem(
    id: 'clothes_red',
    name: 'Camiseta Vermelha',
    emoji: '❤️',
    category: AvatarCategory.clothes,
    startsUnlocked: true,
    cardColor: Color(0xFFFEE2E2),
    borderColor: Color(0xFFEF4444), // Configurado direto na fonte
  ),
  AvatarItem(
    id: 'clothes_hero',
    name: 'Capa de Super-Herói',
    emoji: '🦸',
    category: AvatarCategory.clothes,
    badge: AchievementBadge.velocista, // Uso do enum seguro
    unlockHint: 'Acerte 5 pronúncias de primeira (badge Velocista)',
    cardColor: Color(0xFFFEE2E2),
    borderColor: Color(0xFF8B5CF6),
  ),
];

const kEffectItems = <AvatarItem>[
  AvatarItem(
    id: 'effect_default',
    name: 'Sem Efeito',
    emoji: '⬜',
    category: AvatarCategory.effect,
    startsUnlocked: true,
    backgroundGradient: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
  ),
  AvatarItem(
    id: 'effect_rainbow',
    name: 'Aura Arco-Íris',
    emoji: '🌈',
    category: AvatarCategory.effect,
    badge: AchievementBadge.colecionador,
    unlockHint: 'Desbloqueie 5 conquistas (badge Colecionador)',
    cardColor: Color(0xFFF5F3FF),
    isNew: true,
    backgroundGradient: [Color(0xFFFFE29A), Color(0xFFFFA99F), Color(0xFFB5FCCD)],
  ),
];

const kStyleItems = <AvatarItem>[
  AvatarItem(
    id: 'style_default',
    name: 'Estilo Padrão',
    emoji: '🐼',
    category: AvatarCategory.style,
    startsUnlocked: true,
  ),
];

const kHatItems = <AvatarItem>[
  AvatarItem(
    id: 'hat_none',
    name: 'Sem Chapéu',
    emoji: '✨',
    category: AvatarCategory.hat,
    startsUnlocked: true,
  ),
  AvatarItem(
    id: 'hat_engineer',
    name: 'Capacete Engenheiro',
    emoji: '⛑️',
    category: AvatarCategory.hat,
    badge: AchievementBadge.primeiraPalavra,
    unlockHint: 'Acerte sua primeira palavra (badge Primeira Palavra)',
    cardColor: Color(0xFFFFF7ED),
  ),
];

const kPetItems = <AvatarItem>[
  AvatarItem(
    id: 'pet_none',
    name: 'Sem Pet',
    emoji: '🚫',
    category: AvatarCategory.pet,
    startsUnlocked: true,
  ),
  AvatarItem(
    id: 'pet_star',
    name: 'Estrelinha',
    emoji: '⭐',
    category: AvatarCategory.pet,
    badge: AchievementBadge.leitorSemanal,
    unlockHint: 'Leia 7 dias seguidos (badge Leitor Semanal)',
    cardColor: Color(0xFFFFFBEB),
  ),
];

const List<AvatarItem> kAllAvatarItems = [
  ...kStyleItems,
  ...kHatItems,
  ...kClothesItems,
  ...kPetItems,
  ...kEffectItems,
];

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS LIMPOS E SEGUROS
// ─────────────────────────────────────────────────────────────────────────────

/// Busca simplificada sem necessidade de bloco try/catch manual
AvatarItem? getAvatarItemById(String id) {
  for (final item in kAllAvatarItems) {
    if (item.id == id) return item;
  }
  return null;
}

List<AvatarItem> itemsByCategory(AvatarCategory cat) =>
    kAllAvatarItems.where((i) => i.category == cat).toList();

/// Retorna a cor da borda baseado no item, com um fallback genérico seguro
Color clothesBorderColor(String? clothesId) {
  final item = getAvatarItemById(clothesId ?? '');
  return item?.borderColor ?? const Color(0xFF22C55E);
}

/// Retorna o gradiente baseado no item, com um fallback genérico seguro
List<Color> effectBgColors(String? effectId) {
  final item = getAvatarItemById(effectId ?? '');
  return item?.backgroundGradient ?? const [Color(0xFFDBEAFE), Color(0xFFEFF6FF)];
}