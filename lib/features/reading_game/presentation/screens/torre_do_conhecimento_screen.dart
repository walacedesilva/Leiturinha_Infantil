import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/gamification_models.dart';
import '../../../../services/progress_service.dart';
import '../../../../services/avatar_service.dart';
import 'torre_gameplay_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TORRE DO CONHECIMENTO — HUB SCREEN
// Paleta: Gold #FBBF24, Cyan #06B6D4, Purple #8B5CF6, White
// ═══════════════════════════════════════════════════════════════════════════

// ─── Constants ───────────────────────────────────────────────────────────────
const _kGold       = Color(0xFFD97706);
const _kGoldLight  = Color(0xFFFBBF24);
const _kGoldBg     = Color(0xFFFEF3C7);
const _kCyan       = Color(0xFF06B6D4);
const _kCyanLight  = Color(0xFFCCFBFE);
const _kPurple     = Color(0xFF8B5CF6);
const _kPurpleLight = Color(0xFFEDE9FE);
const _kText       = Color(0xFF1F2937);
const _kSub        = Color(0xFF6B7280);

// ─── Tower floor definitions ──────────────────────────────────────────────────
class TowerFloor {
  final int number;
  final String title;
  final String subtitle;
  final String emoji;
  final String familyKey;
  final int totalWords;
  final Color color;

  const TowerFloor({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.familyKey,
    required this.totalWords,
    required this.color,
  });
}

const kTowerFloors = <TowerFloor>[
  TowerFloor(number: 1,  title: 'Vogais',          subtitle: 'A · E · I · O · U',   emoji: '🌸', familyKey: 'vogal_A',      totalWords: 15, color: Color(0xFF66BB6A)),
  TowerFloor(number: 2,  title: 'Sílabas B/C/D',   subtitle: 'BA · CA · DA · ...',  emoji: '🏘️', familyKey: 'consonant_b',  totalWords: 12, color: Color(0xFFF97316)),
  TowerFloor(number: 3,  title: 'Sílabas F/G',     subtitle: 'FA · GA · FE · ...',  emoji: '🌿', familyKey: 'consonant_f',  totalWords: 10, color: Color(0xFF22C55E)),
  TowerFloor(number: 4,  title: 'Famílias J/L',    subtitle: 'JA · LA · JE · ...',  emoji: '🌳', familyKey: 'consonant_j',  totalWords: 10, color: Color(0xFF388E3C)),
  TowerFloor(number: 5,  title: 'Famílias M/N',    subtitle: 'MA · NA · ME · ...',  emoji: '🦋', familyKey: 'consonant_m',  totalWords: 10, color: Color(0xFF10B981)),
  TowerFloor(number: 6,  title: 'Famílias P/R/S',  subtitle: 'PA · RA · SA · ...',  emoji: '🏰', familyKey: 'consonant_p',  totalWords: 12, color: Color(0xFF8E24AA)),
  TowerFloor(number: 7,  title: 'Famílias T/V',    subtitle: 'TA · VA · TE · ...',  emoji: '🚀', familyKey: 'consonant_t',  totalWords: 10, color: Color(0xFF1565C0)),
  TowerFloor(number: 8,  title: 'Dígrafos',        subtitle: 'CH · LH · NH · QU',   emoji: '🔮', familyKey: 'consonant_ch', totalWords: 10, color: Color(0xFF5E35B1)),
  TowerFloor(number: 9,  title: 'Encontros',       subtitle: 'BR · CL · TR · FL',   emoji: '⚙️', familyKey: 'consonant_br', totalWords: 10, color: Color(0xFFD97706)),
  TowerFloor(number: 10, title: 'Mestre Leitor',   subtitle: 'Frases completas',     emoji: '👑', familyKey: 'consonant_f', totalWords: 10, color: Color(0xFFDC2626)),
];

// ─── Progress state ───────────────────────────────────────────────────────────
enum _FloorState { locked, current, completed }

_FloorState _floorState(TowerFloor floor, ProgressService progress) {
  final fp = progress.getFamilyProgress(floor.familyKey, floor.totalWords);
  if (fp.isCompleted) return _FloorState.completed;
  // Unlock floor 1 always; others unlock if previous completed
  if (floor.number == 1) return _FloorState.current;
  final prev = kTowerFloors[floor.number - 2];
  final prevFp = progress.getFamilyProgress(prev.familyKey, prev.totalWords);
  if (prevFp.isCompleted) return _FloorState.current;
  return _FloorState.locked;
}

int _currentFloorNumber(ProgressService progress) {
  for (int i = kTowerFloors.length - 1; i >= 0; i--) {
    final fp = progress.getFamilyProgress(
        kTowerFloors[i].familyKey, kTowerFloors[i].totalWords);
    if (fp.isCompleted) {
      if (i < kTowerFloors.length - 1) return kTowerFloors[i + 1].number;
      return kTowerFloors[i].number; // all complete
    }
  }
  return 1;
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class TorreDoConhecimentoScreen extends StatefulWidget {
  const TorreDoConhecimentoScreen({super.key});

  @override
  State<TorreDoConhecimentoScreen> createState() =>
      _TorreDoConhecimentoScreenState();
}

class _TorreDoConhecimentoScreenState extends State<TorreDoConhecimentoScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gam      = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final avatar   = context.watch<AvatarService>();
    final state    = gam.state;
    final level    = state.level;
    final currentFloor = _currentFloorNumber(progress);
    final completedFloors = kTowerFloors
        .where((f) => _floorState(f, progress) == _FloorState.completed)
        .length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFEF3C7), Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Top HUD ──────────────────────────────────────────────
              _TopHud(
                state: state,
                level: level,
                avatar: avatar,
                completedFloors: completedFloors,
              ),
              // ── Tower + Ladder ────────────────────────────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: Tower visual
                    Expanded(
                      flex: 3,
                      child: _TowerVisual(
                        floatCtrl: _floatCtrl,
                        glowCtrl: _glowCtrl,
                        particleCtrl: _particleCtrl,
                        completedFloors: completedFloors,
                        currentFloor: currentFloor,
                      ),
                    ),
                    // Right: Progress ladder
                    SizedBox(
                      width: 120,
                      child: _ProgressLadder(
                        progress: progress,
                        currentFloor: currentFloor,
                        glowCtrl: _glowCtrl,
                      ),
                    ),
                  ],
                ),
              ),
              // ── CTA Button ────────────────────────────────────────────
              _CtaButton(
                currentFloor: currentFloor,
                progress: progress,
                onTap: () => _goToFloor(context, currentFloor, progress),
              ),
              const SizedBox(height: 100), // tab bar clearance
            ],
          ),
        ),
      ),
    );
  }

  void _goToFloor(
      BuildContext context, int floorNumber, ProgressService progress) {
    final floor = kTowerFloors[floorNumber - 1];
    final floorState = _floorState(floor, progress);
    if (floorState == _FloorState.locked) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => TorreGameplayScreen(floor: floor),
        transitionsBuilder: (_, anim, __, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
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
// TOP HUD
// ═══════════════════════════════════════════════════════════════════════════

class _TopHud extends StatelessWidget {
  final PlayerState state;
  final PlayerLevel level;
  final AvatarService avatar;
  final int completedFloors;

  const _TopHud({
    required this.state,
    required this.level,
    required this.avatar,
    required this.completedFloors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Avatar + Level
          _AvatarChip(level: level, avatar: avatar),
          const SizedBox(width: 12),
          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Torre do Conhecimento',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _kText,
                  ),
                ),
                Text(
                  'Suba todos os andares! 🏆',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: _kSub,
                  ),
                ),
              ],
            ),
          ),
          // Coins + XP
          _CurrencyChips(coins: state.coins, xp: state.xp),
        ],
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final PlayerLevel level;
  final AvatarService avatar;

  const _AvatarChip({required this.level, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_kGoldLight, _kGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _kGoldLight.withOpacity(0.6),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              level.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _kPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Nível ${level.level}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrencyChips extends StatelessWidget {
  final int coins;
  final int xp;

  const _CurrencyChips({required this.coins, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Chip(icon: '🪙', value: '$coins', color: _kGold),
        const SizedBox(height: 4),
        _Chip(icon: '⭐', value: '$xp XP', color: _kPurple),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String icon;
  final String value;
  final Color color;

  const _Chip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOWER VISUAL
// ═══════════════════════════════════════════════════════════════════════════

class _TowerVisual extends StatelessWidget {
  final AnimationController floatCtrl;
  final AnimationController glowCtrl;
  final AnimationController particleCtrl;
  final int completedFloors;
  final int currentFloor;

  const _TowerVisual({
    required this.floatCtrl,
    required this.glowCtrl,
    required this.particleCtrl,
    required this.completedFloors,
    required this.currentFloor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([floatCtrl, glowCtrl, particleCtrl]),
      builder: (context, _) {
        final floatOffset = math.sin(floatCtrl.value * math.pi) * 8.0;
        final glowOpacity = 0.5 + glowCtrl.value * 0.5;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Background glow halo
            Positioned(
              bottom: 60,
              child: Container(
                width: 180,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGoldLight.withOpacity(0.15 * glowOpacity),
                ),
              ),
            ),
            // Tower body
            Transform.translate(
              offset: Offset(0, floatOffset),
              child: _TowerBody(
                completedFloors: completedFloors,
                currentFloor: currentFloor,
                glowOpacity: glowOpacity,
              ),
            ),
            // Floating particles
            ..._buildParticles(particleCtrl.value),
            // Mascots at base
            Positioned(
              bottom: 20,
              child: _Mascots(floatOffset: floatOffset * 0.3),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildParticles(double t) {
    final particles = <Widget>[];
    final random = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 + t * math.pi * 2;
      final radius = 80.0 + random.nextDouble() * 60;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius * 0.4 - 80;
      final size = 4.0 + random.nextDouble() * 6;
      final opacity = 0.3 + math.sin((t * math.pi * 2) + i) * 0.3;
      particles.add(
        Positioned(
          left: MediaQuery.of(_dummyContext!).size.width / 2 / 2 + x - size / 2,
          top: 200 + y,
          child: Opacity(
            opacity: opacity.clamp(0.1, 0.8),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i % 3 == 0
                    ? _kGoldLight
                    : i % 3 == 1
                        ? _kCyan
                        : _kPurple,
                boxShadow: [
                  BoxShadow(
                    color: (i % 3 == 0 ? _kGoldLight : _kCyan)
                        .withOpacity(0.6),
                    blurRadius: size,
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }
    return particles;
  }

  // Workaround: particles use overlay positioning via CustomPaint instead
  static BuildContext? _dummyContext;
}

class _TowerBody extends StatelessWidget {
  final int completedFloors;
  final int currentFloor;
  final double glowOpacity;

  const _TowerBody({
    required this.completedFloors,
    required this.currentFloor,
    required this.glowOpacity,
  });

  @override
  Widget build(BuildContext context) {
    _TowerVisual._dummyContext = context;
    return CustomPaint(
      size: const Size(200, 380),
      painter: _TowerPainter(
        completedFloors: completedFloors,
        currentFloor: currentFloor,
        glowOpacity: glowOpacity,
      ),
      child: SizedBox(
        width: 200,
        height: 380,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Crown at top
            Positioned(
              top: 8,
              child: const Text('👑', style: TextStyle(fontSize: 32))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.9, end: 1.1, duration: 1500.ms),
            ),
            // Floor counter text
            Positioned(
              top: 52,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGoldLight, width: 1.5),
                ),
                child: Text(
                  'Andar $currentFloor de 10',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _kGold,
                  ),
                ),
              ),
            ),
            // Open book floating
            Positioned(
              top: 110,
              child: const Text('📖', style: TextStyle(fontSize: 28))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -8, duration: 2000.ms)
                  .fade(begin: 0.7, end: 1.0),
            ),
            // Letter block
            Positioned(
              top: 180,
              right: 20,
              child: const Text('🔤', style: TextStyle(fontSize: 22))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -6, duration: 2500.ms, delay: 500.ms)
                  .fade(begin: 0.6, end: 1.0),
            ),
            // Star sparkle
            Positioned(
              top: 240,
              left: 15,
              child: const Text('✨', style: TextStyle(fontSize: 20))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.3, end: 1.0, duration: 1800.ms, delay: 800.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _TowerPainter extends CustomPainter {
  final int completedFloors;
  final int currentFloor;
  final double glowOpacity;

  _TowerPainter({
    required this.completedFloors,
    required this.currentFloor,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final floorHeight = (size.height - 60) / 10;
    final baseWidth = size.width * 0.72;
    final topWidth = size.width * 0.28;

    // Draw tower floors from bottom to top
    for (int i = 0; i < 10; i++) {
      final floorNum = i + 1;
      final bottom = size.height - 20 - (i * floorHeight);
      final top = bottom - floorHeight;
      final pct = i / 9;
      final halfW = (baseWidth / 2) * (1 - pct) + (topWidth / 2) * pct;

      final floorState = floorNum <= completedFloors
          ? _FloorState.completed
          : floorNum == currentFloor
              ? _FloorState.current
              : _FloorState.locked;

      // Floor fill
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: floorState == _FloorState.completed
              ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
              : floorState == _FloorState.current
                  ? [const Color(0xFF06B6D4), const Color(0xFF0891B2)]
                  : [const Color(0xFFE5E7EB), const Color(0xFFD1D5DB)],
        ).createShader(Rect.fromLTWH(cx - halfW, top, halfW * 2, floorHeight));

      final path = Path()
        ..moveTo(cx - halfW, top)
        ..lineTo(cx + halfW, top)
        ..lineTo(cx + halfW + 4, bottom)
        ..lineTo(cx - halfW - 4, bottom)
        ..close();

      canvas.drawPath(path, paint);

      // Glow for current floor
      if (floorState == _FloorState.current) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color =
              const Color(0xFF06B6D4).withOpacity(0.8 * glowOpacity);
        canvas.drawPath(path, glowPaint);
      }

      // Divider line
      final divPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 0.8;
      canvas.drawLine(
          Offset(cx - halfW - 2, top), Offset(cx + halfW + 2, top), divPaint);

      // Checkmark for completed
      if (floorState == _FloorState.completed) {
        final iconPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final midY = (top + bottom) / 2;
        final checkPath = Path()
          ..moveTo(cx - 6, midY)
          ..lineTo(cx - 1, midY + 5)
          ..lineTo(cx + 7, midY - 5);
        canvas.drawPath(checkPath, iconPaint);
      }
    }

    // Tower top spire
    final spirePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFFEF9C3)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(
          Rect.fromLTWH(cx - topWidth / 2, 0, topWidth, 50));

    final floorBottom = size.height - 20 - 9 * floorHeight;
    final spire = Path()
      ..moveTo(cx, 4)
      ..lineTo(cx + topWidth / 2 + 4, floorBottom)
      ..lineTo(cx - topWidth / 2 - 4, floorBottom)
      ..close();
    canvas.drawPath(spire, spirePaint..style = PaintingStyle.fill);

    // Spiral staircase lines
    final stairPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 10; i++) {
      final pct = i / 9;
      final y = size.height - 20 - (i + 0.5) * floorHeight;
      final halfW =
          (baseWidth / 2) * (1 - pct) + (topWidth / 2) * pct - 6;
      canvas.drawLine(
          Offset(cx - halfW, y), Offset(cx + halfW, y), stairPaint);
    }
  }

  @override
  bool shouldRepaint(_TowerPainter old) =>
      old.completedFloors != completedFloors ||
      old.currentFloor != currentFloor ||
      (old.glowOpacity - glowOpacity).abs() > 0.01;
}

// ═══════════════════════════════════════════════════════════════════════════
// MASCOTS
// ═══════════════════════════════════════════════════════════════════════════

class _Mascots extends StatelessWidget {
  final double floatOffset;

  const _Mascots({required this.floatOffset});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, floatOffset),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Beto — bear
          Column(
            children: [
              const Text('🐻', style: TextStyle(fontSize: 32)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kGold.withOpacity(0.4)),
                ),
                child: const Text(
                  'Beto',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _kGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Luna — fox
          Column(
            children: [
              const Text('🦊', style: TextStyle(fontSize: 28)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kCyan.withOpacity(0.4)),
                ),
                child: const Text(
                  'Luna',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _kCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Zeca — rabbit
          Column(
            children: [
              const Text('🐰', style: TextStyle(fontSize: 26)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kPurple.withOpacity(0.4)),
                ),
                child: const Text(
                  'Zeca',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _kPurple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROGRESS LADDER (right side)
// ═══════════════════════════════════════════════════════════════════════════

class _ProgressLadder extends StatelessWidget {
  final ProgressService progress;
  final int currentFloor;
  final AnimationController glowCtrl;

  const _ProgressLadder({
    required this.progress,
    required this.currentFloor,
    required this.glowCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      builder: (context, _) {
        final glowOpacity = 0.5 + glowCtrl.value * 0.5;
        return Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Andares',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kSub,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                reverse: true, // floor 1 at bottom
                itemCount: kTowerFloors.length,
                itemBuilder: (context, index) {
                  final floor = kTowerFloors[index];
                  final fs = _floorState(floor, progress);
                  return _LadderStep(
                    floor: floor,
                    floorState: fs,
                    isCurrent: floor.number == currentFloor,
                    glowOpacity: glowOpacity,
                    onTap: fs != _FloorState.locked
                        ? () => Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, anim, __) =>
                                    TorreGameplayScreen(floor: floor),
                                transitionsBuilder:
                                    (_, anim, __, child) => FadeTransition(
                                        opacity: anim, child: child),
                              ),
                            )
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LadderStep extends StatelessWidget {
  final TowerFloor floor;
  final _FloorState floorState;
  final bool isCurrent;
  final double glowOpacity;
  final VoidCallback? onTap;

  const _LadderStep({
    required this.floor,
    required this.floorState,
    required this.isCurrent,
    required this.glowOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    Widget dotChild;

    switch (floorState) {
      case _FloorState.completed:
        dotColor = _kGoldLight;
        dotChild = const Icon(Icons.check_rounded, size: 14, color: Colors.white);
      case _FloorState.current:
        dotColor = _kCyan;
        dotChild = Text(
          '${floor.number}',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        );
      case _FloorState.locked:
        dotColor = const Color(0xFFE5E7EB);
        dotChild = Icon(
          Icons.lock_rounded,
          size: 11,
          color: Colors.grey.shade400,
        );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: isCurrent
            ? BoxDecoration(
                color: _kCyanLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _kCyan.withOpacity(0.8 * glowOpacity), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _kCyan.withOpacity(0.25 * glowOpacity),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              )
            : null,
        child: Row(
          children: [
            // Dot
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: isCurrent || floorState == _FloorState.completed
                    ? [
                        BoxShadow(
                          color: dotColor.withOpacity(0.5),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
              child: Center(child: dotChild),
            ),
            const SizedBox(width: 6),
            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    floor.emoji,
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    floor.title,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      fontWeight: isCurrent
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isCurrent ? _kCyan : _kSub,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CTA BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _CtaButton extends StatelessWidget {
  final int currentFloor;
  final ProgressService progress;
  final VoidCallback onTap;

  const _CtaButton({
    required this.currentFloor,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final floor = kTowerFloors[currentFloor - 1];
    final fp = progress.getFamilyProgress(floor.familyKey, floor.totalWords);
    final isComplete = fp.isCompleted && currentFloor == 10;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _kGoldLight.withOpacity(0.55),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isComplete ? '🏆' : '⭐',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isComplete ? 'CONCLUÍDO!' : 'SUBIR A TORRE',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Andar ${floor.number}: ${floor.title}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.02, duration: 1200.ms),
    );
  }
}
