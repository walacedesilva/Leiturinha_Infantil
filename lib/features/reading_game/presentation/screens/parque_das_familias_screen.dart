import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../domain/lock_policy.dart';
import '../../data/word_bank.dart';
import 'syllable_selector_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS & DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum _PCardState { completed, active, locked }

class _ParkFamily {
  final String letter;
  final String attractionEmoji;
  final String attractionName;
  final String mascot;
  final Color primary;
  final Color light;
  final Color dark;
  final List<String> syllables;
  final List<String> exampleWords;
  final _PCardState state;
  final int progress;
  final int total;
  final String familyKey;

  const _ParkFamily({
    required this.letter,
    required this.attractionEmoji,
    required this.attractionName,
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

const _kFamilies = <_ParkFamily>[
  _ParkFamily(
    letter: 'J',
    attractionEmoji: '🎡',
    attractionName: 'Parquinho do J',
    mascot: '🦎',
    primary: Color(0xFF7C3AED),
    light: Color(0xFFEDE9FE),
    dark: Color(0xFF4C1D95),
    syllables: ['JA', 'JE', 'JI', 'JO', 'JU'],
    exampleWords: ['JACA', 'JATO', 'JIPE', 'JOGO', 'JUBA'],
    state: _PCardState.active,
    progress: 0,
    total: 5,
    familyKey: 'J',
  ),
  _ParkFamily(
    letter: 'L',
    attractionEmoji: '🌊',
    attractionName: 'Lagoa do L',
    mascot: '🦁',
    primary: Color(0xFF0284C7),
    light: Color(0xFFE0F2FE),
    dark: Color(0xFF0C4A6E),
    syllables: ['LA', 'LE', 'LI', 'LO', 'LU'],
    exampleWords: ['LAMA', 'LEVE', 'LIMA', 'LONA', 'LUPA'],
    state: _PCardState.locked,
    progress: 0,
    total: 5,
    familyKey: 'L',
  ),
  _ParkFamily(
    letter: 'M',
    attractionEmoji: '🌺',
    attractionName: 'Jardim do M',
    mascot: '🦋',
    primary: Color(0xFFDB2777),
    light: Color(0xFFFCE7F3),
    dark: Color(0xFF831843),
    syllables: ['MA', 'ME', 'MI', 'MO', 'MU'],
    exampleWords: ['MALA', 'MESA', 'MICO', 'MOLA', 'MULA'],
    state: _PCardState.locked,
    progress: 0,
    total: 5,
    familyKey: 'M',
  ),
  _ParkFamily(
    letter: 'N',
    attractionEmoji: '🌿',
    attractionName: 'Natureza do N',
    mascot: '🐦',
    primary: Color(0xFF059669),
    light: Color(0xFFD1FAE5),
    dark: Color(0xFF064E3B),
    syllables: ['NA', 'NE', 'NI', 'NO', 'NU'],
    exampleWords: ['NABO', 'NENE', 'NIDO', 'NOTA', 'NUCA'],
    state: _PCardState.locked,
    progress: 0,
    total: 5,
    familyKey: 'N',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ParqueDasFamiliasScreen extends StatelessWidget {
  const ParqueDasFamiliasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final families = _buildFamilies(progress);

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: SafeArea(
        child: Column(
          children: [
            _Header(coins: gam.state.coins),
            const _ParkTitle(),
            Expanded(
              child: _FamilyList(families: families),
            ),
            _PlayButton(
              onTap: () {
                final first = families.firstWhere(
                  (f) => f.state != _PCardState.locked,
                  orElse: () => families.first,
                );
                _openFamily(context, first);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds family list with dynamic state from ProgressService.
  List<_ParkFamily> _buildFamilies(ProgressService progress) {
    var prevCompleted = true; // a primeira família está sempre liberada
    return _kFamilies.map((f) {
      final fp = progress.getFamilyProgress('consonant_${f.familyKey}', f.total);
      final done = fp.completedWords;
      _PCardState state;
      // Bloqueio sequencial: só abre quando a família anterior é concluída.
      if (done >= f.total) {
        state = _PCardState.completed;
      } else if (isLevelUnlocked(
          prevCompleted: prevCompleted, hasProgress: done > 0)) {
        state = _PCardState.active;
      } else {
        state = _PCardState.locked;
      }
      prevCompleted = done >= f.total;
      return _ParkFamily(
        letter: f.letter,
        attractionEmoji: f.attractionEmoji,
        attractionName: f.attractionName,
        mascot: f.mascot,
        primary: f.primary,
        light: f.light,
        dark: f.dark,
        syllables: f.syllables,
        exampleWords: f.exampleWords,
        state: state,
        progress: done,
        total: f.total,
        familyKey: f.familyKey,
      );
    }).toList();
  }

  static void _openFamily(BuildContext context, _ParkFamily family) {
    if (family.state == _PCardState.locked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FamilySheet(family: family),
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
                color: Colors.white.withOpacity(0.15),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🐻', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Nível 3  🏆',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1,
                  ),
                ),
                Text(
                  'Aventureiro',
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
// PARK TITLE
// ─────────────────────────────────────────────────────────────────────────────

class _ParkTitle extends StatelessWidget {
  const _ParkTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            '🌳 PARQUE DAS FAMÍLIAS',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🌿  Famílias J · L · M · N',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: -0.15, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAMILY LIST
// ─────────────────────────────────────────────────────────────────────────────

class _FamilyList extends StatelessWidget {
  final List<_ParkFamily> families;
  const _FamilyList({required this.families});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: families.length,
      itemBuilder: (context, idx) {
        return _FamilyCard(family: families[idx], index: idx)
            .animate(delay: Duration(milliseconds: 80 * idx))
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAMILY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FamilyCard extends StatelessWidget {
  final _ParkFamily family;
  final int index;

  const _FamilyCard({required this.family, required this.index});

  void _onTap(BuildContext context) {
    if (family.state == _PCardState.locked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FamilySheet(family: family),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = family.state == _PCardState.locked;
    final isCompleted = family.state == _PCardState.completed;
    final isActive = family.state == _PCardState.active;

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
                    color: family.primary.withOpacity(isActive ? 0.45 : 0.25),
                    blurRadius: isActive ? 22 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Card background
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isLocked
                      ? const LinearGradient(
                          colors: [Color(0xFF374151), Color(0xFF1F2937)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [family.light, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: Row(
                  children: [
                    _FamilyRing(family: family),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            family.attractionName,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? const Color(0xFF9CA3AF)
                                  : family.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _PStateLabel(family: family),
                          if (!isLocked) ...[
                            const SizedBox(height: 8),
                            _SyllableChips(family: family),
                            const SizedBox(height: 8),
                            _PProgressBar(family: family),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FamilyRight(family: family),
                  ],
                ),
              ),
              // Active glow border
              if (isActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: family.primary.withOpacity(0.70),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              // Completed shimmer top bar
              if (isCompleted)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          family.primary,
                          family.light,
                          family.primary,
                        ],
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
// FAMILY RING
// ─────────────────────────────────────────────────────────────────────────────

class _FamilyRing extends StatelessWidget {
  final _ParkFamily family;
  const _FamilyRing({required this.family});

  @override
  Widget build(BuildContext context) {
    final isLocked = family.state == _PCardState.locked;
    final isCompleted = family.state == _PCardState.completed;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _RingPainter(
              progress: family.total == 0 ? 0 : family.progress / family.total,
              color: isLocked ? const Color(0xFF4B5563) : family.primary,
              trackColor: isLocked
                  ? const Color(0xFF374151)
                  : family.primary.withOpacity(0.15),
              strokeWidth: 5,
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked
                  ? const Color(0xFF1F2937)
                  : isCompleted
                      ? family.primary
                      : Colors.white,
              boxShadow: isLocked
                  ? []
                  : [
                      BoxShadow(
                        color: family.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: isLocked
                  ? const Icon(Icons.lock_rounded,
                      color: Color(0xFF9CA3AF), size: 22)
                  : isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 28)
                      : Text(
                          family.letter,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: family.primary,
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

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
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
  final _ParkFamily family;
  const _SyllableChips({required this.family});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: family.syllables.map((syl) {
        return GestureDetector(
          onTap: () => AudioManager().playSyllableInstant(syl.toLowerCase()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: family.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: family.primary.withOpacity(0.30),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  syl,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: family.dark,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.volume_up_rounded,
                    size: 10, color: family.primary.withOpacity(0.60)),
              ],
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

class _PStateLabel extends StatelessWidget {
  final _ParkFamily family;
  const _PStateLabel({required this.family});

  @override
  Widget build(BuildContext context) {
    switch (family.state) {
      case _PCardState.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 15, color: family.primary),
            const SizedBox(width: 4),
            Text(
              'Concluído!  ${family.progress}/${family.total}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: family.primary,
              ),
            ),
          ],
        );
      case _PCardState.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: family.primary,
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
      case _PCardState.locked:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF6B7280)),
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

class _PProgressBar extends StatelessWidget {
  final _ParkFamily family;
  const _PProgressBar({required this.family});

  @override
  Widget build(BuildContext context) {
    final pct = family.total == 0 ? 0.0 : family.progress / family.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: family.primary.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(family.primary),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${family.progress} de ${family.total} lições',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: family.dark.withOpacity(0.60),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT ICON
// ─────────────────────────────────────────────────────────────────────────────

class _FamilyRight extends StatelessWidget {
  final _ParkFamily family;
  const _FamilyRight({required this.family});

  @override
  Widget build(BuildContext context) {
    final isActive = family.state == _PCardState.active;
    final isLocked = family.state == _PCardState.locked;

    if (isLocked) return const SizedBox(width: 32);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(family.attractionEmoji, style: const TextStyle(fontSize: 30)),
        Text(family.mascot, style: const TextStyle(fontSize: 18)),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: family.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: family.primary.withOpacity(0.40),
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
// PLAY BUTTON
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
              colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF16A34A),
                blurRadius: 20,
                offset: Offset(0, 8),
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
                child: const Icon(Icons.mic_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'JOGAR AGORA',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
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
        color: Colors.white.withOpacity(0.10),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
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
                  color: Colors.white.withOpacity(0.20),
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
// FAMILY BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _FamilySheet extends StatelessWidget {
  final _ParkFamily family;
  const _FamilySheet({required this.family});

  SyllabicFamily? _findFamily() {
    try {
      return WordBank.families.firstWhere((f) => f.key == family.familyKey);
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
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Letter circle
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: family.primary,
              boxShadow: [
                BoxShadow(
                  color: family.primary.withOpacity(0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                family.letter,
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
            '${family.attractionEmoji} ${family.attractionName}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: family.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toque para ouvir cada sílaba:',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: family.syllables.map((syl) {
              return GestureDetector(
                onTap: () =>
                    AudioManager().playSyllableInstant(syl.toLowerCase()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: family.light,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: family.primary.withOpacity(0.50), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: family.primary.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded,
                          size: 14, color: family.primary),
                      const SizedBox(width: 5),
                      Text(
                        syl,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: family.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Palavras de exemplo:',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          // Word chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: family.exampleWords
                .map(
                  (word) => GestureDetector(
                    onTap: () =>
                        AudioManager().playWord(word.toLowerCase()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: family.light,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: family.primary.withOpacity(0.30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded,
                              size: 12,
                              color: family.primary.withOpacity(0.70)),
                          const SizedBox(width: 4),
                          Text(
                            word,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: family.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          // Practice button
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
                backgroundColor: family.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.mic_rounded, size: 22),
              label: const Text(
                'Praticar Agora',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
