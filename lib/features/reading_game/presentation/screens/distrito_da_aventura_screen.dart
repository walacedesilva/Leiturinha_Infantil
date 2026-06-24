import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../data/adventure_content.dart';
import 'adventure_reading_screen.dart';
import 'adventure_story_screen.dart';
import 'portal_transition_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DISTRITO DA AVENTURA — Mapa Principal (3D Cartoon Isométrico)
// Paleta: Ciano #06B6D4, Azul Céu #7DD3FC, Dourado #FBBF24
// Estilo: Pixar-inspired, arestas suaves, golden hour
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTES VISUAIS
// ─────────────────────────────────────────────────────────────────────────────
const _kCyan = Color(0xFF06B6D4);
const _kSkyBlue = Color(0xFF7DD3FC);
const _kGold = Color(0xFFBFBF24);
const _kGoldLight = Color(0xFFFDE68A);
const _kGoldDeep = Color(0xFFD97706);
const _kCyanDark = Color(0xFF0E7490);
const _kCyanLight = Color(0xFFCFFAFE);
const _kSkyTop = Color(0xFFFED7AA);
const _kSkyBottom = Color(0xFFDBEAFE);
const _kPortalGlow = Color(0xFFFBBF24);
const _kMountainBase = Color(0xFF065F46);
const _kMountainMid = Color(0xFF059669);
const _kMountainTop = Color(0xFF34D399);
const _kGroundColor = Color(0xFF6EE7B7);
const _kPathColor = Color(0xFFFBBF24);

// ─────────────────────────────────────────────────────────────────────────────
// DATA: atividades do distrito
// ─────────────────────────────────────────────────────────────────────────────
enum _ActivityType { reading, story }

class _AdventureActivity {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final _ActivityType type;
  final Color color;
  final Color lightColor;
  final int totalItems;

  const _AdventureActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.type,
    required this.color,
    required this.lightColor,
    required this.totalItems,
  });
}

const _kActivities = <_AdventureActivity>[
  _AdventureActivity(
    id: 'reading_1',
    title: 'Trilha das Frases',
    subtitle: 'Frases para ler em voz alta',
    emoji: '📖',
    type: _ActivityType.reading,
    color: _kCyan,
    lightColor: _kCyanLight,
    totalItems: 18,
  ),
  _AdventureActivity(
    id: 'stories_1',
    title: 'Contos Mágicos',
    subtitle: 'Histórias para completar',
    emoji: '📜',
    type: _ActivityType.story,
    color: Color(0xFF8B5CF6),
    lightColor: Color(0xFFF3E8FF),
    totalItems: 6,
  ),
  _AdventureActivity(
    id: 'reading_2',
    title: 'Escada das Palavras',
    subtitle: 'Vocabulário em contexto',
    emoji: '🔤',
    type: _ActivityType.reading,
    color: Color(0xFF22C55E),
    lightColor: Color(0xFFF0FDF4),
    totalItems: 10,
  ),
  _AdventureActivity(
    id: 'portal',
    title: 'Portal Dourado',
    subtitle: 'O próximo reino te espera!',
    emoji: '✨',
    type: _ActivityType.reading,
    color: _kGoldDeep,
    lightColor: _kGoldLight,
    totalItems: 1,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DistritoAventuraScreen extends StatefulWidget {
  const DistritoAventuraScreen({super.key});

  @override
  State<DistritoAventuraScreen> createState() => _DistritoAventuraScreenState();
}

class _DistritoAventuraScreenState extends State<DistritoAventuraScreen>
    with TickerProviderStateMixin {
  // Balloon animation controllers (3 balloons with staggered drift)
  late final List<AnimationController> _balloonCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _portalCtrl;
  late final AnimationController _mascotCtrl;

  static const _balloonDefs = <({
    double startX,
    double startY,
    double endX,
    double endY,
    int durationMs,
    Color bodyColor,
    Color stripeColor,
    String label,
  })>[
    (
      startX: -0.15,
      startY: 0.12,
      endX: 1.15,
      endY: 0.08,
      durationMs: 22000,
      bodyColor: Color(0xFFEF4444),
      stripeColor: Color(0xFFFBBF24),
      label: 'O GATO MIA',
    ),
    (
      startX: -0.15,
      startY: 0.22,
      endX: 1.15,
      endY: 0.18,
      durationMs: 28000,
      bodyColor: Color(0xFF8B5CF6),
      stripeColor: Color(0xFF06B6D4),
      label: 'A BOLA ROLA',
    ),
    (
      startX: -0.15,
      startY: 0.32,
      endX: 1.15,
      endY: 0.27,
      durationMs: 19000,
      bodyColor: Color(0xFF22C55E),
      stripeColor: Color(0xFFFBBF24),
      label: 'TODOS SÃO AMIGOS',
    ),
  ];

  int _completedActivities = 0;

  @override
  void initState() {
    super.initState();
    _balloonCtrl = _balloonDefs.map((b) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: b.durationMs),
      );
      ctrl.forward();
      ctrl.addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) ctrl.forward(from: 0);
      });
      return ctrl;
    }).toList();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _portalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    for (final c in _balloonCtrl) c.dispose();
    _particleCtrl.dispose();
    _portalCtrl.dispose();
    _mascotCtrl.dispose();
    super.dispose();
  }

  void _launchActivity(BuildContext context, _AdventureActivity activity) {
    if (activity.id == 'portal') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PortalTransitionScreen()),
      );
      return;
    }
    if (activity.type == _ActivityType.reading) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdventureReadingScreen(activityId: activity.id),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdventureStoryScreen(activityId: activity.id),
        ),
      );
    }
  }

  void _startAdventure(BuildContext context) {
    // Find the first incomplete activity
    final progress = context.read<ProgressService>();
    _AdventureActivity first = _kActivities.first;
    for (final act in _kActivities) {
      if (act.id == 'portal') continue;
      final done = act.type == _ActivityType.reading
          ? kReadingPhrases
              .where((p) =>
                  progress.getCompletedWords(AdventureProgressKeys.phraseKey(p.id)).isNotEmpty)
              .length
          : kMicroStories
              .where((s) =>
                  progress.getCompletedWords(AdventureProgressKeys.storyKey(s.id)).isNotEmpty)
              .length;
      if (done < act.totalItems) {
        first = act;
        break;
      }
    }
    _launchActivity(context, first);
  }

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final size = MediaQuery.sizeOf(context);

    // Calculate progress
    final completedPhrases = kReadingPhrases
        .where((p) =>
            progress.getCompletedWords(AdventureProgressKeys.phraseKey(p.id)).isNotEmpty)
        .length;
    final completedStories = kMicroStories
        .where((s) =>
            progress.getCompletedWords(AdventureProgressKeys.storyKey(s.id)).isNotEmpty)
        .length;
    final totalActivities = 4;
    _completedActivities = [
      if (completedPhrases >= 5) 1,
      if (completedStories >= 2) 1,
      if (completedPhrases >= 10) 1,
      if (completedPhrases >= 18 && completedStories >= 6) 1,
    ].length;

    return Scaffold(
      backgroundColor: _kSkyBottom,
      body: Stack(
        children: [
          // ── Layer 1: Golden Hour Sky ─────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kSkyTop,
                    Color(0xFFFEF3C7),
                    _kSkyBlue,
                    _kSkyBottom,
                  ],
                  stops: [0.0, 0.25, 0.65, 1.0],
                ),
              ),
            ),
          ),
          // ── Layer 2: Letter-shaped clouds ──────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: CustomPaint(
              painter: _CloudPainter(),
            ),
          ),
          // ── Layer 3: Terrain & Portal (background) ─────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: CustomPaint(
              painter: _TerrainPainter(size),
            ),
          ),
          // ── Layer 4: Golden Portal glow ─────────────────────────────────
          AnimatedBuilder(
            animation: _portalCtrl,
            builder: (_, __) => Positioned(
              top: size.height * 0.28,
              left: size.width * 0.28,
              right: size.width * 0.28,
              child: _PortalWidget(pulse: _portalCtrl.value),
            ),
          ),
          // ── Layer 5: Floating Balloons ──────────────────────────────────
          ...List.generate(_balloonDefs.length, (i) {
            final b = _balloonDefs[i];
            return AnimatedBuilder(
              animation: _balloonCtrl[i],
              builder: (_, __) {
                final t = _balloonCtrl[i].value;
                final x = b.startX + (b.endX - b.startX) * t;
                final y = b.startY + (b.endY - b.startY) * t;
                // Gentle vertical bob
                final bob =
                    math.sin(t * math.pi * 6) * 0.012;
                return Positioned(
                  left: x * size.width,
                  top: (y + bob) * size.height,
                  child: _BalloonWidget(
                    bodyColor: b.bodyColor,
                    stripeColor: b.stripeColor,
                    label: b.label,
                  ),
                );
              },
            );
          }),
          // ── Layer 6: Mascot characters ──────────────────────────────────
          AnimatedBuilder(
            animation: _mascotCtrl,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.22,
              left: 24,
              child: _MascotFox(bounce: _mascotCtrl.value),
            ),
          ),
          AnimatedBuilder(
            animation: _mascotCtrl,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.25,
              right: 24,
              child: _MascotBird(bounce: 1.0 - _mascotCtrl.value),
            ),
          ),
          // ── Layer 7: Ink/page particles ─────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _ParticlePainter(_particleCtrl.value),
              ),
            ),
          ),
          // ── Layer 8: Top HUD ────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _TopHud(
                  coins: gam.state.coins,
                  xp: gam.state.xp,
                  streak: gam.state.currentStreak,
                  completedActivities: _completedActivities,
                  totalActivities: totalActivities,
                ),
                const Spacer(),
                // Activities scroll (bottom half)
                _ActivitiesPanel(
                  activities: _kActivities,
                  progress: progress,
                  onTap: (act) => _launchActivity(context, act),
                ),
                // CTA button
                _StartButton(
                  onTap: () => _startAdventure(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP HUD
// ─────────────────────────────────────────────────────────────────────────────
class _TopHud extends StatelessWidget {
  final int coins;
  final int xp;
  final int streak;
  final int completedActivities;
  final int totalActivities;

  const _TopHud({
    required this.coins,
    required this.xp,
    required this.streak,
    required this.completedActivities,
    required this.totalActivities,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar + badge
          _AvatarBadge(),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distrito da Aventura',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A5F),
                    shadows: [
                      Shadow(
                        color: Colors.white70,
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
                // Progress path
                _ProgressPath(
                  done: completedActivities,
                  total: totalActivities,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Coins + XP
          _CoinsXp(coins: coins, xp: xp, streak: streak),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.4);
  }
}

class _AvatarBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_kCyan, _kCyanDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _kGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: _kCyan.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text('🧒', style: TextStyle(fontSize: 26)),
          ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _kGold,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kGoldDeep.withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Text(
              'Nv.3',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF78350F),
              ),
            ),
          ),
        ),
        Positioned(
          top: -6,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Leitor Iniciante',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: _kGoldLight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressPath extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressPath({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Aventura: $done/$total',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0E7490),
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(total, (i) => Container(
          margin: const EdgeInsets.only(right: 3),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < done ? _kGold : Colors.white.withOpacity(0.7),
            border: Border.all(
              color: i < done ? _kGoldDeep : const Color(0xFF7DD3FC),
              width: 1.5,
            ),
            boxShadow: i < done
                ? [BoxShadow(color: _kGold.withOpacity(0.6), blurRadius: 4)]
                : null,
          ),
          child: i < done
              ? const Icon(Icons.check, size: 9, color: Color(0xFF78350F))
              : null,
        )),
      ],
    );
  }
}

class _CoinsXp extends StatelessWidget {
  final int coins;
  final int xp;
  final int streak;

  const _CoinsXp({required this.coins, required this.xp, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Chip(icon: '🪙', value: '$coins', color: _kGold),
        const SizedBox(height: 4),
        _Chip(icon: '⭐', value: '$xp XP', color: const Color(0xFF8B5CF6)),
        if (streak > 0) ...[
          const SizedBox(height: 4),
          _Chip(icon: '🔥', value: '$streak', color: const Color(0xFFEF4444)),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITIES PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _ActivitiesPanel extends StatelessWidget {
  final List<_AdventureActivity> activities;
  final ProgressService progress;
  final ValueChanged<_AdventureActivity> onTap;

  const _ActivitiesPanel({
    required this.activities,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final act = activities[i];
          final done = _getDone(act);
          final pct = done / act.totalItems;
          return _ActivityCard(
            activity: act,
            done: done,
            pct: pct,
            delay: Duration(milliseconds: 100 * i),
            onTap: () => onTap(act),
          );
        },
      ),
    );
  }

  int _getDone(_AdventureActivity act) {
    if (act.type == _ActivityType.reading) {
      return kReadingPhrases
          .where((p) =>
              progress.getCompletedWords(AdventureProgressKeys.phraseKey(p.id)).isNotEmpty)
          .length;
    }
    return kMicroStories
        .where((s) =>
            progress.getCompletedWords(AdventureProgressKeys.storyKey(s.id)).isNotEmpty)
        .length;
  }
}

class _ActivityCard extends StatelessWidget {
  final _AdventureActivity activity;
  final int done;
  final double pct;
  final Duration delay;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.done,
    required this.pct,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = pct >= 1.0;
    final isPortal = activity.id == 'portal';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 118,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPortal
                ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                : isCompleted
                    ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                    : [activity.lightColor, Colors.white],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPortal
                ? _kGoldDeep
                : isCompleted
                    ? const Color(0xFF16A34A)
                    : activity.color.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPortal ? _kGoldDeep : activity.color).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(activity.emoji, style: const TextStyle(fontSize: 28)),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle,
                        size: 16, color: Color(0xFF16A34A)),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              activity.title,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isPortal
                    ? const Color(0xFF78350F)
                    : isCompleted
                        ? Colors.white
                        : const Color(0xFF1E3A5F),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (!isPortal) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: Colors.black12,
                  color: isCompleted ? Colors.white : activity.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$done/${activity.totalItems}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9,
                  color: isCompleted
                      ? Colors.white.withOpacity(0.9)
                      : activity.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      )
          .animate(delay: delay)
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.3, curve: Curves.easeOut),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// START BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _StartButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kCyan, _kGold],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _kCyan.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: _kGold.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.explore_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'INICIAR AVENTURA',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
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
        .animate()
        .fadeIn(delay: 300.ms, duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _kCyan.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Início',
            isActive: false,
            onTap: () => Navigator.of(context).pop(),
          ),
          _NavItem(
            icon: Icons.emoji_events_rounded,
            label: 'Desafios',
            isActive: true,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.star_rounded,
            label: 'Conquistas',
            isActive: false,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Perfil',
            isActive: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? _kCyan.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isActive ? _kCyanDark : const Color(0xFF94A3B8),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? _kCyanDark : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BALLOON WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _BalloonWidget extends StatelessWidget {
  final Color bodyColor;
  final Color stripeColor;
  final String label;

  const _BalloonWidget({
    required this.bodyColor,
    required this.stripeColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Balloon body
        Container(
          width: 62,
          height: 75,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              radius: 0.8,
              colors: [
                Color.lerp(bodyColor, Colors.white, 0.5)!,
                bodyColor,
                Color.lerp(bodyColor, Colors.black, 0.2)!,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.elliptical(31, 45),
              topRight: Radius.elliptical(31, 45),
              bottomLeft: Radius.elliptical(31, 30),
              bottomRight: Radius.elliptical(31, 30),
            ),
            boxShadow: [
              BoxShadow(
                color: bodyColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: CustomPaint(painter: _BalloonStripePainter(stripeColor)),
        ),
        // Rope
        Container(
          width: 1.5,
          height: 18,
          color: const Color(0xFF92400E),
        ),
        // Banner label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: bodyColor.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: bodyColor.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BalloonStripePainter extends CustomPainter {
  final Color stripeColor;
  _BalloonStripePainter(this.stripeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    for (int i = 0; i < 4; i++) {
      final x = size.width * (i + 1) / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_BalloonStripePainter o) => o.stripeColor != stripeColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// PORTAL WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _PortalWidget extends StatelessWidget {
  final double pulse;

  const _PortalWidget({required this.pulse});

  @override
  Widget build(BuildContext context) {
    final glowRadius = 18.0 + pulse * 14;
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow rays behind arch
          CustomPaint(
            size: const Size(150, 110),
            painter: _PortalRaysPainter(pulse),
          ),
          // Arch
          Container(
            width: 110 + pulse * 6,
            height: 100 + pulse * 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kGold,
                  _kGoldDeep,
                  const Color(0xFFB45309),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.elliptical(55, 50),
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPortalGlow.withOpacity(0.6),
                  blurRadius: glowRadius,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: _kPortalGlow.withOpacity(0.3),
                  blurRadius: glowRadius * 2,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          // Inner glow (portal interior)
          Container(
            width: 82 + pulse * 4,
            height: 76 + pulse * 3,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  _kGoldLight.withOpacity(0.7),
                  _kGold.withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.elliptical(41, 38),
              ),
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 28)),
            ),
          ),
          // PORTAL label
          Positioned(
            bottom: 0,
            child: Text(
              'PORTAL DOURADO',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: _kGoldDeep,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalRaysPainter extends CustomPainter {
  final double pulse;
  _PortalRaysPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final paint = Paint()
      ..color = _kGold.withOpacity(0.15 + pulse * 0.1)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final r1 = 42.0;
      final r2 = 70.0 + pulse * 12;
      canvas.drawLine(
        center + Offset(math.cos(angle) * r1, math.sin(angle) * r1),
        center + Offset(math.cos(angle) * r2, math.sin(angle) * r2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PortalRaysPainter o) => o.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// MASCOTS
// ─────────────────────────────────────────────────────────────────────────────
class _MascotFox extends StatelessWidget {
  final double bounce;

  const _MascotFox({required this.bounce});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -bounce * 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFED7AA), Color(0xFFF97316)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const Text('🦊', style: TextStyle(fontSize: 32)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF97316), width: 1.5),
            ),
            child: const Text(
              'Vamos lá! 🚀',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC2410C),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideX(begin: -0.5, curve: Curves.easeOut);
  }
}

class _MascotBird extends StatelessWidget {
  final double bounce;

  const _MascotBird({required this.bounce});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -bounce * 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFBAE6FD), Color(0xFF0284C7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const Text('🐦', style: TextStyle(fontSize: 32)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
            ),
            child: const Text(
              'Você consegue! 💪',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF075985),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 400.ms)
        .slideX(begin: 0.5, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

/// Clouds shaped like letters floating in the sky.
class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    void _drawCloud(double cx, double cy, double scale) {
      final path = Path();
      // Simple rounded cloud shape
      path.addOval(Rect.fromCenter(
          center: Offset(cx, cy), width: 60 * scale, height: 36 * scale));
      path.addOval(Rect.fromCenter(
          center: Offset(cx - 20 * scale, cy + 5 * scale),
          width: 44 * scale,
          height: 28 * scale));
      path.addOval(Rect.fromCenter(
          center: Offset(cx + 22 * scale, cy + 5 * scale),
          width: 44 * scale,
          height: 28 * scale));
      canvas.drawPath(path, paint);
    }

    _drawCloud(size.width * 0.12, size.height * 0.18, 0.8);
    _drawCloud(size.width * 0.45, size.height * 0.08, 1.1);
    _drawCloud(size.width * 0.78, size.height * 0.2, 0.7);
    _drawCloud(size.width * 0.62, size.height * 0.35, 0.6);
    _drawCloud(size.width * 0.22, size.height * 0.42, 0.5);

    // Floating books
    final bookPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.55, 22, 16),
        const Radius.circular(3),
      ),
      bookPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.88, size.height * 0.48, 18, 13),
        const Radius.circular(3),
      ),
      bookPaint,
    );
  }

  @override
  bool shouldRepaint(_CloudPainter o) => false;
}

/// Isometric terrain with mountain path, library corner, and ground.
class _TerrainPainter extends CustomPainter {
  final Size screenSize;
  _TerrainPainter(this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground (grass)
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_kGroundColor, const Color(0xFF34D399)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.18, w, h * 0.82), groundPaint);

    // Story Mountain (center-back)
    _drawMountain(canvas, w, h);

    // Library Corner (left)
    _drawLibraryCorner(canvas, w, h);

    // Golden path (dotted trail leading to portal)
    _drawGoldenPath(canvas, w, h);
  }

  void _drawMountain(Canvas canvas, double w, double h) {
    // Mountain base
    final basePaint = Paint()..color = _kMountainBase;
    final path = Path()
      ..moveTo(w * 0.25, h * 0.55)
      ..lineTo(w * 0.5, h * 0.0)
      ..lineTo(w * 0.75, h * 0.55)
      ..close();
    canvas.drawPath(path, basePaint);

    // Snow cap
    final snowPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    final snowPath = Path()
      ..moveTo(w * 0.41, h * 0.14)
      ..lineTo(w * 0.5, h * 0.0)
      ..lineTo(w * 0.59, h * 0.14)
      ..lineTo(w * 0.5, h * 0.18)
      ..close();
    canvas.drawPath(snowPath, snowPaint);

    // Mountain mid layer (lighter)
    final midPaint = Paint()..color = _kMountainMid;
    final midPath = Path()
      ..moveTo(w * 0.3, h * 0.55)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.52, h * 0.06)
      ..lineTo(w * 0.72, h * 0.55)
      ..close();
    canvas.drawPath(midPath, midPaint);

    // Milestone markers on mountain
    final markerPaint = Paint()
      ..color = _kGold
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final t = (i + 1) / 5.0;
      final mx = w * (0.38 + t * 0.14);
      final my = h * (0.48 - t * 0.38);
      canvas.drawCircle(Offset(mx, my), 5, markerPaint);
      canvas.drawCircle(
        Offset(mx, my),
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawLibraryCorner(Canvas canvas, double w, double h) {
    // Cozy open-air structure
    final roofPaint = Paint()..color = const Color(0xFFB45309);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.04, h * 0.38, w * 0.22, 6),
      roofPaint,
    );
    // Wall
    final wallPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.38, w * 0.22, h * 0.14),
        const Radius.circular(6),
      ),
      wallPaint,
    );
    // Books icon
    final bookPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.42, 10, 14),
        const Radius.circular(2),
      ),
      bookPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.09, h * 0.42, 10, 14),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF3B82F6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.42, 10, 14),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF22C55E),
    );
  }

  void _drawGoldenPath(Canvas canvas, double w, double h) {
    final pathPaint = Paint()
      ..color = _kGold.withOpacity(0.85)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = _kGold
      ..style = PaintingStyle.fill;

    // Winding dotted path from bottom to portal
    final pathPoints = [
      Offset(w * 0.5, h * 0.95),
      Offset(w * 0.35, h * 0.80),
      Offset(w * 0.5, h * 0.65),
      Offset(w * 0.6, h * 0.50),
      Offset(w * 0.5, h * 0.32),
    ];

    for (int i = 0; i < pathPoints.length - 1; i++) {
      // Draw dashes
      final p1 = pathPoints[i];
      final p2 = pathPoints[i + 1];
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final steps = (dist / 14).ceil();
      for (int j = 0; j < steps; j += 2) {
        final t1 = j / steps;
        final t2 = math.min((j + 1) / steps, 1.0);
        canvas.drawLine(
          Offset(p1.dx + dx * t1, p1.dy + dy * t1),
          Offset(p1.dx + dx * t2, p1.dy + dy * t2),
          pathPaint,
        );
      }
    }

    // X marker at portal position
    canvas.drawCircle(pathPoints.last, 8, dotPaint);
    canvas.drawCircle(
      pathPoints.last,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Draw X
    final xPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      pathPoints.last + const Offset(-4, -4),
      pathPoints.last + const Offset(4, 4),
      xPaint,
    );
    canvas.drawLine(
      pathPoints.last + const Offset(4, -4),
      pathPoints.last + const Offset(-4, 4),
      xPaint,
    );
  }

  @override
  bool shouldRepaint(_TerrainPainter o) => false;
}

/// Floating ink-drop sparkles and page particles.
class _ParticlePainter extends CustomPainter {
  final double t;
  static final _rng = math.Random(42);
  static final _positions = List.generate(
    18,
    (i) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final _speeds = List.generate(18, (i) => 0.3 + _rng.nextDouble() * 0.7);
  static final _sizes = List.generate(18, (i) => 3.0 + _rng.nextDouble() * 5);
  static final _emojis = ['✨', '📄', '⭐', '💫', '📖', '✨', '🌟', '📄', '⭐'];

  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 18; i++) {
      final progress = ((t * _speeds[i]) + _positions[i].dx) % 1.0;
      final y = _positions[i].dy * size.height -
          progress * size.height * 0.3;
      if (y < 0 || y > size.height) continue;
      final x = _positions[i].dx * size.width;
      final paint = Paint()
        ..color = (i % 2 == 0 ? _kGold : _kCyan)
            .withOpacity(0.35 * (1 - progress));
      canvas.drawCircle(Offset(x, y), _sizes[i] * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter o) => o.t != t;
}
