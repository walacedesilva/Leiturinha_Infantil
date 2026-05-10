import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../services/audio_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────

const _kPink     = Color(0xFFEC4899);
const _kCyan     = Color(0xFF06B6D4);
const _kGold     = Color(0xFFFBBF24);
const _kGreen    = Color(0xFF22C55E);
const _kDark     = Color(0xFF0C1445);
const _kPurple   = Color(0xFF4F46E5);

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────

class _DanceRound {
  /// Word shown with syllable separators, e.g. "ca-BE-lo"
  final String displayWord;

  /// Plain word, e.g. "cabelo"
  final String plainWord;

  /// Index of the stressed syllable (0-based)
  final int stressedIndex;

  /// All syllables split, e.g. ["ca", "BE", "lo"]
  final List<String> syllables;

  final String emoji;

  const _DanceRound({
    required this.displayWord,
    required this.plainWord,
    required this.stressedIndex,
    required this.syllables,
    required this.emoji,
  });
}

const _kRounds = <_DanceRound>[
  _DanceRound(
    displayWord: 'ca-BE-lo',
    plainWord: 'cabelo',
    stressedIndex: 1,
    syllables: ['ca', 'BE', 'lo'],
    emoji: '💇',
  ),
  _DanceRound(
    displayWord: 'ca-SA',
    plainWord: 'casa',
    stressedIndex: 0,
    syllables: ['CA', 'sa'],
    emoji: '🏠',
  ),
  _DanceRound(
    displayWord: 'me-SA',
    plainWord: 'mesa',
    stressedIndex: 0,
    syllables: ['ME', 'sa'],
    emoji: '🪑',
  ),
  _DanceRound(
    displayWord: 'ma-CA-co',
    plainWord: 'macaco',
    stressedIndex: 1,
    syllables: ['ma', 'CA', 'co'],
    emoji: '🐒',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SyllableDanceScreen extends StatefulWidget {
  const SyllableDanceScreen({super.key});

  @override
  State<SyllableDanceScreen> createState() => _SyllableDanceScreenState();
}

class _SyllableDanceScreenState extends State<SyllableDanceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _foxCtrl;
  late final AnimationController _notesCtrl;
  late final AnimationController _confettiCtrl;

  int _roundIndex = 0;
  int? _tappedIndex;   // which syllable was tapped
  bool _isCorrect = false;
  bool _showFeedback = false;
  bool _roundComplete = false;
  bool _allDone = false;
  int _score = 0;

  _DanceRound get _round => _kRounds[_roundIndex];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _foxCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _notesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _foxCtrl.dispose();
    _notesCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _onSyllableTap(int index) {
    if (_roundComplete || _showFeedback) return;
    HapticFeedback.lightImpact();

    final correct = index == _round.stressedIndex;
    setState(() {
      _tappedIndex   = index;
      _isCorrect     = correct;
      _showFeedback  = true;
    });

    if (correct) {
      _score += 10;
      AudioManager().playSFX(SFXType.correct);
      _confettiCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _roundComplete = true);
      });
    } else {
      AudioManager().playSFX(SFXType.error);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _tappedIndex  = null;
          _showFeedback = false;
        });
      });
    }
  }

  void _nextRound() {
    if (_roundIndex + 1 >= _kRounds.length) {
      setState(() => _allDone = true);
    } else {
      setState(() {
        _roundIndex++;
        _tappedIndex  = null;
        _isCorrect    = false;
        _showFeedback = false;
        _roundComplete = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allDone) {
      return _AllDoneView(
        score: _score,
        onBack: () => Navigator.of(context).pop(),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Dance floor background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => CustomPaint(
                painter: _DanceFloorPainter(t: _pulseCtrl.value),
              ),
            ),
          ),

          // Floating music notes
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _notesCtrl,
              builder: (_, __) => CustomPaint(
                painter: _NotesPainter(t: _notesCtrl.value),
              ),
            ),
          ),

          // Confetti on correct
          if (_isCorrect && _roundComplete)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(t: _confettiCtrl.value),
                ),
              ),
            ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _TopBar(
                  roundIndex: _roundIndex,
                  total: _kRounds.length,
                  score: _score,
                  onBack: () => Navigator.of(context).pop(),
                ),

                const SizedBox(height: 12),

                // Banner + disco ball
                _DiscoBanner(),

                const SizedBox(height: 14),

                // Word card
                _WordCard(
                  round: _round,
                  pulseCtrl: _pulseCtrl,
                ),

                const SizedBox(height: 10),

                // Fox mascot
                _FoxMascot(
                  foxCtrl: _foxCtrl,
                  isCorrect: _isCorrect && _showFeedback,
                ),

                const SizedBox(height: 8),

                // Feedback bubble
                _FeedbackBubble(
                  round: _round,
                  showFeedback: _showFeedback,
                  isCorrect: _isCorrect,
                ),

                const SizedBox(height: 8),

                // Syllable targets
                Expanded(
                  child: _SyllableTargets(
                    round: _round,
                    pulseCtrl: _pulseCtrl,
                    tappedIndex: _tappedIndex,
                    isCorrect: _isCorrect,
                    onTap: _onSyllableTap,
                  ),
                ),

                // Bottom bar
                _BottomBar(
                  round: _round,
                  roundComplete: _roundComplete,
                  onListen: () =>
                      AudioManager().playWord(_round.plainWord),
                  onListenSlow: () =>
                      AudioManager().playWord(_round.plainWord),
                  onNext: _nextRound,
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
// DANCE FLOOR PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _DanceFloorPainter extends CustomPainter {
  final double t; // 0..1 pulsing

  const _DanceFloorPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark dance floor
    final bg = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_kDark, const Color(0xFF0F172A)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = bg);

    // Pulsing light rings from top center
    final glow = (math.sin(t * math.pi) + 1) / 2;
    final colors = [_kPink, _kCyan, _kGold];
    for (var i = 0; i < 3; i++) {
      final r = 80.0 + i * 90 + glow * 20;
      canvas.drawCircle(
        Offset(size.width / 2, -30),
        r,
        Paint()
          ..color = colors[i].withValues(alpha: (0.10 - i * 0.025).clamp(0, 1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18,
      );
    }

    // Disco tiles bottom area
    final tilePaint = Paint()..style = PaintingStyle.fill;
    const tileSize = 32.0;
    final cols = (size.width / tileSize).ceil() + 1;
    const rows = 5;
    final baseY = size.height - rows * tileSize;
    final tileColors = [_kPink, _kCyan, _kGold, _kPurple, Colors.white];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final phase = (t + (r + c) * 0.15) % 1.0;
        final alpha = (0.05 + math.sin(phase * math.pi) * 0.08)
            .clamp(0.0, 0.15);
        tilePaint.color = tileColors[(r + c) % tileColors.length]
            .withValues(alpha: alpha);
        canvas.drawRect(
          Rect.fromLTWH(
            c * tileSize - tileSize / 2,
            baseY + r * tileSize,
            tileSize - 1,
            tileSize - 1,
          ),
          tilePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DanceFloorPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING NOTES
// ─────────────────────────────────────────────────────────────────────────────

class _NotesPainter extends CustomPainter {
  final double t;
  const _NotesPainter({required this.t});

  static final _rng = math.Random(12);
  static final _notes = List.generate(10, (i) => (
    x: _rng.nextDouble(),
    phase: _rng.nextDouble(),
    speed: 0.06 + _rng.nextDouble() * 0.10,
    sym: ['♩', '♪', '♫', '♬'][i % 4],
    color: [_kPink, _kCyan, _kGold, Colors.white][i % 4],
  ));

  @override
  void paint(Canvas canvas, Size size) {
    for (final n in _notes) {
      final progress = (t * n.speed + n.phase) % 1.0;
      final y = size.height - progress * size.height * 1.2;
      final x = size.width * n.x + math.sin(progress * math.pi * 2) * 14;
      final tp = TextPainter(
        text: TextSpan(
          text: n.sym,
          style: TextStyle(
            fontSize: 18,
            color: n.color.withValues(alpha: (0.6 - progress * 0.5).clamp(0, 1)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_NotesPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFETTI
// ─────────────────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double t;
  const _ConfettiPainter({required this.t});

  static final _rng = math.Random(55);
  static final _pieces = List.generate(25, (i) => (
    x: _rng.nextDouble(),
    size: 5.0 + _rng.nextDouble() * 6,
    speed: 0.18 + _rng.nextDouble() * 0.30,
    phase: _rng.nextDouble(),
    color: [_kPink, _kGold, _kCyan, Colors.white, _kPurple][i % 5],
  ));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _pieces) {
      if (t < p.phase * 0.5) continue;
      final elapsed = (t - p.phase * 0.4).clamp(0.0, 1.0);
      final y = size.height * elapsed * p.speed;
      final x = size.width * p.x + math.sin(elapsed * math.pi * 3) * 22;
      paint.color = p.color.withValues(alpha: (1 - elapsed * 0.9));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(elapsed * math.pi * 5);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int roundIndex;
  final int total;
  final int score;
  final VoidCallback onBack;

  const _TopBar({
    required this.roundIndex,
    required this.total,
    required this.score,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dança das Sílabas',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: List.generate(total, (i) => Icon(
                    i <= roundIndex
                        ? Icons.music_note_rounded
                        : Icons.music_note_rounded,
                    color: i < roundIndex
                        ? _kGold
                        : (i == roundIndex
                            ? _kCyan
                            : Colors.white24),
                    size: 14,
                  )),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: _kGold.withValues(alpha: 0.50), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _kGold,
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
// DISCO BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoBanner extends StatelessWidget {
  const _DiscoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _kCyan.withValues(alpha: 0.40), width: 1.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🪩', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text(
            'Toque na sílaba FORTE!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: 8),
          Text('🎵', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD CARD — e.g. "ca-BE-lo" with stressed syllable in gold
// ─────────────────────────────────────────────────────────────────────────────

class _WordCard extends StatelessWidget {
  final _DanceRound round;
  final AnimationController pulseCtrl;

  const _WordCard({required this.round, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) {
        final glow = (math.sin(pulseCtrl.value * math.pi) + 1) / 2;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _kGold.withValues(alpha: 0.30 + glow * 0.40),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _kGold.withValues(alpha: glow * 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(round.emoji,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              _StressedWordDisplay(
                  round: round, pulseCtrl: pulseCtrl),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 350.ms).scaleXY(begin: 0.90, end: 1.0);
  }
}

class _StressedWordDisplay extends StatelessWidget {
  final _DanceRound round;
  final AnimationController pulseCtrl;

  const _StressedWordDisplay({
    required this.round,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: round.syllables.asMap().entries.expand((e) {
        final idx = e.key;
        final syl = e.value;

        final widget = Text(
          syl.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.90),
            shadows: const [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        );

        return [
          widget,
          if (idx < round.syllables.length - 1)
            Text(
              '-',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
        ];
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOX MASCOT
// ─────────────────────────────────────────────────────────────────────────────

class _FoxMascot extends StatelessWidget {
  final AnimationController foxCtrl;
  final bool isCorrect;

  const _FoxMascot({required this.foxCtrl, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: foxCtrl,
      builder: (_, __) {
        final y = math.sin(foxCtrl.value * math.pi) * 8;
        return Transform.translate(
          offset: Offset(0, -y),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isCorrect ? '🦊🎉' : '🦊',
                style: const TextStyle(fontSize: 42),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEEDBACK BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackBubble extends StatelessWidget {
  final _DanceRound round;
  final bool showFeedback;
  final bool isCorrect;

  const _FeedbackBubble({
    required this.round,
    required this.showFeedback,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    if (!showFeedback) {
      return const SizedBox(height: 42);
    }

    final stressed =
        round.syllables[round.stressedIndex].toUpperCase();
    final text = isCorrect
        ? 'Isso! ${round.plainWord.toUpperCase()} — a sílaba forte é $stressed!'
        : 'A sílaba forte é $stressed! Tente de novo.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCorrect
              ? _kGreen.withValues(alpha: 0.18)
              : _kGold.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCorrect ? _kGreen : _kGold,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              isCorrect ? '✅' : '💡',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCorrect ? _kGreen : _kGold,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: -0.1, end: 0, duration: 250.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SYLLABLE TARGETS — big tappable buttons
// ─────────────────────────────────────────────────────────────────────────────

class _SyllableTargets extends StatelessWidget {
  final _DanceRound round;
  final AnimationController pulseCtrl;
  final int? tappedIndex;
  final bool isCorrect;
  final void Function(int) onTap;

  const _SyllableTargets({
    required this.round,
    required this.pulseCtrl,
    required this.tappedIndex,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: round.syllables.asMap().entries.map((e) {
          final idx = e.key;
          final syl = e.value;
          final isStressed = idx == round.stressedIndex;
          final isTapped = tappedIndex == idx;

          Color borderColor;
          Color bgColor;
          Color textColor;
          double elevation = 6;

          if (isTapped) {
            if (isCorrect) {
              bgColor = _kGreen;
              borderColor = const Color(0xFF15803D);
              textColor = Colors.white;
              elevation = 18;
            } else {
              bgColor = const Color(0xFFEF4444);
              borderColor = const Color(0xFFDC2626);
              textColor = Colors.white;
            }
          } else {
            bgColor = Colors.white.withValues(alpha: 0.12);
            borderColor = Colors.white.withValues(alpha: 0.25);
            textColor = Colors.white;
          }

          return GestureDetector(
            onTap: () => onTap(idx),
            child: AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) {
                final scale = 1.0;
                return Transform.scale(
                  scale: isTapped && isCorrect ? 1.06 : scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: borderColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: (isTapped && isCorrect
                                  ? _kGreen
                                  : Colors.transparent)
                              .withValues(alpha: 0.45),
                          blurRadius: elevation,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          syl.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        if (isTapped && isCorrect)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
              .animate(delay: Duration(milliseconds: 80 * idx))
              .fadeIn(duration: 300.ms)
              .scaleXY(
                  begin: 0.6,
                  end: 1.0,
                  duration: 400.ms,
                  curve: Curves.elasticOut);
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final _DanceRound round;
  final bool roundComplete;
  final VoidCallback onListen;
  final VoidCallback onListenSlow;
  final VoidCallback onNext;

  const _BottomBar({
    required this.round,
    required this.roundComplete,
    required this.onListen,
    required this.onListenSlow,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1445).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
              color: _kCyan.withValues(alpha: 0.25), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Play rhythm
          GestureDetector(
            onTap: onListen,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _kCyan.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _kCyan.withValues(alpha: 0.50), width: 1.5),
              ),
              child: const Icon(Icons.play_circle_rounded,
                  color: _kCyan, size: 28),
            ),
          ),

          const SizedBox(width: 10),

          // Ouvir devagar (turtle)
          GestureDetector(
            onTap: onListenSlow,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20), width: 1.5),
              ),
              child: const Center(
                child: Text('🐢', style: TextStyle(fontSize: 22)),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Next / current action
          Expanded(
            child: roundComplete
                ? GestureDetector(
                    onTap: onNext,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kCyan, Color(0xFF0EA5E9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kCyan.withValues(alpha: 0.50),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🎵', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text(
                            'PRÓXIMO RITMO',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                        begin: 1.0,
                        end: 1.04,
                        duration: 700.ms,
                        curve: Curves.easeInOut)
                : Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kPink, Color(0xFFF472B6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎵', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          'DANÇAR E RIMAR',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
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
// ALL DONE VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _AllDoneView extends StatelessWidget {
  final int score;
  final VoidCallback onBack;

  const _AllDoneView({required this.score, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🦊🎉', style: TextStyle(fontSize: 72))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'Incrível!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 10),
            Text(
              'Você dominou o ritmo! ⭐ $score pontos',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kGold,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kCyan, Color(0xFF0EA5E9)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kCyan.withValues(alpha: 0.50),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'Voltar ao Circo',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).scaleXY(begin: 0.8, end: 1.0),
          ],
        ),
      ),
    );
  }
}
