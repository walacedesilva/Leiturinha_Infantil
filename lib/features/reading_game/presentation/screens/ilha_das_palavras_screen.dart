import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../data/word_bank.dart';
import 'corrida_silabas_screen.dart';
import 'dashboard_relatorio_screen.dart';
import 'desafio_pronuncia_screen.dart';
import 'bairro_das_familias_screen.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';
import 'vila_das_vogais_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum _IslandState { completed, current, locked }

class _IslandData {
  final String name;
  final String emoji;
  final Color iconBg;
  final _IslandState state;
  final int completed;
  final int total;
  final bool isSoon;

  /// Fractional position of the island's icon-circle center within the map
  /// area (0..1 of width / height-minus-button-area).
  final double fx;
  final double fy;

  const _IslandData({
    required this.name,
    required this.emoji,
    required this.iconBg,
    required this.state,
    required this.completed,
    required this.total,
    this.isSoon = false,
    required this.fx,
    required this.fy,
  });
}

const _kIslands = <_IslandData>[
  _IslandData(
    name: 'Vila das\nVogais',
    emoji: '🌱',
    iconBg: Color(0xFF66BB6A),
    state: _IslandState.completed,
    completed: 5,
    total: 5,
    fx: 0.22,
    fy: 0.17,
  ),
  _IslandData(
    name: 'Bairro das\nFamílias',
    emoji: '🏠',
    iconBg: Color(0xFFEF6C00),
    state: _IslandState.current,
    completed: 2,
    total: 5,
    fx: 0.62,
    fy: 0.34,
  ),
  _IslandData(
    name: 'Cidade das\nSílabas',
    emoji: '🏙️',
    iconBg: Color(0xFF1976D2),
    state: _IslandState.locked,
    completed: 0,
    total: 5,
    fx: 0.48,
    fy: 0.58,
  ),
  _IslandData(
    name: 'Reino das\nHistórias',
    emoji: '⭐',
    iconBg: Color(0xFFFFA000),
    state: _IslandState.locked,
    completed: 0,
    total: 5,
    isSoon: true,
    fx: 0.78,
    fy: 0.75,
  ),
];

// Icon-circle center is 36 px from the top of the island widget
// (icon top-offset 4 + radius 32 = 36).
const double _kIconCenterOffsetY = 36.0;
// Half-width of the island widget
const double _kIslandHalfW = 65.0;

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class IlhaDasPalavrasScreen extends StatelessWidget {
  const IlhaDasPalavrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    return Scaffold(
      backgroundColor: const Color(0xFF5BC8F5),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(coins: gam.state.coins, xp: gam.state.xp),
            Expanded(child: _MapArea()),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int coins;
  final int xp;

  const _TopBar({required this.coins, required this.xp});

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
      color: const Color(0xFF5BC8F5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Avatar — círculo 56px borda roxa
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8B5CF6), width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('👦', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          // Nome + moedas
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _levelName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Nível $_levelNumber',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Badge moedas dourado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Acesso rápido ao relatório
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DashboardRelatorioScreen()),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAP AREA
// ─────────────────────────────────────────────────────────────────────────────

class _MapArea extends StatelessWidget {
  const _MapArea();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final totalH = constraints.maxHeight;
        // Reserve bottom for the circular "JOGAR AGORA" button + padding
        const btnAreaH = 164.0;
        final mapH = totalH - btnAreaH;

        // Compute the icon-circle center for each island in map coords.
        final centers = _kIslands
            .map((i) => Offset(i.fx * w, i.fy * mapH))
            .toList(growable: false);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Sky gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5BC8F5), Color(0xFFB3E5FC)],
                  ),
                ),
              ),
            ),

            // Connecting paths (only in map area height)
            Positioned(
              top: 0,
              left: 0,
              width: w,
              height: mapH,
              child: CustomPaint(
                painter: _PathPainter(centers: centers),
              ),
            ),

            // Islands
            ..._kIslands.asMap().entries.map((entry) {
              final idx = entry.key;
              final island = entry.value;
              final c = centers[idx];
              return Positioned(
                left: c.dx - _kIslandHalfW,
                top: c.dy - _kIconCenterOffsetY,
                child: _IslandWidget(
                  island: island,
                  animDelay: Duration(milliseconds: 130 * idx),
                  onTap: island.state == _IslandState.locked
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🔒 Complete as ilhas anteriores primeiro!',
                                style: TextStyle(fontFamily: 'Nunito'),
                              ),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          )
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) {
                                if (idx == 0) return const VilaDasVogaisScreen();
                                if (idx == 1) return const BairroDasFamiliasScreen();
                                return const MenuScreen();
                              },
                            ),
                          ),
                ),
              );
            }),

            // JOGAR AGORA button — centered
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(child: _PlayButton()),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATH PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _PathPainter extends CustomPainter {
  final List<Offset> centers;

  const _PathPainter({required this.centers});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    final shadowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.35)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final pathPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.40)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < centers.length - 1; i++) {
      final p1 = centers[i];
      final p2 = centers[i + 1];

      // Quadratic bezier with outward bulge
      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      // Perpendicular offset (alternating sides for visual interest)
      final sign = (i % 2 == 0) ? 1.0 : -1.0;
      final ctrl = Offset(
        midX + sign * (-dy) * 0.22,
        midY + sign * dx * 0.22,
      );

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);

      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, pathPaint);
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.centers != centers;
}

// ─────────────────────────────────────────────────────────────────────────────
// ISLAND WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _IslandWidget extends StatelessWidget {
  final _IslandData island;
  final Duration animDelay;
  final VoidCallback onTap;

  const _IslandWidget({
    required this.island,
    required this.animDelay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = island.state == _IslandState.locked;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visual: icon circle + floating island platform + state badge
          SizedBox(
            width: 130,
            height: 90,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Island platform — starts at icon-center y so it "floats" below
                Positioned(
                  left: 20,
                  top: 36, // = _kIconCenterOffsetY
                  child: _IslandPlatform(isLocked: isLocked),
                ),
                // Icon circle — center at (65, 42) within this widget
                Positioned(
                  left: 27, // (130 - 76) / 2
                  top: 4,   // 4 + 38 ≈ center above platform
                  child: _IconCircle(
                    emoji: island.emoji,
                    isLocked: isLocked,
                    iconBg: island.iconBg,
                  ),
                ),
                // State badge — top-right corner of icon circle
                Positioned(
                  right: 10,
                  top: 0,
                  child: _StateBadge(state: island.state),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Island name
          Text(
            island.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isLocked
                  ? Colors.white54
                  : const Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 6),
          // Progress label
          _ProgressLabel(
            completed: island.completed,
            total: island.total,
            state: island.state,
            isSoon: island.isSoon,
          ),
        ],
      )
          .animate(delay: animDelay)
          .fadeIn(duration: 400.ms)
          .scale(
            begin: const Offset(0.72, 0.72),
            end: const Offset(1.0, 1.0),
            duration: 460.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }
}

// ─── Island platform (layered grass + earth) ─────────────────────────────────

class _IslandPlatform extends StatelessWidget {
  final bool isLocked;

  const _IslandPlatform({required this.isLocked});

  @override
  Widget build(BuildContext context) {
    // Cores spec: grama #86EFAC→#4ADE80, terra #92400E→#78350F
    final grassGradient = isLocked
        ? const LinearGradient(
            colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFF86EFAC), Color(0xFF4ADE80)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final earthGradient = isLocked
        ? const LinearGradient(
            colors: [Color(0xFF90A4AE), Color(0xFF78909C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFF92400E), Color(0xFF78350F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final darkEdge =
        isLocked ? const Color(0xFF78909C) : const Color(0xFF5D4037);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 92,
          height: 28,
          decoration: BoxDecoration(
            gradient: grassGradient,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
              bottom: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Container(
          width: 74,
          height: 18,
          decoration: BoxDecoration(
            gradient: earthGradient,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
        ),
        Container(
          width: 54,
          height: 10,
          decoration: BoxDecoration(
            color: darkEdge,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Icon circle ──────────────────────────────────────────────────────────────

class _IconCircle extends StatelessWidget {
  final String emoji;
  final bool isLocked;
  final Color iconBg;

  const _IconCircle({
    required this.emoji,
    required this.isLocked,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isLocked ? const Color(0xFFCFD8DC) : iconBg;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: (isLocked ? Colors.black : iconBg).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 42)),
      ),
    );
  }
}

// ─── State badge ─────────────────────────────────────────────────────────────

class _StateBadge extends StatelessWidget {
  final _IslandState state;

  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _IslandState.completed:
        return Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF43A047),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
        );

      case _IslandState.current:
        return const Text('✨', style: TextStyle(fontSize: 20))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 0.85,
              end: 1.20,
              duration: 900.ms,
              curve: Curves.easeInOut,
            );

      case _IslandState.locked:
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF90A4AE),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 14),
        );
    }
  }
}

// ─── Progress label ──────────────────────────────────────────────────────────

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
    final IconData? icon;

    if (isDone) {
      bg = const Color(0xFF43A047);
      label = 'Concluído $completed/$total';
      icon = Icons.check_rounded;
    } else if (!isLocked) {
      bg = const Color(0xFF0097A7);
      label = 'Capítulo $completed/$total';
      icon = null;
    } else if (isSoon) {
      bg = const Color(0xFF78909C);
      label = 'Em breve';
      icon = Icons.lock_rounded;
    } else {
      bg = const Color(0xFF78909C);
      label = 'Desbloquear: $completed/$total';
      icon = Icons.lock_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOGAR AGORA BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  /// Retoma a última família jogada; se nunca jogou, usa a primeira.
  SyllabicFamily _resolveFamily(BuildContext context) {
    final progress = context.read<ProgressService>();
    final lastKey = progress.getLastPlayedFamilyKey();
    if (lastKey != null) {
      try {
        return WordBank.families.firstWhere((f) => f.key == lastKey);
      } catch (_) {}
    }
    return WordBank.families.first;
  }

  @override
  Widget build(BuildContext context) {
    // Botão circular 140×140px com gradiente dourado (spec)
    return GestureDetector(
      onTap: () {
        final family = _resolveFamily(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DesafioDePronunciaScreen(family: family),
          ),
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_rounded, color: Colors.white, size: 48),
            SizedBox(height: 4),
            Text(
              'JOGAR\nAGORA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
                height: 1.1,
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
          duration: 1400.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAVIGATION
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;

  const _BottomNav({required this.currentIndex});

  static const _items = [
    (icon: Icons.home_rounded, label: 'Início'),
    (icon: Icons.sports_esports_rounded, label: 'Desafios'),
    (icon: Icons.star_rounded, label: 'Conquistas'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.indexed.map((entry) {
          final i = entry.$1;
          final item = entry.$2;
          final isSelected = i == currentIndex;
          return GestureDetector(
            onTap: () {
              if (i == currentIndex) return;
              if (i == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CorridaSilabasScreen()),
                );
              } else if (i == 2) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DashboardRelatorioScreen()),
                );
              } else if (i == 3) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 28,
                    color: isSelected
                        ? const Color(0xFFF97316)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFF97316)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}
