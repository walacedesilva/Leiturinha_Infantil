import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_colors.dart';
import '../../../../services/gamification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _ShopItem {
  final String id;
  final String emoji;
  final String label;
  final String description;
  final int price;
  final String category;

  const _ShopItem({
    required this.id,
    required this.emoji,
    required this.label,
    required this.description,
    required this.price,
    required this.category,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CATALOG
// ─────────────────────────────────────────────────────────────────────────────

const List<_ShopItem> _kItems = [
  // Chapéus
  _ShopItem(
    id: 'hat_coroa',
    emoji: '👑',
    label: 'Coroa Real',
    description: 'Para a realeza das letras!',
    price: 10,
    category: 'Chapéu',
  ),
  _ShopItem(
    id: 'hat_topo',
    emoji: '🎩',
    label: 'Cartola Mágica',
    description: 'Palavras saem de dentro dela!',
    price: 8,
    category: 'Chapéu',
  ),
  _ShopItem(
    id: 'hat_bone',
    emoji: '🧢',
    label: 'Boné Esportivo',
    description: 'Para o leitor atleta!',
    price: 5,
    category: 'Chapéu',
  ),
  _ShopItem(
    id: 'hat_cowboy',
    emoji: '🤠',
    label: 'Chapéu Cowboy',
    description: 'Yeehaw, vamos ler!',
    price: 7,
    category: 'Chapéu',
  ),
  // Personagens
  _ShopItem(
    id: 'char_robo',
    emoji: '🤖',
    label: 'Robozinho',
    description: 'Processa sílabas em nanossegundos!',
    price: 20,
    category: 'Personagem',
  ),
  _ShopItem(
    id: 'char_dino',
    emoji: '🦕',
    label: 'Dino Leitor',
    description: 'Lê desde a pré-história!',
    price: 15,
    category: 'Personagem',
  ),
  _ShopItem(
    id: 'char_unicorn',
    emoji: '🦄',
    label: 'Unicórnio',
    description: 'Mágico e cheio de letras!',
    price: 25,
    category: 'Personagem',
  ),
  _ShopItem(
    id: 'char_dragon',
    emoji: '🐉',
    label: 'Dragão',
    description: 'Sopra palavras em vez de fogo!',
    price: 30,
    category: 'Personagem',
  ),
  // Acessórios
  _ShopItem(
    id: 'acc_stars',
    emoji: '⭐',
    label: 'Halo de Estrelas',
    description: 'Brilhe como suas conquistas!',
    price: 12,
    category: 'Acessório',
  ),
  _ShopItem(
    id: 'acc_magic',
    emoji: '✨',
    label: 'Brilho Mágico',
    description: 'Você sempre brilha!',
    price: 8,
    category: 'Acessório',
  ),
  _ShopItem(
    id: 'acc_rainbow',
    emoji: '🌈',
    label: 'Arco-íris',
    description: 'Colorido como as vogais!',
    price: 10,
    category: 'Acessório',
  ),
  _ShopItem(
    id: 'acc_fire',
    emoji: '🔥',
    label: 'Chama',
    description: 'Está em chamas de tanto ler!',
    price: 6,
    category: 'Acessório',
  ),
];

const _kCategories = ['Todos', 'Chapéu', 'Personagem', 'Acessório'];
const _kOwnedKey   = 'shop_owned_items';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// Loja de recompensas — compra itens com moedas ganhas no jogo.
/// Navegação: AvatarPersonalizacaoScreen → [esta tela] → pop de volta
class LojaRecompensasScreen extends StatefulWidget {
  const LojaRecompensasScreen({super.key});

  @override
  State<LojaRecompensasScreen> createState() => _LojaRecompensasScreenState();
}

class _LojaRecompensasScreenState extends State<LojaRecompensasScreen> {
  Set<String> _owned  = {};
  int _activeCategory = 0; // index into _kCategories
  SharedPreferences? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOwned();
  }

  Future<void> _loadOwned() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kOwnedKey) ?? [];
    setState(() {
      _prefs = prefs;
      _owned = Set<String>.from(raw);
      _loading = false;
    });
  }

  Future<void> _saveOwned() async {
    await _prefs?.setStringList(_kOwnedKey, _owned.toList());
  }

  List<_ShopItem> get _filteredItems {
    if (_activeCategory == 0) return _kItems;
    final cat = _kCategories[_activeCategory];
    return _kItems.where((i) => i.category == cat).toList();
  }

  Future<void> _purchase(_ShopItem item) async {
    final gam = context.read<GamificationService>();
    final success = await gam.spendCoins(item.price);
    if (!success) {
      _showInsufficientCoins(item);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _owned.add(item.id));
    await _saveOwned();
    if (!mounted) return;
    _showPurchaseSuccess(item);
  }

  void _showInsufficientCoins(_ShopItem item) {
    showDialog(
      context: context,
      builder: (_) => _InsufficientDialog(item: item),
    );
  }

  void _showPurchaseSuccess(_ShopItem item) {
    showDialog(
      context: context,
      builder: (_) => _SuccessDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(coins: context.watch<GamificationService>().state.coins),
            const SizedBox(height: 8),
            _CategoryRow(
              active: _activeCategory,
              onSelect: (i) => setState(() => _activeCategory = i),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _filteredItems.length,
                  itemBuilder: (_, i) {
                    final item = _filteredItems[i];
                    final isOwned = _owned.contains(item.id);
                    final coins =
                        context.read<GamificationService>().state.coins;
                    return _ItemCard(
                      item: item,
                      isOwned: isOwned,
                      canAfford: coins >= item.price,
                      onAction: isOwned ? null : () => _purchase(item),
                      delay: Duration(milliseconds: 60 * i),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int coins;

  const _TopBar({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          MinTouchArea(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textDark),
          ),
          const Expanded(
            child: Text(
              '🛒 Loja de Recompensas',
              textAlign: TextAlign.center,
              style: AppTextStyles.tituloSmall,
            ),
          ),
          // Coin balance
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.atencao.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.atencao.withOpacity(0.7), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY ROW
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final int active;
  final ValueChanged<int> onSelect;

  const _CategoryRow({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isActive = i == active;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.principal
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.principal
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.principal.withOpacity(0.3),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
              child: Text(
                _kCategories[i],
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color:
                      isActive ? Colors.white : AppColors.textMid,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final _ShopItem item;
  final bool isOwned;
  final bool canAfford;
  final VoidCallback? onAction;
  final Duration delay;

  const _ItemCard({
    required this.item,
    required this.isOwned,
    required this.canAfford,
    required this.onAction,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOwned
              ? AppColors.sucesso.withOpacity(0.5)
              : Colors.grey.shade200,
          width: isOwned ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Emoji + owned badge ───────────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isOwned
                      ? AppColors.sucesso.withOpacity(0.12)
                      : AppColors.surfaceDim,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(item.emoji,
                      style: const TextStyle(fontSize: 38)),
                ),
              ),
              if (isOwned)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.sucesso,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Name ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── Action button ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: isOwned
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_outline,
                          size: 16, color: AppColors.sucesso),
                      label: const Text(
                        'Adquirido',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.sucesso,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.sucesso, width: 1.5),
                        shape: const StadiumBorder(),
                        padding: EdgeInsets.zero,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: canAfford ? onAction : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford
                            ? AppColors.principal
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: const StadiumBorder(),
                        padding: EdgeInsets.zero,
                        elevation: canAfford ? 3 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🪙',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${item.price}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: canAfford
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Comprar',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: canAfford
                                  ? Colors.white70
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay, duration: 300.ms)
        .scale(
          delay: delay,
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOGS
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final _ShopItem item;

  const _SuccessDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 56))
                .animate()
                .scale(curve: Curves.elasticOut, duration: 500.ms),
            const SizedBox(height: 12),
            Text(
              '${item.label} desbloqueado!',
              textAlign: TextAlign.center,
              style: AppTextStyles.tituloSmall
                  .copyWith(color: AppColors.principal),
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: AppTextStyles.corpoSmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sucesso,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Ótimo! 🎉',
                    style: AppTextStyles.botao),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsufficientDialog extends StatelessWidget {
  final _ShopItem item;

  const _InsufficientDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 50))
                .animate()
                .shake(duration: 500.ms),
            const SizedBox(height: 12),
            const Text(
              'Moedas insuficientes',
              textAlign: TextAlign.center,
              style: AppTextStyles.tituloSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Faltam moedas para comprar "${item.label}".\nContinue jogando para ganhar mais! 💪',
              textAlign: TextAlign.center,
              style: AppTextStyles.corpoSmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.principal,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Vou jogar mais! 🎮',
                    style: AppTextStyles.botao),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
