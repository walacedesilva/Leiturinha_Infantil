import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme_provider.dart';
import '../../../../core/app_themes.dart';
import '../../../../services/audio_manager.dart'; // lib/services/
import '../../data/word_bank.dart';
import '../../domain/game_logic.dart';
import 'game_screen.dart';

/// Tela de seleção de sílabas antes de entrar no jogo.
///
/// Fluxo:
///   MenuScreen → SyllableSelectorScreen → GameScreen
///
/// A criança (ou educador) marca quais sílabas da família farão parte
/// da sessão. O WordBank filtra palavras que usam apenas essas sílabas.
/// Mínimo de 2 sílabas para habilitar o botão "Começar".
class SyllableSelectorScreen extends StatefulWidget {
  final SyllabicFamily family;

  const SyllableSelectorScreen({super.key, required this.family});

  @override
  State<SyllableSelectorScreen> createState() => _SyllableSelectorScreenState();
}

class _SyllableSelectorScreenState extends State<SyllableSelectorScreen> {
  late List<String> _allSyllables;
  final Set<String> _selected = {};
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    _allSyllables = WordBank.getSyllablesOfFamily(widget.family);
    // Pré-seleciona todas as sílabas para facilitar o uso rápido
    _selected.addAll(_allSyllables);
  }

  // ── Validação ─────────────────────────────────────────────────────

  List<WordEntry> get _validWords =>
      WordBank.filterBySyllables(widget.family, _selected.toList());

  bool get _canStart => _selected.length >= 2 && _validWords.isNotEmpty;

  // ── Toque em sílaba ───────────────────────────────────────────────

  void _toggleSyllable(String syllable) {
    HapticFeedback.selectionClick();
    AudioManager().playSyllableInstant(syllable.toLowerCase());

    setState(() {
      if (_selected.contains(syllable)) {
        _selected.remove(syllable);
      } else {
        _selected.add(syllable);
      }
      _showWarning = !_canStart && _selected.isNotEmpty;
    });
  }

  // ── Iniciar sessão ────────────────────────────────────────────────

  void _startGame(BuildContext context) {
    if (!_canStart) {
      setState(() => _showWarning = true);
      HapticFeedback.vibrate();
      return;
    }

    final gameLogic = context.read<GameLogic>();
    // Inicializa com as palavras filtradas pelas sílabas escolhidas
    gameLogic.initWithFamilyAndSyllables(widget.family, _selected.toList());

    // Pré-carrega TTS para as sílabas da sessão
    AudioManager().preloadSyllables(_selected.map((s) => s.toLowerCase()).toList());

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const GameScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final tokens = theme.tokens;
    final color = Color(widget.family.colorValue);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.family.label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Instrução ───────────────────────────────────────
              Text(
                'Toque nas sílabas para a sessão:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 6),

              Text(
                'Mínimo 2 sílabas • Toque para ouvir o som',
                style: TextStyle(
                  fontSize: 14,
                  color: tokens.primary.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

              const SizedBox(height: 24),

              // ── Grid de chips ────────────────────────────────────
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _allSyllables.asMap().entries.map((e) {
                  final idx = e.key;
                  final syl = e.value;
                  final isSelected = _selected.contains(syl);
                  return _SyllableChip(
                    syllable: syl,
                    isSelected: isSelected,
                    familyColor: color,
                    tokens: tokens,
                    onTap: () => _toggleSyllable(syl),
                    animationDelay: Duration(milliseconds: 60 * idx),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Aviso quando seleção insuficiente ────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showWarning
                    ? Container(
                        key: const ValueKey('warning'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.info_outline,
                                color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Escolha mais uma sílaba para formar palavras!',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().shake(duration: 400.ms)
                    : const SizedBox.shrink(key: ValueKey('no-warning')),
              ),

              const Spacer(),

              // ── Contador de palavras disponíveis ─────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _canStart
                    ? Text(
                        '${_validWords.length} palavras disponíveis ✓',
                        key: ValueKey(_validWords.length),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: tokens.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),

              // ── Botão Começar ────────────────────────────────────
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _canStart ? color : Colors.grey.shade300,
                    foregroundColor:
                        _canStart ? Colors.white : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: _canStart ? 3 : 0,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text(
                    'Começar',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _startGame(context),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip individual de sílaba com animação de escala ao selecionar
// ─────────────────────────────────────────────────────────────────────────────

class _SyllableChip extends StatefulWidget {
  final String syllable;
  final bool isSelected;
  final Color familyColor;
  final AppThemeTokens tokens;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _SyllableChip({
    required this.syllable,
    required this.isSelected,
    required this.familyColor,
    required this.tokens,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_SyllableChip> createState() => _SyllableChipState();
}

class _SyllableChipState extends State<_SyllableChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected ? widget.familyColor : Colors.white;
    final fg = widget.isSelected ? Colors.white : widget.tokens.primary;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 72,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected
                  ? widget.familyColor
                  : widget.tokens.primary.withOpacity(0.3),
              width: widget.isSelected ? 2.5 : 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.familyColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                widget.syllable,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: fg,
                ),
              ),
              // Checkmark no canto superior direito
              if (widget.isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 13,
                      color: widget.familyColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate(delay: widget.animationDelay).fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}
