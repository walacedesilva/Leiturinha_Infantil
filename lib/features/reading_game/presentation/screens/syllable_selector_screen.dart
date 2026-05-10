import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme_provider.dart';
import '../../../../core/app_themes.dart';
import '../../../../services/audio_manager.dart'; // lib/services/
import '../../data/word_bank.dart';
import '../../domain/game_logic.dart';
import 'syllable_crane_screen.dart';

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

  // ── Estado de combinação com família secundária ───────────────────────────
  bool _combineMode = false;
  SyllabicFamily? _secondaryFamily;
  final Set<String> _selectedSecondary = {};
  List<String> _secondarySyllables = [];

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

  List<WordEntry> get _validWordsDual => WordBank.filterByDualFamilies(
        widget.family,
        _selected.toList(),
        _combineMode ? _secondaryFamily : null,
        _combineMode ? _selectedSecondary.toList() : const [],
      );

  bool get _canStart {
    if (_combineMode && _secondaryFamily != null) {
      return _selected.isNotEmpty &&
          _selectedSecondary.isNotEmpty &&
          _validWordsDual.isNotEmpty;
    }
    return _selected.length >= 2 && _validWords.isNotEmpty;
  }

  // ── Toque em sílaba primária ─────────────────────────────────────────────────────

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

  // ── Combinar com família secundária ──────────────────────────────────────────

  void _toggleCombineMode() {
    setState(() {
      _combineMode = !_combineMode;
      if (_combineMode && _secondaryFamily == null) {
        _pickSecondaryFamily(
          WordBank.families.firstWhere((f) => f.key != widget.family.key),
        );
      }
      _showWarning = !_canStart && _selected.isNotEmpty;
    });
  }

  void _pickSecondaryFamily(SyllabicFamily family) {
    setState(() {
      _secondaryFamily = family;
      _secondarySyllables = family.canonicalSyllables;
      _selectedSecondary
        ..clear()
        ..addAll(_secondarySyllables);
      _showWarning = !_canStart && _selected.isNotEmpty;
    });
  }

  void _toggleSecondarySyllable(String syllable) {
    HapticFeedback.selectionClick();
    AudioManager().playSyllableInstant(syllable.toLowerCase());
    setState(() {
      if (_selectedSecondary.contains(syllable)) {
        _selectedSecondary.remove(syllable);
      } else {
        _selectedSecondary.add(syllable);
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

    // Modo família única: expande as sílabas ativas para incluir as sílabas
    // estruturais das palavras (ex: ao selecionar BA, LA de BALA entra
    // automaticamente). O seletor exibe apenas as canônicas ao usuário.
    //
    // Modo combinação: usa as sílabas exatamente como selecionadas, sem expansão.
    // filterByDualFamilies filtrará apenas palavras cujas sílabas pertencem
    // exclusivamente às famílias envolvidas (sem sílabas de terceiras famílias).
    Set<String> _expand(SyllabicFamily fam, List<String> canonical) {
      final expanded = <String>{...canonical};
      for (final w in fam.words) {
        final hasFamilySyllable =
            w.syllables.any((s) => canonical.contains(s));
        if (hasFamilySyllable) expanded.addAll(w.syllables);
      }
      return expanded;
    }

    final List<String> expandedPrimary;
    final List<String> expandedSecondary;

    if (_combineMode && _secondaryFamily != null) {
      // Combinação: sem expansão — garante pool apenas com sílabas das famílias ativas
      expandedPrimary = _selected.toList();
      expandedSecondary = _selectedSecondary.toList();
    } else {
      // Família única: expande para incluir sílabas secundárias das palavras
      expandedPrimary = _expand(widget.family, _selected.toList()).toList();
      expandedSecondary = const [];
    }

    final config = DualFamilyConfig(
      primary: widget.family,
      activePrimary: expandedPrimary,
      secondary: _combineMode ? _secondaryFamily : null,
      activeSecondary: expandedSecondary,
    );
    gameLogic.initWithDualFamilies(config);
    AudioManager().preloadSyllables(
      config.allActiveSyllables.map((s) => s.toLowerCase()).toList(),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SyllableCraneScreen(),
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
      // Botão fixo na base — flutua acima do scroll
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _canStart
                    ? Text(
                        '${(_combineMode ? _validWordsDual : _validWords).length} palavras disponíveis ✓',
                        key: ValueKey(
                            (_combineMode ? _validWordsDual : _validWords)
                                .length),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(widget.family.colorValue),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canStart
                        ? Color(widget.family.colorValue)
                        : Colors.grey.shade300,
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
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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

              const SizedBox(height: 16),

              // ── Combinação com família secundária ───────────────────────────
              _CombineSection(
                primaryKey: widget.family.key,
                combineMode: _combineMode,
                secondaryFamily: _secondaryFamily,
                secondarySyllables: _secondarySyllables,
                selectedSecondary: _selectedSecondary,
                tokens: tokens,
                onToggle: _toggleCombineMode,
                onFamilyPicked: _pickSecondaryFamily,
                onSyllableToggled: _toggleSecondarySyllable,
              ),

              const SizedBox(height: 16),

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
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _combineMode
                                    ? 'Selecione sílabas em ambas as famílias!'
                                    : 'Escolha mais uma sílaba para formar palavras!',
                                style: const TextStyle(
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seção de combinação com família secundária
// ─────────────────────────────────────────────────────────────────────────────

class _CombineSection extends StatelessWidget {
  final String primaryKey;
  final bool combineMode;
  final SyllabicFamily? secondaryFamily;
  final List<String> secondarySyllables;
  final Set<String> selectedSecondary;
  final AppThemeTokens tokens;
  final VoidCallback onToggle;
  final ValueChanged<SyllabicFamily> onFamilyPicked;
  final ValueChanged<String> onSyllableToggled;

  const _CombineSection({
    required this.primaryKey,
    required this.combineMode,
    required this.secondaryFamily,
    required this.secondarySyllables,
    required this.selectedSecondary,
    required this.tokens,
    required this.onToggle,
    required this.onFamilyPicked,
    required this.onSyllableToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle row
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: combineMode
                  ? tokens.primary.withOpacity(0.1)
                  : tokens.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tokens.primary.withOpacity(combineMode ? 0.35 : 0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  combineMode
                      ? Icons.merge_type_rounded
                      : Icons.add_circle_outline_rounded,
                  color: tokens.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Combinar com outra família',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.primary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: combineMode,
                  onChanged: (_) => onToggle(),
                  activeColor: tokens.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),

        // Picker expandido
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: combineMode
              ? _SecondaryFamilyPicker(
                  primaryKey: primaryKey,
                  secondaryFamily: secondaryFamily,
                  secondarySyllables: secondarySyllables,
                  selectedSecondary: selectedSecondary,
                  tokens: tokens,
                  onFamilyPicked: onFamilyPicked,
                  onSyllableToggled: onSyllableToggled,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SecondaryFamilyPicker extends StatelessWidget {
  final String primaryKey;
  final SyllabicFamily? secondaryFamily;
  final List<String> secondarySyllables;
  final Set<String> selectedSecondary;
  final AppThemeTokens tokens;
  final ValueChanged<SyllabicFamily> onFamilyPicked;
  final ValueChanged<String> onSyllableToggled;

  const _SecondaryFamilyPicker({
    required this.primaryKey,
    required this.secondaryFamily,
    required this.secondarySyllables,
    required this.selectedSecondary,
    required this.tokens,
    required this.onFamilyPicked,
    required this.onSyllableToggled,
  });

  @override
  Widget build(BuildContext context) {
    final otherFamilies =
        WordBank.families.where((f) => f.key != primaryKey).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Família 2:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: tokens.primary.withOpacity(0.7),
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),

          // Selector horizontal de família
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: otherFamilies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final fam = otherFamilies[i];
                final isChosen = secondaryFamily?.key == fam.key;
                final col = Color(fam.colorValue);
                return GestureDetector(
                  onTap: () => onFamilyPicked(fam),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isChosen ? col : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isChosen ? col : col.withOpacity(0.45),
                        width: isChosen ? 2.5 : 1.5,
                      ),
                      boxShadow: isChosen
                          ? [
                              BoxShadow(
                                color: col.withOpacity(0.32),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        fam.key,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: isChosen ? Colors.white : col,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sílabas canônicas da família escolhida
          if (secondaryFamily != null) ...[
            const SizedBox(height: 12),
            Text(
              'Sílabas de ${secondaryFamily!.key}:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(secondaryFamily!.colorValue),
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: secondarySyllables.asMap().entries.map((e) {
                final syl = e.value;
                return _SyllableChip(
                  syllable: syl,
                  isSelected: selectedSecondary.contains(syl),
                  familyColor: Color(secondaryFamily!.colorValue),
                  tokens: tokens,
                  onTap: () => onSyllableToggled(syl),
                  animationDelay: Duration(milliseconds: 50 * e.key),
                );
              }).toList(),
            ),
          ],
        ],
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
