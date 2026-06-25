import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_colors.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../../services/audio_manager.dart';
import '../widgets/leo_bear.dart';
import 'vila_das_vogais_screen.dart';
import 'bairro_das_familias_screen.dart';
import 'praca_central_screen.dart';
import 'reino_historias_screen.dart';
import 'missao_decodificacao_galactica_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ILHA DAS PALAVRAS — mapa em trilha vertical (retrato)
// Recriação do design "island trail" do handoff. A navegação, os 4 nós e a
// política de bloqueio são os mesmos; muda apenas o layout para vertical.
// ═══════════════════════════════════════════════════════════════════════════

enum _NodeState { done, current, locked }

class _NodeDef {
  final String id;
  final String label;
  final _NodeState state;
  final int done;
  final int total;
  final String lockedHint;
  const _NodeDef(
    this.id,
    this.label,
    this.state, {
    this.done = 0,
    this.total = 5,
    this.lockedHint = 'Bloqueado',
  });
}

class IlhaDasPalavrasScreen extends StatefulWidget {
  const IlhaDasPalavrasScreen({super.key});

  @override
  State<IlhaDasPalavrasScreen> createState() => _IlhaDasPalavrasScreenState();
}

class _IlhaDasPalavrasScreenState extends State<IlhaDasPalavrasScreen> {
  String _childName = '';

  @override
  void initState() {
    super.initState();
    _loadChildName();
  }

  Future<void> _loadChildName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString('child_name') ?? '').trim();
    if (mounted && name.isNotEmpty) setState(() => _childName = name);
  }

  // ── Estado / progresso ────────────────────────────────────────────────────

  List<_NodeDef> _buildNodes(ProgressService progress) {
    int vogaisDone = 0;
    for (final v in ['A', 'E', 'I', 'O', 'U']) {
      if (progress.getFamilyProgress('vogal_$v', 3).isCompleted) vogaisDone++;
    }
    final vogaisComplete = vogaisDone >= 5;

    int bairroDone = 0;
    for (final f in ['B', 'C', 'D', 'F', 'M']) {
      if (progress.getFamilyProgress(f, 5).isCompleted) bairroDone++;
    }
    final bairroPassed = bairroDone >= 1;

    final vogaisState =
        vogaisComplete ? _NodeState.done : _NodeState.current;
    final bairroState = !vogaisComplete
        ? _NodeState.locked
        : (bairroDone >= 5 ? _NodeState.done : _NodeState.current);
    final silabasState =
        !bairroPassed ? _NodeState.locked : _NodeState.current;
    final historiasState =
        !bairroPassed ? _NodeState.locked : _NodeState.current;

    return [
      _NodeDef('vogais', 'Vila das Vogais', vogaisState,
          done: vogaisDone, total: 5),
      _NodeDef('familias', 'Bairro das Famílias', bairroState,
          done: bairroDone, total: 5),
      _NodeDef('silabas', 'Cidade das Sílabas', silabasState,
          done: 0, total: 5, lockedHint: 'Complete a fase anterior'),
      _NodeDef('historias', 'Reino das Histórias', historiasState,
          done: 0, total: 5, lockedHint: 'Em breve'),
    ];
  }

  _NodeDef? _currentNode(List<_NodeDef> nodes) {
    for (final n in nodes) {
      if (n.state == _NodeState.current) return n;
    }
    return null;
  }

  // ── Navegação ──────────────────────────────────────────────────────────────

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
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
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
                style:
                    TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final nodes = _buildNodes(progress);
    final current = _currentNode(nodes);
    final reduceMotion = AppAccessibility.prefersReducedMotion(context);

    return Scaffold(
      body: Stack(
        children: [
          // Fundo — gradiente vertical
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.blue100,
                    AppColors.blue50,
                    AppColors.primary50,
                  ],
                  stops: [0.0, 0.38, 1.0],
                ),
              ),
            ),
          ),
          // Nuvens decorativas
          Positioned(top: 120, left: -20, child: _cloud(120, 42, 0.7)),
          Positioned(top: 300, right: -26, child: _cloud(130, 46, 0.6)),

          // Conteúdo rolável
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(gam.state.coins),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'SUA JORNADA',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary600,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'Ilha das Palavras',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _IslandTrail(nodes: nodes, reduceMotion: reduceMotion, onTap: _onNodeTap),
                ],
              ),
            ),
          ),

          // CTA flutuante "JOGAR AGORA"
          if (current != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Center(
                child: _PlayCta(
                  reduceMotion: reduceMotion,
                  onTap: () => _onNodeTap(current),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(int coins) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          // Mascote Léo em círculo dourado
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x4DCA8A04),
                    blurRadius: 10,
                    offset: Offset(0, 4)),
              ],
            ),
            child: const ClipOval(child: LeoBear(size: 40)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Olá, Explorador!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary600,
                  ),
                ),
                Text(
                  _childName.isEmpty ? 'Leitor(a)' : _childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // Chip de moedas
          Container(
            padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.yellow200, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.3, -0.4),
                      colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
                    ),
                    border: Border.all(color: AppColors.yellow400, width: 2),
                  ),
                  child: const Text(
                    '\$',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF854D0E),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF854D0E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cloud(double w, double h, double opacity) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRILHA DE ILHAS — canvas 360×486 escalado à largura
// ═══════════════════════════════════════════════════════════════════════════

class _IslandTrail extends StatelessWidget {
  final List<_NodeDef> nodes;
  final bool reduceMotion;
  final void Function(_NodeDef) onTap;
  const _IslandTrail(
      {required this.nodes, required this.reduceMotion, required this.onTap});

  // Posições (left/top, em canvas 360×486) conforme o protótipo.
  static const _layout = <String, ({double left, double top, double width})>{
    'vogais': (left: 34.0, top: 30.0, width: 140.0),
    'familias': (left: 194.0, top: 128.0, width: 148.0),
    'silabas': (left: 24.0, top: 248.0, width: 148.0),
    'historias': (left: 194.0, top: 368.0, width: 148.0),
  };

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: SizedBox(
        width: 360,
        height: 486,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Caminho pontilhado
            CustomPaint(size: const Size(360, 486), painter: _DashedTrailPainter()),
            // Nós
            for (final n in nodes)
              if (_layout[n.id] != null)
                Positioned(
                  left: _layout[n.id]!.left,
                  top: _layout[n.id]!.top,
                  width: _layout[n.id]!.width,
                  child: _IslandNode(
                      node: n, reduceMotion: reduceMotion, onTap: () => onTap(n)),
                ),
          ],
        ),
      ),
    );
  }
}

class _DashedTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(104, 92)
      ..cubicTo(180, 120, 200, 150, 250, 190)
      ..cubicTo(290, 222, 250, 280, 150, 300)
      ..cubicTo(60, 318, 120, 380, 250, 410);

    final paint = Paint()
      ..color = AppColors.primary300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    const dash = 2.0, gap = 18.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedTrailPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// NÓ-ILHA
// ═══════════════════════════════════════════════════════════════════════════

class _IslandNode extends StatelessWidget {
  final _NodeDef node;
  final bool reduceMotion;
  final VoidCallback onTap;
  const _IslandNode(
      {required this.node, required this.reduceMotion, required this.onTap});

  IconData get _icon => switch (node.id) {
        'vogais' => Icons.local_florist_rounded,
        'familias' => Icons.home_rounded,
        'silabas' => Icons.grid_view_rounded,
        'historias' => Icons.auto_stories_rounded,
        _ => Icons.place_rounded,
      };

  Color get _accent => switch (node.id) {
        'vogais' => AppColors.green600,
        'familias' => AppColors.orange600,
        'silabas' => AppColors.blue500,
        'historias' => AppColors.yellow600,
        _ => AppColors.primary600,
      };

  @override
  Widget build(BuildContext context) {
    final isLocked = node.state == _NodeState.locked;
    final isCurrent = node.state == _NodeState.current;
    final isDone = node.state == _NodeState.done;

    Widget graphic = SizedBox(
      width: 104,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Terra (base)
          Positioned(
            bottom: 0,
            child: Container(
              width: 84,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLocked
                      ? const [Color(0xFF9CA3AF), Color(0xFF6B7280)]
                      : const [Color(0xFFA16207), Color(0xFF854D0E)],
                ),
              ),
            ),
          ),
          // Grama (topo)
          Positioned(
            bottom: 18,
            child: Container(
              width: 104,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLocked
                      ? const [Color(0xFFD1D5DB), Color(0xFF9CA3AF)]
                      : const [Color(0xFF86EFAC), Color(0xFF4ADE80)],
                ),
              ),
            ),
          ),
          // Disco do ícone
          Positioned(
            top: 0,
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isLocked ? AppColors.gray100 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone
                      ? const Color(0xFFBBF7D0)
                      : isCurrent
                          ? const Color(0xFFFDBA74)
                          : AppColors.gray200,
                  width: 3,
                ),
                boxShadow: [
                  if (isCurrent)
                    const BoxShadow(
                        color: Color(0x2EF97316),
                        blurRadius: 0,
                        spreadRadius: 6),
                  BoxShadow(
                    color: isCurrent
                        ? const Color(0x59F97316)
                        : Colors.black.withOpacity(0.12),
                    blurRadius: isCurrent ? 18 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(_icon,
                  size: 38, color: isLocked ? AppColors.gray400 : _accent),
            ),
          ),
          // Badge (check / cadeado)
          if (isDone)
            Positioned(top: -2, right: 8, child: _badge(AppColors.green500, Icons.check_rounded)),
          if (isLocked)
            Positioned(top: -2, right: 6, child: _badge(AppColors.gray500, Icons.lock_rounded)),
        ],
      ),
    );

    if (isCurrent && !reduceMotion) {
      graphic = graphic
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 3000.ms, curve: Curves.easeInOut);
    }

    final labelColor = isDone
        ? const Color(0xFF166534)
        : isCurrent
            ? const Color(0xFF9A3412)
            : AppColors.gray500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isLocked ? 0.9 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Estrelas (apenas no nó atual)
            if (isCurrent) _stars(reduceMotion) else const SizedBox(height: 14),
            graphic,
            const SizedBox(height: 8),
            Text(
              node.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 3),
            _status(isDone, isCurrent),
          ],
        ),
      ),
    );
  }

  Widget _badge(Color color, IconData icon) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, size: 13, color: Colors.white),
    );
  }

  Widget _status(bool isDone, bool isCurrent) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${node.done}/${node.total} ✓',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF16A34A),
          ),
        ),
      );
    }
    if (isCurrent) {
      final frac = node.total == 0 ? 0.0 : (node.done / node.total).clamp(0.0, 1.0);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFFED7AA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: frac,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${node.done}/${node.total}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEA580C),
            ),
          ),
        ],
      );
    }
    // locked
    return Text(
      node.lockedHint,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.gray400,
      ),
    );
  }

  Widget _stars(bool reduceMotion) {
    Widget star(double size, Color color, int delayMs) {
      final s = Icon(Icons.star_rounded, size: size, color: color);
      if (reduceMotion) return s;
      return s
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 1800.ms, delay: Duration(milliseconds: delayMs))
          .scaleXY(begin: 0.7, end: 1.0, duration: 1800.ms);
    }

    return SizedBox(
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          star(11, AppColors.yellow400, 0),
          const SizedBox(width: 5),
          star(14, AppColors.yellow300, 400),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CTA "JOGAR AGORA"
// ═══════════════════════════════════════════════════════════════════════════

class _PlayCta extends StatelessWidget {
  final bool reduceMotion;
  final VoidCallback onTap;
  const _PlayCta({required this.reduceMotion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF97316), Color(0xFFFB923C)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99F97316),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                ),
                child: const Icon(Icons.mic_rounded,
                    size: 17, color: Colors.white),
              ),
              const SizedBox(width: 11),
              const Text(
                'JOGAR AGORA',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) return btn;
    return btn
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 2600.ms, curve: Curves.easeInOut);
  }
}
