import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import 'bairro_das_familias_screen.dart';
import 'castelo_das_palavras_screen.dart';
import 'circo_das_rimas_screen.dart';
import 'distrito_da_construcao_screen.dart';
import 'ilha_das_palavras_screen.dart';
import 'distrito_da_aventura_screen.dart';
import 'distrito_digrafos_screen.dart';
import 'distrito_encontros_screen.dart';
import 'metro_transition_screen.dart';
import 'parque_das_familias_screen.dart';
import 'vila_das_vogais_screen.dart';
import '../../../../services/avatar_service.dart';
import '../../../../navigation/nav_shell.dart';
import 'torre_do_conhecimento_screen.dart';
import 'missao_decodificacao_galactica_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum _DState { available, locked, comingSoon }

class _DistrictDef {
  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final Color primary;
  final Color light;
  final bool comingSoon;

  const _DistrictDef({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.primary,
    required this.light,
    required this.comingSoon,
  });
}

const _kDistricts = <_DistrictDef>[
  _DistrictDef(
    id: 'vogais',
    name: 'Vila das Vogais',
    subtitle: 'A · E · I · O · U',
    emoji: '🌸',
    primary: Color(0xFF66BB6A),
    light: Color(0xFFE8F5E9),
    comingSoon: false,
  ),
  _DistrictDef(
    id: 'silabas',
    name: 'Bairro das Sílabas',
    subtitle: 'B · C · D · F · G',
    emoji: '🏘️',
    primary: Color(0xFFEF6C00),
    light: Color(0xFFFFF3E0),
    comingSoon: false,
  ),
  _DistrictDef(
    id: 'familias',
    name: 'Parque das Famílias',
    subtitle: 'J · L · M · N',
    emoji: '🌳',
    primary: Color(0xFF388E3C),
    light: Color(0xFFF1F8E9),
    comingSoon: false,
  ),
  _DistrictDef(
    id: 'palavras',
    name: 'Castelo das Palavras',
    subtitle: 'P · R · S · T · V',
    emoji: '🏰',
    primary: Color(0xFF8E24AA),
    light: Color(0xFFF3E5F5),
    comingSoon: false,
  ),
  _DistrictDef(
    id: 'construcao',
    name: 'Dist. da Construção',
    subtitle: 'G · X · Z',
    emoji: '🏗️',
    primary: Color(0xFF22C55E),
    light: Color(0xFFF0FDF4),
    comingSoon: false,
  ),
  _DistrictDef(
    id: 'circo',
    name: 'Circo das Rimas',
    subtitle: 'Ritmo e rima',
    emoji: '🎪',
    primary: Color(0xFFD81B60),
    light: Color(0xFFFCE4EC),
    comingSoon: false,
  ),
  _DistrictDef(
    id: 'aventura',
    name: 'Dist. da Aventura',
    subtitle: 'Frases completas',
    emoji: '🚀',
    primary: Color(0xFF1565C0),
    light: Color(0xFFE3F2FD),
    comingSoon: false,
  ),
  _DistrictDef(
    id: 'digrafos',
    name: 'Dist. dos Dígrafos',
    subtitle: 'CH · LH · NH · QU',
    emoji: '🔮',
    primary: Color(0xFF5E35B1),
    light: Color(0xFFEDE7F6),
    comingSoon: false,
  ),
  _DistrictDef(
    id: 'encontros',
    name: 'Encontros Cons.',
    subtitle: 'BR · CL · TR · FL',
    emoji: '🏭',
    primary: Color(0xFFF97316),
    light: Color(0xFFFFF7ED),
    comingSoon: false,
  ),
  _DistrictDef(
    id: 'portal_estelar',
    name: 'Portal Estelar',
    subtitle: 'Decodificação Galáctica 🚀',
    emoji: '🔮',
    primary: Color(0xFFFFF176),
    light: Color(0xFFFFFDE7),
    comingSoon: false,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

bool _isVogaisComplete(ProgressService p) => const ['A', 'E', 'I', 'O', 'U']
    .every((v) => p.getFamilyProgress('vogal_$v', 3).isCompleted);

({int done, int total}) _vogaisCount(ProgressService p) {
  final done = const ['A', 'E', 'I', 'O', 'U']
      .fold(0, (s, v) => s + p.getFamilyProgress('vogal_$v', 3).completedWords);
  return (done: done, total: 15);
}

_DState _stateOf(int index, _DistrictDef d, ProgressService p) {
  // TODO: remover para produção — libera tudo para testes
  return _DState.available;
}

String _firstAvailableId(ProgressService p) {
  for (var i = 0; i < _kDistricts.length; i++) {
    if (_stateOf(i, _kDistricts[i], p) == _DState.available) {
      return _kDistricts[i].id;
    }
  }
  return 'vogais';
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PracaCentralScreen extends StatefulWidget {
  const PracaCentralScreen({super.key});

  @override
  State<PracaCentralScreen> createState() => _PracaCentralScreenState();
}

class _PracaCentralScreenState extends State<PracaCentralScreen>
    with TickerProviderStateMixin {
  // Cloud animation controllers — 4 clouds with staggered start positions
  late final List<AnimationController> _cloudCtrl;

  static const _cloudDefs = <({
    double top,
    double size,
    double opacity,
    int durationMs,
    double startFraction,
  })>[
    (top: 50, size: 90, opacity: 0.72, durationMs: 18000, startFraction: 0.0),
    (top: 95, size: 60, opacity: 0.55, durationMs: 24000, startFraction: 0.4),
    (top: 28, size: 50, opacity: 0.50, durationMs: 13000, startFraction: 0.65),
    (top: 130, size: 75, opacity: 0.65, durationMs: 21000, startFraction: 0.25),
  ];

  @override
  void initState() {
    super.initState();
    _cloudCtrl = _cloudDefs.map((cloud) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: cloud.durationMs),
      );
      ctrl.forward(from: cloud.startFraction);
      ctrl.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          ctrl.forward(from: 0.0);
        }
      });
      return ctrl;
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _cloudCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _navigateTo(BuildContext context, String id) {
    Widget? screen;
    switch (id) {
      case 'vogais':
        screen = const VilaDasVogaisScreen();
      case 'silabas':
        screen = const MetroTransitionScreen(
          districtName: 'Bairro das Sílabas',
          destination: BairroDasFamiliasScreen(),
        );
      case 'familias':
        screen = const MetroTransitionScreen(
          districtName: 'Parque das Famílias',
          destination: ParqueDasFamiliasScreen(),
        );
      case 'palavras':
        screen = const MetroTransitionScreen(
          districtName: 'Castelo das Palavras',
          destination: CastelodasPalavrasScreen(),
        );
      case 'construcao':
        screen = const MetroTransitionScreen(
          districtName: 'Distrito da Construção',
          destination: DistritoConstucaoScreen(),
        );
      case 'circo':
        screen = const MetroTransitionScreen(
          districtName: 'Circo das Rimas',
          destination: CircoDasRimasScreen(),
        );
      case 'aventura':
        screen = const MetroTransitionScreen(
          districtName: 'Distrito da Aventura',
          destination: DistritoAventuraScreen(),
        );
      case 'digrafos':
        screen = const MetroTransitionScreen(
          districtName: 'Distrito dos Dígrafos',
          destination: DistritoDigrafosScreen(),
        );
      case 'encontros':
        screen = const MetroTransitionScreen(
          districtName: 'Encontros Consonantais',
          destination: DistritoEncontrosScreen(),
        );
      case 'portal_estelar':
        screen = const MissaoDecodificacaoGalacticaScreen();
    }
    if (screen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🚀 Em breve! Estamos construindo este distrito.',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen!),
    );
  }

  void _onDistrictTap(BuildContext context, int index, _DState state) {
    switch (state) {
      case _DState.locked:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🔒 Complete os distritos anteriores primeiro!',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      case _DState.comingSoon:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🚀 Em breve! Ainda estamos construindo este distrito.',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      case _DState.available:
        _navigateTo(context, _kDistricts[index].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFF5BC8F5),
      body: Stack(
        children: [
          // ── Layer 1: Sky gradient ──────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF64B5F6),
                    Color(0xFF5BC8F5),
                    Color(0xFF80CBC4),
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
          // ── Layer 2: Animated clouds ───────────────────────────────────────
          ..._buildClouds(screenWidth),
          // ── Layer 3: Decorative city skyline ──────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _SkylinePainter(),
              size: Size(screenWidth, 110),
            ),
          ),
          // ── Layer 4: Main content ──────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  coins: gam.state.coins,
                  xp: gam.state.xp,
                  onMapTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const IlhaDasPalavrasScreen(),
                    ),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: _BetoWelcome(),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                        sliver: SliverToBoxAdapter(
                          child: _SectionLabel('🏙️ Distritos da Cidade'),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverGrid.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.82,
                          children: List.generate(
                            _kDistricts.length,
                            (i) {
                              final d = _kDistricts[i];
                              final state = _stateOf(i, d, progress);
                              final prog =
                                  i == 0 ? _vogaisCount(progress) : (done: 0, total: 0);
                              return _DistrictCard(
                                district: d,
                                state: state,
                                progressDone: prog.done,
                                progressTotal: prog.total,
                                delay: Duration(milliseconds: 80 * i),
                                onTap: () => _onDistrictTap(context, i, state),
                              );
                            },
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _TorreCard(),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 160),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Layer 5: Floating JOGAR button ────────────────────────────────
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _PlayButton(
                onTap: () =>
                    _navigateTo(context, _firstAvailableId(progress)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildClouds(double screenWidth) {
    return List.generate(_cloudDefs.length, (i) {
      final cloud = _cloudDefs[i];
      return AnimatedBuilder(
        animation: _cloudCtrl[i],
        builder: (_, child) {
          final x =
              -cloud.size + (_cloudCtrl[i].value * (screenWidth + cloud.size * 2));
          return Positioned(
            top: cloud.top,
            left: x,
            child: child!,
          );
        },
        child: _CloudShape(size: cloud.size, opacity: cloud.opacity),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLOUD SHAPE
// ─────────────────────────────────────────────────────────────────────────────

class _CloudShape extends StatelessWidget {
  final double size;
  final double opacity;

  const _CloudShape({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.65,
      child: Stack(
        children: [
          // Base body
          Positioned(
            bottom: 0,
            left: size * 0.1,
            right: size * 0.1,
            child: Container(
              height: size * 0.35,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          // Left puff
          Positioned(
            bottom: size * 0.18,
            left: 0,
            child: Container(
              width: size * 0.40,
              height: size * 0.40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Center puff (tallest)
          Positioned(
            bottom: size * 0.24,
            left: size * 0.28,
            child: Container(
              width: size * 0.46,
              height: size * 0.46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right puff
          Positioned(
            bottom: size * 0.12,
            left: size * 0.60,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CITY SKYLINE (decorative CustomPainter)
// ─────────────────────────────────────────────────────────────────────────────

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final buildingPaint = Paint()..color = const Color(0xFF4DB6AC).withOpacity(0.40);
    final groundPaint = Paint()..color = const Color(0xFF26A69A).withOpacity(0.70);

    // Building definitions: (xFrac, widthFrac, heightFrac, hasTriangleRoof)
    const defs = <(double, double, double, bool)>[
      (0.01, 0.08, 0.52, false),
      (0.07, 0.05, 0.72, true),
      (0.12, 0.09, 0.44, false),
      (0.19, 0.06, 0.82, true),
      (0.25, 0.08, 0.54, false),
      (0.31, 0.05, 0.68, false),
      (0.35, 0.10, 0.76, true),
      (0.44, 0.06, 0.48, false),
      (0.49, 0.08, 0.88, true),
      (0.56, 0.09, 0.58, false),
      (0.63, 0.06, 0.72, true),
      (0.68, 0.08, 0.44, false),
      (0.74, 0.07, 0.80, true),
      (0.80, 0.09, 0.54, false),
      (0.87, 0.07, 0.68, true),
      (0.93, 0.08, 0.42, false),
    ];

    for (final (bx, bw, bh, hasRoof) in defs) {
      final rect = Rect.fromLTWH(
        bx * w,
        h - bh * h,
        bw * w,
        bh * h,
      );
      canvas.drawRect(rect, buildingPaint);
      if (hasRoof) {
        final roofPath = Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.left + rect.width / 2, rect.top - 14)
          ..lineTo(rect.right, rect.top)
          ..close();
        canvas.drawPath(roofPath, buildingPaint);
      }
    }

    // Ground strip
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.86, w, h * 0.14),
      groundPaint,
    );
  }

  @override
  bool shouldRepaint(_SkylinePainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int coins;
  final int xp;
  final VoidCallback onMapTap;

  const _TopBar({
    required this.coins,
    required this.xp,
    required this.onMapTap,
  });

  String get _levelName {
    if (xp < 50) return 'Explorador';
    if (xp < 150) return 'Aventureiro';
    if (xp < 300) return 'Descobridor';
    return 'Mestre';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          // Avatar (toca → Perfil)
          GestureDetector(
            onTap: () => NavTabController.maybeOf(context)?.setTab(3),
            child: Consumer<AvatarService>(
              builder: (ctx, av, _) {
                final emoji = av.activeStyle?.emoji ?? '🧒';
                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF8B5CF6), width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Title + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cidade das Sílabas',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _levelName,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Coins
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Map icon
          IconButton(
            icon: const Icon(Icons.map_rounded, color: Colors.white, size: 22),
            tooltip: 'Mapa Mundial',
            onPressed: onMapTap,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.3, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BETO WELCOME
// ─────────────────────────────────────────────────────────────────────────────

class _BetoWelcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Beto mascot (bouncing)
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF8D6E63),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: Text('🐻', style: TextStyle(fontSize: 38)),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 1.0,
              end: 1.06,
              duration: 1200.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(width: 10),
        // Speech bubble
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'Bem-vindo à Cidade das Sílabas! 🏙️\nEscolha um distrito para explorar!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF37474F),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideX(begin: -0.2, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DISTRICT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _DistrictCard extends StatelessWidget {
  final _DistrictDef district;
  final _DState state;
  final int progressDone;
  final int progressTotal;
  final Duration delay;
  final VoidCallback onTap;

  const _DistrictCard({
    required this.district,
    required this.state,
    required this.progressDone,
    required this.progressTotal,
    required this.delay,
    required this.onTap,
  });

  bool get _isDimmed => state == _DState.locked || state == _DState.comingSoon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _isDimmed ? const Color(0xFFECEFF1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: state == _DState.available
                ? district.primary.withOpacity(0.55)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: state == _DState.available
                  ? district.primary.withOpacity(0.18)
                  : Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji circle + badge row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: _isDimmed ? 0.45 : 1.0,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _isDimmed
                                ? Colors.grey.shade200
                                : district.light,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              district.emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                      ),
                      _StatusBadge(state: state, primary: district.primary),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Name
                  Text(
                    district.name,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isDimmed
                          ? Colors.grey.shade400
                          : const Color(0xFF37474F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Subtitle (letter families)
                  Text(
                    district.subtitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: _isDimmed
                          ? Colors.grey.shade300
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                  ),
                  const Spacer(),
                  // Progress bar (only when available + has total)
                  if (state == _DState.available && progressTotal > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressDone / progressTotal,
                        backgroundColor: district.light,
                        valueColor:
                            AlwaysStoppedAnimation(district.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$progressDone / $progressTotal palavras',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        color: district.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Lock overlay
            if (state == _DState.locked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete o\nDistrito Anterior',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: delay)
          .scaleXY(
            begin: 0.88,
            end: 1.0,
            duration: 400.ms,
            delay: delay,
            curve: Curves.easeOutBack,
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final _DState state;
  final Color primary;

  const _StatusBadge({required this.state, required this.primary});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _DState.available:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'JOGAR',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
        );
      case _DState.locked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('🔒', style: TextStyle(fontSize: 10)),
        );
      case _DState.comingSoon:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'EM BREVE',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TORRE DO CONHECIMENTO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TorreCard extends StatelessWidget {
  const _TorreCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, anim, __) =>
              const TorreDoConhecimentoScreen(),
          transitionsBuilder: (_, anim, __, child) {
            final curved =
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFBBF24).withOpacity(0.40),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tower icon (pulsing)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.50),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('🗼', style: TextStyle(fontSize: 32)),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.07,
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Torre do Conhecimento',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '10 andares',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Suba todos os andares e torne-se Leitor Mestre! 👑',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Entrar na Torre',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 700.ms)
        .slideY(begin: 0.3, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOGAR AGORA BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo laranja-dourado com microfone
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withOpacity(0.40),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.mic_rounded, color: Colors.white, size: 42),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.06,
                duration: 1400.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 8),
          // Rótulo abaixo do círculo
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'JOGAR AGORA',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF97316),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
