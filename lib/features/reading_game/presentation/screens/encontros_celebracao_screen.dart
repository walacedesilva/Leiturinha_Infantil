import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import 'praca_central_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CELEBRAÇÃO DOS ENCONTROS — "Mestre dos Encontros"
// Paleta: Dourado #FBBF24 | Laranja #F97316 | Prata | Party colors
// Estilo: Industrial festivo Pixar — troféu engrenagem, mascotes, confetes
// ═════════════════════════════════════════════════════════════════════════════

const _kGold       = Color(0xFFFBBF24);
const _kGoldDeep   = Color(0xFFD97706);
const _kGoldLight  = Color(0xFFFEF3C7);
const _kOrange     = Color(0xFFF97316);
const _kOrangeDark = Color(0xFFEA580C);
const _kGreen      = Color(0xFF22C55E);
const _kBlue       = Color(0xFF3B82F6);
const _kPink       = Color(0xFFEC4899);
const _kSilver     = Color(0xFF9CA3AF);
const _kSilverLight= Color(0xFFE2E8F0);
const _kDark       = Color(0xFF1F2937);

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class EncontrosCelebracaoScreen extends StatefulWidget {
  const EncontrosCelebracaoScreen({super.key});

  @override
  State<EncontrosCelebracaoScreen> createState() =>
      _EncontrosCelebracaoScreenState();
}

class _EncontrosCelebracaoScreenState
    extends State<EncontrosCelebracaoScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _trophyCtrl;
  late final AnimationController _gearCtrl;
  late final AnimationController _mascotCtrl;
  late final AnimationController _lightCtrl;
  late final AnimationController _scrollCtrl;
  late final AnimationController _rayCtrl;

  @override
  void initState() {
    super.initState();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _trophyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _gearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _lightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scrollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _rayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    // SFX + TTS
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      AudioManager().playSFX(SFXType.balloons);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      AudioManager().playWord(
        'Parabéns! Você é o Mestre dos Encontros Consonantais!',
      );
    });

    // Recompensas finais
    Future.microtask(() {
      if (!mounted) return;
      final gam = context.read<GamificationService>();
      gam.addCoins(50);
      gam.addXp(100);
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _trophyCtrl.dispose();
    _gearCtrl.dispose();
    _mascotCtrl.dispose();
    _lightCtrl.dispose();
    _scrollCtrl.dispose();
    _rayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Fundo: fábrica com luzes de discoteca ────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _lightCtrl,
              builder: (_, __) => _FactoryDiscoBg(t: _lightCtrl.value),
            ),
          ),
          // ── Raios de luz do troféu ───────────────────────────────────────
          Positioned(
            top: size.height * 0.08,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _rayCtrl,
              builder: (_, __) => CustomPaint(
                size: Size(size.width, size.height * 0.5),
                painter: _VolumetricRayPainter(_rayCtrl.value, size),
              ),
            ),
          ),
          // ── Conteúdo scrollável ──────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Troféu central
                  _GearTrophy(
                    trophyT: _trophyCtrl,
                    gearT: _gearCtrl,
                  ),
                  const SizedBox(height: 16),
                  // Título
                  _CelebTitle(),
                  const SizedBox(height: 12),
                  // Diploma/scroll
                  _DiplomaScroll(
                    scrollT: _scrollCtrl,
                    gearT: _gearCtrl,
                  ),
                  const SizedBox(height: 16),
                  // Mascotes
                  _MascotsRow(mascotT: _mascotCtrl),
                  const SizedBox(height: 20),
                  // Recompensas
                  _RewardsModal(),
                  const SizedBox(height: 24),
                  // Botão próximo distrito
                  _ProximoDistritoButton(),
                  const SizedBox(height: 12),
                  _PlayAgainButton(),
                ],
              ),
            ),
          ),
          // ── Confetes ─────────────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(_confettiCtrl.value, size),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FACTORY DISCO BG
// ─────────────────────────────────────────────────────────────────────────────
class _FactoryDiscoBg extends StatelessWidget {
  final double t;
  const _FactoryDiscoBg({required this.t});

  @override
  Widget build(BuildContext context) {
    final hue1 = (t * 60).toInt(); // oscila entre laranja e dourado
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A),
            Color.fromARGB(
              255,
              (30 + t * 20).toInt(),
              (20 + t * 15).toInt(),
              0,
            ),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Opacity(
        opacity: 0.12,
        child: CustomPaint(
          painter: _FactoryWallPainter(),
        ),
      ),
    );
  }
}

class _FactoryWallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Grade industrial
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Bolhas de rebite
    final rivetPaint = Paint()
      ..color = _kGold.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    for (double x = 20; x < size.width; x += 40) {
      for (double y = 20; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 2.5, rivetPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// VOLUMETRIC RAY PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _VolumetricRayPainter extends CustomPainter {
  final double t;
  final Size screen;
  _VolumetricRayPainter(this.t, this.screen);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = 0.0;
    final numRays = 12;

    for (int i = 0; i < numRays; i++) {
      final angle = (i / numRays * 2 * math.pi) + t * math.pi * 2 / 8;
      final opacity =
          (math.sin(t * math.pi * 2 + i * 0.5) * 0.3 + 0.1).clamp(0.0, 0.45);
      final rayPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            _kGold.withOpacity(opacity),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: size.width,
            height: size.height * 2,
          ),
        )
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(
          cx + math.cos(angle - 0.12) * size.width,
          cy + math.sin(angle - 0.12) * size.height * 2,
        )
        ..lineTo(
          cx + math.cos(angle + 0.12) * size.width,
          cy + math.sin(angle + 0.12) * size.height * 2,
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(_VolumetricRayPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// GEAR TROPHY
// ─────────────────────────────────────────────────────────────────────────────
class _GearTrophy extends StatelessWidget {
  final AnimationController trophyT, gearT;
  const _GearTrophy({required this.trophyT, required this.gearT});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([trophyT, gearT]),
      builder: (_, __) {
        final dy = math.sin(trophyT.value * math.pi * 2) * 8;
        final glow = 0.5 + trophyT.value * 0.5;

        return Transform.translate(
          offset: Offset(0, dy),
          child: SizedBox(
            width: 180,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Brilho de fundo
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kGold.withOpacity(glow * 0.7),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Engrenagem giratória (base)
                Transform.rotate(
                  angle: gearT.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(140, 140),
                    painter: _TrophyGearPainter(glow),
                  ),
                ),
                // Troféu central
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🏆',
                      style: TextStyle(
                        fontSize: 54,
                        shadows: [
                          Shadow(
                            color: _kGold.withOpacity(0.8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '⭐',
                      style: TextStyle(
                        fontSize: 22,
                        shadows: [
                          Shadow(
                            color: _kGold.withOpacity(glow),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Pedestal
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 80,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kGoldDeep, _kGold, _kGoldDeep],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _kGold.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'MESTRE',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF78350F),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut);
  }
}

class _TrophyGearPainter extends CustomPainter {
  final double glow;
  _TrophyGearPainter(this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.47;
    final innerR = outerR * 0.70;
    final teeth = 16;
    final step = 2 * math.pi / teeth;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Gradiente dourado
    paint.shader = const LinearGradient(
      colors: [_kGold, _kGoldDeep, _kGold],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    for (int i = 0; i < teeth; i++) {
      final a0 = step * i;
      final a1 = a0 + step * 0.3;
      final a2 = a0 + step * 0.7;
      final a3 = a0 + step;
      final toothH = outerR * 0.22;
      if (i == 0) {
        path.moveTo(cx + innerR * math.cos(a0), cy + innerR * math.sin(a0));
      }
      path.lineTo(cx + (innerR + toothH) * math.cos(a1),
          cy + (innerR + toothH) * math.sin(a1));
      path.lineTo(cx + (innerR + toothH) * math.cos(a2),
          cy + (innerR + toothH) * math.sin(a2));
      path.lineTo(cx + innerR * math.cos(a3), cy + innerR * math.sin(a3));
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(cx, cy), innerR, paint);

    // Buraco central
    canvas.drawCircle(
      Offset(cx, cy),
      innerR * 0.32,
      Paint()..color = const Color(0xFF0F172A),
    );

    // Brilho glow externo
    canvas.drawCircle(
      Offset(cx, cy),
      outerR + 6,
      Paint()
        ..color = _kGold.withOpacity(glow * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_TrophyGearPainter o) => o.glow != glow;
}

// ─────────────────────────────────────────────────────────────────────────────
// TÍTULO DE CELEBRAÇÃO
// ─────────────────────────────────────────────────────────────────────────────
class _CelebTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'PARABÉNS,',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: _kGold,
            letterSpacing: 2,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_kOrange, _kGold, _kOrange],
          ).createShader(bounds),
          child: const Text(
            'MESTRE DOS ENCONTROS!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '🏭 Fábrica de Palavras desbloqueada! 🏭',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: -0.3, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIPLOMA SCROLL
// ─────────────────────────────────────────────────────────────────────────────
class _DiplomaScroll extends StatelessWidget {
  final AnimationController scrollT, gearT;
  const _DiplomaScroll({required this.scrollT, required this.gearT});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollT,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEFCE8), Color(0xFFFFF7ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGoldDeep, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                // Enrolamentos do pergaminho
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        width: 24,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _kGoldDeep,
                          borderRadius: BorderRadius.circular(5),
                        )),
                    Text(
                      '📜 DIPLOMA 📜',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _kGoldDeep,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                        width: 24,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _kGoldDeep,
                          borderRadius: BorderRadius.circular(5),
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Parabéns!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Você domina os encontros\nconsonantais:',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: _kDark,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Encontros aprendidos
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _ClusterBadge(cluster: 'BR', emoji: '🦁'),
                    _ClusterBadge(cluster: 'CL', emoji: '☀️'),
                    _ClusterBadge(cluster: 'TR', emoji: '🚂'),
                    _ClusterBadge(cluster: 'FL', emoji: '🌸'),
                    _ClusterBadge(cluster: 'PR', emoji: '🍽️'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: gearT,
                      builder: (_, __) => Transform.rotate(
                        angle: gearT.value * 2 * math.pi,
                        child: const Text('⚙️', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Engenheiro da Leitura',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kGoldDeep,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: gearT,
                      builder: (_, __) => Transform.rotate(
                        angle: -gearT.value * 2 * math.pi,
                        child: const Text('⚙️', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 500.ms)
            .slideY(begin: 0.4, curve: Curves.easeOut);
      },
    );
  }
}

class _ClusterBadge extends StatelessWidget {
  final String cluster, emoji;
  const _ClusterBadge({required this.cluster, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kOrange, _kGoldDeep],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            cluster,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Color(0x55000000),
                  blurRadius: 3,
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
// MASCOTES CELEBRANDO
// ─────────────────────────────────────────────────────────────────────────────
class _MascotsRow extends StatelessWidget {
  final AnimationController mascotT;
  const _MascotsRow({required this.mascotT});

  @override
  Widget build(BuildContext context) {
    const mascots = [
      ('🐻', '👷', 'Beto'),    // urso + capacete
      ('🦊', '🎉', 'Luna'),    // raposa
      ('🐰', '🎊', 'Zeca'),    // coelho
    ];

    return AnimatedBuilder(
      animation: mascotT,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(mascots.length, (i) {
            final phase = i / mascots.length * math.pi;
            final dy = math.sin(mascotT.value * math.pi * 2 + phase) * 8;
            final m = mascots[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _kGold.withOpacity(0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFFED7AA), _kOrange],
                            ),
                            border: Border.all(color: _kGold, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: _kOrange.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              m.$1,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        // EPI / acessório
                        Positioned(
                          top: 2,
                          child: Text(
                            m.$2,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.$3,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 500.ms)
        .slideY(begin: 0.5, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARDS MODAL
// ─────────────────────────────────────────────────────────────────────────────
class _RewardsModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kGold.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: _kGold.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              '🎁 Recompensas',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kGold,
              ),
            ),
            const SizedBox(height: 14),
            // Grid de recompensas
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: const [
                _RewardItem(icon: '🪙', label: '+50 moedas',  color: _kGold),
                _RewardItem(icon: '⭐', label: '+100 XP',      color: _kOrange),
                _RewardItem(icon: '🏆', label: 'Badge: Mestre', color: _kGoldDeep),
                _RewardItem(icon: '⛑️',  label: 'Capacete desbloqueado!', color: _kBlue),
              ],
            ),
            const SizedBox(height: 12),
            // Badge de conquista
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kGoldDeep, _kGold, _kGoldDeep],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⚙️', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Mestre dos Encontros',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF78350F),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('⚙️', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 1000.ms, duration: 500.ms)
        .slideY(begin: 0.4, curve: Curves.easeOut);
  }
}

class _RewardItem extends StatelessWidget {
  final String icon, label;
  final Color color;
  const _RewardItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTÃO PRÓXIMO DISTRITO
// ─────────────────────────────────────────────────────────────────────────────
class _ProximoDistritoButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          AudioManager().playSFX(SFXType.correct);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PracaCentralScreen()),
            (route) => false,
          );
        },
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kOrange, _kGold, _kOrange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: _kOrange.withOpacity(0.6),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _kGold.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🚀', style: TextStyle(fontSize: 26)),
              SizedBox(width: 12),
              Text(
                'PRÓXIMO DISTRITO',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Color(0x55000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Text('⚙️', style: TextStyle(fontSize: 22)),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 1200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut);
  }
}

class _PlayAgainButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        AudioManager().playSFX(SFXType.pop);
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.replay_rounded, color: Colors.white54, size: 18),
      label: const Text(
        'Jogar novamente',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFETTI PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double t;
  final Size screen;
  _ConfettiPainter(this.t, this.screen);

  static final _colors = [
    _kGold, _kOrange, _kGreen, _kBlue, _kPink,
    Colors.white, _kGoldDeep, const Color(0xFFA855F7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(77);

    for (int i = 0; i < 60; i++) {
      final phase = (t + i / 60.0) % 1.0;
      final x = rng.nextDouble() * size.width;
      final startY = -40.0;
      final endY = size.height + 40;
      final y = startY + (endY - startY) * phase;

      // Adiciona oscilação horizontal
      final sx = x + math.sin(phase * math.pi * 4 + i) * 24;

      final color = _colors[i % _colors.length];
      final opacity = (math.sin(phase * math.pi)).clamp(0.3, 1.0);
      final paint = Paint()..color = color.withOpacity(opacity);

      // Alterna entre formas
      final shape = i % 3;
      final sz = 4.0 + rng.nextDouble() * 5;
      final rot = phase * math.pi * 4 + i * 0.7;

      canvas.save();
      canvas.translate(sx, y);
      canvas.rotate(rot);
      if (shape == 0) {
        // Retângulo
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: sz * 1.6, height: sz * 0.7), paint);
      } else if (shape == 1) {
        // Círculo
        canvas.drawCircle(Offset.zero, sz * 0.5, paint);
      } else {
        // Losango
        final path = Path()
          ..moveTo(0, -sz * 0.7)
          ..lineTo(sz * 0.5, 0)
          ..lineTo(0, sz * 0.7)
          ..lineTo(-sz * 0.5, 0)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}
