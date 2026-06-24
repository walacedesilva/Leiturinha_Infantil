import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../domain/lock_policy.dart';
import '../../data/word_bank.dart';
import 'syllable_selector_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum _WCardState { completed, active, locked }

class _WorkZone {
  final String letter;
  final String zoneEmoji;
  final String zoneName;
  final String mascot;
  final Color primary;
  final Color light;
  final Color dark;
  final List<String> syllables;
  final List<String> exampleWords;
  final _WCardState state;
  final int progress;
  final int total;
  final String familyKey;

  const _WorkZone({
    required this.letter,
    required this.zoneEmoji,
    required this.zoneName,
    required this.mascot,
    required this.primary,
    required this.light,
    required this.dark,
    required this.syllables,
    required this.exampleWords,
    required this.state,
    required this.progress,
    required this.total,
    required this.familyKey,
  });
}

const _kZones = <_WorkZone>[
  _WorkZone(
    letter: 'G',
    zoneEmoji: '🏗️',
    zoneName: 'Guincho do G',
    mascot: '🦎',
    primary: Color(0xFF22C55E),
    light: Color(0xFFF0FDF4),
    dark: Color(0xFF14532D),
    syllables: ['GA', 'GE', 'GI', 'GO', 'GU'],
    exampleWords: ['GATO', 'GELO', 'GIRA', 'GOLA', 'GURI'],
    state: _WCardState.active,
    progress: 0,
    total: 5,
    familyKey: 'G',
  ),
  _WorkZone(
    letter: 'X',
    zoneEmoji: '🔧',
    zoneName: 'Oficina do X',
    mascot: '🦊',
    primary: Color(0xFFF59E0B),
    light: Color(0xFFFFFBEB),
    dark: Color(0xFF78350F),
    syllables: ['XA', 'XI', 'XO', 'XU'],
    exampleWords: ['XALE', 'XICA', 'XIXI', 'XOTE', 'XUXU'],
    state: _WCardState.locked,
    progress: 0,
    total: 5,
    familyKey: 'X',
  ),
  _WorkZone(
    letter: 'Z',
    zoneEmoji: '⚙️',
    zoneName: 'Fábrica do Z',
    mascot: '🦋',
    primary: Color(0xFF6366F1),
    light: Color(0xFFEEF2FF),
    dark: Color(0xFF312E81),
    syllables: ['ZA', 'ZE', 'ZO', 'ZU'],
    exampleWords: ['ZAGA', 'ZERO', 'ZONA', 'ZUMBI'],
    state: _WCardState.locked,
    progress: 0,
    total: 5,
    familyKey: 'Z',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DistritoConstucaoScreen extends StatelessWidget {
  const DistritoConstucaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final zones = _buildZones(progress);

    return Scaffold(
      backgroundColor: const Color(0xFF0D2010),
      body: SafeArea(
        child: Column(
          children: [
            _Header(coins: gam.state.coins),
            const _SiteTitle(),
            Expanded(child: _ZoneList(zones: zones)),
            _PlayButton(
              onTap: () {
                final first = zones.firstWhere(
                  (z) => z.state != _WCardState.locked,
                  orElse: () => zones.first,
                );
                _openZone(context, first);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_WorkZone> _buildZones(ProgressService progress) {
    var prevCompleted = true; // a primeira zona está sempre liberada
    return _kZones.map((z) {
      final fp =
          progress.getFamilyProgress('consonant_${z.familyKey}', z.total);
      final done = fp.completedWords;
      _WCardState state;
      // Bloqueio sequencial: só abre quando a zona anterior é concluída.
      if (done >= z.total) {
        state = _WCardState.completed;
      } else if (isLevelUnlocked(
          prevCompleted: prevCompleted, hasProgress: done > 0)) {
        state = _WCardState.active;
      } else {
        state = _WCardState.locked;
      }
      prevCompleted = done >= z.total;
      return _WorkZone(
        letter: z.letter,
        zoneEmoji: z.zoneEmoji,
        zoneName: z.zoneName,
        mascot: z.mascot,
        primary: z.primary,
        light: z.light,
        dark: z.dark,
        syllables: z.syllables,
        exampleWords: z.exampleWords,
        state: state,
        progress: done,
        total: z.total,
        familyKey: z.familyKey,
      );
    }).toList();
  }

  static void _openZone(BuildContext context, _WorkZone zone) {
    if (zone.state == _WCardState.locked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ZoneSheet(zone: zone),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int coins;
  const _Header({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Mascot avatar — bear in hard hat
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFF59E0B), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.40),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🐻', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nível 3  🏆',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white54,
                    height: 1,
                  ),
                ),
                Text(
                  'Construtor',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Coin counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFF59E0B),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SITE TITLE — crane + title block
// ─────────────────────────────────────────────────────────────────────────────

class _SiteTitle extends StatelessWidget {
  const _SiteTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Crane animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏗️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                'DISTRITO DA CONSTRUÇÃO',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF22C55E).withOpacity(0.70),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Syllable bricks row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['GA', 'XA', 'ZO'].map((syl) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.40),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  syl,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                    letterSpacing: 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: -0.15, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE LIST
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneList extends StatelessWidget {
  final List<_WorkZone> zones;
  const _ZoneList({required this.zones});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: zones.length,
      itemBuilder: (context, idx) {
        return _ZoneCard(zone: zones[idx], index: idx)
            .animate(delay: Duration(milliseconds: 80 * idx))
            .fadeIn(duration: 400.ms)
            .slideX(
                begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneCard extends StatelessWidget {
  final _WorkZone zone;
  final int index;

  const _ZoneCard({required this.zone, required this.index});

  void _onTap(BuildContext context) {
    if (zone.state == _WCardState.locked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ZoneSheet(zone: zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = zone.state == _WCardState.locked;
    final isCompleted = zone.state == _WCardState.completed;
    final isActive = zone.state == _WCardState.active;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: isLocked
              ? []
              : [
                  BoxShadow(
                    color: zone.primary.withOpacity(isActive ? 0.50 : 0.28),
                    blurRadius: isActive ? 24 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isLocked
                      ? const LinearGradient(
                          colors: [Color(0xFF1A3020), Color(0xFF0D2010)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [zone.light, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: Row(
                  children: [
                    _ZoneRing(zone: zone),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.zoneName,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? const Color(0xFF6B7280)
                                  : zone.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _WStateLabel(zone: zone),
                          if (!isLocked) ...[
                            const SizedBox(height: 8),
                            _SyllableChips(zone: zone),
                            const SizedBox(height: 8),
                            _WProgressBar(zone: zone),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ZoneRight(zone: zone),
                  ],
                ),
              ),
              // Amber glow border for active
              if (isActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: zone.primary.withOpacity(0.70),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              // Completed shimmer bar
              if (isCompleted)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [zone.primary, zone.light, zone.primary],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      )
          .animate(
            target: isActive ? 1 : 0,
            onPlay: (c) => isActive ? c.repeat(reverse: true) : null,
          )
          .scaleXY(
            begin: 1.0,
            end: 1.015,
            duration: 1200.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE RING
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneRing extends StatelessWidget {
  final _WorkZone zone;
  const _ZoneRing({required this.zone});

  @override
  Widget build(BuildContext context) {
    final isLocked = zone.state == _WCardState.locked;
    final isCompleted = zone.state == _WCardState.completed;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _RingPainter(
              progress: zone.total == 0 ? 0 : zone.progress / zone.total,
              color: isLocked ? const Color(0xFF374151) : zone.primary,
              trackColor: isLocked
                  ? const Color(0xFF1A3020)
                  : zone.primary.withOpacity(0.15),
              strokeWidth: 5,
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked
                  ? const Color(0xFF1A3020)
                  : isCompleted
                      ? zone.primary
                      : Colors.white,
              boxShadow: isLocked
                  ? []
                  : [
                      BoxShadow(
                        color: zone.primary.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: isLocked
                  ? const Icon(Icons.lock_rounded,
                      color: Color(0xFF6B7280), size: 22)
                  : isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 28)
                      : Text(
                          zone.letter,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: zone.primary,
                            height: 1,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// SYLLABLE CHIPS
// ─────────────────────────────────────────────────────────────────────────────

class _SyllableChips extends StatelessWidget {
  final _WorkZone zone;
  const _SyllableChips({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: zone.syllables.map((syl) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: zone.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: zone.primary.withOpacity(0.30), width: 1),
          ),
          child: Text(
            syl,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: zone.dark,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _WStateLabel extends StatelessWidget {
  final _WorkZone zone;
  const _WStateLabel({required this.zone});

  @override
  Widget build(BuildContext context) {
    switch (zone.state) {
      case _WCardState.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 15, color: zone.primary),
            const SizedBox(width: 4),
            Text(
              'Concluído!  ${zone.progress}/${zone.total}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: zone.primary,
              ),
            ),
          ],
        );
      case _WCardState.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: zone.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '▶  Em Andamento',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      case _WCardState.locked:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 14, color: Color(0xFF6B7280)),
            SizedBox(width: 4),
            Text(
              'Bloqueado',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _WProgressBar extends StatelessWidget {
  final _WorkZone zone;
  const _WProgressBar({required this.zone});

  @override
  Widget build(BuildContext context) {
    final pct = zone.total == 0 ? 0.0 : zone.progress / zone.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: zone.primary.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(zone.primary),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${zone.progress} de ${zone.total} lições',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: zone.dark.withOpacity(0.60),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT ICON
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneRight extends StatelessWidget {
  final _WorkZone zone;
  const _ZoneRight({required this.zone});

  @override
  Widget build(BuildContext context) {
    final isActive = zone.state == _WCardState.active;
    final isLocked = zone.state == _WCardState.locked;

    if (isLocked) return const SizedBox(width: 32);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(zone.zoneEmoji, style: const TextStyle(fontSize: 30)),
        Text(zone.mascot, style: const TextStyle(fontSize: 18)),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: zone.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: zone.primary.withOpacity(0.40),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              '▶ JOGAR',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAY BUTTON — "MONTAR PALAVRA"
// ─────────────────────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            gradient: const LinearGradient(
              colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withOpacity(0.55),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                ),
                child: const Center(
                  child: Text('🔨', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'MONTAR PALAVRA',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(
                      color: Color(0x55000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
            begin: 1.0,
            end: 1.025,
            duration: 1400.ms,
            curve: Curves.easeInOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.10), width: 1),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Início', active: true),
          _NavItem(icon: Icons.flash_on_rounded, label: 'Desafios'),
          _NavItem(icon: Icons.emoji_events_rounded, label: 'Troféus'),
          _NavItem(icon: Icons.person_rounded, label: 'Perfil'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: active
              ? BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Icon(
            icon,
            color: active ? Colors.white : Colors.white38,
            size: 24,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneSheet extends StatelessWidget {
  final _WorkZone zone;
  const _ZoneSheet({required this.zone});

  SyllabicFamily? _findFamily() {
    try {
      return WordBank.families.firstWhere((f) => f.key == zone.familyKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: zone.primary,
              boxShadow: [
                BoxShadow(
                  color: zone.primary.withOpacity(0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                zone.letter,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${zone.zoneEmoji} ${zone.zoneName}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: zone.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sílabas: ${zone.syllables.join('  ')}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: zone.exampleWords
                .map(
                  (word) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: zone.light,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: zone.primary.withOpacity(0.30)),
                    ),
                    child: Text(
                      word,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: zone.primary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                final wbFamily = _findFamily();
                if (wbFamily != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SyllableSelectorScreen(family: wbFamily),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: zone.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Text('🔨', style: TextStyle(fontSize: 20)),
              label: const Text(
                'Montar Palavra',
                style: TextStyle(
       