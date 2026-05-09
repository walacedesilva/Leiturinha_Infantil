import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_colors.dart';
import '../../../../services/gamification_service.dart';
import 'loja_recompensas_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kCharKey = 'avatar_char';
const _kHatKey  = 'avatar_hat';
const _kAccKey  = 'avatar_acc';

// Opções de personagem
const List<Map<String, String>> _kChars = [
  {'emoji': '👦', 'label': 'Lucas'},
  {'emoji': '👧', 'label': 'Ana'},
  {'emoji': '🧒', 'label': 'Bia'},
  {'emoji': '🧒‍♂️', 'label': 'Pedro'},
  {'emoji': '🦊', 'label': 'Raposa'},
  {'emoji': '🐼', 'label': 'Pandinha'},
  {'emoji': '🐸', 'label': 'Sapo'},
  {'emoji': '🦁', 'label': 'Leão'},
  {'emoji': '🤖', 'label': 'Robô'},
  {'emoji': '🦄', 'label': 'Unicórnio'},
  {'emoji': '🐉', 'label': 'Dragão'},
  {'emoji': '🧙', 'label': 'Mago'},
];

// Opções de chapéu
const List<Map<String, String>> _kHats = [
  {'emoji': '',   'label': 'Nenhum'},
  {'emoji': '👑', 'label': 'Coroa'},
  {'emoji': '🎩', 'label': 'Cartola'},
  {'emoji': '🧢', 'label': 'Boné'},
  {'emoji': '🎓', 'label': 'Formatura'},
  {'emoji': '⛑️', 'label': 'Capacete'},
  {'emoji': '🤠', 'label': 'Cowboy'},
  {'emoji': '🪖', 'label': 'Militar'},
];

// Opções de acessório
const List<Map<String, String>> _kAccs = [
  {'emoji': '',   'label': 'Nenhum'},
  {'emoji': '⭐', 'label': 'Estrela'},
  {'emoji': '🌈', 'label': 'Arco-íris'},
  {'emoji': '✨', 'label': 'Brilho'},
  {'emoji': '🔥', 'label': 'Chama'},
  {'emoji': '💎', 'label': 'Diamante'},
  {'emoji': '🍀', 'label': 'Trevo'},
  {'emoji': '⚡', 'label': 'Raio'},
];

const List<String> _kTabLabels = ['Personagem', 'Chapéu', 'Acessório'];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// Tela de personalização de avatar.
/// Permite escolher personagem, chapéu e acessório.
/// Navegação: Feedback → [esta tela] ↔ Loja de Recompensas
class AvatarPersonalizacaoScreen extends StatefulWidget {
  const AvatarPersonalizacaoScreen({super.key});

  @override
  State<AvatarPersonalizacaoScreen> createState() =>
      _AvatarPersonalizacaoScreenState();
}

class _AvatarPersonalizacaoScreenState
    extends State<AvatarPersonalizacaoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  String _char = '👦';
  String _hat  = '';
  String _acc  = '';

  SharedPreferences? _prefs;
  bool _loading = true;
  bool _saved   = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadPrefs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _char  = prefs.getString(_kCharKey) ?? '👦';
      _hat   = prefs.getString(_kHatKey)  ?? '';
      _acc   = prefs.getString(_kAccKey)  ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    await Future.wait([
      _prefs!.setString(_kCharKey, _char),
      _prefs!.setString(_kHatKey, _hat),
      _prefs!.setString(_kAccKey, _acc),
    ]);
    HapticFeedback.lightImpact();
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop();
  }

  void _openLoja() {
    Navigator.of(context).push(
      AppPageRoute(page: const LojaRecompensasScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _TopBar(coins: _coins(context), onLoja: _openLoja),
                  const SizedBox(height: 8),
                  _AvatarPreview(char: _char, hat: _hat, acc: _acc),
                  const SizedBox(height: 16),
                  _TabBar(controller: _tabCtrl),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _OptionGrid(
                          options: _kChars,
                          selected: _char,
                          onSelect: (v) =>
                              setState(() => _char = v),
                        ),
                        _OptionGrid(
                          options: _kHats,
                          selected: _hat,
                          onSelect: (v) =>
                              setState(() => _hat = v),
                        ),
                        _OptionGrid(
                          options: _kAccs,
                          selected: _acc,
                          onSelect: (v) =>
                              setState(() => _acc = v),
                        ),
                      ],
                    ),
                  ),
                  _SaveButton(saved: _saved, onTap: _save),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }

  int _coins(BuildContext context) {
    return context.watch<GamificationService>().state.coins;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int coins;
  final VoidCallback onLoja;

  const _TopBar({required this.coins, required this.onLoja});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          MinTouchArea(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textDark),
          ),
          const SizedBox(width: 8),
          // Coin badge — spec: yellow #FDE68A, 56×32, text #92400E ExtraBold 24px
          Container(
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 2),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Text(
              'Meu Avatar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: AppColors.textDark,
              ),
            ),
          ),
          // Loja button — spec: yellow #FBBF24, text #92400E, padding 12×24, radius 12
          GestureDetector(
            onTap: onLoja,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Loja',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR PREVIEW
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarPreview extends StatelessWidget {
  final String char;
  final String hat;
  final String acc;

  const _AvatarPreview(
      {required this.char, required this.hat, required this.acc});

  @override
  Widget build(BuildContext context) {
    // spec: circular 240×240, gradient #DBEAFE→#BFDBFE, white 8px border, shadow
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular gradient container
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
              ),
              border: Border.all(color: Colors.white, width: 8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x283B82F6),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Character
          Text(char, style: const TextStyle(fontSize: 80)),
          // Hat (top-center)
          if (hat.isNotEmpty)
            Positioned(
              top: 8,
              child: Text(hat, style: const TextStyle(fontSize: 42)),
            ),
          // Accessory (bottom-right)
          if (acc.isNotEmpty)
            Positioned(
              bottom: 14,
              right: 14,
              child: Text(acc, style: const TextStyle(fontSize: 32)),
            ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;

  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TabBar(
          controller: controller,
          labelStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMid,
          indicator: BoxDecoration(
            color: AppColors.principal,
            borderRadius: BorderRadius.circular(30),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: _kTabLabels
              .map((l) => Tab(text: l, height: 38))
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPTION GRID
// ─────────────────────────────────────────────────────────────────────────────

class _OptionGrid extends StatelessWidget {
  final List<Map<String, String>> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: options.length,
      itemBuilder: (_, i) {
        final opt = options[i];
        final isSelected = opt['emoji'] == selected;
        return _OptionTile(
          emoji: opt['emoji']!,
          label: opt['label']!,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(opt['emoji']!);
          },
          delay: Duration(milliseconds: 40 * i),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration delay;

  const _OptionTile({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF22C55E).withOpacity(0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF22C55E)
                : Colors.grey.shade200,
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withOpacity(0.30),
                    blurRadius: 10,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            emoji.isEmpty
                ? Icon(Icons.block_rounded,
                    size: 32, color: Colors.grey.shade400)
                : Text(emoji,
                    style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.principal
                    : AppColors.textMid,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 250.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 250.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;

  const _SaveButton({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // spec: full width, 56px, blue #3B82F6, ExtraBold 20px, radius 16, shadow
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: saved ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (saved
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF3B82F6))
                    .withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                saved ? '✅' : '✨',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Text(
                saved ? 'Salvo!' : 'Salvar Avatar',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}
