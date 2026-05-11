import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/avatar_service.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/gamification_models.dart';
import '../../data/avatar_data.dart';
import 'acessorios_screen.dart';
import '../../../../navigation/nav_shell.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PERFIL SCREEN — "Meu Avatar"  (Opção 1: Visão Principal)
// Paleta: Azul céu #DBEAFE | Dourado #FBBF24 | Verde #22C55E | Roxo #8B5CF6
// ═════════════════════════════════════════════════════════════════════════════

const _kBlue       = Color(0xFF3B82F6);
const _kBlueDark   = Color(0xFF1D4ED8);
const _kBluePale   = Color(0xFFDBEAFE);
const _kGold       = Color(0xFFFBBF24);
const _kGoldDeep   = Color(0xFFD97706);
const _kGreen      = Color(0xFF22C55E);
const _kGreenDark  = Color(0xFF15803D);
const _kPurple     = Color(0xFF8B5CF6);
const _kGray       = Color(0xFF9CA3AF);
const _kGrayDark   = Color(0xFF4B5563);
const _kGrayLight  = Color(0xFFF3F4F6);

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with TickerProviderStateMixin {
  // Categoria selecionada no seletor em cruz
  AvatarCategory _selectedCategory = AvatarCategory.hat;

  // Animações
  late final AnimationController _glowCtrl;
  late final AnimationController _avatarBounceCtrl;
  late final AnimationController _saveCtrl;
  bool _saveSuccess = false;

  // Preview temporário (antes de salvar)
  AvatarItem? _previewStyle;
  AvatarItem? _previewHat;
  AvatarItem? _previewClothes;
  AvatarItem? _previewPet;
  AvatarItem? _previewEffect;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _avatarBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _saveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Inicializa preview com valores atuais equipados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final av = context.read<AvatarService>();
      setState(() {
        _previewStyle   = av.activeStyle;
        _previewHat     = av.activeHat;
        _previewClothes = av.activeClothes;
        _previewPet     = av.activePet;
        _previewEffect  = av.activeEffect;
      });
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _avatarBounceCtrl.dispose();
    _saveCtrl.dispose();
    super.dispose();
  }

  // ── Selecionar item do carrossel ────────────────────────────────────────
  void _onItemTap(AvatarItem item) {
    final av = context.read<AvatarService>();
    final gam = context.read<GamificationService>();
    final badgeIds = gam.state.earnedBadgeIds;

    // Item bloqueado por badge
    if (!av.isUnlocked(item, badgeIds) && !av.isPurchasable(item, badgeIds)) {
      AudioManager().playSFX(SFXType.error);
      _showLockedDialog(item);
      return;
    }

    // Item que precisa ser comprado
    if (av.isPurchasable(item, badgeIds)) {
      _showPurchaseDialog(item, av, gam);
      return;
    }

    // Disponível — atualiza preview
    AudioManager().playSFX(SFXType.pop);
    setState(() {
      switch (item.category) {
        case AvatarCategory.style:
          _previewStyle = (item.id == 'style_default') ? null : item;
        case AvatarCategory.hat:
          _previewHat = (item.id == 'hat_none') ? null : item;
        case AvatarCategory.clothes:
          _previewClothes = (item.id == 'clothes_default') ? null : item;
        case AvatarCategory.pet:
          _previewPet = (item.id == 'pet_none') ? null : item;
        case AvatarCategory.effect:
          _previewEffect = (item.id == 'effect_none') ? null : item;
      }
    });
  }

  void _showLockedDialog(AvatarItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              item.unlockHint.isEmpty
                  ? 'Complete mais atividades para desbloquear!'
                  : item.unlockHint,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: _kGrayDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                color: _kBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(
      AvatarItem item, AvatarService av, GamificationService gam) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '${item.cost} moedas',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _kGoldDeep,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seu saldo: 🪙 ${gam.state.coins}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: _kGrayDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Nunito', color: _kGray),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await av.purchase(item, gam);
              if (!mounted) return;
              if (ok) {
                AudioManager().playSFX(SFXType.correct);
                _onItemTap(item); // aplica preview
              } else {
                AudioManager().playSFX(SFXType.error);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      '🪙 Moedas insuficientes! Continue jogando para ganhar mais.',
                      style: TextStyle(fontFamily: 'Nunito'),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                );
              }
            },
            child: const Text(
              'Comprar! 🪙',
              style: TextStyle(
                  fontFamily: 'Nunito', fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAvatar() async {
    final av = context.read<AvatarService>();
    AudioManager().playSFX(SFXType.correct);

    // Aplica o preview como equipado
    if (_previewStyle != null) av.equip(_previewStyle!);
    if (_previewHat != null) {
      av.equip(_previewHat!);
    } else {
      av.unequip(AvatarCategory.hat);
    }
    if (_previewClothes != null) {
      av.equip(_previewClothes!);
    } else {
      av.unequip(AvatarCategory.clothes);
    }
    if (_previewPet != null) {
      av.equip(_previewPet!);
    } else {
      av.unequip(AvatarCategory.pet);
    }
    if (_previewEffect != null) {
      av.equip(_previewEffect!);
    } else {
      av.unequip(AvatarCategory.effect);
    }

    setState(() => _saveSuccess = true);
    await _saveCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saveSuccess = false);
  }

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final av  = context.watch<AvatarService>();
    final badgeIds = gam.state.earnedBadgeIds;

    // Items da categoria selecionada
    final categoryItems = itemsByCategory(_selectedCategory);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Stack(
        children: [
          // ── Fundo azul claro com bolhas decorativas ────────────────────
          Positioned.fill(child: _PerfilBg()),
          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ───────────────────────────────────────────────
                _PerfilTopBar(
                  coins: gam.state.coins,
                  onBack: () {
                    final nav = Navigator.of(context);
                    if (nav.canPop()) {
                      nav.pop();
                    } else {
                      NavTabController.maybeOf(context)?.setTab(0);
                    }
                  },
                  onLoja: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🛍️ Loja — Em breve!',
                          style: TextStyle(fontFamily: 'Nunito')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // ── Título ────────────────────────────────────────────────
                const Text(
                  'Meu Avatar',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E40AF),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),
                const SizedBox(height: 8),
                // ── Avatar + seletores em cruz ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _AvatarCrossLayout(
                    selectedCategory: _selectedCategory,
                    onCategoryTap: (cat) =>
                        setState(() => _selectedCategory = cat),
                    glowT: _glowCtrl,
                    bounceT: _avatarBounceCtrl,
                    previewStyle:   _previewStyle,
                    previewHat:     _previewHat,
                    previewClothes: _previewClothes,
                    previewPet:     _previewPet,
                    previewEffect:  _previewEffect,
                  ),
                ),
                const SizedBox(height: 12),
                // ── Carrossel de itens ────────────────────────────────────
                _ItemCarousel(
                  items: categoryItems,
                  av: av,
                  badgeIds: badgeIds,
                  previewStyle:   _previewStyle,
                  previewHat:     _previewHat,
                  previewClothes: _previewClothes,
                  previewPet:     _previewPet,
                  previewEffect:  _previewEffect,
                  onTap: _onItemTap,
                  onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AcessoriosScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // ── Badge pills ───────────────────────────────────────────
                _BadgeRow(earnedBadgeIds: badgeIds),
                const Spacer(),
                // ── Botão Salvar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
                  child: _SaveButton(
                    onTap: _saveAvatar,
                    success: _saveSuccess,
                    saveT: _saveCtrl,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BG DECORATIVO
// ─────────────────────────────────────────────────────────────────────────────
class _PerfilBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF), Colors.white],
          stops: [0, 0.5, 1],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _PerfilTopBar extends StatelessWidget {
  final int coins;
  final VoidCallback onBack, onLoja;

  const _PerfilTopBar({
    required this.coins,
    required this.onBack,
    required this.onLoja,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Voltar
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1E40AF)),
              onPressed: onBack,
              padding: EdgeInsets.zero,
            ),
          ),
          // Moedas
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF9C3), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _kGoldDeep,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Botão Loja
          GestureDetector(
            onTap: onLoja,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kGold, Color(0xFFFBBF24)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _kGold.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🛍️', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text(
                    'Loja',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR + CROSS LAYOUT
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarCrossLayout extends StatelessWidget {
  final AvatarCategory selectedCategory;
  final ValueChanged<AvatarCategory> onCategoryTap;
  final AnimationController glowT, bounceT;
  final AvatarItem? previewStyle, previewHat, previewClothes,
      previewPet, previewEffect;

  const _AvatarCrossLayout({
    required this.selectedCategory,
    required this.onCategoryTap,
    required this.glowT,
    required this.bounceT,
    this.previewStyle,
    this.previewHat,
    this.previewClothes,
    this.previewPet,
    this.previewEffect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão Cabelo (topo)
        _CategoryBtn(
          label: 'Cabelo',
          emoji: '🦱',
          selected: selectedCategory == AvatarCategory.style,
          onTap: () => onCategoryTap(AvatarCategory.style),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Botão Pet (esquerda)
            _CategoryBtn(
              label: 'Pet',
              emoji: '🐾',
              selected: selectedCategory == AvatarCategory.pet,
              onTap: () => onCategoryTap(AvatarCategory.pet),
            ),
            const SizedBox(width: 10),
            // Avatar central
            _AvatarPreview(
              glowT: glowT,
              bounceT: bounceT,
              previewStyle: previewStyle,
              previewHat: previewHat,
              previewClothes: previewClothes,
              previewPet: previewPet,
              previewEffect: previewEffect,
            ),
            const SizedBox(width: 10),
            // Botão Acessório (direita)
            _CategoryBtn(
              label: 'Acessório',
              emoji: '🎩',
              selected: selectedCategory == AvatarCategory.hat,
              onTap: () => onCategoryTap(AvatarCategory.hat),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Botão Roupa (baixo)
        _CategoryBtn(
          label: 'Roupa',
          emoji: '👕',
          selected: selectedCategory == AvatarCategory.clothes,
          onTap: () => onCategoryTap(AvatarCategory.clothes),
        ),
      ],
    );
  }
}

class _CategoryBtn extends StatelessWidget {
  final String label, emoji;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryBtn({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: selected
                ? [_kGold, _kGoldDeep]
                : [const Color(0xFFFEF3C7), const Color(0xFFFEF9C3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: selected ? _kGoldDeep : _kGold.withOpacity(0.5),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? _kGold : Colors.black).withOpacity(0.2),
              blurRadius: selected ? 12 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _kGrayDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR PREVIEW
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarPreview extends StatelessWidget {
  final AnimationController glowT, bounceT;
  final AvatarItem? previewStyle, previewHat, previewClothes,
      previewPet, previewEffect;

  const _AvatarPreview({
    required this.glowT,
    required this.bounceT,
    this.previewStyle,
    this.previewHat,
    this.previewClothes,
    this.previewPet,
    this.previewEffect,
  });

  @override
  Widget build(BuildContext context) {
    final characterEmoji = previewStyle?.emoji ?? '🧒';
    final hatEmoji = previewHat?.emoji;
    final petEmoji = previewPet?.emoji;
    final borderColor = clothesBorderColor(previewClothes?.id);
    final bgColors = effectBgColors(previewEffect?.id);
    final isRainbow = previewEffect?.id == 'effect_rainbow';

    return AnimatedBuilder(
      animation: Listenable.merge([glowT, bounceT]),
      builder: (_, __) {
        final glowOpacity = 0.4 + glowT.value * 0.5;
        final dy = math.sin(bounceT.value * math.pi * 2) * 4;

        return Transform.translate(
          offset: Offset(0, dy),
          child: SizedBox(
            width: 160,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Glow halo (efeito arco-íris ou padrão)
                if (isRainbow)
                  Container(
                    width: 156,
                    height: 156,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(glowOpacity * 0.5),
                          blurRadius: 28,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: Colors.cyan.withOpacity(glowOpacity * 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withOpacity(glowOpacity * 0.4),
                          blurRadius: 20,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                // Avatar circle
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: bgColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: borderColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hat (top)
                      if (hatEmoji != null)
                        Positioned(
                          top: 6,
                          child: Text(
                            hatEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      // Character (slightly below center to account for hat)
                      Positioned(
                        top: hatEmoji != null ? 36 : 24,
                        child: Text(
                          characterEmoji,
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                    ],
                  ),
                ),
                // Pet badge (bottom-right)
                if (petEmoji != null)
                  Positioned(
                    bottom: 20,
                    right: 0,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: _kGreen, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(petEmoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                // Clothes indicator (bottom-left)
                if (previewClothes != null)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          previewClothes!.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM CAROUSEL
// ─────────────────────────────────────────────────────────────────────────────
class _ItemCarousel extends StatelessWidget {
  final List<AvatarItem> items;
  final AvatarService av;
  final Set<String> badgeIds;
  final AvatarItem? previewStyle, previewHat, previewClothes,
      previewPet, previewEffect;
  final ValueChanged<AvatarItem> onTap;
  final VoidCallback onSeeAll;

  const _ItemCarousel({
    required this.items,
    required this.av,
    required this.badgeIds,
    required this.onTap,
    required this.onSeeAll,
    this.previewStyle,
    this.previewHat,
    this.previewClothes,
    this.previewPet,
    this.previewEffect,
  });

  bool _isPreview(AvatarItem item) {
    switch (item.category) {
      case AvatarCategory.style:
        return previewStyle?.id == item.id;
      case AvatarCategory.hat:
        return previewHat?.id == item.id;
      case AvatarCategory.clothes:
        return previewClothes?.id == item.id;
      case AvatarCategory.pet:
        return previewPet?.id == item.id;
      case AvatarCategory.effect:
        return previewEffect?.id == item.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _categoryLabel(items.first.category),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _kGrayDark,
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'Ver todos →',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              final unlocked = av.isUnlocked(item, badgeIds);
              final purchasable = av.isPurchasable(item, badgeIds);
              final previewing = _isPreview(item);
              return _AccessoryCard(
                item: item,
                unlocked: unlocked,
                purchasable: purchasable,
                previewing: previewing,
                onTap: () => onTap(item),
              );
            },
          ),
        ),
      ],
    );
  }

  String _categoryLabel(AvatarCategory cat) {
    switch (cat) {
      case AvatarCategory.style:  return '✂️ Estilo / Cabelo';
      case AvatarCategory.hat:    return '🎩 Acessórios';
      case AvatarCategory.clothes:return '👕 Roupas';
      case AvatarCategory.pet:    return '🐾 Pets';
      case AvatarCategory.effect: return '✨ Efeitos';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCESSORY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AccessoryCard extends StatelessWidget {
  final AvatarItem item;
  final bool unlocked, purchasable, previewing;
  final VoidCallback onTap;

  const _AccessoryCard({
    required this.item,
    required this.unlocked,
    required this.purchasable,
    required this.previewing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !unlocked && !purchasable;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: previewing
                ? _kGreen
                : locked
                    ? Colors.transparent
                    : item.cardColor,
            width: previewing ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: previewing
                  ? _kGreen.withOpacity(0.35)
                  : Colors.black.withOpacity(0.08),
              blurRadius: previewing ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon area
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: locked
                          ? const Color(0xFFF3F4F6)
                          : item.cardColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: TextStyle(
                          fontSize: 34,
                          color: locked ? null : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Name
                  Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: locked ? _kGray : _kGrayDark,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Overlay bloqueado
            if (locked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            // Badge: equipado ✓
            if (previewing)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            // Badge: bloqueado 🔒
            if (locked)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _kGray.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            // Badge: comprar (preço em moedas)
            if (purchasable)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.cost}🪙',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ),
              ),
            // Badge: NOVO
            if (item.isNew && !locked)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kGold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NOVO',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ),
              ),
            // Badge: preço para bloqueados pagos
            if (locked && item.cost > 0)
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.cost}🪙',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE ROW
// ─────────────────────────────────────────────────────────────────────────────
class _BadgeRow extends StatelessWidget {
  final Set<String> earnedBadgeIds;

  const _BadgeRow({required this.earnedBadgeIds});

  @override
  Widget build(BuildContext context) {
    // Mostra até 5 badges (ganhas + as primeiras bloqueadas)
    final all = kAllBadges.take(5).toList();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final badge = all[i];
          final earned = earnedBadgeIds.contains(badge.id);
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: earned
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: earned ? _kGreen : _kGray.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(badge.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  badge.name,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: earned ? _kGreenDark : _kGray,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  earned ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 12,
                  color: earned ? _kGreen : _kGray,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool success;
  final AnimationController saveT;

  const _SaveButton({
    required this.onTap,
    required this.success,
    required this.saveT,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: success
                ? [_kGreen, _kGreenDark]
                : [_kBlue, _kBlueDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(29),
          boxShadow: [
            BoxShadow(
              color: (success ? _kGreen : _kBlue).withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.save_alt_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                success ? 'Avatar Salvo! ✨' : 'Salvar Avatar',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(autoPlay: false, controller: saveT)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.02, 1.02),
          duration: 200.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.02, 1.02),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
        );
  }
}
