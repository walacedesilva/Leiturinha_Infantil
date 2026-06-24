import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import 'rhyme_juggling_screen.dart';
import 'syllable_dance_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────

const _kPink     = Color(0xFFEC4899);
const _kLavender = Color(0xFFF472B6);
const _kGold     = Color(0xFFFBBF24);
const _kCyan     = Color(0xFF06B6D4);
const _kDark     = Color(0xFF831843);
const _kSky1     = Color(0xFFFED7AA);
const _kSky2     = Color(0xFFFDBA74);

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum _ActivityState { active, locked }

class _Activity {
  final String id;
  final String emoji;
  final String name;
  final String subtitle;
  final Color primary;
  final Color light;
  final _ActivityState state;
  final int totalLevels;

  const _Activity({
    required this.id,
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.light,
    required this.state,
    required this.totalLevels,
  });
}

const _kActivities = <_Activity>[
  _Activity(
    id: 'malabarismo',
    emoji: '🤹',
    name: 'Malabarismo de Rimas',
    subtitle: 'Toque nas palavras que rimam!',
    primary: _kPink,
    light: Color(0xFFFCE7F3),
    state: _ActivityState.active,
    totalLevels: 5,
  ),
  _Activity(
    id: 'danca',
    emoji: '🕺',
    name: 'Dança das Sílabas',
    subtitle: 'Toque na sílaba FORTE!',
    primary: _kCyan,
    light: Color(0xFFCFFAFE),
    state: _ActivityState.active,
    totalLevels: 4,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CircoDasRimasScreen extends StatefulWidget {
  const CircoDasRimasScreen({super.key});

  @override
  State<CircoDasRimasScreen> createState() => _CircoDasRimasScreenState();
}

class _CircoDasRimasScreenState extends State<CircoDasRimasScreen>
    with TickerProviderStateMixin {
  late final AnimationController _tentCtrl;
  late final AnimationController _ballCtrl;
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _tentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _ballCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _tentCtrl.dispose();
    _ballCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _onActivityTap(_Activity act) {
    HapticFeedback.lightImpact();
    Widget screen;
    switch (act.id) {
      case 'malabarismo':
        screen = const RhymeJugglingScreen();
      case 'danca':
        screen = const SyllableDanceScreen();
      default:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final gam  = context.watch<GamificationService>();
    final prog = context.watch<ProgressService>();
    final rimasProgress = prog.getFamilyProgress('circo_rimas', 5);
    final dancaProgress = prog.getFamilyProgress('circo_danca', 4);
    final totalDone  = rimasProgress.completedWords + dancaProgress.completedWords;
    const totalTotal = 9;

    return Scaffold(
      body: Stack(
        children: [
          // ── Sunset sky background ───────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _SkyPainter(ctrl: _tentCtrl)),
          ),

          // ── Floating juggling balls ─────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ballCtrl,
              builder: (_, __) => CustomPaint(
                painter: _FloatingBallsPainter(t: _ballCtrl.value),
              ),
            ),
          ),

          // ── Confetti particles ──────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(t: _confettiCtrl.value),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _TopBar(coins: gam.state.coins),

                // Circus tent + title
                _CircusTent(ctrl: _tentCtrl),

                // Marquee rhyme pairs
                const _MarqueePairs(),

                // Progress
                _ProgressBar(done: totalDone, total: totalTotal),

                const SizedBox(height: 12),

                // Activities
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _kActivities.length,
                    itemBuilder: (_, i) => _ActivityCard(
                      act: _kActivities[i],
                      onTap: () => _onActivityTap(_kActivities[i]),
                    )
                        .animate(delay: Duration(milliseconds: 120 * i))
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, duration: 400.ms),
                  ),
                ),

                // Mascot row
                const _MascotRow(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKY PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SkyPainter extends CustomPainter {
  final AnimationController ctrl;
  _SkyPainter({required this.ctrl}) : super(repaint: ctrl);

  @override
  void paint(Canvas canvas, Size size) {
    final t = (math.sin(ctrl.value * math.pi) + 1) / 2;
    final c1 = Color.lerp(_kSky1, const Color(0xFFFDBA74), t * 0.3)!;
    final c2 = Color.lerp(_kSky2, const Color(0xFFFCA5A5), t * 0.2)!;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c1, c2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // String lights across top
    final lightPaint = Paint()
      ..color = _kGold.withValues(alpha: 0.60)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, 90), Offset(size.width, 90), lightPaint);

    final bulbPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 10; i++) {
      final x = size.width * i / 9;
      final y = 90 + math.sin(i * 0.7) * 6;
      final glow = (math.sin(ctrl.value * math.pi * 2 + i) + 1) / 2;
      bulbPaint.color = Color.lerp(
        _kGold.withValues(alpha: 0.5),
        _kGold,
        glow,
      )!;
      canvas.drawCircle(Offset(x, y), 5, bulbPaint);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter _) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING BALLS PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingBallsPainter extends CustomPainter {
  final double t;
  const _FloatingBallsPainter({required this.t});

  static const _balls = [
    (text: 'GA', color: Color(0xFFEC4899), offset: 0.0),
    (text: 'TO', color: Color(0xFF06B6D4), offset: 0.33),
    (text: 'PA', color: Color(0xFFFBBF24), offset: 0.66),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final ball in _balls) {
      final phase = (t + ball.offset) % 1.0;
      final x = size.width * 0.15 +
          size.width * 0.70 * math.sin(phase * math.pi * 2).abs();
      final baseY = size.height * 0.18;
      final y = baseY - 30 * math.sin(phase * math.pi);

      // Shadow
      canvas.drawCircle(
        Offset(x, y + 28),
        18,
        Paint()..color = Colors.black.withValues(alpha: 0.12),
      );

      // Ball
      canvas.drawCircle(
        Offset(x, y),
        22,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.white.withValues(alpha: 0.5), ball.color],
            stops: const [0.0, 0.8],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 22)),
      );

      // Outline
      canvas.drawCircle(
        Offset(x, y),
        22,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.60)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Text
      final tp = TextPainter(
        text: TextSpan(
          text: ball.text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Color(0x88000000), blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_FloatingBallsPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFETTI PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double t;
  const _ConfettiPainter({required this.t});

  static final _rng = math.Random(42);
  static final _pieces = List.generate(20, (i) => (
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    size: 4.0 + _rng.nextDouble() * 6,
    speed: 0.08 + _rng.nextDouble() * 0.12,
    phase: _rng.nextDouble(),
    color: [_kPink, _kGold, _kCyan, Colors.white, const Color(0xFFA855F7)][i % 5],
  ));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _pieces) {
      final phase = (t * p.speed + p.phase) % 1.0;
      final y = size.height * phase;
      final x = size.width * p.x + math.sin(phase * math.pi * 4) * 18;
      paint.color = p.color.withValues(alpha: 0.70);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * math.pi * 3);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.55,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _kDark,
                size: 18,
              ),
            ),
          ),

          const Spacer(),

          // District badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _kPink.withValues(alpha: 0.40), width: 1.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎪', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text(
                  'Circo das Rimas',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kDark,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Coins
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _kGold.withValues(alpha: 0.50), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 5),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kDark,
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
// CIRCUS TENT
// ─────────────────────────────────────────────────────────────────────────────

class _CircusTent extends StatelessWidget {
  final AnimationController ctrl;
  const _CircusTent({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final glow = (math.sin(ctrl.value * math.pi) + 1) / 2;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFBE185D), _kPink, _kLavender],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPink.withValues(alpha: 0.40 + glow * 0.25),
                blurRadius: 24 + glow * 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Stripe pattern overlay
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  size: const Size(double.infinity, 110),
                  painter: _TentStripePainter(),
                ),
              ),
              // Tent content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Tent emoji big
                    const Text('🎪',
                        style: TextStyle(fontSize: 52))
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .scaleXY(
                          begin: 1.0,
                          end: 1.08,
                          duration: 2000.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Circo das Rimas',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Ritmo · Rima · Sílaba',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TentStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    const stripeW = 28.0;
    var x = -stripeW;
    while (x < size.width + stripeW) {
      canvas.drawParallelogram(
        Offset(x, 0),
        Offset(x + stripeW, 0),
        Offset(x + stripeW + 20, size.height),
        Offset(x + 20, size.height),
        paint,
      );
      x += stripeW * 2;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

extension on Canvas {
  void drawParallelogram(
      Offset a, Offset b, Offset c, Offset d, Paint paint) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();
    drawPath(path, paint);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARQUEE — rhyme pairs
// ─────────────────────────────────────────────────────────────────────────────

class _MarqueePairs extends StatelessWidget {
  const _MarqueePairs();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _kGold.withValues(alpha: 0.50), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _RhymePair(a: 'GATO', b: 'PATO', emoji: '🐱🦆'),
          _RhymePair(a: 'BOLA', b: 'COLA', emoji: '⚽🖊️'),
          _RhymePair(a: 'MESA', b: 'PESA', emoji: '🪑⚖️'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _RhymePair extends StatelessWidget {
  final String a;
  final String b;
  final String emoji;
  const _RhymePair({required this.a, required this.b, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(
          '$a / $b',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _kDark,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                'Rimas: $done/$total',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                ),
              ),
              const Spacer(),
              ...List.generate(
                3,
                (i) => Icon(
                  i < (pct * 3).ceil()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _kGold,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.55),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_kPink),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final _Activity act;
  final VoidCallback onTap;
  const _ActivityCard({required this.act, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLocked = act.state == _ActivityState.locked;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: act.primary.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Locked overlay
            if (isLocked)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.shade200
                          : act.light,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        isLocked ? '🔒' : act.emoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act.name,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isLocked
                                ? Colors.grey.shade500
                                : const Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLocked ? 'Em breve...' : act.subtitle,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isLocked
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Level pills
                        if (!isLocked)
                          Row(
                            children: List.generate(
                              act.totalLevels,
                              (i) => Container(
                                width: 22,
                                height: 7,
                                margin:
                                    const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: i < 2
                                      ? act.primary
                                      : act.primary.withValues(alpha: 0.20),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Arrow
                  if (!isLocked)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: act.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),

            // "Em breve" badge
            if (isLocked)
              Positioned(
                top: 12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Em breve',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
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
// MASCOT ROW — Bear · Rabbit · Fox
// ─────────────────────────────────────────────────────────────────────────────

class _MascotRow extends StatelessWidget {
  const _MascotRow();

  @override
  Widget build(BuildContext context) {
    const mascots = [
      (emoji: '🐻', label: 'Urso Malabarista', hat: '🎩'),
      (emoji: '🐰', label: 'Coelho Palhaço', hat: '🤡'),
      (emoji: '🦊', label: 'Raposa Dançarina', hat: '🎩'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: _kPink.withValues(alpha: 0.30), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: mascots.asMap().entries.map((e) {
            final idx = e.key;
            final m = e.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(m.emoji,
                        style: const TextStyle(fontSize: 32))
                        .animate(delay: Duration(milliseconds: 200 * idx))
                        .then()
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .slideY(
                          begin: 0,
                          end: -0.15,
                          duration: Duration(
                              milliseconds: 800 + idx * 200),
                          curve: Curves.easeInOut,
                        ),
                    Positioned(
                      top: -8,
                      right: -4,
                      child: Text(m.hat,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  m.label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
