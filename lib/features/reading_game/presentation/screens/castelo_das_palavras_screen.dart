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
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum _CCardState { completed, active, locked }

class _CastleTower {
  final String letter;
  final String towerEmoji;
  final String towerName;
  final String mascot;
  final Color primary;
  final Color light;
  final Color dark;
  final List<String> syllables;
  final List<String> exampleWords;
  final _CCardState state;
  final int progress;
  final int total;
  final String familyKey;

  const _CastleTower({
    required this.letter,
    required this.towerEmoji,
    required this.towerName,
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

const _kTowers = <_CastleTower>[
  _CastleTower(
    letter: 'P',
    towerEmoji: '🗼',
    towerName: 'Torre do P',
    mascot: '🦚',
    primary: Color(0xFF7B1FA2),
    light: Color(0xFFF3E5F5),
    dark: Color(0xFF4A0072),
    syllables: ['PA', 'PE', 'PI', 'PO', 'PU'],
    exampleWords: ['PATO', 'PENA', 'PICO', 'POLO', 'PUMA'],
    state: _CCardState.active,
    progress: 0,
    total: 5,
    familyKey: 'P',
  ),
  _CastleTower(
    letter: 'R',
    towerEmoji: '🏯',
    towerName: 'Muralha do R',
    mascot: '🦁',
    primary: Color(0xFFC62828),
    light: Color(0xFFFFEBEE),
    dark: Color(0xFF7F0000),
    syllables: ['RA', 'RE', 'RI', 'RO', 'RU'],
    exampleWords: ['RABO', 'REDE', 'RIMA', 'RODA', 'RUGA'],
    state: _CCardState.locked,
    progress: 0,
    total: 5,
    familyKey: 'R',
  ),
  _CastleTower(
    letter: 'S',
    towerEmoji: '⚔️',
    towerName: 'Salão do S',
    mascot: '🐍',
    primary: Color(0xFF00695C),
    light: Color(0xFFE0F2F1),
    dark: Color(0xFF004D40),
    syllables: ['SA', 'SE', 'SI', 'SO', 'SU'],
    exampleWords: ['SAPO', 'SELA', 'SINO', 'SOPA', 'SUCO'],
    state: _CCardState.locked,
    progress: 0,
    total: 5,
    familyKey: 'S',
  ),
  _CastleTower(
    letter: 'T',
    towerEmoji: '🛡️',
    towerName: 'Guarita do T',
    mascot: '🐢',
    primary: Color(0xFF1565C0),
    light: Color(0xFFE3F2FD),
    dark: Color(0xFF0D47A1),
    syllables: ['TA', 'TE', 'TI', 'TO', 'TU'],
    exampleWords: ['TATU', 'TEMA', 'TIPO', 'TOCA', 'TUBA'],
    state: _CCardState.locked,
    progress: 0,
    total: 5,
    familyKey: 'T',
  ),
  _CastleTower(
    letter: 'V',
    towerEmoji: '👑',
    towerName: 'Trono do V',
    mascot: '🦅',
    primary: Color(0xFF558B2F),
    light: Color(0xFFF9FBE7),
    dark: Color(0xFF33691E),
    syllables: ['VA', 'VE', 'VI', 'VO', 'VU'],
    exampleWords: ['VACA', 'VELA', 'VIDA', 'VOTO', 'VALE'],
    state: _CCardState.locked,
    progress: 0,
    total: 5,
    familyKey: 'V',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CastelodasPalavrasScreen extends StatelessWidget {
  const CastelodasPalavrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final towers = _buildTowers(progress);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0030),
      body: SafeArea(
        child: Column(
          children: [
            _Header(coins: gam.state.coins),
            const _CastleTitle(),
            Expanded(child: _TowerList(towers: towers)),
            _PlayButton(
              onTap: () {
                final first = towers.firstWhere(
                  (t) => t.state != _CCardState.locked,
                  orElse: () => towers.first,
                );
                _openTower(context, first);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_CastleTower> _buildTowers(ProgressService progress) {
    var prevCompleted = true; // a primeira torre está sempre liberada
    return _kTowers.map((t) {
      final fp =
          progress.getFamilyProgress('consonant_${t.familyKey}', t.total);
      final done = fp.completedWords;
      _CCardState state;
      // Bloqueio sequencial: só abre quando a torre anterior é concluída.
      if (done >= t.total) {
        state = _CCardState.completed;
      } else if (isLevelUnlocked(
          prevCompleted: prevCompleted, hasProgress: done > 0)) {
        state = _CCardState.active;
      } else {
        state = _CCardState.locked;
      }
      prevCompleted = done >= t.total;
      return _CastleTower(
        letter: t.letter,
        towerEmoji: t.towerEmoji,
        towerName: t.towerName,
        mascot: t.mascot,
        primary: t.primary,
        light: t.light,
        dark: t.dark,
        syllables: t.syllables,
        exampleWords: t.exampleWords,
        state: state,
        progress: done,
        total: t.total,
        familyKey: t.familyKey,
      );
    }).toList();
  }

  static void _openTower(BuildContext context, _CastleTower tower) {
    if (tower.state == _CCardState.locked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TowerSheet(tower: tower),
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
                colors: [Color(0xFFCE93D8), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nível 4  🏆',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1,
                  ),
                ),
                Text(
                  'Cavaleiro',
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
// CASTLE TITLE
// ─────────────────────────────────────────────────────────────────────────────

class _CastleTitle extends StatelessWidget {
  const _CastleTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            '🏰 CASTELO DAS PALAVRAS',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: Colors.purpleAccent.withOpacity(0.60),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '⚔️  Torres P · R · S · T · V',
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
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: -0.15, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOWER LIST
// ─────────────────────────────────────────────────────────────────────────────

class _TowerList extends StatelessWidget {
  final List<_CastleTower> towers;
  const _TowerList({required this.towers});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: towers.length,
      itemBuilder: (context, idx) {
        return _TowerCard(tower: towers[idx], index: idx)
            .animate(delay: Duration(milliseconds: 80 * idx))
            .fadeIn(duration: 400.ms)
            .slideX(
                begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOWER CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TowerCard extends StatelessWidget {
  final _CastleTower tower;
  final int index;

  const _TowerCard({required this.tower, required this.index});

  void _onTap(BuildContext context) {
    if (tower.state == _CCardState.locked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TowerSheet(tower: tower),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = tower.state == _CCardState.locked;
    final isCompleted = tower.state == _CCardState.completed;
    final isActive = tower.state == _CCardState.active;

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
                    color: tower.primary.withOpacity(isActive ? 0.50 : 0.28),
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
                          colors: [Color(0xFF2D1B42), Color(0xFF1A0030)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [tower.light, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: Row(
                  children: [
                    _TowerRing(tower: tower),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tower.towerName,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? const Color(0xFF9CA3AF)
                                  : tower.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _CStateLabel(tower: tower),
                          if (!isLocked) ...[
                            const SizedBox(height: 8),
                            _SyllableChips(tower: tower),
                            const SizedBox(height: 8),
                            _CProgressBar(tower: tower),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _TowerRight(tower: tower),
                  ],
                ),
              ),
              if (isActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: tower.primary.withOpacity(0.70),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isCompleted)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [tower.primary, tower.light, tower.primary],
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
// TOWER RING
// ─────────────────────────────────────────────────────────────────────────────

class _TowerRing extends StatelessWidget {
  final _CastleTower tower;
  const _TowerRing({required this.tower});

  @override
  Widget build(BuildContext context) {
    final isLocked = tower.state == _CCardState.locked;
    final isCompleted = tower.state == _CCardState.completed;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _RingPainter(
              progress: tower.total == 0 ? 0 : tower.progress / tower.total,
              color: isLocked ? const Color(0xFF4B5563) : tower.primary,
              trackColor: isLocked
                  ? const Color(0xFF2D1B42)
                  : tower.primary.withOpacity(0.15),
              strokeWidth: 5,
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked
                  ? const Color(0xFF2D1B42)
                  : isCompleted
                      ? tower.primary
                      : Colors.white,
              boxShadow: isLocked
                  ? []
                  : [
                      BoxShadow(
                        color: tower.primary.withOpacity(0.25),
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
                          tower.letter,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: tower.primary,
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
  final _CastleTower tower;
  const _SyllableChips({required this.tower});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: tower.syllables.map((syl) {
        return GestureDetector(
          onTap: () => AudioManager().playSyllableInstant(syl.toLowerCase()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: tower.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: tower.primary.withOpacity(0.30), width: 1),
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
                    color: tower.dark,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.volume_up_rounded,
                    size: 10, color: tower.primary.withOpacity(0.60)),
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

class _CStateLabel extends StatelessWidget {
  final _CastleTower tower;
  const _CStateLabel({required this.tower});

  @override
  Widget build(BuildContext context) {
    switch (tower.state) {
      case _CCardState.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 15, color: tower.primary),
            const SizedBox(width: 4),
            Text(
              'Concluído!  ${tower.progress}/${tower.total}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tower.primary,
              ),
            ),
          ],
        );
      case _CCardState.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: tower.primary,
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
      case _CCardState.locked:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 14, color: Color(0xFF9CA3AF)),
            SizedBox(width: 4),
            Text(
              'Bloqueado',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Color(0xFF9CA3AF),
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

class _CProgressBar extends StatelessWidget {
  final _CastleTower tower;
  const _CProgressBar({required this.tower});

  @override
  Widget build(BuildContext context) {
    final pct = tower.total == 0 ? 0.0 : tower.progress / tower.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: tower.primary.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(tower.primary),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${tower.progress} de ${tower.total} lições',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: tower.dark.withOpacity(0.60),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT ICON
// ─────────────────────────────────────────────────────────────────────────────

class _TowerRight extends StatelessWidget {
  final _CastleTower tower;
  const _TowerRight({required this.tower});

  @override
  Widget build(BuildContext context) {
    final isActive = tower.state == _CCardState.active;
    final isLocked = tower.state == _CCardState.locked;

    if (isLocked) return const SizedBox(width: 32);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tower.towerEmoji, style: const TextStyle(fontSize: 30)),
        Text(tower.mascot, style: const TextStyle(fontSize: 18)),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tower.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: tower.primary.withOpacity(0.40),
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
              colors: [Color(0xFFCE93D8), Color(0xFF8E24AA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF8E24AA),
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
        color: Colors.white.withOpacity(0.08),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
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
// TOWER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _TowerSheet extends StatelessWidget {
  final _CastleTower tower;
  const _TowerSheet({required this.tower});

  SyllabicFamily? _findFamily() {
    try {
      return WordBank.families.firstWhere((f) => f.key == tower.familyKey);
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
              color: tower.primary,
              boxShadow: [
                BoxShadow(
                  color: tower.primary.withOpacity(0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                tower.letter,
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
            '${tower.towerEmoji} ${tower.towerName}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tower.primary,
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
            children: tower.syllables.map((syl) {
              return GestureDetector(
                onTap: () =>
                    AudioManager().playSyllableInstant(syl.toLowerCase()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tower.light,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: tower.primary.withOpacity(0.50), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: tower.primary.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded,
                          size: 14, color: tower.primary),
                      const SizedBox(width: 5),
                      Text(
                        syl,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: tower.primary,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: tower.exampleWords
                .map(
                  (word) => GestureDetector(
                    onTap: () =>
                        AudioManager().playWord(word.toLowerCase()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: tower.light,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: tower.primary.withOpacity(0.30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded,
                              size: 12,
                              color: tower.primary.withOpacity(0.70)),
                          const SizedBox(width: 4),
                          Text(
                            word,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: tower.primary,
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
                backgroundColor: tower.primary,
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
      