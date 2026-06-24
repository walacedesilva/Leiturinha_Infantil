import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_models.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../data/word_bank.dart';
import '../../domain/game_logic.dart';
import '../../../../services/speech_validator.dart';
import '../widgets/gamification_widgets.dart';
import '../widgets/mic_button.dart';
import 'session_summary_screen.dart';
import 'feedback_recompensas_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kSyllableColors = [
  Color(0xFFEF6C00), // laranja — sílaba 1
  Color(0xFF388E3C), // verde   — sílaba 2
  Color(0xFF1565C0), // azul    — sílaba 3
  Color(0xFF6A1B9A), // roxo    — sílaba 4
];

const _wordEmojis = <String, String>{
  'BALA': '🍬', 'BELO': '🌟', 'BICO': '🐦', 'BOLO': '🎂', 'BULE': '☕',
  'BOCA': '👄', 'BODE': '🐐', 'BOTA': '👢', 'BOIA': '🛟',
  'CAMA': '🛏️', 'CASA': '🏠', 'CALO': '🦵', 'COPO': '🥤', 'CUCA': '🧠',
  'DADO': '🎲', 'DEDO': '👆', 'DOCA': '⚓', 'DUNA': '🏜️', 'DINO': '🦕',
  'FACA': '🔪', 'FADA': '🧚', 'FIGO': '🍇', 'FOCA': '🦭', 'FULA': '💨',
  'GALO': '🐓', 'GATO': '🐱', 'GELO': '🧊', 'GOMA': '🔵', 'GULA': '😋',
  'JATO': '✈️', 'JOGO': '🎮', 'JUBA': '🦁',
  'LATA': '🥫', 'LEGO': '🧱', 'LIMA': '🍋', 'LONA': '🎪', 'LAMA': '💧',
  'MALA': '💼', 'MAPA': '🗺️', 'MICO': '🐒', 'MOLA': '🔩', 'MULA': '🐴',
  'NABO': '🥕', 'NETO': '👦',
  'PATO': '🐥', 'PELE': '🌟', 'PICO': '⛰️', 'POLO': '👕', 'PULA': '🏃',
  'RATO': '🐭', 'ROCA': '🌿', 'RODA': '⭕', 'RICO': '💰',
  'SALA': '🛋️', 'SELA': '🐴', 'SILO': '🏗️',
  'TACO': '🏑', 'TATU': '🦔', 'TELA': '📺', 'TIPO': '😎', 'TOCA': '🏠',
  'VACA': '🐄', 'VALE': '🌄', 'VELA': '🕯️', 'VIVO': '🎉',
  'XALE': '🧣',
  'ZERO': '0️⃣',
};

String _emojiFor(String word, String familyEmoji) =>
    _wordEmojis[word.toUpperCase()] ?? familyEmoji;

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DesafioDePronunciaScreen extends StatefulWidget {
  final SyllabicFamily family;

  const DesafioDePronunciaScreen({super.key, required this.family});

  @override
  State<DesafioDePronunciaScreen> createState() =>
      _DesafioDePronunciaScreenState();
}

class _DesafioDePronunciaScreenState extends State<DesafioDePronunciaScreen> {
  bool _rewardShown = false;
  bool _feedbackShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameLogic>().initWithFamilyDirect(widget.family);
      context
          .read<ProgressService>()
          .saveLastPlayedFamily(widget.family.key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Consumer2<GameLogic, ProgressService>(
          builder: (context, gameLogic, progress, _) {
            // Reward toast — only for non-success (full-screen feedback handles success)
            if (gameLogic.isValidated &&
                gameLogic.lastReward != null &&
                (gameLogic.lastReward!.hasReward ||
                    gameLogic.lastReward!.hasBadge) &&
                gameLogic.lastValidation?.isSuccess != true &&
                !_rewardShown) {
              _rewardShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) showRewardToast(context, gameLogic.lastReward!);
              });
            }

            // Full-screen feedback on successful validation
            if (gameLogic.isValidated &&
                gameLogic.lastValidation?.isSuccess == true &&
                !_feedbackShown) {
              _feedbackShown = true;
              // Style-guide: haptic feedback on success
              HapticFeedback.mediumImpact();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final gl = gameLogic;
                final gamSvc = context.read<GamificationService>();
                final nextIdx = gl.wordIndex + 1;
                String? nextWordPreview;
                if (nextIdx < widget.family.words.length) {
                  nextWordPreview =
                      widget.family.words[nextIdx].syllables.join('-');
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FeedbackRecompensasScreen(
                      word: gl.currentWord,
                      syllables: gl.targetSyllables,
                      validation: gl.lastValidation!,
                      reward: gl.lastReward ??
                          const RewardEvent(
                              coins: 0, xp: 0, label: 'Palavra concluída'),
                      playerState: gamSvc.state,
                      nextWordPreview: nextWordPreview,
                      onNextWord: () {
                        Navigator.of(context).pop();
                        gl.goToNextWord();
                      },
                      onRepeat: () {
                        Navigator.of(context).pop();
                        gl.startSpeechValidation();
                      },
                      onMenu: () {
                        Navigator.of(context)
                            .popUntil((r) => r.isFirst);
                      },
                    ),
                  ),
                );
              });
            }

            if (!gameLogic.isValidated) {
              _rewardShown = false;
              _feedbackShown = false;
            }

            // Família concluída → navega para resumo
            if (gameLogic.isFamilyDone) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final session = gameLogic.lastSession;
                if (session == null) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SessionSummaryScreen(
                      session: session,
                      coinsEarned: gameLogic.sessionCoins,
                      xpEarned: gameLogic.sessionXp,
                      newBadgeIds: gameLogic.sessionBadges,
                      nextChallenge: 'Na próxima aventura, vamos explorar novas palavras! 🚀',
                      onContinue: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              });
              return const Center(child: CircularProgressIndicator());
            }

            // Carregando
            if (gameLogic.currentWord.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // ── Barra de progresso segmentada ───────────────────────
                _ProgressHeader(
                  family: widget.family,
                  wordIndex: gameLogic.wordIndex,
                  totalWords: gameLogic.totalWords,
                  onBack: () => Navigator.of(context).pop(),
                ),

                // ── Conteúdo rolável ─────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── Card da palavra + imagem ──────────────────────
                        _WordCard(
                          word: gameLogic.currentWord,
                          syllables: gameLogic.targetSyllables,
                          family: widget.family,
                        ),

                        const SizedBox(height: 16),

                        // ── Grid de sílabas com progresso ────────────────
                        _SyllableCheckGrid(
                          family: widget.family,
                          completedWords:
                              progress.getCompletedWords(widget.family.key),
                        ),

                        const SizedBox(height: 20),

                        // ── Botão de microfone com waveform ──────────────
                        _MicSection(
                          isRecording: gameLogic.isValidating,
                          isDisabled: !gameLogic.canRetryValidation &&
                              !gameLogic.isValidating,
                          partialText: gameLogic.isValidating
                              ? gameLogic.partialTranscript
                              : null,
                          onTap: gameLogic.isValidating
                              ? null
                              : gameLogic.startSpeechValidation,
                          onCancel: gameLogic.isValidating
                              ? gameLogic.cancelSpeechValidation
                              : null,
                        ),

                        const SizedBox(height: 12),

                        // ── Card de feedback pós-validação (non-success only)
                        if (gameLogic.isValidated &&
                            gameLogic.lastValidation != null &&
                            !gameLogic.lastValidation!.isSuccess)
                          _ValidationArea(
                            key: const ValueKey('feedback'),
                            result: gameLogic.lastValidation!,
                            canRetry: gameLogic.canRetryValidation,
                            onRetry: gameLogic.startSpeechValidation,
                            onAdvance: () => gameLogic.goToNextWord(),
                          ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ── Rodapé: tentativas + ouvir modelo ────────────────────
                _BottomBar(
                  attempts: gameLogic.validationAttempts,
                  maxAttempts: gameLogic.maxValidationAttempts,
                  onListen: gameLogic.playFormedWord,
                  onListenSlow: gameLogic.playFormedWordSlow,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final SyllabicFamily family;
  final int wordIndex;
  final int totalWords;
  final VoidCallback onBack;

  const _ProgressHeader({
    required this.family,
    required this.wordIndex,
    required this.totalWords,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalWords == 0 ? 0 : (wordIndex * 100 ~/ totalWords);
    // Segmentos de cor conforme spec: vermelho, laranja, amarelo, verde-claro, verde, azul
    const segColors = [
      Color(0xFFEF4444),
      Color(0xFFF97316),
      Color(0xFFFACC15),
      Color(0xFF84CC16),
      Color(0xFF22C55E),
      Color(0xFF3B82F6),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                color: const Color(0xFF37474F),
                onPressed: onBack,
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Fundo da barra
                      Container(
                        height: 16,
                        color: const Color(0xFFE5E7EB),
                      ),
                      // Fill segmentado
                      FractionallySizedBox(
                        widthFactor: (pct / 100).clamp(0.0, 1.0),
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: segColors,
                            ),
                          ),
                        ),
                      ),
                      // Texto da porcentagem
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '$pct%',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color(0x66000000),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded,
                    size: 20, color: Color(0xFF37474F)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD CARD
// ─────────────────────────────────────────────────────────────────────────────

class _WordCard extends StatelessWidget {
  final String word;
  final List<String> syllables;
  final SyllabicFamily family;

  const _WordCard({
    required this.word,
    required this.syllables,
    required this.family,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = _emojiFor(word, '📖');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Ilustração da palavra ────────────────────────────────
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Color(family.colorValue).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 62)),
            ),
          )
              .animate(key: ValueKey(word))
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // ── Sílabas da palavra ────────────────────────────────────
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              for (int i = 0; i < syllables.length; i++) ...[
                _SyllablePill(
                  syllable: syllables[i],
                  color: _kSyllableColors[i % _kSyllableColors.length],
                  animDelay: Duration(milliseconds: 80 * i),
                ),
                if (i < syllables.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    ).animate(key: ValueKey(word)).fadeIn(duration: 350.ms);
  }
}

class _SyllablePill extends StatelessWidget {
  final String syllable;
  final Color color;
  final Duration animDelay;

  const _SyllablePill({
    required this.syllable,
    required this.color,
    required this.animDelay,
  });

  // Gradientes spec: sílaba 1 = laranja, sílaba 2 = verde, sílaba 3 = azul, sílaba 4 = roxo
  static const _kSylGradients = <List<Color>>[
    [Color(0xFFFB923C), Color(0xFFF97316)],
    [Color(0xFF4ADE80), Color(0xFF22C55E)],
    [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    [Color(0xFFC084FC), Color(0xFFA855F7)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradColors =
        _kSylGradients[animDelay.inMilliseconds ~/ 80 % _kSylGradients.length];

    return Container(
      width: 140,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradColors.last.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          syllable,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    )
        .animate(delay: animDelay)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
          duration: 380.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 250.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SYLLABLE CHECK GRID
// ─────────────────────────────────────────────────────────────────────────────

class _SyllableCheckGrid extends StatelessWidget {
  final SyllabicFamily family;
  final List<String> completedWords;

  const _SyllableCheckGrid({
    required this.family,
    required this.completedWords,
  });

  Set<String> _practicedSyllables() {
    final practiced = <String>{};
    for (final entry in family.words) {
      if (completedWords.contains(entry.word)) {
        practiced.addAll(entry.syllables);
      }
    }
    return practiced;
  }

  @override
  Widget build(BuildContext context) {
    final syllables = family.canonicalSyllables;
    final practiced = _practicedSyllables();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: syllables.asMap().entries.map((entry) {
          final idx = entry.key;
          final syl = entry.value;
          final done = practiced.contains(syl);
          return _SyllableCheckChip(
            syllable: syl,
            checked: done,
            animDelay: Duration(milliseconds: 50 * idx),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 150.ms);
  }
}

class _SyllableCheckChip extends StatelessWidget {
  final String syllable;
  final bool checked;
  final Duration animDelay;

  const _SyllableCheckChip({
    required this.syllable,
    required this.checked,
    required this.animDelay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: checked ? const Color(0xFFDCFCE7) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: checked ? const Color(0xFF22C55E) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (checked)
            const Icon(Icons.check_rounded,
                size: 14, color: Color(0xFF22C55E)),
          if (checked) const SizedBox(width: 4),
          Text(
            syllable,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: checked
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    ).animate(delay: animDelay).fadeIn(duration: 300.ms).slideX(begin: 0.1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WAVEFORM PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final double animValue;
  final bool active;
  final bool mirrorX;
  final List<Color> barColors;

  const _WaveformPainter({
    required this.animValue,
    required this.active,
    required this.mirrorX,
    required this.barColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 12;
    final barW = (size.width - (barCount - 1) * 3) / barCount;
    final rnd = math.Random(42); // seeded for consistent shape
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final idxF = mirrorX ? (barCount - 1 - i) : i;
      // Base shape: outer bars are short, center bars are tall
      final centerBias = 1.0 - (idxF - barCount / 2).abs() / (barCount / 2);
      final baseH = size.height * 0.15 + centerBias * size.height * 0.45;
      final noise = rnd.nextDouble() * size.height * 0.15;

      double h;
      if (active) {
        final wave = math.sin(animValue * 2 * math.pi + idxF * 0.6) * 0.5 + 0.5;
        h = (baseH + noise + wave * size.height * 0.30).clamp(4.0, size.height);
      } else {
        h = (baseH * 0.3).clamp(4.0, size.height * 0.35);
      }

      final x = i * (barW + 3) + barW / 2;
      final top = (size.height - h) / 2;

      // Color: cycle through barColors based on position
      final colorIdx = (idxF * barColors.length / barCount).floor();
      paint.color = barColors[colorIdx % barColors.length]
          .withOpacity(active ? 0.85 : 0.35);
      paint.strokeWidth = barW;
      canvas.drawLine(Offset(x, top), Offset(x, top + h), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.animValue != animValue || old.active != active;
}

// ─────────────────────────────────────────────────────────────────────────────
// MIC DISPLAY STATE
// ─────────────────────────────────────────────────────────────────────────────

enum _MicDisplayState { ready, pressing, recording, processing, disabled }

// ─────────────────────────────────────────────────────────────────────────────
// MIC SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _MicSection extends StatefulWidget {
  final bool isRecording;
  final bool isDisabled;
  final String? partialText;
  final Future<void> Function()? onTap;
  final Future<void> Function()? onCancel;

  const _MicSection({
    required this.isRecording,
    required this.isDisabled,
    required this.partialText,
    required this.onTap,
    required this.onCancel,
  });

  @override
  State<_MicSection> createState() => _MicSectionState();
}

class _MicSectionState extends State<_MicSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  _MicDisplayState _displayState = _MicDisplayState.ready;
  Timer? _recordingTimer;
  int _secondsLeft = 5;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _syncState();
  }

  @override
  void didUpdateWidget(_MicSection old) {
    super.didUpdateWidget(old);
    _syncState();
  }

  void _syncState() {
    if (widget.isDisabled) {
      _displayState = _MicDisplayState.disabled;
      _cancelTimer();
    } else if (widget.isRecording) {
      if (_displayState != _MicDisplayState.recording) {
        _displayState = _MicDisplayState.recording;
        _startCountdown();
      }
    } else {
      _cancelTimer();
      if (_displayState == _MicDisplayState.recording) {
        // Brief processing state after recording stops
        setState(() => _displayState = _MicDisplayState.processing);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _displayState == _MicDisplayState.processing) {
            setState(() => _displayState = _MicDisplayState.ready);
          }
        });
      } else if (_displayState != _MicDisplayState.pressing) {
        _displayState = _MicDisplayState.ready;
      }
    }
  }

  void _startCountdown() {
    _cancelTimer();
    _secondsLeft = 5;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _secondsLeft = (_secondsLeft - 1).clamp(0, 5);
      });
      if (_secondsLeft == 0) t.cancel();
    });
  }

  void _cancelTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _secondsLeft = 5;
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const leftColors = [
      Color(0xFFEF6C00),
      Color(0xFFF57F17),
      Color(0xFFE53935),
      Color(0xFFD32F2F),
    ];
    const rightColors = [
      Color(0xFFE53935),
      Color(0xFF7B1FA2),
      Color(0xFF1565C0),
      Color(0xFF0288D1),
    ];

    return Column(
      children: [
        // Partial transcript bubble
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: (widget.partialText != null &&
                  widget.partialText!.isNotEmpty)
              ? Padding(
                  key: ValueKey(widget.partialText),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFF8F00), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.graphic_eq_rounded,
                            size: 16, color: Color(0xFFEF6C00)),
                        const SizedBox(width: 6),
                        Text(
                          '"${widget.partialText}"',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFBF360C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Recording timer badge
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _displayState == _MicDisplayState.recording
              ? Padding(
                  key: const ValueKey('timer'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            size: 10, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'FALE AGORA! 0:0$_secondsLeft',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .fadeIn(begin: 0.6, duration: 600.ms),
                )
              : const SizedBox(key: ValueKey('no-timer'), height: 0),
        ),

        // Waveform + mic button row
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (context, _) {
            final isActive = _displayState == _MicDisplayState.recording;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left waveform
                SizedBox(
                  width: 80,
                  height: 56,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      animValue: _waveCtrl.value,
                      active: isActive,
                      mirrorX: false,
                      barColors: leftColors,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Big mic button
                _BigMicButton(
                  displayState: _displayState,
                  pulseAnim: _waveCtrl,
                  onTapDown: () {
                    if (_displayState == _MicDisplayState.ready) {
                      setState(() => _displayState = _MicDisplayState.pressing);
                    }
                  },
                  onTapUp: () {
                    if (_displayState == _MicDisplayState.pressing) {
                      setState(() => _displayState = _MicDisplayState.ready);
                    }
                  },
                  onTap: widget.onTap,
                  onCancel: widget.onCancel,
                ),

                const SizedBox(width: 16),

                // Right waveform
                SizedBox(
                  width: 80,
                  height: 56,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      animValue: _waveCtrl.value,
                      active: isActive,
                      mirrorX: true,
                      barColors: rightColors,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Processing label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _displayState == _MicDisplayState.processing
              ? Padding(
                  key: const ValueKey('proc'),
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analisando...',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(key: ValueKey('no-proc')),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BIG MIC BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _BigMicButton extends StatelessWidget {
  final _MicDisplayState displayState;
  final AnimationController pulseAnim;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final Future<void> Function()? onTap;
  final Future<void> Function()? onCancel;

  const _BigMicButton({
    required this.displayState,
    required this.pulseAnim,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    const size = 160.0;
    final isRecording = displayState == _MicDisplayState.recording;
    final isDisabled = displayState == _MicDisplayState.disabled;
    final isPressing = displayState == _MicDisplayState.pressing;
    final isProcessing = displayState == _MicDisplayState.processing;

    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      onTap: () {
        HapticFeedback.mediumImpact();
        if (isRecording) {
          onCancel?.call();
        } else if (!isDisabled && !isProcessing) {
          onTap?.call();
        }
      },
      child: AnimatedBuilder(
        animation: pulseAnim,
        builder: (context, child) {
          final scale = isPressing ? 0.93 : 1.0;
          final glowRadius = isRecording ? 8.0 + pulseAnim.value * 18.0 : 8.0;
          final glowOpacity = isRecording ? 0.45 - pulseAnim.value * 0.35 : 0.25;

          // Concentric expanding rings during recording
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: size + 48,
              height: size + 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer expanding rings (recording only)
                  if (isRecording) ...[
                    for (int i = 0; i < 3; i++)
                      AnimatedBuilder(
                        animation: pulseAnim,
                        builder: (_, __) {
                          final offset = (i / 3.0);
                          final phase = (pulseAnim.value + offset) % 1.0;
                          final ringSize = size + 16 + phase * 48;
                          final opacity = (1.0 - phase) * 0.25;
                          return Container(
                            width: ringSize,
                            height: ringSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEF4444)
                                    .withOpacity(opacity.clamp(0.0, 1.0)),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                  ],

                  // Main circle
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 8),
                      gradient: isDisabled
                          ? const LinearGradient(
                              colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)],
                            )
                          : isProcessing
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                                )
                              : isRecording
                                  ? const RadialGradient(
                                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                    )
                                  : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFDBA74),
                                        Color(0xFFF97316),
                                        Color(0xFFFB923C),
                                      ],
                                    ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDisabled
                                  ? const Color(0xFF9CA3AF)
                                  : isRecording
                                      ? const Color(0xFFEF4444)
                                      : isProcessing
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFFF97316))
                              .withOpacity((glowOpacity + 0.15).clamp(0.0, 1.0)),
                          blurRadius: glowRadius * 3,
                          spreadRadius: isRecording ? glowRadius * 0.5 : 4,
                        ),
                      ],
                    ),
                    child: isProcessing
                        ? const Center(
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 4,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isRecording
                                    ? Icons.stop_rounded
                                    : isDisabled
                                        ? Icons.mic_off_rounded
                                        : Icons.mic_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isDisabled
                                    ? 'ESGOTADO'
                                    : isRecording
                                        ? 'PARAR'
                                        : 'TOQUE\nPARA FALAR',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: isRecording || isDisabled || isProcessing ? 1.0 : 1.04,
          duration: 1100.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VALIDATION AREA
// ─────────────────────────────────────────────────────────────────────────────

class _ValidationArea extends StatelessWidget {
  final ValidationResult result;
  final bool canRetry;
  final Future<void> Function() onRetry;
  final Future<void> Function() onAdvance;

  const _ValidationArea({
    super.key,
    required this.result,
    required this.canRetry,
    required this.onRetry,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final data = _buildFeedbackData(result, canRetry);

    return ValidationFeedbackCard(
      data: data,
      onRetry: () => onRetry(),
      onAdvance: () => onAdvance(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int attempts;
  final int maxAttempts;
  final Future<void> Function() onListen;
  final Future<void> Function() onListenSlow;

  const _BottomBar({
    required this.attempts,
    required this.maxAttempts,
    required this.onListen,
    required this.onListenSlow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECECEC), width: 1)),
      ),
      child: Row(
        children: [
          // Attempt counter badge — 48×48px yellow circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: attempts >= maxAttempts
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(
                color: attempts >= maxAttempts
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$attempts/$maxAttempts',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: attempts >= maxAttempts
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFB45309),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Ouvir devagar button — 🐌 #FDE68A
          Flexible(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onListenSlow();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🐌', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Devagar',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF92400E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Ouvir modelo button — 🔊 #DBEAFE
          Flexible(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onListen();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up_rounded,
                        size: 18, color: Color(0xFF3B82F6)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Ouvir',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1E40AF),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEEDBACK DATA BUILDER (mirrors game_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

ValidationFeedbackData _buildFeedbackData(ValidationResult r, bool canRetry) {
  // ── Soletração detectada → feedback pedagógico específico ──────────
  if (r.spellingType != SpellingType.none) {
    return switch (r.spellingType) {
      SpellingType.letterSpelling => ValidationFeedbackData(
          emoji: '🔤',
          title: 'Soletrando!',
          message: r.spellingExplanation,
          confidence: 0.0,
          backgroundColor: const Color(0xFFFFF3E0),
          borderColor: Colors.deepOrange,
          titleColor: Colors.deepOrange,
          showRetry: canRetry,
          nextAction: 'retry',
          advanceLabel: 'Pular',
        ),
      SpellingType.separatedLetters => ValidationFeedbackData(
          emoji: '🔗',
          title: 'Junte as Letras!',
          message: r.spellingExplanation,
          confidence: 0.0,
          backgroundColor: const Color(0xFFFFF9E6),
          borderColor: Colors.amber,
          titleColor: Colors.orange,
          showRetry: canRetry,
          nextAction: 'retry',
          advanceLabel: 'Pular',
        ),
      SpellingType.supportVowel => ValidationFeedbackData(
          emoji: '👄',
          title: 'Quase Lá!',
          message: r.spellingExplanation,
          confidence: 0.0,
          backgroundColor: const Color(0xFFFFF3E0),
          borderColor: Colors.orange,
          titleColor: Colors.orange,
          showRetry: canRetry,
          nextAction: 'retry',
          advanceLabel: 'Pular',
        ),
      SpellingType.none => ValidationFeedbackData(
          emoji: '🔄',
          title: 'Tente Mais Uma Vez',
          message: r.feedbackMessage,
          confidence: r.confidence,
          backgroundColor: const Color(0xFFFFF3F3),
          borderColor: Colors.deepOrange,
          titleColor: Colors.deepOrange,
          showRetry: canRetry,
          nextAction: 'retry',
          advanceLabel: 'Pular',
        ),
    };
  }

  return switch (r.status) {
    ValidationStatus.excellent => ValidationFeedbackData(
        emoji: '🌟',
        title: 'Excelente!',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFE8F8E8),
        borderColor: Colors.green,
        titleColor: Colors.green,
        showRetry: false,
        nextAction: 'advance',
        advanceLabel: 'Próxima Palavra!',
      ),
    ValidationStatus.almostThere => ValidationFeedbackData(
        emoji: '👍',
        title: 'Quase Lá!',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFFFF9E6),
        borderColor: Colors.amber,
        titleColor: Colors.orange,
        showRetry: canRetry,
        nextAction: 'advance',
        advanceLabel: 'Continuar',
      ),
    ValidationStatus.tryAgain => ValidationFeedbackData(
        emoji: '🔄',
        title: 'Tente Mais Uma Vez',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFFFF3F3),
        borderColor: Colors.deepOrange,
        titleColor: Colors.deepOrange,
        showRetry: canRetry,
        nextAction: 'retry',
        advanceLabel: 'Pular',
      ),
    ValidationStatus.listenRepeat => ValidationFeedbackData(
        emoji: '🎧',
        title: 'Vamos Ouvir Juntos',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFEFF5FF),
        borderColor: Colors.blueAccent,
        titleColor: Colors.blueAccent,
        showRetry: canRetry,
        nextAction: 'reinforce',
        advanceLabel: 'Próxima Palavra',
      ),
  };
}
