import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../../services/avatar_service.dart';
import '../../../../services/audio_manager.dart';
import 'vila_das_vogais_screen.dart';
import 'bairro_das_familias_screen.dart';
import 'praca_central_screen.dart';
import 'reino_historias_screen.dart';
import 'missao_decodificacao_galactica_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MUNDO DA LEITURINHA · OVERWORLD
// Redesign do mapa-aventura ilustrado (handoff Claude Design).
// Mapa fixo 1000×580 com rolagem horizontal; HUD fixo sobre o viewport.
// Os nós abrem as telas reais respeitando a política de bloqueio existente.
// ═══════════════════════════════════════════════════════════════════════════

// Dimensões do "World Frame" do design.
const double _kWorldW = 1000;
const double _kWorldH = 580;

enum _NodeState { done, current, locked }

class _NodeDef {
  final String id;
  final String label;
  final Offset center; // em coordenadas 1000×580
  final _NodeState state;
  const _NodeDef(this.id, this.label, this.center, this.state);
}

class IlhaDasPalavrasScreen extends StatefulWidget {
  const IlhaDasPalavrasScreen({super.key});

  @override
  State<IlhaDasPalavrasScreen> createState() => _IlhaDasPalavrasScreenState();
}

class _IlhaDasPalavrasScreenState extends State<IlhaDasPalavrasScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient; // glow/sparkle/path pulse
  late final AnimationController _bob; // bob do personagem

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _bob.dispose();
    super.dispose();
  }

  // ── Estado / progresso ──────────────────────────────────────────────────────

  List<_NodeDef> _buildNodes(ProgressService progress) {
    // Vila das Vogais — concluída quando as 5 famílias de vogais terminam.
    int vogaisDone = 0;
    for (final v in ['A', 'E', 'I', 'O', 'U']) {
      if (progress.getFamilyProgress('vogal_$v', 3).isCompleted) vogaisDone++;
    }
    final vogaisComplete = vogaisDone >= 5;

    // Bairro das Famílias.
    int bairroDone = 0;
    for (final f in ['B', 'C', 'D', 'F', 'M']) {
      if (progress.getFamilyProgress(f, 5).isCompleted) bairroDone++;
    }
    final bairroPassed = bairroDone >= 1;

    _NodeState vogaisState =
        vogaisComplete ? _NodeState.done : _NodeState.current;
    _NodeState bairroState = !vogaisComplete
        ? _NodeState.locked
        : (bairroDone >= 5 ? _NodeState.done : _NodeState.current);
    _NodeState silabasState =
        !bairroPassed ? _NodeState.locked : _NodeState.current;
    _NodeState historiasState =
        !bairroPassed ? _NodeState.locked : _NodeState.current;

    return [
      _NodeDef('vogais', 'Vila das Vogais', const Offset(470, 356), vogaisState),
      _NodeDef('familias', 'Bairro das Famílias', const Offset(285, 380),
          bairroState),
      _NodeDef('silabas', 'Cidade das Sílabas', const Offset(745, 318),
          silabasState),
      _NodeDef('historias', 'Reino das Histórias', const Offset(610, 440),
          historiasState),
    ];
  }

  ({String id, String label, int done, int total}) _currentMission(
      List<_NodeDef> nodes, ProgressService progress) {
    int bairroDone = 0;
    for (final f in ['B', 'C', 'D', 'F', 'M']) {
      if (progress.getFamilyProgress(f, 5).isCompleted) bairroDone++;
    }
    int vogaisDone = 0;
    for (final v in ['A', 'E', 'I', 'O', 'U']) {
      if (progress.getFamilyProgress('vogal_$v', 3).isCompleted) vogaisDone++;
    }
    // Primeiro nó "current" (jogável e não concluído) é a missão atual.
    for (final n in nodes) {
      if (n.state == _NodeState.current) {
        if (n.id == 'vogais') {
          return (id: n.id, label: n.label, done: vogaisDone, total: 5);
        }
        if (n.id == 'familias') {
          return (id: n.id, label: n.label, done: bairroDone, total: 5);
        }
        return (id: n.id, label: n.label, done: 0, total: 5);
      }
    }
    return (id: 'vogais', label: 'Vila das Vogais', done: vogaisDone, total: 5);
  }

  // ── Navegação ───────────────────────────────────────────────────────────────

  void _onNodeTap(_NodeDef node) {
    if (node.state == _NodeState.locked) {
      _showLocked();
      return;
    }
    AudioManager().playSFX(SFXType.pop);
    final Widget screen = switch (node.id) {
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

  void _showLocked() {
    AudioManager().playSFX(SFXType.error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Conclua os reinos anteriores para liberar este!',
                style: TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.bold),
              ),
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

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final nodes = _buildNodes(progress);
    final mission = _currentMission(nodes, progress);

    final xp = gam.state.xp;
    final level = (xp ~/ 100) + 1;
    final levelFrac = (xp % 100) / 100.0;

    void explore() {
      final target = nodes.firstWhere(
        (n) => n.id == mission.id,
        orElse: () => nodes.first,
      );
      _onNodeTap(target);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C2A24),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho (título do mundo) ───────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _WorldHeader(),
              ),
            ),

            // Mapa inteiro encaixado na tela (ideal em paisagem) ────────────
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _kWorldW,
                    height: _kWorldH,
                    child: _WorldFrame(
                      nodes: nodes,
                      ambient: _ambient,
                      bob: _bob,
                      onNodeTap: _onNodeTap,
                      coins: gam.state.coins,
                      lives: 5,
                      level: level,
                      frac: levelFrac,
                      mission: mission,
                      onExplore: explore,
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// CABEÇALHO
// ═══════════════════════════════════════════════════════════════════════════

class _WorldHeader extends StatelessWidget {
  const _WorldHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Mundo da Leiturinha · Overworld',
          style: TextStyle(
            fontFamily: 'Baloo 2',
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFDE9C8),
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Mapa-aventura ilustrado · 4 reinos de alfabetização',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9FB8A8),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WORLD FRAME — 1000×580
// ═══════════════════════════════════════════════════════════════════════════

class _WorldFrame extends StatelessWidget {
  final List<_NodeDef> nodes;
  final AnimationController ambient;
  final AnimationController bob;
  final void Function(_NodeDef) onNodeTap;
  final int coins;
  final int lives;
  final int level;
  final double frac;
  final ({String id, String label, int done, int total}) mission;
  final VoidCallback onExplore;

  const _WorldFrame({
    required this.nodes,
    required this.ambient,
    required this.bob,
    required this.onNodeTap,
    required this.coins,
    required this.lives,
    required this.level,
    required this.frac,
    required this.mission,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kWorldW,
      height: _kWorldH,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFCDEFF2),
            Color(0xFFA6E2E6),
            Color(0xFF6FCBD2),
            Color(0xFF46AEC4),
            Color(0xFF2E8FB8),
          ],
          stops: [0.0, 0.14, 0.28, 0.44, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 90,
            offset: Offset(0, 40),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: ambient,
        builder: (context, _) {
          final pulse = 0.55 + 0.45 * ambient.value; // 0.55..1.0
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1) Céu + terreno (CustomPaint com paths do SVG) ──────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _TerrainPainter(pulse: pulse),
                ),
              ),

              // 2) Nuvens ────────────────────────────────────────────────────
              ..._clouds(),

              // 3) Faróis / ilhota ───────────────────────────────────────────
              const Positioned(top: 96, left: 291, child: _Lighthouse()),

              // 4) Árvores ───────────────────────────────────────────────────
              ..._trees(),

              // 5) Castelo (Vila das Vogais) ─────────────────────────────────
              Positioned(top: 212, left: 480, child: _Castle(glow: pulse)),

              // 6) Casas da vila ─────────────────────────────────────────────
              const Positioned(top: 330, left: 250, child: _House(roof: Color(0xFFEF4444), body: Color(0xFFFBE3B8), w: 30)),
              const Positioned(top: 344, left: 296, child: _House(roof: Color(0xFF3B82F6), body: Color(0xFFDBEAFE), w: 28)),
              const Positioned(top: 360, left: 226, child: _House(roof: Color(0xFFF59E0B), body: Color(0xFFFEF3C7), w: 26)),

              // 7) Tendas do mercado ─────────────────────────────────────────
              const Positioned(top: 316, left: 424, child: _MarketTents()),

              // 8) Vulcão ─────────────────────────────────────────────────────
              Positioned(top: 208, left: 730, child: _Volcano(glow: pulse)),

              // 9) Cristais roxos ────────────────────────────────────────────
              Positioned(top: 452, left: 232, child: _Crystals(sparkle: pulse)),

              // 10) Ilhota do tesouro + árvore dourada ───────────────────────
              const Positioned(top: 400, left: 548, child: _TreasureIslet()),
              Positioned(top: 352, left: 580, child: _GoldenTree(glow: pulse)),

              // 11) Moldura de folhas ────────────────────────────────────────
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _LeafFramePainter()),
                ),
              ),

              // 12) Nós de nível ─────────────────────────────────────────────
              ...nodes.map((n) => _NodeWidget(
                    node: n,
                    bob: bob,
                    pulse: pulse,
                    onTap: () => onNodeTap(n),
                  )),

              // 13) HUD (dentro do frame, topo da pilha) ──────────────────────
              Positioned(
                top: 22,
                left: 96,
                child: _PlayerCard(level: level, frac: frac),
              ),
              Positioned(
                top: 24,
                right: 96,
                child: _CoinsLives(coins: coins, lives: lives),
              ),
              Positioned(
                bottom: 26,
                left: 0,
                right: 0,
                child: Center(
                  child: _MissionBanner(
                    label: mission.label,
                    done: mission.done,
                    total: mission.total,
                    onExplore: onExplore,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _clouds() {
    const defs = <(double top, double left, double w, double h, double op, bool round)>[
      (30, 180, 120, 34, 0.92, false),
      (22, 230, 70, 42, 0.92, true),
      (54, 700, 140, 38, 0.90, false),
      (42, 710, 80, 48, 0.90, true),
      (100, 60, 90, 26, 0.70, false),
    ];
    return defs
        .map((c) => Positioned(
              top: c.$1,
              left: c.$2,
              child: Container(
                width: c.$3,
                height: c.$4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(c.$5),
                  borderRadius:
                      BorderRadius.circular(c.$6 ? c.$4 : 30),
                ),
              ),
            ))
        .toList();
  }

  List<Widget> _trees() {
    const defs = <(double top, double left, double size, Color c, Color s)>[
      (248, 392, 30, Color(0xFF5E9648), Color(0xFF3F7A3A)),
      (300, 610, 36, Color(0xFF6AA547), Color(0xFF4C7E3A)),
      (266, 560, 24, Color(0xFF7CC36B), Color(0xFF58974A)),
      (430, 600, 28, Color(0xFF5E9648), Color(0xFF3F7A3A)),
      (332, 330, 26, Color(0xFF6AA547), Color(0xFF4C7E3A)),
      (455, 560, 22, Color(0xFF7CC36B), Color(0xFF58974A)),
    ];
    return defs
        .map((t) => Positioned(
              top: t.$1,
              left: t.$2,
              child: Container(
                width: t.$3,
                height: t.$3,
                decoration: BoxDecoration(
                  color: t.$4,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: t.$5,
                      offset: const Offset(0, 7),
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TERRENO — CustomPainter portando os paths do SVG do design
// ═══════════════════════════════════════════════════════════════════════════

class _TerrainPainter extends CustomPainter {
  final double pulse;
  const _TerrainPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // O design é desenhado em 1000×580; escala caso o frame mude de tamanho.
    canvas.save();
    canvas.scale(size.width / _kWorldW, size.height / _kWorldH);

    // — Rainbow —
    void arc(String d, Color c) {
      canvas.drawPath(
        _svgPath(d),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = c.withOpacity(0.5)
          ..strokeCap = StrokeCap.round,
      );
    }

    arc('M70 200 A 180 180 0 0 1 420 180', const Color(0xFFF87171));
    arc('M78 206 A 175 175 0 0 1 416 188', const Color(0xFFFBBF24));
    arc('M86 212 A 170 170 0 0 1 412 196', const Color(0xFFA3E635));
    arc('M94 218 A 165 165 0 0 1 408 204', const Color(0xFF60A5FA));

    const islandPath =
        'M150 300 C 130 230, 250 195, 360 205 C 470 175, 640 175, 720 205 C 840 195, 905 250, 890 340 C 905 430, 820 510, 680 520 C 560 545, 420 540, 320 510 C 200 495, 150 420, 150 300 Z';
    const grassPath =
        'M172 300 C 158 240, 260 215, 365 224 C 470 198, 635 198, 712 224 C 822 216, 880 262, 868 340 C 880 420, 805 488, 678 498 C 560 520, 425 516, 332 488 C 222 474, 175 412, 172 300 Z';

    // sombra da ilha na água
    canvas.save();
    canvas.translate(8, 16);
    canvas.drawPath(
      _svgPath(islandPath),
      Paint()..color = const Color(0xFF1F6E8C).withOpacity(0.5),
    );
    canvas.restore();

    // base de areia
    final sand = _svgPath(islandPath);
    canvas.drawPath(sand, _vGrad(sand, const Color(0xFFF4E2B0), const Color(0xFFE6CE8A)));
    canvas.drawPath(
        sand,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFD8BE82));

    // grama
    final grass = _svgPath(grassPath);
    canvas.drawPath(grass, _vGrad(grass, const Color(0xFF86CC68), const Color(0xFF5EA847)));
    canvas.drawPath(
        grass,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF4C8A3C));

    // rios
    const riverPath =
        'M470 175 C 455 240, 420 250, 430 320 C 438 380, 400 420, 430 500';
    canvas.drawPath(
        _svgPath(riverPath),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF6FD3E6).withOpacity(0.92));
    canvas.drawPath(
        _svgPath(riverPath),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFA8EAF2).withOpacity(0.8));

    // patches
    final meadow = _svgPath(
        'M455 240 C 540 224, 640 238, 670 300 C 690 350, 650 396, 560 404 C 480 412, 442 372, 442 312 C 442 280, 445 250, 455 240 Z');
    canvas.drawPath(meadow, _vGrad(meadow, const Color(0xFFA6DD7E), const Color(0xFF7FC15C)));

    canvas.drawPath(
        _svgPath(
            'M205 320 C 240 285, 320 290, 360 320 C 392 350, 380 408, 320 430 C 260 448, 205 420, 198 372 C 195 350, 195 335, 205 320 Z'),
        Paint()..color = const Color(0xFF7BBE9C));

    final cave = _svgPath(
        'M205 430 C 250 420, 310 430, 330 470 C 345 504, 312 520, 262 518 C 212 516, 188 486, 192 458 C 194 444, 196 434, 205 430 Z');
    canvas.drawPath(cave, _rGrad(cave, const Color(0xFFB07AD6), const Color(0xFF6D3F9E)));

    final rock = _svgPath(
        'M690 220 C 760 205, 840 225, 858 290 C 872 345, 832 372, 768 366 C 706 360, 676 318, 678 270 C 679 244, 680 228, 690 220 Z');
    canvas.drawPath(rock, _vGrad(rock, const Color(0xFF8A93A8), const Color(0xFF5C6478)));

    final canyon = _svgPath(
        'M700 372 C 760 362, 830 378, 838 426 C 845 466, 806 492, 752 486 C 700 480, 678 446, 684 410 C 687 392, 690 378, 700 372 Z');
    canvas.drawPath(canyon, _vGrad(canyon, const Color(0xFFEBA85A), const Color(0xFFCE7E36)));

    // hortas
    final plotStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF4C8A3C);
    void plot(double x, double y, Color c) {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 46, 34), const Radius.circular(4));
      canvas.drawRRect(r, Paint()..color = c);
      canvas.drawRRect(r, plotStroke);
    }

    plot(470, 408, const Color(0xFF9ED06A));
    plot(520, 408, const Color(0xFF86C254));
    plot(470, 446, const Color(0xFF86C254));
    plot(520, 446, const Color(0xFF9ED06A));

    // caminho brilhante
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFDE68A).withOpacity(pulse);
    canvas.drawPath(
        _svgPath(
            'M285 380 C 360 372, 410 366, 470 360 C 560 352, 640 330, 745 318'),
        glow);
    canvas.drawPath(
        _svgPath('M500 360 C 556 378, 598 386, 608 390'), glow);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TerrainPainter old) => old.pulse != pulse;
}

// ═══════════════════════════════════════════════════════════════════════════
// MOLDURA DE FOLHAS
// ═══════════════════════════════════════════════════════════════════════════

class _LeafFramePainter extends CustomPainter {
  const _LeafFramePainter();

  // (symbol2?, x, y, w, h, angle, pivotX, pivotY)
  static const _leaves = <(bool, double, double, double, double, double, double, double)>[
    // TOPO
    (true, -30, -44, 150, 117, 18, 45, 14),
    (false, 70, -52, 160, 125, 0, 0, 0),
    (true, 200, -46, 140, 109, -12, 270, 7),
    (false, 320, -56, 150, 117, 8, 395, 2),
    (true, 450, -50, 140, 109, 0, 0, 0),
    (false, 560, -54, 150, 117, -10, 635, 4),
    (true, 680, -48, 145, 113, 12, 752, 8),
    (false, 800, -54, 160, 125, 0, 0, 0),
    (true, 920, -44, 150, 117, -16, 995, 14),
    // BASE
    (false, -30, 510, 155, 121, -18, 47, 570),
    (true, 90, 520, 150, 117, 0, 0, 0),
    (false, 220, 516, 145, 113, 14, 292, 572),
    (true, 350, 522, 150, 117, 0, 0, 0),
    (false, 480, 514, 150, 117, -10, 555, 572),
    (true, 600, 520, 150, 117, 10, 675, 578),
    (false, 730, 516, 150, 117, 0, 0, 0),
    (true, 860, 520, 160, 125, -14, 940, 578),
    // ESQUERDA
    (true, -50, 90, 150, 117, -70, 25, 148),
    (false, -56, 210, 160, 125, -88, 24, 272),
    (true, -50, 330, 150, 117, -100, 25, 388),
    (false, -54, 420, 150, 117, -112, 21, 478),
    // DIREITA
    (true, 900, 90, 150, 117, 70, 975, 148),
    (false, 900, 210, 160, 125, 88, 980, 272),
    (true, 906, 330, 150, 117, 100, 981, 388),
    (false, 904, 420, 150, 117, 112, 979, 478),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _kWorldW, size.height / _kWorldH);

    final body =
        _svgPath('M50 3 C 92 14, 96 54, 50 75 C 4 54, 8 14, 50 3 Z');
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF33662E).withOpacity(0.8);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFF2F5E2A);

    for (final l in _leaves) {
      final isLf2 = l.$1;
      final x = l.$2, y = l.$3, w = l.$4, h = l.$5;
      final angle = l.$6, px = l.$7, py = l.$8;
      canvas.save();
      if (angle != 0) {
        canvas.translate(px, py);
        canvas.rotate(angle * math.pi / 180);
        canvas.translate(-px, -py);
      }
      canvas.translate(x, y);
      canvas.scale(w / 100, h / 78);
      final fill = Paint()
        ..shader = ui.Gradient.radial(
          const Offset(35, 23),
          80,
          isLf2
              ? const [Color(0xFF6AA84E), Color(0xFF2F6A2E)]
              : const [Color(0xFF7FB85E), Color(0xFF3F7A3A)],
        );
      canvas.drawPath(body, fill);
      canvas.drawPath(body, outline);
      canvas.drawLine(const Offset(50, 10), const Offset(50, 68), vein);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LeafFramePainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// NÓ DE NÍVEL
// ═══════════════════════════════════════════════════════════════════════════

class _NodeWidget extends StatelessWidget {
  final _NodeDef node;
  final AnimationController bob;
  final double pulse;
  final VoidCallback onTap;

  const _NodeWidget({
    required this.node,
    required this.bob,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = node.state == _NodeState.current;
    final marker = _marker();
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker,
        const SizedBox(height: 4),
        _chip(),
      ],
    );

    // Bob apenas no nó atual.
    Widget positionedChild = GestureDetector(onTap: onTap, child: content);
    if (isCurrent) {
      positionedChild = AnimatedBuilder(
        animation: bob,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, -7 * math.sin(bob.value * math.pi)),
          child: child,
        ),
        child: positionedChild,
      );
    }

    // Centraliza no ponto do design; largura folgada evita overflow da legenda.
    const double boxW = 160;
    return Positioned(
      left: node.center.dx - boxW / 2,
      top: node.center.dy - 34,
      width: boxW,
      child: Center(child: positionedChild),
    );
  }

  Widget _marker() {
    switch (node.state) {
      case _NodeState.done:
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF2DD4BF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x4D000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
        );
      case _NodeState.current:
        return Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFF6B4A), width: 3),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFDE68A).withOpacity(0.55),
                  blurRadius: 0,
                  spreadRadius: 7),
              const BoxShadow(
                  color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: const _KidFace(size: 40),
        );
      case _NodeState.locked:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x4D000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.lock_rounded, color: Color(0xFF7A6E5E), size: 18),
        );
    }
  }

  Widget _chip() {
    late Color bg;
    late Color fg;
    switch (node.state) {
      case _NodeState.done:
        bg = Colors.white.withOpacity(0.92);
        fg = const Color(0xFF0E7C70);
      case _NodeState.current:
        bg = const Color(0xFFFF6B4A);
        fg = Colors.white;
      case _NodeState.locked:
        bg = Colors.white.withOpacity(0.85);
        fg = const Color(0xFF7A6E5E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        boxShadow: node.state == _NodeState.current
            ? [BoxShadow(color: const Color(0xFFFF6B4A).withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3))]
            : const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Text(
        node.label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ROSTO DO PERSONAGEM (kid) — aproximação do desenho CSS do design
// ═══════════════════════════════════════════════════════════════════════════

class _KidFace extends StatelessWidget {
  final double size;
  const _KidFace({required this.size});

  @override
  Widget build(BuildContext context) {
    final s = size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // pele
          Positioned(
            top: s * 0.20,
            left: s * 0.16,
            child: Container(
              width: s * 0.70,
              height: s * 0.70,
              decoration: BoxDecoration(
                color: const Color(0xFFF4C49A),
                borderRadius: BorderRadius.circular(s * 0.34),
              ),
            ),
          ),
          // cabelo
          Positioned(
            top: s * 0.04,
            left: s * 0.14,
            child: Container(
              width: s * 0.72,
              height: s * 0.40,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B4A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(s)),
              ),
            ),
          ),
          // franja
          Positioned(
            top: s * 0.32,
            left: s * 0.06,
            child: Container(
              width: s * 0.5,
              height: s * 0.12,
              decoration: BoxDecoration(
                color: const Color(0xFFE5522F),
                borderRadius: BorderRadius.circular(s * 0.06),
              ),
            ),
          ),
          // olhos
          Positioned(top: s * 0.46, left: s * 0.34, child: _dot(s * 0.09, const Color(0xFF3A2A1E))),
          Positioned(top: s * 0.46, right: s * 0.34, child: _dot(s * 0.09, const Color(0xFF3A2A1E))),
          // bochechas
          Positioned(top: s * 0.58, left: s * 0.24, child: _dot(s * 0.10, const Color(0xFFF6A6A0))),
          Positioned(top: s * 0.58, right: s * 0.24, child: _dot(s * 0.10, const Color(0xFFF6A6A0))),
          // sorriso
          Positioned(
            top: s * 0.62,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: s * 0.24,
                height: s * 0.13,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3A2A1E), width: 2),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(s * 0.13)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// PROPS
// ═══════════════════════════════════════════════════════════════════════════

class _Lighthouse extends StatelessWidget {
  const _Lighthouse();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 46,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white, Colors.white,
                Color(0xFFEF4444), Color(0xFFEF4444),
                Colors.white, Colors.white,
                Color(0xFFEF4444), Color(0xFFEF4444),
              ],
              stops: [0, .28, .28, .5, .5, .72, .72, 1],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
        Container(
          width: 54,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF7CC36B),
            borderRadius: BorderRadius.circular(50),
            boxShadow: const [BoxShadow(color: Color(0xFF58974A), offset: Offset(0, 4), spreadRadius: -1)],
          ),
        ),
      ],
    );
  }
}

class _House extends StatelessWidget {
  final Color roof;
  final Color body;
  final double w;
  const _House({required this.roof, required this.body, required this.w});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(size: Size(w, w * 0.45), painter: _TriPainter(roof)),
        Container(
          width: w * 0.7,
          height: w * 0.55,
          decoration: BoxDecoration(
            color: body,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
          ),
        ),
      ],
    );
  }
}

class _MarketTents extends StatelessWidget {
  const _MarketTents();
  @override
  Widget build(BuildContext context) {
    BoxDecoration striped(Color c) => BoxDecoration(
          gradient: LinearGradient(
            tileMode: TileMode.repeated,
            begin: Alignment.topLeft,
            end: const Alignment(-0.6, -1.0),
            colors: [c, c, Colors.white, Colors.white],
            stops: const [0, .5, .5, 1],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 26, height: 20, decoration: striped(const Color(0xFFEF4444))),
        const SizedBox(width: 5),
        Container(width: 26, height: 20, decoration: striped(const Color(0xFF2DD4BF))),
      ],
    );
  }
}

class _Castle extends StatelessWidget {
  final double glow;
  const _Castle({required this.glow});
  @override
  Widget build(BuildContext context) {
    Widget tower(double w, double h, Color c, Color shade) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: c,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            boxShadow: [BoxShadow(color: shade, offset: const Offset(-3, 0), spreadRadius: -1)],
          ),
        );
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // aura
          Positioned(
            bottom: 6,
            child: Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF86EF79).withOpacity(0.55 * glow),
                  Colors.transparent,
                ], stops: const [0, 0.7]),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              tower(16, 40, const Color(0xFFF2E6C2), const Color(0xFFDCC79A)),
              const SizedBox(width: 3),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  tower(26, 56, const Color(0xFFFBEFCB), const Color(0xFFE6D2A0)),
                  Positioned(
                    top: -34,
                    child: Container(width: 14, height: 9, color: const Color(0xFFEF4444)),
                  ),
                  Positioned(
                    top: -22,
                    child: Container(
                      width: 14,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C24C),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.6 * glow), blurRadius: 10)],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 3),
              tower(16, 40, const Color(0xFFF2E6C2), const Color(0xFFDCC79A)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Volcano extends StatelessWidget {
  final double glow;
  const _Volcano({required this.glow});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 60,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(size: const Size(68, 54), painter: _TriPainter(const Color(0xFFB5483A))),
          Positioned(
            bottom: 44,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)]),
                boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.8 * glow), blurRadius: 20)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Crystals extends StatelessWidget {
  final double sparkle;
  const _Crystals({required this.sparkle});
  @override
  Widget build(BuildContext context) {
    Widget crystal(double w, double h, Color c) => CustomPaint(
          size: Size(w, h),
          painter: _TriPainter(c, glow: true),
        );
    return SizedBox(
      width: 50,
      height: 40,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(left: 0, bottom: 0, child: crystal(14, 24, const Color(0xFFC084FC))),
          Positioned(left: 14, bottom: 0, child: crystal(18, 34, const Color(0xFFA855F7))),
          Positioned(left: 32, bottom: 0, child: crystal(12, 20, const Color(0xFFE879F9))),
          Positioned(
            left: 8,
            bottom: 30,
            child: Opacity(
              opacity: 0.4 + 0.6 * sparkle,
              child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFF0ABFC), shape: BoxShape.circle)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasureIslet extends StatelessWidget {
  const _TreasureIslet();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: 62,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE6CE8A),
                borderRadius: BorderRadius.circular(62),
                boxShadow: const [BoxShadow(color: Color(0x731F6E8C), offset: Offset(0, 7), spreadRadius: -2)],
              ),
            ),
          ),
          Positioned(
            top: 6, left: 9, right: 9, bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF86CC68), Color(0xFF5EA847)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldenTree extends StatelessWidget {
  final double glow;
  const _GoldenTree({required this.glow});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 70,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 8,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFFBBF24).withOpacity(0.7 * glow),
                  Colors.transparent,
                ], stops: const [0, 0.7]),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Transform.rotate(angle: -12 * math.pi / 180, child: _trunk(10, 40, const Color(0xFFC99B5E))),
              const SizedBox(width: 3),
              _trunk(12, 48, const Color(0xFFB5854A)),
              const SizedBox(width: 3),
              Transform.rotate(angle: 12 * math.pi / 180, child: _trunk(10, 40, const Color(0xFFC99B5E))),
            ],
          ),
          Positioned(
            top: -2,
            child: Container(
              width: 50,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE047),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: const Color(0xFFFDE047).withOpacity(glow), blurRadius: 16)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trunk(double w, double h, Color c) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// HUD
// ═══════════════════════════════════════════════════════════════════════════

class _PlayerCard extends StatelessWidget {
  final int level;
  final double frac;
  const _PlayerCard({required this.level, required this.frac});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A24).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE3D6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Consumer<AvatarService>(
              builder: (_, av, __) {
                final emoji = av.activeStyle?.emoji;
                if (emoji != null) {
                  return Center(child: Text(emoji, style: const TextStyle(fontSize: 24)));
                }
                return const _KidFace(size: 34);
              },
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Téo',
                style: TextStyle(
                  fontFamily: 'Baloo 2',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Nv $level',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFDE68A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 90,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: frac.clamp(0.04, 1.0).toDouble(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFFDE047)]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinsLives extends StatelessWidget {
  final int coins;
  final int lives;
  const _CoinsLives({required this.coins, required this.lives});

  @override
  Widget build(BuildContext context) {
    Widget pill(Widget icon, String value) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2A24).withOpacity(0.6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 5),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill(
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
              ),
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
          ),
          '$coins',
        ),
        const SizedBox(width: 8),
        pill(
          const Icon(Icons.favorite, color: Color(0xFFFF6B4A), size: 16),
          '$lives',
        ),
      ],
    );
  }
}

class _MissionBanner extends StatelessWidget {
  final String label;
  final int done;
  final int total;
  final VoidCallback onExplore;

  const _MissionBanner({
    required this.label,
    required this.done,
    required this.total,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B4A),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFFFF6B4A).withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MISSÃO ATUAL',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Color(0xFFFF6B4A),
                ),
              ),
              Text(
                '$label · $done/$total',
                style: const TextStyle(
                  fontFamily: 'Baloo 2',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A2A1E),
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onExplore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF8A52), Color(0xFFE5522F)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFFB8451F), offset: Offset(0, 5))],
              ),
              child: const Text(
                'Explorar ›',
                style: TextStyle(
                  fontFamily: 'Baloo 2',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS DE DESENHO
// ═══════════════════════════════════════════════════════════════════════════

/// Triângulo apontando para cima (usado em telhados, vulcão e cristais).
class _TriPainter extends CustomPainter {
  final Color color;
  final bool glow;
  const _TriPainter(this.color, {this.glow = false});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    if (glow) {
      canvas.drawPath(
        p,
        Paint()
          ..color = color.withOpacity(0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TriPainter old) => old.color != color;
}

/// Paint com gradiente linear vertical sobre a bounding box do path.
Paint _vGrad(Path p, Color top, Color bottom) {
  final b = p.getBounds();
  return Paint()
    ..shader = ui.Gradient.linear(
      Offset(b.left, b.top),
      Offset(b.left, b.bottom),
      [top, bottom],
    );
}

/// Paint com gradiente radial sobre a bounding box do path.
Paint _rGrad(Path p, Color inner, Color outer) {
  final b = p.getBounds();
  final c = Offset(b.left + b.width * 0.5, b.top + b.height * 0.4);
  final r = math.max(b.width, b.height) * 0.7;
  return Paint()..shader = ui.Gradient.radial(c, r, [inner, outer]);
}

/// Parser mínimo de path SVG (comandos absolutos M, L, C, A, Z).
Path _svgPath(String d) {
  final path = Path();
  final tokens = RegExp(r'[MLCAZmlcaz]|-?\d*\.?\d+(?:[eE]-?\d+)?')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  int i = 0;
  double rd() => double.parse(tokens[i++]);
  bool isNum(String t) => RegExp(r'^-?\.?\d').hasMatch(t);

  String cmd = '';
  while (i < tokens.length) {
    final t = tokens[i];
    if (!isNum(t)) {
      cmd = t;
      i++;
    }
    switch (cmd) {
      case 'M':
        path.moveTo(rd(), rd());
        cmd = 'L'; // pares seguintes viram lineTo (spec SVG)
        break;
      case 'L':
        path.lineTo(rd(), rd());
        break;
      case 'C':
        path.cubicTo(rd(), rd(), rd(), rd(), rd(), rd());
        break;
      case 'A':
        final rx = rd(), ry = rd(), rot = rd(), large = rd(), sweep = rd();
        final x = rd(), y = rd();
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rot,
          largeArc: large != 0,
          clockwise: sweep != 0,
        );
        break;
      case 'Z':
        path.close();
        break;
      default:
        i++; // segurança
    }
  }
  return path;
}
