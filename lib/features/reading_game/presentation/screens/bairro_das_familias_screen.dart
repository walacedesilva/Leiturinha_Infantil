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

enum _BCardState { completed, active, locked }

class _FamilyBuilding {
  final String letter;
  final String buildingEmoji;
  final String buildingType;
  final String mascot;
  final Color primary;
  final Color light;
  final Color dark;
  final List<String> syllables;
  final List<String> exampleWords;
  final _BCardState state;
  final int progress;
  final int total;
  final String familyKey;

  const _FamilyBuilding({
    required this.letter,
    required this.buildingEmoji,
    required this.buildingType,
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

// NOTA: os campos `state` e `progress` abaixo são apenas placeholders.
// Os valores reais são recalculados a partir do ProgressService em
// `_buildingsFrom`. Não dependa destes valores fixos.
const _kBuildings = <_FamilyBuilding>[
  _FamilyBuilding(
    letter: 'B',
    buildingEmoji: '🏢',
    buildingType: 'Prédio do B',
    mascot: '🐝',
    primary: Color(0xFFF97316),
    light: Color(0xFFFFEDD5),
    dark: Color(0xFFC2410C),
    syllables: ['BA', 'BE', 'BI', 'BO', 'BU'],
    exampleWords: ['BALA', 'BELO', 'BICO', 'BOLO', 'BULE'],
    state: _BCardState.locked, // placeholder — recalculado em _buildingsFrom
    progress: 0,
    total: 5,
    familyKey: 'B',
  ),
  _FamilyBuilding(
    letter: 'C',
    buildingEmoji: '🏫',
    buildingType: 'Escola do C',
    mascot: '🐛',
    primary: Color(0xFF22C55E),
    light: Color(0xFFDCFCE7),
    dark: Color(0xFF166534),
    syllables: ['CA', 'CE', 'CI', 'CO', 'CU'],
    exampleWords: ['CAMA', 'CEDO', 'CIMA', 'COCO', 'CUBO'],
    state: _BCardState.locked, // placeholder — recalculado em _buildingsFrom
    progress: 0,
    total: 5,
    familyKey: 'C',
  ),
  _FamilyBuilding(
    letter: 'D',
    buildingEmoji: '🚒',
    buildingType: 'Bombeiros do D',
    mascot: '🦆',
    primary: Color(0xFF3B82F6),
    light: Color(0xFFDBEAFE),
    dark: Color(0xFF1D4ED8),
    syllables: ['DA', 'DE', 'DI', 'DO', 'DU'],
    exampleWords: ['DADO', 'DEDO', 'DICA', 'DOCE', 'DUNA'],
    state: _BCardState.locked, // placeholder — recalculado em _buildingsFrom
    progress: 0,
    total: 5,
    familyKey: 'D',
  ),
  _FamilyBuilding(
    letter: 'F',
    buildingEmoji: '🍞',
    buildingType: 'Padaria do F',
    mascot: '🦋',
    primary: Color(0xFFA855F7),
    light: Color(0xFFF3E8FF),
    dark: Color(0xFF6B21A8),
    syllables: ['FA', 'FE', 'FI', 'FO', 'FU'],
    exampleWords: ['FADA', 'FETO', 'FITA', 'FOCA', 'FUMO'],
    state: _BCardState.locked, // placeholder — recalculado em _buildingsFrom
    progress: 0,
    total: 5,
    familyKey: 'F',
  ),
  _FamilyBuilding(
    letter: 'M',
    buildingEmoji: '📚',
    buildingType: 'Biblioteca do M',
    mascot: '🐛',
    primary: Color(0xFFEF4444),
    light: Color(0xFFFEE2E2),
    dark: Color(0xFF991B1B),
    syllables: ['MA', 'ME', 'MI', 'MO', 'MU'],
    exampleWords: ['MALA', 'MEDO', 'MICO', 'MOTO', 'MULA'],
    state: _BCardState.locked, // placeholder — recalculado em _buildingsFrom
    progress: 0,
    total: 5,
    familyKey: 'M',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// Recalcula os prédios a partir do progresso REAL do ProgressService.
/// Antes os estados/progresso estavam fixos (hardcoded) na lista `_kBuildings`,
/// ignorando o que a criança realmente concluiu — e tudo ficava liberado.
/// Agora aplicamos bloqueio sequencial: um prédio só abre quando o anterior
/// é concluído.
List<_FamilyBuilding> _buildingsFrom(ProgressService progress) {
  var prevCompleted = true; // o primeiro prédio está sempre liberado
  return _kBuildings.map((b) {
    final fp = progress.getFamilyProgress('consonant_${b.familyKey}', b.total);
    final done = fp.completedWords;
    _BCardState state;
    if (done >= b.total) {
      state = _BCardState.completed;
    } else if (isLevelUnlocked(
        prevCompleted: prevCompleted, hasProgress: done > 0)) {
      state = _BCardState.active;
    } else {
      state = _BCardState.locked;
    }
    prevCompleted = done >= b.total;
    return _FamilyBuilding(
      letter: b.letter,
      buildingEmoji: b.buildingEmoji,
      buildingType: b.buildingType,
      mascot: b.mascot,
      primary: b.primary,
      light: b.light,
      dark: b.dark,
      syllables: b.syllables,
      exampleWords: b.exampleWords,
      state: state,
      progress: done,
      total: b.total,
      familyKey: b.familyKey,
    );
  }).toList();
}

class BairroDasFamiliasScreen extends StatelessWidget {
  const BairroDasFamiliasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final buildings = _buildingsFrom(progress);
    final firstPlayable = buildings.firstWhere(
      (b) => b.state != _BCardState.locked,
      orElse: () => buildings.first,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF14532D),
      body: SafeArea(
        child: Column(
          children: [
            _Header(coins: gam.state.coins),
            const _MapTitle(),
            Expanded(child: _BuildingList(buildings: buildings)),
            _PlayButton(
              onTap: () => _openBuilding(context, firstPlayable),
            ),
          ],
        ),
      ),
    );
  }

  static void _openBuilding(BuildContext context, _FamilyBuilding building) {
    if (building.state == _BCardState.locked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BuildingSheet(building: building),
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
                colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
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
              child: Text('🧒', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nível 2  🏆',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1,
                  ),
                ),
                const Text(
                  'Explorador',
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
// MAP TITLE
// ─────────────────────────────────────────────────────────────────────────────

class _MapTitle extends StatelessWidget {
  const _MapTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            '🏠 BAIRRO DAS FAMÍLIAS',
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
              '⭐  1 de 5 famílias concluída',
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
// BUILDING LIST
// ─────────────────────────────────────────────────────────────────────────────

class _BuildingList extends StatelessWidget {
  final List<_FamilyBuilding> buildings;
  const _BuildingList({required this.buildings});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: buildings.length,
      itemBuilder: (context, idx) {
        return _BuildingCard(building: buildings[idx], index: idx)
            .animate(delay: Duration(milliseconds: 80 * idx))
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUILDING CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BuildingCard extends StatelessWidget {
  final _FamilyBuilding building;
  final int index;

  const _BuildingCard({required this.building, required this.index});

  void _onTap(BuildContext context) {
    if (building.state == _BCardState.locked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BuildingSheet(building: building),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = building.state == _BCardState.locked;
    final isCompleted = building.state == _BCardState.completed;
    final isActive = building.state == _BCardState.active;

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
                    color: building.primary.withOpacity(isActive ? 0.45 : 0.25),
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
                          colors: [building.light, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: Row(
                  children: [
                    // Progress ring + letter
                    _BuildingRing(building: building),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            building.buildingType,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? const Color(0xFF9CA3AF)
                                  : building.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _BStateLabel(building: building),
                          if (!isLocked) ...[
                            const SizedBox(height: 8),
                            // Syllable chips
                            _SyllableChips(building: building),
                            const SizedBox(height: 8),
                            _BProgressBar(building: building),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Right side
                    _BuildingRight(building: building),
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
                          color: building.primary.withOpacity(0.70),
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
                          building.primary,
                          building.light,
                          building.primary
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
// BUILDING RING (progress circle with letter)
// ─────────────────────────────────────────────────────────────────────────────

class _BuildingRing extends StatelessWidget {
  final _FamilyBuilding building;
  const _BuildingRing({required this.building});

  @override
  Widget build(BuildContext context) {
    final isLocked = building.state == _BCardState.locked;
    final isCompleted = building.state == _BCardState.completed;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _RingPainter(
              progress: building.progress / building.total,
              color: isLocked ? const Color(0xFF4B5563) : building.primary,
              trackColor: isLocked
                  ? const Color(0xFF374151)
                  : building.primary.withOpacity(0.15),
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
                      ? building.primary
                      : Colors.white,
              boxShadow: isLocked
                  ? []
                  : [
                      BoxShadow(
                        color: building.primary.withOpacity(0.25),
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
                          building.letter,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: building.primary,
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
// SYLLABLE CHIPS (window display)
// ─────────────────────────────────────────────────────────────────────────────

class _SyllableChips extends StatelessWidget {
  final _FamilyBuilding building;
  const _SyllableChips({required this.building});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: building.syllables.map((syl) {
        return GestureDetector(
          onTap: () => AudioManager().playSyllableInstant(syl.toLowerCase()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: building.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: building.primary.withOpacity(0.30),
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
                    color: building.dark,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.volume_up_rounded,
                    size: 10, color: building.primary.withOpacity(0.60)),
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

class _BStateLabel extends StatelessWidget {
  final _FamilyBuilding building;
  const _BStateLabel({required this.building});

  @override
  Widget build(BuildContext context) {
    switch (building.state) {
      case _BCardState.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 15, color: building.primary),
            const SizedBox(width: 4),
            Text(
              'Concluído!  ${building.progress}/${building.total}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: building.primary,
              ),
            ),
          ],
        );
      case _BCardState.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: building.primary,
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
      case _BCardState.locked:
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

class _BProgressBar extends StatelessWidget {
  final _FamilyBuilding building;
  const _BProgressBar({required this.building});

  @override
  Widget build(BuildContext context) {
    final pct = building.progress / building.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: building.primary.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(building.primary),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${building.progress} de ${building.total} lições',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: building.dark.withOpacity(0.60),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT ICON
// ─────────────────────────────────────────────────────────────────────────────

class _BuildingRight extends StatelessWidget {
  final _FamilyBuilding building;
  const _BuildingRight({required this.building});

  @override
  Widget build(BuildContext context) {
    final isActive = building.state == _BCardState.active;
    final isLocked = building.state == _BCardState.locked;

    if (isLocked) return const SizedBox(width: 32);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(building.buildingEmoji, style: const TextStyle(fontSize: 30)),
        Text(building.mascot, style: const TextStyle(fontSize: 18)),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: building.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: building.primary.withOpacity(0.40),
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
// PLAY BUTTON (pill-shaped)
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
              colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFF97316),
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
                child:
                    const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
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
        .scaleXY(begin: 1.0, end: 1.025, duration: 1400.ms, curve: Curves.easeInOut);
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
// BUILDING BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _BuildingSheet extends StatelessWidget {
  final _FamilyBuilding building;
  const _BuildingSheet({required this.building});

  SyllabicFamily? _findFamily() {
    try {
      return WordBank.families
          .firstWhere((f) => f.key == building.familyKey);
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
          // Building circle
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: building.primary,
              boxShadow: [
                BoxShadow(
                  color: building.primary.withOpacity(0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                building.letter,
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
            '${building.buildingEmoji} ${building.buildingType}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: building.primary,
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
            children: building.syllables.map((syl) {
              return GestureDetector(
                onTap: () =>
                    AudioManager().playSyllableInstant(syl.toLowerCase()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: building.light,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: building.primary.withOpacity(0.50), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: building.primary.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded,
                          size: 14, color: building.primary),
                      const SizedBox(width: 5),
                      Text(
                        syl,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: building.primary,
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
            children: building.exampleWords
                .map(
                  (word) => GestureDetector(
                    onTap: () =>
                        AudioManager().playWord(word.toLowerCase()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: building.light,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: building.primary.withOpacity(0.30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded,
                              size: 12,
                              color: building.primary.withOpacity(0.70)),
                          const SizedBox(width: 4),
                          Text(
                            word,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: building.primary,
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
                final family = _findFamily();
                if (family != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SyllableSelectorScreen(family: family),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: building.primary,
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
