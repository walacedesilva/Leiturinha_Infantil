import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../services/audio_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────

const _kPink     = Color(0xFFEC4899);
const _kLavender = Color(0xFFF472B6);
const _kGold     = Color(0xFFFBBF24);
const _kCyan     = Color(0xFF06B6D4);
const _kGreen    = Color(0xFF22C55E);
const _kOrange   = Color(0xFFF97316);
const _kBlue     = Color(0xFF0284C7);
const _kDark     = Color(0xFF831843);

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────

class _RhymeRound {
  final String targetWord;
  final String targetEmoji;
  final String hint; // common ending
  final List<_WordBall> balls;

  const _RhymeRound({
    required this.targetWord,
    required this.targetEmoji,
    required this.hint,
    required this.balls,
  });
}

class _WordBall {
  final String word;
  final String emoji;
  final bool isRhyme;
  final Color color;

  const _WordBall({
    required this.word,
    required this.emoji,
    required this.isRhyme,
    required this.color,
  });
}

const _kRounds = <_RhymeRound>[
  _RhymeRound(
    targetWord: 'GATO',
    targetEmoji: '🐱',
    hint: 'ATO',
    balls: [
      _WordBall(word: 'PATO',  emoji: '🦆', isRhyme: true,  color: Color(0xFF3B82F6)),
      _WordBall(word: 'BOLA',  emoji: '⚽', isRhyme: false, color: Color(0xFFEF4444)),
      _WordBall(word: 'RATO',  emoji: '🐭', isRhyme: true,  color: Color(0xFF8B5CF6)),
      _WordBall(word: 'MALA',  emoji: '💼', isRhyme: false, color: Color(0xFF10B981)),
    ],
  ),
  _RhymeRound(
    targetWord: 'BOLA',
    targetEmoji: '⚽',
    hint: 'OLA',
    balls: [
      _WordBall(word: 'COLA',  emoji: '🖊️', isRhyme: true,  color: Color(0xFFEC4899)),
      _WordBall(word: 'GATO',  emoji: '🐱', isRhyme: false, color: Color(0xFFEF4444)),
      _WordBall(word: 'MOLA',  emoji: '🌀', isRhyme: true,  color: Color(0xFF06B6D4)),
      _WordBall(word: 'CASA',  emoji: '🏠', isRhyme: false, color: Color(0xFFFBBF24)),
    ],
  ),
  _RhymeRound(
    targetWord: 'MESA',
    targetEmoji: '🪑',
    hint: 'ESA',
    balls: [
      _WordBall(word: 'PESA',  emoji: '⚖️', isRhyme: true,  color: Color(0xFF8B5CF6)),
      _WordBall(word: 'FADA',  emoji: '🧚', isRhyme: false, color: Color(0xFFEF4444)),
      _WordBall(word: 'PRESA', emoji: '🔒', isRhyme: true,  color: Color(0xFF3B82F6)),
      _WordBall(word: 'CAMA',  emoji: '🛏️', isRhyme: false, color: Color(0xFF10B981)),
    ],
  ),
  _RhymeRound(
    targetWord: 'FADA',
    targetEmoji: '🧚',
    hint: 'ADA',
    balls: [
      _WordBall(word: 'NADA',  emoji: '🌊', isRhyme: true,  color: Color(0xFF06B6D4)),
      _WordBall(word: 'BOLA',  emoji: '⚽', isRhyme: false, color: Color(0xFFEF4444)),
      _WordBall(word: 'CADA',  emoji: '📦', isRhyme: true,  color: Color(0xFFEC4899)),
      _WordBall(word: 'PATO',  emoji: '🦆', isRhyme: false, color: Color(0xFFFBBF24)),
    ],
  ),
  _RhymeRound(
    targetWord: 'LEÃO',
    targetEmoji: '🦁',
    hint: 'ÃO',
    balls: [
      _WordBall(word: 'CORAÇÃO', emoji: '❤️', isRhyme: true,  color: Color(0xFFEC4899)),
      _WordBall(word: 'CASA',    emoji: '🏠', isRhyme: false, color: Color(0xFFEF4444)),
      _WordBall(word: 'MÃO',     emoji: '🤚', isRhyme: true,  color: Color(0xFF8B5CF6)),
      _WordBall(word: 'GATO',    emoji: '🐱', isRhyme: false, color: Color(0xFF10B981)),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RhymeJugglingScreen extends StatefulWidget {
  const RhymeJugglingScreen({super.key});

  @override
  State<RhymeJugglingScreen> createState() => _RhymeJugglingScreenState();
}

class _RhymeJugglingScreenState extends State<RhymeJugglingScreen>
    with TickerProviderStateMixin {
  // ── Ball animations ────────────────────────────────────────────────────────
  late final AnimationController _juggleCtrl;
  late final AnimationController _feedbackCtrl;
  late final AnimationController _confettiCtrl;

  // ── Game state ─────────────────────────────────────────────────────────────
  int _roundIndex = 0;
  final Set<int> _tappedCorrect = {};
  int? _tappedWrong;
  bool _showHint = false;
  bool _roundComplete = false;
  bool _allDone = false;
  int _score = 0;
  String _feedbackText = '';
  bool _feedbackSuccess = false;
  late List<int> _shuffledIndices;

  _RhymeRound get _round => _kRounds[_roundIndex];

  void _shuffleBalls() {
    final rng = math.Random();
    _shuffledIndices = List.generate(_round.balls.length, (i) => i)
      ..shuffle(rng);
  }

  @override
  void initState() {
    super.initState();
    _shuffleBalls();

    _juggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _juggleCtrl.dispose();
    _feedbackCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  int get _totalRhymesInRound =>
      _round.balls.where((b) => b.isRhyme).length;

  void _onBallTap(int index) {
    final ball = _round.balls[index];
    if (_roundComplete) return;
    if (_tappedCorrect.contains(index)) return;

    HapticFeedback.lightImpact();

    if (ball.isRhyme) {
      setState(() {
        _tappedCorrect.add(index);
        _tappedWrong = null;
        _feedbackText = 'Isso! ${ball.word} rima com ${_round.targetWord}! 🎉';
        _feedbackSuccess = true;
        _score += 10;
      });
      _feedbackCtrl.forward(from: 0);
      AudioManager().playSFX(SFXType.correct);

      // Check if round complete
      if (_tappedCorrect.length == _totalRhymesInRound) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() => _roundComplete = true);
          _confettiCtrl.forward(from: 0);
        });
      }
    } else {
      setState(() {
        _tappedWrong = index;
        _feedbackText =
            '${_round.targetWord} termina com "${_round.hint}". Tente de novo!';
        _feedbackSuccess = false;
      });
      _feedbackCtrl.forward(from: 0);
      AudioManager().playSFX(SFXType.error);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _tappedWrong = null);
      });
    }
  }

  void _nextRound() {
    if (_roundIndex + 1 >= _kRounds.length) {
      setState(() => _allDone = true);
    } else {
      setState(() {
        _roundIndex++;
        _shuffleBalls();
        _tappedCorrect.clear();
        _tappedWrong = null;
        _showHint = false;
        _roundComplete = false;
        _feedbackText = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allDone) {
      return _AllDoneView(score: _score, onBack: () => Navigator.of(context).pop());
    }

    return Scaffold(
      body: Stack(
        children: [
          // Stage backdrop
          Positioned.fill(child: CustomPaint(painter: _StagePainter())),

          // Confetti on round complete
          if (_roundComplete)
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
                  showHint: _showHint,
                  onBack: () => Navigator.of(context).pop(),
                  onHint: () => setState(() => _showHint = !_showHint),
                ),

                // Hint tooltip
                if (_showHint)
                  _HintTooltip(
                    text:
                        'Rimas terminam igual! "${_round.hint}" fica no final.',
                  ),

                // Target word
                _TargetWordCard(round: _round),

                // Juggling balls
                Expanded(
                  child: AnimatedBuilder(
                    animation: _juggleCtrl,
                    builder: (_, __) => _BallsGrid(
                      round: _round,
                      shuffledIndices: _shuffledIndices,
                      juggleT: _juggleCtrl.value,
                      tappedCorrect: _tappedCorrect,
                      tappedWrong: _tappedWrong,
                      onTap: _onBallTap,
                    ),
                  ),
                ),

                // Feedback text
                if (_feedbackText.isNotEmpty)
                  _FeedbackBanner(
                    text: _feedbackText,
                    isSuccess: _feedbackSuccess,
                    ctrl: _feedbackCtrl,
                  ),

                // Progress indicator
                _RoundProgress(
                  found: _tappedCorrect.length,
                  total: _totalRhymesInRound,
                ),

                // Bottom bar
                _BottomBar(
                  targetWord: _round.targetWord,
                  roundComplete: _roundComplete,
                  onListen: () =>
                      AudioManager().playWord(_round.targetWord.toLowerCase()),
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
// STAGE BACKDROP PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _StagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark stage background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A0A2E),
    );

    // Stage spotlight ellipse from top center
    final spotPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), spotPaint);

    // Curtain left
    final curtainPaint = Paint()
      ..shader = LinearGradient(
        colors: [_kPink.withValues(alpha: 0.90), _kLavender.withValues(alpha: 0.60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.18, size.height));
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.18, 0)
        ..lineTo(size.width * 0.12, size.height * 0.55)
        ..lineTo(0, size.height * 0.6),
      curtainPaint,
    );

    // Curtain right
    final curtainPaintR = Paint()
      ..shader = LinearGradient(
        colors: [_kLavender.withValues(alpha: 0.60), _kPink.withValues(alpha: 0.90)],
        begin: Alignment.topRight,
        end: Alignment.bottomRight,
      ).createShader(
          Rect.fromLTWH(size.width * 0.82, 0, size.width * 0.18, size.height));
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.82, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height * 0.6)
        ..lineTo(size.width * 0.88, size.height * 0.55),
      curtainPaintR,
    );

    // Stage floor
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      Paint()..color = const Color(0xFF2D1B69),
    );

    // Floor line
    canvas.drawLine(
      Offset(0, size.height * 0.78),
      Offset(size.width, size.height * 0.78),
      Paint()
        ..color = _kGold.withValues(alpha: 0.60)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFETTI
// ─────────────────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double t;
  const _ConfettiPainter({required this.t});

  static final _rng = math.Random(7);
  static final _pieces = List.generate(30, (i) => (
    x: _rng.nextDouble(),
    size: 5.0 + _rng.nextDouble() * 7,
    speed: 0.20 + _rng.nextDouble() * 0.35,
    phase: _rng.nextDouble(),
    color: [_kPink, _kGold, _kCyan, Colors.white, const Color(0xFFA855F7)][i % 5],
  ));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _pieces) {
      if (t < p.phase * 0.6) continue;
      final elapsed = (t - p.phase * 0.5).clamp(0.0, 1.0);
      final y = size.height * elapsed * p.speed;
      final x = size.width * p.x + math.sin(elapsed * math.pi * 3) * 25;
      paint.color = p.color.withValues(alpha: (1 - elapsed * 0.8));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(elapsed * math.pi * 4);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.5),
          paint);
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
  final bool showHint;
  final VoidCallback onBack;
  final VoidCallback onHint;

  const _TopBar({
    required this.roundIndex,
    required this.total,
    required this.score,
    required this.showHint,
    required this.onBack,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 10),

          // Title + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Malabarismo de Rimas',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Atividade ${roundIndex + 1} de $total',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),

          // Score
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _kGold.withValues(alpha: 0.50), width: 1.5),
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

          const SizedBox(width: 8),

          // Hint button
          GestureDetector(
            onTap: onHint,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: showHint
                    ? _kGold.withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _kGold.withValues(alpha: 0.40), width: 1.5),
              ),
              child: Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: showHint ? _kGold : Colors.white70,
                  ),
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
// HINT TOOLTIP
// ─────────────────────────────────────────────────────────────────────────────

class _HintTooltip extends StatelessWidget {
  final String text;
  const _HintTooltip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _kGold.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _kGold.withValues(alpha: 0.50), width: 1.5),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kGold,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.1, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARGET WORD CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TargetWordCard extends StatelessWidget {
  final _RhymeRound round;
  const _TargetWordCard({required this.round});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPink, _kLavender],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPink.withValues(alpha: 0.50),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐻', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Toque nas que rimam com',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      round.targetWord,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x55000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      round.targetEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Hint: ending
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '-${round.hint}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).scaleXY(begin: 0.92, end: 1.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BALLS GRID
// ─────────────────────────────────────────────────────────────────────────────

class _BallsGrid extends StatelessWidget {
  final _RhymeRound round;
  final List<int> shuffledIndices;
  final double juggleT;
  final Set<int> tappedCorrect;
  final int? tappedWrong;
  final void Function(int) onTap;

  const _BallsGrid({
    required this.round,
    required this.shuffledIndices,
    required this.juggleT,
    required this.tappedCorrect,
    required this.tappedWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.25,
        children: shuffledIndices.asMap().entries.map((e) {
          final displayPos = e.key;
          final idx = e.value; // original ball index
          final ball = round.balls[idx];
          final isCorrect = tappedCorrect.contains(idx);
          final isWrong = tappedWrong == idx;

          // Bob offset per display position
          final phase = (juggleT + displayPos * 0.25) % 1.0;
          final bobY = math.sin(phase * math.pi * 2) * (isCorrect ? 0 : 8);

          return Transform.translate(
            offset: Offset(0, -bobY),
            child: _JuggleBall(
              ball: ball,
              isCorrect: isCorrect,
              isWrong: isWrong,
              onTap: () => onTap(idx),
            )
                .animate(delay: Duration(milliseconds: 80 * displayPos))
                .fadeIn(duration: 300.ms)
                .scaleXY(
                  begin: 0.7,
                  end: 1.0,
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
          );
        }).toList(),
      ),
    );
  }
}

class _JuggleBall extends StatelessWidget {
  final _WordBall ball;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const _JuggleBall({
    required this.ball,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Widget? overlay;

    if (isCorrect) {
      bgColor = _kGreen;
      borderColor = const Color(0xFF15803D);
      overlay = const Positioned(
        top: 8,
        right: 8,
        child: Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 22),
      );
    } else if (isWrong) {
      bgColor = const Color(0xFFEF4444);
      borderColor = const Color(0xFFDC2626);
      overlay = null;
    } else {
      bgColor = ball.color;
      borderColor = Colors.white.withValues(alpha: 0.30);
      overlay = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bgColor.withValues(alpha: 0.85),
              bgColor,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: isCorrect ? 0.55 : 0.30),
              blurRadius: isCorrect ? 20 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Shine highlight
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                width: 28,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ball.emoji,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    ball.word,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (overlay != null) overlay,

            // Wrong shake animation
            if (isWrong)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.15),
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
// FEEDBACK BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final String text;
  final bool isSuccess;
  final AnimationController ctrl;

  const _FeedbackBanner({
    required this.text,
    required this.isSuccess,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final opacity = (math.sin(ctrl.value * math.pi)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSuccess
                  ? _kGreen.withValues(alpha: 0.15)
                  : _kGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSuccess ? _kGreen : _kGold,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(
                  isSuccess ? '✅' : '💡',
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
                      color: isSuccess ? _kGreen : _kGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUND PROGRESS
// ─────────────────────────────────────────────────────────────────────────────

class _RoundProgress extends StatelessWidget {
  final int found;
  final int total;
  const _RoundProgress({required this.found, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Encontrou $found de $total rimas!',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          ...List.generate(
            total,
            (i) => Icon(
              i < found
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: _kGold,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final String targetWord;
  final bool roundComplete;
  final VoidCallback onListen;
  final VoidCallback onNext;

  const _BottomBar({
    required this.targetWord,
    required this.roundComplete,
    required this.onListen,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A2E).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
              color: _kPink.withValues(alpha: 0.30), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // "Ouvir modelo"
          Expanded(
            child: GestureDetector(
              onTap: onListen,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _kBlue.withValues(alpha: 0.40), width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up_rounded,
                        color: _kBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Ouvir modelo',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Next round / Próxima
          if (roundComplete)
            Expanded(
              child: GestureDetector(
                onTap: onNext,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPink, _kLavender],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _kPink.withValues(alpha: 0.50),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎵',
                          style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        'PRÓXIMA',
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
                      curve: Curves.easeInOut),
            )
          else
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPink, _kLavender],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kPink.withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎵',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'DANÇAR E RIMAR',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
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
      backgroundColor: const Color(0xFF1A0A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'Parabéns!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 10),
            Text(
              'Você é um Artista das Rimas! ⭐ $score pontos',
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
                    colors: [_kPink, _kLavender],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kPink.withValues(alpha: 0.50),
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
