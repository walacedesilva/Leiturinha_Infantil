import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import 'praca_central_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CELEBRAÇÃO FINAL DOS DÍGRAFOS — "Alquimista Mestre"
// Paleta: Dourado #FBBF24, Roxo #8B5CF6, Branco
// ═════════════════════════════════════════════════════════════════════════════

const _kGold       = Color(0xFFFBBF24);
const _kGoldDeep   = Color(0xFFD97706);
const _kGoldLight  = Color(0xFFFDE68A);
const _kPurple     = Color(0xFF8B5CF6);
const _kPurpleDark = Color(0xFF6D28D9);
const _kLavender   = Color(0xFFA78BFA);

class DigrafosCelebrationScreen extends StatefulWidget {
  const DigrafosCelebrationScreen({super.key});

  @override
  State<DigrafosCelebrationScreen> createState() =>
      _DigrafosCelebrationScreenState();
}

class _DigrafosCelebrationScreenState
    extends State<DigrafosCelebrationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fireworkCtrl;
  late final AnimationController _bookCtrl;
  late final AnimationController _bannerCtrl;
  late final AnimationController _mascotCtrl;
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();

    _fireworkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _bookCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Award coins + XP
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      AudioManager().playSFX(SFXType.balloons);
      await Future.delayed(const Duration(milliseconds: 500));
      AudioManager().playWord('Parabéns! Você é um Mestre dos Dígrafos!');
      final gam = context.read<GamificationService>();
      await gam.addXp(150);
      await gam.addCoins(75);
    });
  }

  @override
  void dispose() {
    _fireworkCtrl.dispose();
    _bookCtrl.dispose();
    _bannerCtrl.dispose();
    _mascotCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background: lab transformed into celebration hall
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF4C1D95),
                    Color(0xFF1E1040),
                    Color(0xFF0D0823),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Purple-gold banners (decorative)
          AnimatedBuilder(
            animation: _bannerCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(painter: _BannerPainter(_bannerCtrl.value)),
            ),
          ),
          // Fireworks
          AnimatedBuilder(
            animation: _fireworkCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(painter: _FireworkPainter(_fireworkCtrl.value)),
            ),
          ),
          // Particles / sparkles
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(painter: _SparkPainter(_particleCtrl.value)),
            ),
          ),
          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Magic cauldron → book animation
                  AnimatedBuilder(
                    animation: _bookCtrl,
                    builder: (_, __) => _CauldronToBook(t: _bookCtrl.value),
                  ),
                  const SizedBox(height: 20),
                  // "Parabéns!" title
                  Column(
                    children: [
                      Text(
                        '✨ Parabéns! ✨',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _kGold,
                          shadows: [
                            Shadow(
                              color: _kGold.withOpacity(0.8),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
                      const SizedBox(height: 4),
                      const Text(
                        'Mestre dos Dígrafos!',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Mascots row
                  AnimatedBuilder(
                    animation: _mascotCtrl,
                    builder: (_, __) => _MascotsRow(bounce: _mascotCtrl.value),
                  ),
                  const SizedBox(height: 24),
                  // Rewards card
                  _RewardsCard().animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                  const SizedBox(height: 20),
                  // Badge
                  _BadgeCard().animate().scale(delay: 700.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 28),
                  // CTA button
                  _NextButton().animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
                  const SizedBox(height: 32),
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
// CAULDRON → BOOK TRANSFORM
// ─────────────────────────────────────────────────────────────────────────────
class _CauldronToBook extends StatelessWidget {
  final double t;
  const _CauldronToBook({required this.t});

  @override
  Widget build(BuildContext context) {
    final cauldronOpacity = (1 - t * 2).clamp(0.0, 1.0);
    final bookOpacity     = ((t - 0.5) * 2).clamp(0.0, 1.0);
    final scale           = 0.7 + t * 0.3;

    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kGold.withOpacity(0.4 * scale),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          // Cauldron (fades out)
          if (cauldronOpacity > 0.01)
            Opacity(
              opacity: cauldronOpacity,
              child: SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(painter: _GoldenCauldronPainter()),
              ),
            ),
          // Open Book (fades in)
          if (bookOpacity > 0.01)
            Transform.scale(
              scale: 0.6 + bookOpacity * 0.4,
              child: Opacity(
                opacity: bookOpacity,
                child: SizedBox(
                  width: 140,
                  height: 110,
                  child: CustomPaint(painter: _OpenBookPainter()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoldenCauldronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.58;

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 95, height: 78),
      Paint()
        ..shader = const RadialGradient(
          colors: [_kGoldLight, _kGold, _kGoldDeep],
          center: Alignment(-0.3, -0.4),
          radius: 0.85,
        ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 95, height: 78))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    // Stars overflow
    final paint = Paint()..color = Colors.white.withOpacity(0.9);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r = 38.0 + math.sin(angle * 2) * 8;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * r, cy - 20 + math.sin(angle) * r * 0.4),
        3, paint,
      );
    }

    // Rim
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 6), width: 102, height: 26),
      Paint()
        ..color = _kGoldDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _OpenBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.55;

    // Left page
    final leftPath = Path()
      ..moveTo(cx - 2, cy - 36)
      ..lineTo(cx - 58, cy - 28)
      ..lineTo(cx - 62, cy + 28)
      ..lineTo(cx - 2, cy + 36)
      ..close();
    canvas.drawPath(
      leftPath,
      Paint()..color = const Color(0xFFFEF9C3),
    );

    // Right page
    final rightPath = Path()
      ..moveTo(cx + 2, cy - 36)
      ..lineTo(cx + 58, cy - 28)
      ..lineTo(cx + 62, cy + 28)
      ..lineTo(cx + 2, cy + 36)
      ..close();
    canvas.drawPath(
      rightPath,
      Paint()..color = const Color(0xFFFEF3C7),
    );

    // Spine
    canvas.drawLine(
      Offset(cx, cy - 38), Offset(cx, cy + 38),
      Paint()
        ..color = _kGoldDeep
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Digraph letters on pages
    final runes = ['CH', 'LH', 'NH', 'QU', 'GU'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < 5; i++) {
      final isLeft = i < 3;
      final xi = isLeft
          ? cx - 45.0 + (i % 3) * 18
          : cx + 10.0 + ((i - 3) % 2) * 24;
      final yi = cy - 18.0 + (i ~/ 2) * 18;
      textPainter.text = TextSpan(
        text: runes[i],
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: _kPurpleDark,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xi, yi));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// MASCOTS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _MascotsRow extends StatelessWidget {
  final double bounce;
  const _MascotsRow({required this.bounce});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Luna fox with diploma
        Transform.translate(
          offset: Offset(0, -bounce * 6),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFED7AA), Color(0xFFF97316)],
                      ),
                      boxShadow: [BoxShadow(color: _kGold.withOpacity(0.4), blurRadius: 10)],
                    ),
                  ),
                  const Text('🦊', style: TextStyle(fontSize: 32)),
                  const Positioned(bottom: 0, right: 0,
                      child: Text('🎓', style: TextStyle(fontSize: 16))),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Luna',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 11,
                      color: _kGoldLight, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Beto bear with wizard hat — center, bigger
        Transform.translate(
          offset: Offset(0, -bounce * 8),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF92400E).withOpacity(0.25),
                      boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.5), blurRadius: 16)],
                    ),
                  ),
                  const Text('🐻', style: TextStyle(fontSize: 44)),
                  const Positioned(top: 0, left: 0,
                      child: Text('🧙', style: TextStyle(fontSize: 22))),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Beto',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 11,
                      color: _kGoldLight, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Zeca rabbit juggling digraphs
        Transform.translate(
          offset: Offset(0, -bounce * 5 - 3),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE0E7FF).withOpacity(0.2),
                      boxShadow: [BoxShadow(color: _kLavender.withOpacity(0.5), blurRadius: 10)],
                    ),
                  ),
                  const Text('🐇', style: TextStyle(fontSize: 30)),
                  const Positioned(top: 0, right: 0,
                      child: Text('✨', style: TextStyle(fontSize: 14))),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Zeca',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 11,
                      color: _kGoldLight, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARDS CARD
// ─────────────────────────────────────────────────────────────────────────────
class _RewardsCard extends StatelessWidget {
  const _RewardsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B69), Color(0xFF4C1D95), Color(0xFF3B0764)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kGold.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Recompensas',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kGold,
            ),
          ),
          const Divider(color: Color(0xFF6D28D9), height: 20),
          _RewardRow(emoji: '🪙', label: '+75 moedas', color: _kGold),
          const SizedBox(height: 10),
          _RewardRow(emoji: '⭐', label: '+150 XP', color: _kGoldLight),
          const SizedBox(height: 10),
          _RewardRow(emoji: '🏆', label: 'Badge: Alquimista Mestre', color: _kLavender),
          const SizedBox(height: 10),
          _RewardRow(emoji: '🧙', label: 'Chapéu de Alquimista desbloqueado!', color: Colors.white),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String emoji, label;
  final Color color;
  const _RewardRow({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: _kGold, size: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  const _BadgeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [_kGoldLight, _kGold, _kGoldDeep],
          radius: 0.8,
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: _kGold.withOpacity(0.8),
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧙‍♂️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 4),
          const Text(
            'Alquimista\nMestre',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1917),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEXT DISTRICT BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  const _NextButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate back to the central plaza
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PracaCentralScreen()),
          (route) => false,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kGold, _kGoldDeep, _kPurple],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _kGold.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🗺️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text(
              'PRÓXIMO DISTRITO',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────
class _FireworkPainter extends CustomPainter {
  final double t;
  _FireworkPainter(this.t);

  static final _rng = math.Random(11);
  static final _fireworks = List.generate(8, (i) => (
    x: _rng.nextDouble(),
    y: _rng.nextDouble() * 0.55,
    phase: _rng.nextDouble(),
    color: [
      const Color(0xFFFBBF24),
      const Color(0xFFA78BFA),
      const Color(0xFF60A5FA),
      const Color(0xFF34D399),
    ][i % 4],
  ));

  @override
  void paint(Canvas canvas, Size size) {
    for (final fw in _fireworks) {
      final phase = (t + fw.phase) % 1.0;
      if (phase > 0.8) continue; // reset gap

      final cx = fw.x * size.width;
      final cy = fw.y * size.height;

      // Burst particles
      for (int p = 0; p < 12; p++) {
        final angle = (p / 12) * math.pi * 2;
        final r = phase * 50;
        final px = cx + math.cos(angle) * r;
        final py = cy + math.sin(angle) * r;
        final alpha = (1 - phase / 0.8).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(px, py),
          3 - phase * 2,
          Paint()..color = fw.color.withOpacity(alpha * 0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FireworkPainter o) => o.t != t;
}

class _SparkPainter extends CustomPainter {
  final double t;
  _SparkPainter(this.t);

  static final _rng = math.Random(99);
  static final _sparks = List.generate(30, (_) => (
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    speed: 0.1 + _rng.nextDouble() * 0.3,
    phase: _rng.nextDouble(),
    size: 1.5 + _rng.nextDouble() * 3,
  ));

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _sparks) {
      final phase = (t * s.speed + s.phase) % 1.0;
      final alpha = math.sin(phase * math.pi) * 0.7;
      final x = s.x * size.width + math.sin(phase * math.pi * 2 + s.phase * 6) * 15;
      final y = s.y * size.height - phase * 100;
      canvas.drawCircle(
        Offset(x, y),
        s.size,
        Paint()
          ..color = _kGold.withOpacity(alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.t != t;
}

class _BannerPainter extends CustomPainter {
  final double t;
  _BannerPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final t2 = t.clamp(0.0, 1.0);
    // Banners: hanging from top corners
    final bannerColors = [_kGold, _kPurple, _kGold, _kLavender];
    for (int i = 0; i < 6; i++) {
      final x = size.width * (i / 5);
      final y = size.height * 0.04;
      final h = (30 + i % 3 * 10) * t2;
      final col = bannerColors[i % bannerColors.length];
      canvas.drawRect(
        Rect.fromLTWH(x - 8, y, 16, h),
        Paint()..color = col.withOpacity(0.35 * t2),
      );
      // Triangle bottom of banner
      final triPath = Path()
        ..moveTo(x - 8, y + h)
        ..lineTo(x, y + h + 10)
        ..lineTo(x + 8, y + h)
        ..close();
      canvas.drawPath(triPath, Paint()..color = col.withOpacity(0.45 * t2));
    }

    // Garland string
    final stringPaint = Paint()
      ..color = _kGold.withOpacity(0.3 * t2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(0, size.height * 0.05);
    for (int i = 1; i <= 6; i++) {
      final x1 = size.width * ((i - 1) / 6);
      final x2 = size.width * (i / 6);
      final mx = (x1 + x2) / 2;
      path.quadraticBezierTo(mx, size.height * 0.12, x2, size.height * 0.05);
    }
    canvas.drawPath(path, stringPaint);
  }

  @override
  bool shouldRepaint(_BannerPainter o) => o.t != t;
}
