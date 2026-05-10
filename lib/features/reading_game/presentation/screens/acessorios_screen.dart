import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/avatar_service.dart';
import '../../../../services/gamification_service.dart';
import '../../data/avatar_data.dart';

// ═════════════════════════════════════════════════════════════════════════════
// ACESSÓRIOS SCREEN — grade completa de todos os itens do avatar
// ═════════════════════════════════════════════════════════════════════════════

const _kBlue      = Color(0xFF3B82F6);
const _kBlueDark  = Color(0xFF1D4ED8);
const _kBluePale  = Color(0xFFDBEAFE);
const _kGold      = Color(0xFFFBBF24);
const _kGoldDeep  = Color(0xFFD97706);
const _kGreen     = Color(0xFF22C55E);
const _kGreenDark = Color(0xFF15803D);
const _kGray      = Color(0xFF9CA3AF);
const _kGrayDark  = Color(0xFF4B5563);

class AcessoriosScreen extends StatefulWidget {
  const AcessoriosScreen({super.key});

  @override
  State<AcessoriosScreen> createState() => _AcessoriosScreenState();
}

class _AcessoriosScreenState extends State<AcessoriosScreen> {
  // null = Todos
  AvatarCategory? _filterCategory;

  List<AvatarItem> _getItems() {
    if (_filterCategory == null) return kAllAvatarItems;
    return itemsByCategory(_filterCategory!);
  }

  Future<void> _handleItemTap(
      AvatarItem item, AvatarService av, GamificationService gam) async {
    final badgeIds = gam.state.earnedBadgeIds;
    final unlocked = av.isUnlocked(item, badgeIds);
    final purchasable = av.isPurchasable(item, badgeIds);

    if (!unlocked && !purchasable) {
      AudioManager().playSFX(SFXType.error);
      _showLockedSnack(item.unlockHint.isEmpty
          ? 'Complete mais atividades para desbloquear!'
          : item.unlockHint);
      return;
    }

    if (purchasable) {
      final confirm = await _showPurchaseDialog(item, gam.state.coins);
      if (confirm != true) return;
      final ok = await av.purchase(item, gam);
      if (!mounted) return;
      if (ok) {
        AudioManager().playSFX(SFXType.correct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.emoji} ${item.name} comprado!',
                style: const TextStyle(fontFamily: 'Nunito')),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        av.equip(item);
      } else {
        AudioManager().playSFX(SFXType.error);
        _showLockedSnack('🪙 Moedas insuficientes! Continue jogando.');
      }
      return;
    }

    // Disponível — equipar / desequipar toggle
    AudioManager().playSFX(SFXType.pop);
    if (av.isEquipped(item.id)) {
      av.unequip(item.category);
    } else {
      av.equip(item);
    }
  }

  Future<bool?> _showPurchaseDialog(AvatarItem item, int coins) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
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
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
            ]),
          ),
          const SizedBox(height: 6),
          Text(
            'Seu saldo: 🪙 $coins',
            style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13, color: _kGrayDark),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(fontFamily: 'Nunito', color: _kGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Comprar! 🪙',
                style: TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showLockedSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
        backgroundColor: const Color(0xFF4B5563),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _resetAvatar(AvatarService av) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '🔄 Resetar Avatar?',
          style: TextStyle(
              fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Isso removerá todos os itens equipados e voltará ao padrão. Seus itens comprados ficarão na sua conta.',
          style: TextStyle(
              fontFamily: 'Nunito', fontSize: 14, color: _kGrayDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(fontFamily: 'Nunito', color: _kGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resetar',
                style: TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      av.resetAvatar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Avatar resetado!',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final av  = context.watch<AvatarService>();
    final gam = context.watch<GamificationService>();
    final badgeIds = gam.state.earnedBadgeIds;
    final displayItems = _getItems();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF), Colors.white],
            stops: [0, 0.4, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ─────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Voltar
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1E40AF)),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Meus Acessórios',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                    // Moedas
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kGold, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${gam.state.coins}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _kGoldDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Filter chips ─────────────────────────────────────────────
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _FilterChip(
                      label: '🌟 Todos',
                      selected: _filterCategory == null,
                      onTap: () =>
                          setState(() => _filterCategory = null),
                    ),
                    _FilterChip(
                      label: '🦱 Estilo',
                      selected: _filterCategory == AvatarCategory.style,
                      onTap: () => setState(
                          () => _filterCategory = AvatarCategory.style),
                    ),
                    _FilterChip(
                      label: '🎩 Chapéus',
                      selected: _filterCategory == AvatarCategory.hat,
                      onTap: () => setState(
                          () => _filterCategory = AvatarCategory.hat),
                    ),
                    _FilterChip(
                      label: '👕 Roupas',
                      selected:
                          _filterCategory == AvatarCategory.clothes,
                      onTap: () => setState(
                          () => _filterCategory = AvatarCategory.clothes),
                    ),
                    _FilterChip(
                      label: '🐾 Pets',
                      selected: _filterCategory == AvatarCategory.pet,
                      onTap: () => setState(
                          () => _filterCategory = AvatarCategory.pet),
                    ),
                    _FilterChip(
                      label: '✨ Efeitos',
                      selected:
                          _filterCategory == AvatarCategory.effect,
                      onTap: () => setState(
                          () => _filterCategory = AvatarCategory.effect),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // ── Grid ─────────────────────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: displayItems.length,
                  itemBuilder: (_, i) {
                    final item = displayItems[i];
                    final unlocked = av.isUnlocked(item, badgeIds);
                    final purchasable = av.isPurchasable(item, badgeIds);
                    final equipped = av.isEquipped(item.id);
                    return _GridCard(
                      item: item,
                      unlocked: unlocked,
                      purchasable: purchasable,
                      equipped: equipped,
                      onTap: () => _handleItemTap(item, av, gam),
                    ).animate(delay: (i * 30).ms).fadeIn(duration: 300.ms);
                  },
                ),
              ),
              // ── Botões de ação ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    // Resetar
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _resetAvatar(av),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                                color: _kGray.withOpacity(0.3), width: 1),
                          ),
                          child: const Center(
                            child: Text(
                              '🔄 Resetar Avatar',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kGrayDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Aplicar (volta para a tela anterior)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          AudioManager().playSFX(SFXType.correct);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kGreen, _kGreenDark],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: _kGreen.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '✅ Aplicar',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_kBlue, _kBlueDark])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kBlueDark : _kGray.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _kGrayDark,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRID CARD
// ─────────────────────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final AvatarItem item;
  final bool unlocked, purchasable, equipped;
  final VoidCallback onTap;

  const _GridCard({
    required this.item,
    required this.unlocked,
    required this.purchasable,
    required this.equipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !unlocked && !purchasable;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: equipped
                ? _kGreen
                : locked
                    ? Colors.transparent
                    : item.cardColor,
            width: equipped ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: equipped
                  ? _kGreen.withOpacity(0.3)
                  : Colors.black.withOpacity(0.07),
              blurRadius: equipped ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: locked
                            ? const Color(0xFFF3F4F6)
                            : item.cardColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          item.emoji,
                          style: TextStyle(
                            fontSize: 28,
                            color: locked
                                ? null
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 8.5,
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            // Equipado ✓
            if (equipped)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                      color: _kGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 11),
                ),
              ),
            // Bloqueado 🔒
            if (locked)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      color: _kGray.withOpacity(0.8),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.lock_rounded,
                      color: Colors.white, size: 11),
                ),
              ),
            // Preço
            if (purchasable)
              Positioned(
                bottom: 4,
                right: 0,
                left: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: _kGold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.cost}🪙',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ),
                ),
              ),
            // NOVO tag
            if (item.isNew && !locked)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: _kGold,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'NOVO',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF78350F),
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
