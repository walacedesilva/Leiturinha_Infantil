import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PORTAL DOURADO — Tela de Transição para o Próximo Reino
// Visual: arco dourado com luz + partículas + mascotes animados
// Duração: ~3.5s → pop back para menu
// ═════════════════════════════════════════════════════════════════════════════

class PortalTransitionScreen extends StatefulWidget {
  const PortalTransitionScreen({super.key});

  @override
  State<PortalTransitionScreen> createState() =>
      _PortalTransitionScreenState();
}

class _PortalTransitionScreenState extends State<PortalTransitionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _portalCtrl;   // arch + glow
  late final AnimationController _lightCtrl;    // light rays sweep
  late final AnimationController _particleCtrl; // floating particles
  late final AnimationController _enterCtrl;    // "entering" zoom effect

  @override
  void initState() {
    super.initState();

    _portalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _lightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          Navigator.of(context).pop();
        }
      });
  }

  @override
  void dispose() {
    _portalCtrl.dispose();
    _lightCtrl.dispose();
    _particleCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _enterCtrl,
              builder: (_, __) {
                final t = _enterCtrl.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.4 + t * 1.2,
                      colors: [
                        const Color(0xFFFBBF24).withOpacity(0.35 * t),
                        const Color(0xFF7C3AED).withOpacity(0.4),
                        const Color(0xFF0F0A1E),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Stars ────────────────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _StarFieldPainter()),
          ),

          // ── Light rays ───────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _lightCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _LightRaysPainter(_lightCtrl.value, size),
              ),
            ),
          ),

          // ── Floating particles ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _MagicParticlePainter(_particleCtrl.value, size),
              ),
            ),
          ),

          // ── Portal arch ──────────────────────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_portalCtrl, _lightCtrl, _enterCtrl]),
            builder: (_, __) {
              final scale = Curves.elasticOut.transform(_portalCtrl.value);
              final enterZoom = 1.0 + _enterCtrl.value * 0.6;
              final opacity = (_enterCtrl.value < 0.75)
                  ? 1.0
                  : 1.0 - (_enterCtrl.value - 0.75) / 0.25;
              return Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: opacity.clamp(0, 1),
                    child: Transform.scale(
                      scale: scale * enterZoom,
                      child: _PortalArch(glowPulse: _lightCtrl.value),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Text overlay ─────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _enterCtrl,
            builder: (_, __) {
              final t = _enterCtrl.value;
              final opacity = t < 0.2
                  ? t / 0.2
                  : t > 0.75
                      ? 1.0 - (t - 0.75) / 0.25
                      : 1.0;
              return Positioned(
                bottom: size.height * 0.18,
                left: 32,
                right: 32,
                child: Opacity(
                  opacity: opacity.clamp(0, 1),
                  child: Column(
                    children: [
                      const Text(
                        'PORTAL DOURADO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFBBF24),
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Color(0xFFFBBF24),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Você desbloqueou o próximo nível!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: Color(0xFFE0F2FE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Reward chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GlowChip(
                              icon: '⭐',
                              label: '+50 XP',
                              color: const Color(0xFFFBBF24)),
                          const SizedBox(width: 12),
                          _GlowChip(
                              icon: '🪙',
                              label: '+20',
                              color: const Color(0xFF06B6D4)),
                          const SizedBox(width: 12),
                          _GlowChip(
                              icon: '🏆',
                              label: 'Troféu',
                              color: const Color(0xFFEC4899)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Mascots cheering ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: _enterCtrl,
            builder: (_, __) {
              final t = _enterCtrl.value;
              return Positioned(
                bottom: size.height * 0.06,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CheeringMascot(
                      emoji: '🦊',
                      message: 'Incrível! 🎉',
                      color: const Color(0xFFF97316),
                      bounce: math.sin(t * math.pi * 4).abs(),
                    ),
                    _CheeringMascot(
                      emoji: '🐦',
                      message: 'Arrasou! ⭐',
                      color: const Color(0xFF06B6D4),
                      bounce: math.sin(t * math.pi * 4 + math.pi).abs(),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── "Coming soon" badge ──────────────────────────────────────────
          Positioned(
            top: size.height * 0.08,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFBBF24).withOpacity(0.6),
                      width: 1.5),
                ),
                child: const Text(
                  '🚀 Reino das Histórias — Em breve!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFDE68A),
                  ),
                ),
              ),
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PORTAL ARCH WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _PortalArch extends StatelessWidget {
  final double glowPulse;

  const _PortalArch({required this.glowPulse});

  @override
  Widget build(BuildContext context) {
    final glow = 24.0 + glowPulse * 16;

    return SizedBox(
      width: 220,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 220,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.elliptical(110, 120)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withOpacity(0.5),
                  blurRadius: glow * 2,
                  spreadRadius: glow / 2,
                ),
              ],
            ),
          ),
          // Arch frame
          Container(
            width: 200,
            height: 220,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFBBF24),
                  Color(0xFFF59E0B),
                  Color(0xFFD97706),
                  Color(0xFF92400E),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.elliptical(100, 110)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withOpacity(0.8),
                  blurRadius: glow,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Inner portal (magical interior)
          Container(
            width: 162,
            height: 182,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  const Color(0xFFE0F2FE).withOpacity(0.8),
                  const Color(0xFF7DD3FC).withOpacity(0.6),
                  const Color(0xFF7C3AED).withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 0.65, 1.0],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.elliptical(81, 91)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✨', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                Text(
                  'REINO\nDAS\nHISTÓRIAS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4C1D95),
                    height: 1.3,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ground base of arch
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF92400E), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          // Gem decorations on arch
          Positioned(
            top: 8,
            left: 80,
            child: _GemDot(color: const Color(0xFFEC4899), size: 14),
          ),
          Positioned(
            top: 30,
            left: 16,
            child: _GemDot(color: const Color(0xFF22C55E), size: 10),
          ),
          Positioned(
            top: 30,
            right: 16,
            child: _GemDot(color: const Color(0xFF06B6D4), size: 10),
          ),
        ],
      ),
    );
  }
}

class _GemDot extends StatelessWidget {
  final Color color;
  final double size;

  const _GemDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size * 0.8, spreadRadius: 1),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHEERING MASCOT
// ─────────────────────────────────────────────────────────────────────────────
class _CheeringMascot extends StatelessWidget {
  final String emoji;
  final String message;
  final Color color;
  final double bounce;

  const _CheeringMascot({
    required this.emoji,
    required this.message,
    required this.color,
    required this.bounce,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -bounce * 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 10),
              ],
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 34))),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.5, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOW CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _GlowChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _GlowChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _StarFieldPainter extends CustomPainter {
  static final _rng = math.Random(13);
  static final _stars = List.generate(
    80,
    (i) => (
      x: _rng.nextDouble(),
      y: _rng.nextDouble() * 0.85,
      size: 0.8 + _rng.nextDouble() * 2.2,
      opacity: 0.3 + _rng.nextDouble() * 0.6,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(s.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter o) => false;
}

class _LightRaysPainter extends CustomPainter {
  final double t;
  final Size screenSize;

  _LightRaysPainter(this.t, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * math.pi + t * math.pi;
      final r1 = 80.0;
      final r2 = 160.0 + math.sin(t * math.pi * 2 + i) * 30;
      final opacity = 0.08 + math.sin(t * math.pi * 2 + i * 0.4).abs() * 0.12;
      final paint = Paint()
        ..color = const Color(0xFFFBBF24).withOpacity(opacity)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + Offset(math.cos(angle) * r1, math.sin(angle) * r1),
        center + Offset(math.cos(angle) * r2, math.sin(angle) * r2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LightRaysPainter o) => o.t != t;
}

class _MagicParticlePainter extends CustomPainter {
  final double t;
  final Size screenSize;

  static final _rng = math.Random(99);
  static final _particles = List.generate(
    30,
    (i) => (
      x: _rng.nextDouble(),
      y: 0.9 - _rng.nextDouble() * 0.5,
      speed: 0.3 + _rng.nextDouble() * 0.7,
      size: 2.0 + _rng.nextDouble() * 5,
      colorIdx: _rng.nextInt(3),
    ),
  );
  static const _colors = [
    Color(0xFFFBBF24),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
  ];

  _MagicParticlePainter(this.t, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final progress = (t * p.speed) % 1.0;
      final x = p.x * size.width + math.sin(progress * math.pi * 3) * 18;
      final y = p.y * size.height - progress * size.height * 0.55;
      if (y < 0) continue;

      final paint = Paint()
        ..color = _colors[p.colorIdx].withOpacity(
            0.7 * (1 - progress * 0.6))
        ..style = PaintingStyle.fill;

      // Draw sparkle
      final sparkSize = p.size * (1 - progress * 0.4);
      canvas.drawCircle(Offset(x, y), sparkSize, paint);

      // Cross sparkle lines
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.4 * (1 - progress))
        ..strokeWidth = 1;
      canvas.drawLine(
          Offset(x, y - sparkSize * 1.8),
          Offset(x, y + sparkSize * 1.8),
          linePaint);
      canvas.drawLine(
          Offset(x - sparkSize * 1.8, y),
          Offset(x + sparkSize * 1.8, y),
          linePaint);
    }
  }

  @override
  bool shouldRepaint(_MagicParticlePainter o) => o.t != t;
}
