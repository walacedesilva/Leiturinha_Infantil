import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../../services/audio_manager.dart';
import 'corrida_silabas_screen.dart';
import 'dashboard_relatorio_screen.dart';
import 'bairro_das_familias_screen.dart';
import 'vila_das_vogais_screen.dart';
import 'praca_central_screen.dart';
import 'reino_historias_screen.dart';
import 'torre_do_conhecimento_screen.dart';
import 'missao_decodificacao_galactica_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MAPA DE APRENDIZADO — ILHA DAS PALAVRAS PREMIUM
// Interface 2.5D Viva:
// - Cada ilha/etapa possui seu próprio ecossistema visual e de partículas.
// - Trilha estelar conectada com fluxo de pulso laser dinâmico.
// - Micro-interações táteis elásticas e transições 60fps.
// ═══════════════════════════════════════════════════════════════════════════

// ─── Data State ──────────────────────────────────────────────────────────────
enum _IslandState { completed, current, locked }

class _IslandData {
  final String id;
  final String name;
  final String emoji;
  final Color primaryColor;
  final Color lightColor;
  final _IslandState state;
  final int completed;
  final int total;
  final bool isSoon;
  final double fx;
  final double fy;

  const _IslandData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primaryColor,
    required this.lightColor,
    required this.state,
    required this.completed,
    required this.total,
    this.isSoon = false,
    required this.fx,
    required this.fy,
  });
}

// Map Layout parameters
const double _kIconCenterOffsetY = 36.0;
const double _kIslandHalfW = 65.0;

// ═══════════════════════════════════════════════════════════════════════════
// MAIN MAP SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class IlhaDasPalavrasScreen extends StatefulWidget {
  const IlhaDasPalavrasScreen({super.key});

  @override
  State<IlhaDasPalavrasScreen> createState() => _IlhaDasPalavrasScreenState();
}

class _IlhaDasPalavrasScreenState extends State<IlhaDasPalavrasScreen>
    with TickerProviderStateMixin {
  late final AnimationController _diagonalSkyCtrl;
  late final AnimationController _roadFlowCtrl;
  late final AnimationController _avatarSpinCtrl;

  @override
  void initState() {
    super.initState();
    _diagonalSkyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _roadFlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _avatarSpinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _diagonalSkyCtrl.dispose();
    _roadFlowCtrl.dispose();
    _avatarSpinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();

    // 1. Calculate Vila das Vogais progress
    int vogaisCompletedFamilies = 0;
    for (final v in ['A', 'E', 'I', 'O', 'U']) {
      if (progress.getFamilyProgress('vogal_$v', 3).isCompleted) {
        vogaisCompletedFamilies++;
      }
    }
    bool vogaisComplete = vogaisCompletedFamilies >= 5;

    // 2. Calculate Bairro das Famílias progress
    int bairroDone = 0;
    for (final f in ['B', 'C', 'D', 'F', 'M']) {
      if (progress.getFamilyProgress(f, 5).isCompleted) {
        bairroDone++;
      }
    }
    bool bairroPassed = bairroDone >= 1;

    // 3. Assemble dynamic 5-island serpentine learning pathway
    final islands = <_IslandData>[
      _IslandData(
        id: 'vogais',
        name: 'Vila das\nVogais',
        emoji: '🌱',
        primaryColor: const Color(0xFF4ADE80),
        lightColor: const Color(0xFFECFDF5),
        state: vogaisComplete ? _IslandState.completed : _IslandState.current,
        completed: vogaisCompletedFamilies,
        total: 5,
        fx: 0.20,
        fy: 0.14,
      ),
      _IslandData(
        id: 'familias',
        name: 'Bairro das\nFamílias',
        emoji: '🏠',
        primaryColor: const Color(0xFFF97316),
        lightColor: const Color(0xFFFFF7ED),
        state: !vogaisComplete
            ? _IslandState.locked
            : (bairroDone >= 5 ? _IslandState.completed : _IslandState.current),
        completed: bairroDone,
        total: 5,
        fx: 0.65,
        fy: 0.28,
      ),
      _IslandData(
        id: 'silabas',
        name: 'Cidade das\nSílabas',
        emoji: '🏙️',
        primaryColor: const Color(0xFF06B6D4),
        lightColor: const Color(0xFFECFEFF),
        state: !bairroPassed ? _IslandState.locked : _IslandState.current,
        completed: 1,
        total: 5,
        fx: 0.28,
        fy: 0.48,
      ),
      _IslandData(
        id: 'historias',
        name: 'Reino das\nHistórias',
        emoji: '🌟',
        primaryColor: const Color(0xFFFBBF24),
        lightColor: const Color(0xFFFFFDF5),
        state: !bairroPassed ? _IslandState.locked : _IslandState.current,
        completed: 0,
        total: 5,
        fx: 0.72,
        fy: 0.65,
      ),
      _IslandData(
        id: 'portal',
        name: 'Portal Estelar\nDecodificação Galáctica',
        emoji: '🔮',
        primaryColor: const Color(0xFF8B5CF6),
        lightColor: const Color(0xFFF5F3FF),
        state: _IslandState.current, // keep always active for premium space hub access
        completed: 3,
        total: 10,
        fx: 0.36,
        fy: 0.81,
      ),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: _diagonalSkyCtrl,
        builder: (context, child) {
          // Living diagonal sky background gradient
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF5BC8F5), const Color(0xFF1E3A8A), _diagonalSkyCtrl.value)!,
                  Color.lerp(const Color(0xFFB3E5FC), const Color(0xFF4A148C), _diagonalSkyCtrl.value)!,
                  Color.lerp(const Color(0xFFE0F7FA), const Color(0xFF311B92), _diagonalSkyCtrl.value)!,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // Top HUD with rotating neon avatar
              _TopBar(
                coins: gam.state.coins,
                xp: gam.state.xp,
                avatarSpinCtrl: _avatarSpinCtrl,
              ),

              // Interactive map viewport
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final totalH = constraints.maxHeight;
                    const btnAreaH = 144.0;
                    final mapH = totalH - btnAreaH;

                    final centers = islands
                        .map((i) => Offset(i.fx * w, i.fy * mapH))
                        .toList(growable: false);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Parallax floating decorative clouds
                        _buildParallaxCloud(50, 85, 0.45, 20000),
                        _buildParallaxCloud(120, 60, 0.35, 28000),
                        _buildParallaxCloud(280, 70, 0.30, 16000),

                        // Spline gold laser connections with flowing wave pulse
                        Positioned(
                          top: 0,
                          left: 0,
                          width: w,
                          height: mapH,
                          child: AnimatedBuilder(
                            animation: _roadFlowCtrl,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _SplinePathPainter(
                                  centers: centers,
                                  progress: _roadFlowCtrl.value,
                                ),
                              );
                            },
                          ),
                        ),

                        // Serpentine Island Platform list
                        ...islands.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final island = entry.value;
                          final c = centers[idx];
                          return Positioned(
                            left: c.dx - _kIslandHalfW - 10,
                            top: c.dy - _kIconCenterOffsetY - 10,
                            child: _IslandWidget(
                              island: island,
                              index: idx,
                              animDelay: Duration(milliseconds: 140 * idx),
                              onTap: island.state == _IslandState.locked
                                  ? () => _showLockedFeedback(context)
                                  : () => _handleIslandNavigation(context, island.id),
                            ),
                          );
                        }),

                        // Animated Main CTA Play button at the bottom center
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: const _PlayButton()
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scaleXY(begin: 1.0, end: 1.04, duration: 1500.ms, curve: Curves.easeInOut)
                                .shimmer(duration: 2500.ms, color: Colors.white.withOpacity(0.5)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParallaxCloud(double top, double size, double opacity, int durationMs) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: size,
      child: IgnorePointer(
        child: Container()
            .animate(onPlay: (c) => c.repeat())
            .custom(
              duration: Duration(milliseconds: durationMs),
              builder: (context, value, child) {
                final w = MediaQuery.sizeOf(context).width;
                final double x = -size + (value * (w + size * 2));
                return Stack(
                  children: [
                    Positioned(
                      left: x,
                      child: Opacity(
                        opacity: opacity,
                        child: Text('☁️', style: TextStyle(fontSize: size * 0.7)),
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }

  void _showLockedFeedback(BuildContext context) {
    AudioManager().playSFX(SFXType.error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Estude os distritos anteriores para liberar este reino!',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFD946EF),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _handleIslandNavigation(BuildContext context, String id) {
    AudioManager().playSFX(SFXType.pop);
    final Widget screen = switch (id) {
      'vogais' => const VilaDasVogaisScreen(),
      'familias' => const BairroDasFamiliasScreen(),
      'silabas' => const PracaCentralScreen(),
      'historias' => const ReinoHistoriasScreen(),
      'portal' => const MissaoDecodificacaoGalacticaScreen(),
      _ => const VilaDasVogaisScreen(),
    };
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => screen,
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
          return ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SPLINE ROAD PATH PAINTER WITH ACTIVE FLUID WAVE
// ═══════════════════════════════════════════════════════════════════════════

class _SplinePathPainter extends CustomPainter {
  final List<Offset> centers;
  final double progress;

  const _SplinePathPainter({required this.centers, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    final shadowPaint = Paint()
      ..color = const Color(0xFFD97706).withOpacity(0.24)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final pathPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final innerTrail = Paint()
      ..color = const Color(0xFFFFF9C4).withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < centers.length - 1; i++) {
      final p1 = centers[i];
      final p2 = centers[i + 1];

      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;

      final sign = (i % 2 == 0) ? 1.2 : -1.2;
      final ctrl = Offset(
        midX + sign * (-dy) * 0.2,
        midY + sign * dx * 0.2,
      );

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);

      // Draw primary golden paths
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, pathPaint);
      canvas.drawPath(path, innerTrail);

      // Render traveling neon laser pulse along the spline
      for (final metric in path.computeMetrics()) {
        final double totalLen = metric.length;
        for (int k = 0; k < 2; k++) {
          final double offset = (totalLen * (progress + k / 2.0)) % totalLen;
          final tangent = metric.getTangentForOffset(offset);
          if (tangent != null) {
            final pulsePaint = Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill;
            final pulseGlow = Paint()
              ..color = const Color(0xFF00F2FE)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

            canvas.drawCircle(tangent.position, 6, pulseGlow);
            canvas.drawCircle(tangent.position, 2.5, pulsePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SplinePathPainter old) =>
      old.centers != centers || old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// DYNAMIC THEMED PARTICLE EMITTER
// ═══════════════════════════════════════════════════════════════════════════

class _IslandParticles extends StatefulWidget {
  final String id;
  final Widget child;

  const _IslandParticles({required this.id, required this.child});

  @override
  State<_IslandParticles> createState() => _IslandParticlesState();
}

class _IslandParticlesState extends State<_IslandParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _IslandParticlePainter(
                  islandId: widget.id,
                  progress: _ctrl.value,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _IslandParticlePainter extends CustomPainter {
  final String islandId;
  final double progress;
  final List<_ParticleSpecs> specs;

  _IslandParticlePainter({required this.islandId, required this.progress})
      : specs = _generateSpecs(islandId);

  static final Map<String, List<_ParticleSpecs>> _cachedSpecs = {};

  static List<_ParticleSpecs> _generateSpecs(String id) {
    if (_cachedSpecs.containsKey(id)) return _cachedSpecs[id]!;
    final random = math.Random(id.hashCode);
    final list = <_ParticleSpecs>[];
    for (int i = 0; i < 8; i++) {
      list.add(_ParticleSpecs(
        xPct: random.nextDouble() * 0.8 + 0.1,
        yPct: random.nextDouble(),
        speed: 0.1 + random.nextDouble() * 0.15,
        size: 2.0 + random.nextDouble() * 4.0,
        opacity: 0.15 + random.nextDouble() * 0.45,
      ));
    }
    _cachedSpecs[id] = list;
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Color color;
    switch (islandId) {
      case 'vogais':
        color = const Color(0xFF4ADE80); // Lime green leaf dust
      case 'familias':
        color = const Color(0xFFF97316); // Heart coral dust
      case 'silabas':
        color = const Color(0xFF00F2FE); // Blue cyber letters
      case 'historias':
        color = const Color(0xFFFFF176); // Gold sparkle dust
      case 'portal':
        color = const Color(0xFFC084FC); // Purple cosmos space
      default:
        color = Colors.white;
    }

    final paint = Paint()..style = PaintingStyle.fill;

    for (final s in specs) {
      double y = size.height - ((s.yPct * size.height + progress * s.speed * size.height) % size.height);
      double x = s.xPct * size.width;

      final double pulse = 0.3 + 0.7 * math.sin(progress * 2 * math.pi + s.xPct * 10);
      paint.color = color.withOpacity(s.opacity * pulse);

      canvas.drawCircle(Offset(x, y), s.size * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _IslandParticlePainter oldDelegate) => true;
}

class _ParticleSpecs {
  final double xPct;
  final double yPct;
  final double speed;
  final double size;
  final double opacity;

  _ParticleSpecs({
    required this.xPct,
    required this.yPct,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// INDIVIDUAL ISLAND WIDGET (ELASTIC TACTILE INPUT)
// ═══════════════════════════════════════════════════════════════════════════

class _IslandWidget extends StatefulWidget {
  final _IslandData island;
  final int index;
  final Duration animDelay;
  final VoidCallback onTap;

  const _IslandWidget({
    required this.island,
    required this.index,
    required this.animDelay,
    required this.onTap,
  });

  @override
  State<_IslandWidget> createState() => _IslandWidgetState();
}

class _IslandWidgetState extends State<_IslandWidget>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.island.state == _IslandState.locked;

    return GestureDetector(
      onTapDown: (_) {
        if (!isLocked) {
          setState(() {
            _scale = 0.92;
          });
        }
      },
      onTapCancel: () {
        if (!isLocked) {
          setState(() {
            _scale = 1.0;
          });
        }
      },
      onTapUp: (_) {
        if (!isLocked) {
          setState(() {
            _scale = 1.0;
          });
        }
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emitter context stack for floating particles
            _IslandParticles(
              id: widget.island.id,
              child: SizedBox(
                width: 140,
                height: 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Floating Platform base
                    Positioned(
                      top: 40,
                      child: _CustomIslandPlatform(
                        island: widget.island,
                        isLocked: isLocked,
                      ),
                    ),
                    // Floating active / locked icon circle
                    Positioned(
                      top: 6,
                      child: _CustomIconCircle(
                        island: widget.island,
                        isLocked: isLocked,
                      ),
                    ),
                    // Spring bounce state badge
                    Positioned(
                      right: 14,
                      top: 2,
                      child: _CustomStateBadge(state: widget.island.state)
                          .animate()
                          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 500.ms, curve: Curves.bounceOut),
                    ),
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 3000.ms, curve: Curves.easeInOut), // Float animation
            const SizedBox(height: 4),

            if (widget.island.id == 'portal')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E0F45), Color(0xFF2D1664), Color(0xFF130730)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFBBF24), width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Portal Estelar -',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Missão Galáctica',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              // Sleek glassmorphic text pill label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
                ),
                child: Text(
                  widget.island.name.replaceAll('\n', ' '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isLocked ? Colors.white.withOpacity(0.4) : Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 5),

            // Responsive chapter indicator
            _ProgressLabel(
              completed: widget.island.completed,
              total: widget.island.total,
              state: widget.island.state,
              isSoon: widget.island.isSoon,
            ),
          ],
        ),
      ),
    )
        .animate(delay: widget.animDelay)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.75, 0.75), end: const Offset(1.0, 1.0), duration: 450.ms, curve: Curves.easeOutBack);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM ISLAND 2.5D PLATFORMS
// ═══════════════════════════════════════════════════════════════════════════

class _CustomIslandPlatform extends StatelessWidget {
  final _IslandData island;
  final bool isLocked;

  const _CustomIslandPlatform({required this.island, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final Gradient baseGrad;
    final Gradient depthGrad;
    Color borderGlow;

    if (isLocked) {
      baseGrad = const LinearGradient(
        colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
      );
      depthGrad = const LinearGradient(
        colors: [Color(0xFF374151), Color(0xFF1F2937)],
      );
      borderGlow = Colors.transparent;
    } else {
      borderGlow = island.primaryColor;
      switch (island.id) {
        case 'vogais':
          baseGrad = const LinearGradient(colors: [Color(0xFF86EFAC), Color(0xFF22C55E)]);
          depthGrad = const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF14532D)]);
        case 'familias':
          baseGrad = const LinearGradient(colors: [Color(0xFFFDBA74), Color(0xFFF97316)]);
          depthGrad = const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFF7C2D12)]);
        case 'silabas':
          baseGrad = const LinearGradient(colors: [Color(0xFF67E8F9), Color(0xFF06B6D4)]);
          depthGrad = const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF164E63)]);
        case 'historias':
          baseGrad = const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]);
          depthGrad = const LinearGradient(colors: [Color(0xFFD97706), Color(0xFF78350F)]);
        case 'portal':
          baseGrad = const LinearGradient(colors: [Color(0xFFC084FC), Color(0xFF8B5CF6)]);
          depthGrad = const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF3B0764)]);
        default:
          baseGrad = const LinearGradient(colors: [Colors.grey, Colors.black]);
          depthGrad = const LinearGradient(colors: [Colors.black, Colors.black]);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Platform top lid
        Container(
          width: 98,
          height: 28,
          decoration: BoxDecoration(
            gradient: baseGrad,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
              bottom: Radius.circular(6),
            ),
            border: Border.all(
              color: isLocked ? Colors.transparent : borderGlow.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isLocked ? Colors.black26 : borderGlow.withOpacity(0.24),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        // Extrusion wall thickness
        Container(
          width: 78,
          height: 18,
          decoration: BoxDecoration(
            gradient: depthGrad,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM HIGHLIGHT ICON SPHERES
// ═══════════════════════════════════════════════════════════════════════════

class _CustomIconCircle extends StatelessWidget {
  final _IslandData island;
  final bool isLocked;

  const _CustomIconCircle({required this.island, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final bg = isLocked ? const Color(0xFF4B5563) : island.primaryColor;
    final isDone = island.state == _IslandState.completed;

    if (island.id == 'portal' && !isLocked) {
      // Spectacular premium swirling portal vortex matching the image!
      return SizedBox(
        width: 90,
        height: 90,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Golden Swirling Vortex Outer (Spinning)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    const Color(0xFFFFF9C4).withOpacity(0.0),
                    const Color(0xFFFBBF24).withOpacity(0.85),
                    const Color(0xFFF59E0B).withOpacity(0.95),
                    const Color(0xFFD97706).withOpacity(0.7),
                    const Color(0xFFFFF9C4).withOpacity(0.0),
                  ],
                ),
              ),
            )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 3500.ms),
              
            // 2. Counter-rotating gold inner swirl
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.0),
                    const Color(0xFFFFF176).withOpacity(0.75),
                    const Color(0xFFFFD700).withOpacity(0.85),
                    const Color(0xFFFBBF24).withOpacity(0.0),
                  ],
                ),
              ),
            )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 2200.ms, begin: 1.0, end: 0.0),

            // 3. Central Dark Core Sphere
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF150A36),
                border: Border.all(
                  color: const Color(0xFFFBBF24),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withOpacity(0.55),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: CustomPaint(
                  painter: _ConstellationPainter(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget center = Center(
      child: Text(
        island.emoji,
        style: const TextStyle(fontSize: 38),
      ),
    );

    // sway swaying plant leaves for vogais
    if (island.id == 'vogais' && !isLocked) {
      center = center
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(begin: -0.05, end: 0.05, duration: 1500.ms, curve: Curves.easeInOut);
    }
    // crown spinning flares for historias
    if (island.id == 'historias' && !isLocked) {
      center = center
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.9, end: 1.1, duration: 1200.ms);
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLocked
              ? Colors.grey.shade400
              : isDone
                  ? const Color(0xFFFFF176)
                  : Colors.white,
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLocked ? Colors.black : island.primaryColor).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: center,
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: isLocked ? 1.0 : (isDone ? 1.05 : 1.02),
          duration: 2000.ms,
        );
  }
}

class _CustomStateBadge extends StatelessWidget {
  final _IslandState state;

  const _CustomStateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _IslandState.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        );
      case _IslandState.current:
        return const Text('✨', style: TextStyle(fontSize: 18))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.8, end: 1.25, duration: 800.ms);
      case _IslandState.locked:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF6B7280),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 12),
        );
    }
  }
}

class _ProgressLabel extends StatelessWidget {
  final int completed;
  final int total;
  final _IslandState state;
  final bool isSoon;

  const _ProgressLabel({
    required this.completed,
    required this.total,
    required this.state,
    required this.isSoon,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = state == _IslandState.completed;
    final isLocked = state == _IslandState.locked;

    final Color bg;
    final String label;

    if (isDone) {
      bg = const Color(0xFF22C55E);
      label = 'Completo';
    } else if (!isLocked) {
      bg = const Color(0xFF00F2FE);
      label = 'Capítulo $completed/$total';
    } else if (isSoon) {
      bg = const Color(0xFF6B7280);
      label = 'Em breve';
    } else {
      bg = const Color(0xFF6B7280);
      label = 'Bloqueado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP HUD HEADER BAR
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final int coins;
  final int xp;
  final AnimationController avatarSpinCtrl;

  const _TopBar({
    required this.coins,
    required this.xp,
    required this.avatarSpinCtrl,
  });

  String get _levelName {
    if (xp < 50) return 'Explorador';
    if (xp < 150) return 'Aventureiro';
    if (xp < 300) return 'Descobridor';
    return 'Mestre';
  }

  int get _levelNumber {
    if (xp < 50) return 1;
    if (xp < 150) return 2;
    if (xp < 300) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      child: Row(
        children: [
          // Rotating neon gradient avatar badge
          RotationTransition(
            turns: avatarSpinCtrl,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFF00F2FE),
                    Color(0xFF8B5CF6),
                    Color(0xFFD946EF),
                    Color(0xFF00F2FE),
                  ],
                ),
              ),
              child: RotationTransition(
                turns: ReverseAnimation(avatarSpinCtrl),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('👦', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Player Rank & Level tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _levelName,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Nível $_levelNumber',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Glowing coins pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Chart metric top-right button
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DashboardRelatorioScreen()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.08, duration: 1500.ms),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CTA PLAY GAME BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  Widget _resolveActiveScreen(BuildContext context) {
    final progress = context.read<ProgressService>();

    int vogaisCompletedFamilies = 0;
    for (final v in const ['A', 'E', 'I', 'O', 'U']) {
      if (progress.getFamilyProgress('vogal_$v', 3).isCompleted) {
        vogaisCompletedFamilies++;
      }
    }
    final bool vogaisComplete = vogaisCompletedFamilies >= 5;

    if (!vogaisComplete) {
      return const VilaDasVogaisScreen();
    }

    int bairroDone = 0;
    for (final f in const ['B', 'C', 'D', 'F', 'M']) {
      if (progress.getFamilyProgress(f, 5).isCompleted) {
        bairroDone++;
      }
    }
    final bool bairroPassed = bairroDone >= 1;

    if (!bairroPassed || bairroDone < 5) {
      return const BairroDasFamiliasScreen();
    }

    return const PracaCentralScreen();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioManager().playSFX(SFXType.correct);
        final screen = _resolveActiveScreen(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => screen,
          ),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF176), Color(0xFFF57F17)],
          ),
          border: Border.all(color: Colors.white, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF57F17).withOpacity(0.55),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_rounded, color: Colors.white, size: 36),
            SizedBox(height: 3),
            Text(
              'JOGAR\nAGORA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: Colors.white,
                height: 1.1,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// PORTAL ESTELAR CONSTELLATION PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
      
    final paintStar = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final paintGlow = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Relatives coordinates matching the golden whirlpool reference image constellation
    final stars = [
      Offset(cx - 16, cy - 8),  // Left-top
      Offset(cx - 6, cy - 10),  // Mid-left-top
      Offset(cx + 12, cy - 12), // Right-top
      Offset(cx + 14, cy + 6),  // Right-bottom
      Offset(cx + 2, cy + 18),  // Mid-right-bottom
      Offset(cx - 10, cy + 4),  // Left-bottom
    ];

    // Connection paths
    canvas.drawLine(stars[0], stars[1], paintLine);
    canvas.drawLine(stars[1], stars[2], paintLine);
    canvas.drawLine(stars[2], stars[3], paintLine);
    canvas.drawLine(stars[3], stars[4], paintLine);
    canvas.drawLine(stars[4], stars[5], paintLine);
    canvas.drawLine(stars[5], stars[0], paintLine);
    canvas.drawLine(stars[1], stars[5], paintLine); // Inner cross closing connection

    // Draw glowing stars
    for (final s in stars) {
      canvas.drawCircle(s, 6.0, paintGlow);
      canvas.drawCircle(s, 3.0, paintStar);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) => false;
}
                              