import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import 'adventure_potion_screen.dart';
import 'portal_transition_screen.dart';
import 'word_garden_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DISTRITO DOS DÍGRAFOS — Mapa Principal (3D Cartoon Isométrico)
// Paleta: Roxo #8B5CF6, Lavanda #A78BFA, Azul Cristal #60A5FA, Dourado #FBBF24
// Estilo: Pixar-inspired, laboratório alquimista, pôr do sol mágico
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTES VISUAIS
// ─────────────────────────────────────────────────────────────────────────────
const _kPurple     = Color(0xFF8B5CF6);
const _kPurpleDark = Color(0xFF6D28D9);
const _kLavender   = Color(0xFFA78BFA);
const _kLavLight   = Color(0xFFEDE9FE);
const _kCrystal    = Color(0xFF60A5FA);
const _kGold       = Color(0xFFFBBF24);
const _kGoldDeep   = Color(0xFFD97706);
const _kGoldLight  = Color(0xFFFDE68A);
const _kSkyTop     = Color(0xFFDDD6FE);
const _kSkyMid     = Color(0xFFEDE9FE);
const _kSkyBottom  = Color(0xFFF5F3FF);
const _kGround     = Color(0xFF7C3AED);
const _kGroundMid  = Color(0xFF8B5CF6);
const _kGroundLow  = Color(0xFFA78BFA);

// ─────────────────────────────────────────────────────────────────────────────
// DATA: atividades do distrito
// ─────────────────────────────────────────────────────────────────────────────
class _DigrafoActivity {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final Color lightColor;
  final int totalItems;
  final bool isPortal;
  final bool comingSoon;

  const _DigrafoActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.lightColor,
    required this.totalItems,
    this.isPortal = false,
    this.comingSoon = false,
  });
}

const _kActivities = <_DigrafoActivity>[
  _DigrafoActivity(
    id: 'caldeiron_1',
    title: 'Caldeirão das Palavras',
    subtitle: 'CH · LH · NH em poções',
    emoji: '🧪',
    color: _kPurple,
    lightColor: _kLavLight,
    totalItems: 5,
    comingSoon: false,
  ),
  _DigrafoActivity(
    id: 'jardim_1',
    title: 'Jardim de Palavras',
    subtitle: 'CHÁ · FOLHA · NINHO',
    emoji: '🌿',
    color: Color(0xFF22C55E),
    lightColor: Color(0xFFF0FDF4),
    totalItems: 10,
    comingSoon: false,
  ),
  _DigrafoActivity(
    id: 'pergaminho_1',
    title: 'Pergaminhos Mágicos',
    subtitle: 'Complete lacunas nas histórias',
    emoji: '📜',
    color: _kCrystal,
    lightColor: Color(0xFFEFF6FF),
    totalItems: 5,
    comingSoon: true,
  ),
  _DigrafoActivity(
    id: 'portal_digrafos',
    title: 'Portal Estelar',
    subtitle: 'O próximo reino te aguarda!',
    emoji: '🔮',
    color: _kGoldDeep,
    lightColor: _kGoldLight,
    totalItems: 1,
    isPortal: true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DistritoDigrafosScreen extends StatefulWidget {
  const DistritoDigrafosScreen({super.key});

  @override
  State<DistritoDigrafosScreen> createState() => _DistritoDigrafosScreenState();
}

class _DistritoDigrafosScreenState extends State<DistritoDigrafosScreen>
    with TickerProviderStateMixin {
  late final AnimationController _cauldronCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _crystalCtrl;
  late final AnimationController _mascotCtrl;
  late final AnimationController _runeCtrl;
  late final List<AnimationController> _floatCtrl;

  // Dígrafos flutuantes
  static const _kDigraphs = ['CH', 'LH', 'NH', 'QU', 'GU'];

  @override
  void initState() {
    super.initState();

    _cauldronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _crystalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _runeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _floatCtrl = List.generate(_kDigraphs.length, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1600 + i * 300),
      )..repeat(reverse: true);
      return ctrl;
    });
  }

  @override
  void dispose() {
    _cauldronCtrl.dispose();
    _particleCtrl.dispose();
    _crystalCtrl.dispose();
    _mascotCtrl.dispose();
    _runeCtrl.dispose();
    for (final c in _floatCtrl) c.dispose();
    super.dispose();
  }

  void _launchActivity(BuildContext context, _DigrafoActivity activity) {
    if (activity.isPortal) {
      AudioManager().playSFX(SFXType.correct);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PortalTransitionScreen()),
      );
      return;
    }
    if (activity.id == 'caldeiron_1') {
      AudioManager().playSFX(SFXType.pop);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdventurePotionScreen()),
      );
      return;
    }
    if (activity.id == 'jardim_1') {
      AudioManager().playSFX(SFXType.pop);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WordGardenScreen()),
      );
      return;
    }
    // Em breve
    AudioManager().playSFX(SFXType.error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${activity.emoji} ${activity.title} — Em breve!',
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kCrystal,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _startPotion(BuildContext context) {
    _launchActivity(context, _kActivities.first);
  }

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _kSkyBottom,
      body: Stack(
        children: [
          // ── Layer 1: Twilight Sky ──────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kSkyTop,
                    _kSkyMid,
                    _kSkyBottom,
                    Color(0xFFEDE9FE),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),
          // ── Layer 2: Stars / Rune particles ────────────────────────────
          AnimatedBuilder(
            animation: _runeCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _RuneParticlePainter(_runeCtrl.value),
              ),
            ),
          ),
          // ── Layer 3: Ground terrain ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.52,
            child: CustomPaint(
              painter: _GroundPainter(size),
            ),
          ),
          // ── Layer 4: Potion Laboratory building ─────────────────────────
          Positioned(
            bottom: size.height * 0.32,
            right: 16,
            child: const _LabBuilding(),
          ),
          // ── Layer 5: Word-plant garden ──────────────────────────────────
          Positioned(
            bottom: size.height * 0.24,
            left: 12,
            child: const _WordGarden(),
          ),
          // ── Layer 6: Open scroll with digraphs ─────────────────────────
          Positioned(
            bottom: size.height * 0.38,
            left: size.width * 0.28,
            child: const _MagicScroll(),
          ),
          // ── Layer 7: Central cauldron ───────────────────────────────────
          AnimatedBuilder(
            animation: _cauldronCtrl,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.20,
              left: size.width * 0.5 - 64,
              child: _Cauldron(bubble: _cauldronCtrl.value),
            ),
          ),
          // ── Layer 8: Floating digraph letters ──────────────────────────
          ...List.generate(_kDigraphs.length, (i) {
            final angle = (i / _kDigraphs.length) * 2 * math.pi - math.pi / 2;
            final radius = size.width * 0.26;
            final cx = size.width / 2 + math.cos(angle) * radius;
            final cy = size.height * 0.52 - math.sin(angle) * radius * 0.45;
            return AnimatedBuilder(
              animation: _floatCtrl[i],
              builder: (_, __) {
                final dy = math.sin(_floatCtrl[i].value * math.pi) * 8.0;
                return Positioned(
                  left: cx - 22,
                  top: cy + dy,
                  child: _DigrafoLabel(text: _kDigraphs[i]),
                );
              },
            );
          }),
          // ── Layer 9: Crystal clusters ────────────────────────────────
          AnimatedBuilder(
            animation: _crystalCtrl,
            builder: (_, __) => Positioned(
              top: size.height * 0.12,
              right: 28,
              child: _CrystalCluster(glow: _crystalCtrl.value),
            ),
          ),
          AnimatedBuilder(
            animation: _crystalCtrl,
            builder: (_, __) => Positioned(
              top: size.height * 0.18,
              left: 18,
              child: _CrystalCluster(glow: 1 - _crystalCtrl.value, small: true),
            ),
          ),
          // ── Layer 10: Magical mist ──────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.22,
              child: CustomPaint(
                painter: _MistPainter(_particleCtrl.value),
              ),
            ),
          ),
          // ── Layer 11: Beto (urso) na janela do lab ───────────────────
          Positioned(
            bottom: size.height * 0.44,
            right: 36,
            child: const _MascotBeto(),
          ),
          // ── Layer 12: Luna (raposa alquimista) ───────────────────────
          AnimatedBuilder(
            animation: _mascotCtrl,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.22,
              left: 18,
              child: _MascotLuna(bounce: _mascotCtrl.value),
            ),
          ),
          // ── Layer 13: Potion spark particles ────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _SparkPainter(_particleCtrl.value),
              ),
            ),
          ),
          // ── Layer 14: HUD ────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _TopHud(
                  coins: gam.state.coins,
                  xp: gam.state.xp,
                  streak: gam.state.currentStreak,
                ),
                const Spacer(),
                _ActivitiesPanel(
                  activities: _kActivities,
                  onTap: (act) => _launchActivity(context, act),
                ),
                _MakePotion(onTap: () => _startPotion(context)),
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
  final int coins, xp, streak;
  const _TopHud({required this.coins, required this.xp, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _AvatarBadge(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distrito dos Dígrafos',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    shadows: [Shadow(color: Colors.white70, blurRadius: 6)],
                  ),
                ),
                _ProgressPotion(),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
              colors: [_kLavender, _kPurpleDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _kGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(child: Text('🧒', style: TextStyle(fontSize: 26))),
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
                color: _kPurpleDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Alquimista Aprendiz',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 6.5,
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

class _ProgressPotion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Dígrafos: 0/5',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kPurpleDark,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Text(
              i < 0 ? '🧪' : '🫙',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoinsXp extends StatelessWidget {
  final int coins, xp, streak;
  const _CoinsXp({required this.coins, required this.xp, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Chip(icon: '🪙', value: '$coins', color: _kGold),
        const SizedBox(height: 4),
        _Chip(icon: '⭐', value: '$xp XP', color: _kPurple),
        if (streak > 0) ...[
          const SizedBox(height: 4),
          _Chip(icon: '🔥', value: '$streak', color: const Color(0xFFEF4444)),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String icon, value;
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
  final List<_DigrafoActivity> activities;
  final ValueChanged<_DigrafoActivity> onTap;

  const _ActivitiesPanel({required this.activities, required this.onTap});

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
          return _ActivityCard(
            activity: act,
            delay: Duration(milliseconds: 100 * i),
            onTap: () => onTap(act),
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _DigrafoActivity activity;
  final Duration delay;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPortal = activity.isPortal;
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
                : [activity.lightColor, Colors.white],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPortal ? _kGoldDeep : activity.color.withOpacity(0.4),
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
                if (!isPortal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: activity.comingSoon
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: activity.comingSoon
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF16A34A),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      activity.comingSoon ? 'Em breve' : '✓ Disponível',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: activity.comingSoon
                            ? const Color(0xFF92400E)
                            : const Color(0xFF15803D),
                      ),
                    ),
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
                color: isPortal ? const Color(0xFF78350F) : const Color(0xFF3B0764),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              activity.subtitle,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                color: isPortal
                    ? const Color(0xFF92400E)
                    : activity.color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isPortal) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0,
                  minHeight: 5,
                  backgroundColor: Colors.black12,
                  color: activity.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '0/${activity.totalItems}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9,
                  color: activity.color,
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
// MAKE POTION BUTTON (CTA)
// ─────────────────────────────────────────────────────────────────────────────
class _MakePotion extends StatelessWidget {
  final VoidCallback onTap;
  const _MakePotion({required this.onTap});

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
              colors: [_kPurple, _kGold],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: _kGold.withOpacity(0.35),
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
                child: const Text('🧪', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 10),
              const Text(
                'FAZER POÇÕES',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2)),
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
            color: _kPurple.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Início', isActive: false,
              onTap: () => Navigator.of(context).pop()),
          _NavItem(icon: Icons.emoji_events_rounded, label: 'Desafios', isActive: true, onTap: () {}),
          _NavItem(icon: Icons.star_rounded, label: 'Conquistas', isActive: false, onTap: () {}),
          _NavItem(icon: Icons.person_rounded, label: 'Perfil', isActive: false, onTap: () {}),
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
      child: SizedBox(
        width: 56,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? _kPurple.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? _kPurpleDark : const Color(0xFF94A3B8),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? _kPurpleDark : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAULDRON WIDGET (peça central)
// ─────────────────────────────────────────────────────────────────────────────
class _Cauldron extends StatelessWidget {
  final double bubble;
  const _Cauldron({required this.bubble});

  @override
  Widget build(BuildContext context) {
    final glowRadius = 20.0 + bubble * 16;
    return SizedBox(
      width: 128,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow de fundo
          Positioned(
            bottom: 0,
            child: Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withOpacity(0.4 + bubble * 0.2),
                    blurRadius: glowRadius,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          // Corpo do caldeirão (CustomPaint)
          CustomPaint(
            size: const Size(128, 130),
            painter: _CauldronPainter(bubble),
          ),
        ],
      ),
    );
  }
}

class _CauldronPainter extends CustomPainter {
  final double bubble;
  _CauldronPainter(this.bubble);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.58;

    // ── Pernas do caldeirão ──────────────────────────────────────────────
    final legPaint = Paint()
      ..color = const Color(0xFF4C1D95)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 28, cy + 28), Offset(cx - 38, cy + 52), legPaint);
    canvas.drawLine(Offset(cx + 28, cy + 28), Offset(cx + 38, cy + 52), legPaint);
    canvas.drawLine(Offset(cx, cy + 32), Offset(cx, cy + 52), legPaint);

    // ── Corpo do caldeirão ────────────────────────────────────────────────
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [Color(0xFF7C3AED), Color(0xFF4C1D95), Color(0xFF2E1065)],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, cy),
        width: 90,
        height: 80,
      ));
    final bodyPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: 90, height: 72));
    canvas.drawPath(bodyPath, bodyPaint);

    // ── Rim (borda) do caldeirão ──────────────────────────────────────────
    final rimPaint = Paint()
      ..color = const Color(0xFF6D28D9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 6), width: 96, height: 24),
      rimPaint,
    );

    // ── Líquido da poção (interior) ───────────────────────────────────────
    final liquidShader = LinearGradient(
      colors: [
        Color.lerp(const Color(0xFF8B5CF6), const Color(0xFF60A5FA), bubble)!,
        Color.lerp(const Color(0xFF60A5FA), const Color(0xFFA78BFA), bubble)!,
        const Color(0xFFFBBF24),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCenter(
      center: Offset(cx, cy - 4),
      width: 76,
      height: 30,
    ));
    final liquidPaint = Paint()..shader = liquidShader;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 4 - bubble * 3), width: 76, height: 26),
      liquidPaint,
    );

    // ── Bolhas na superfície ──────────────────────────────────────────────
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final rng = math.Random(42);
    for (int i = 0; i < 5; i++) {
      final bx = cx - 28.0 + rng.nextDouble() * 56;
      final by = cy - 6.0 - bubble * 4 + math.sin(bubble * math.pi + i) * 3;
      final br = 3.0 + rng.nextDouble() * 4;
      canvas.drawCircle(Offset(bx, by), br, bubblePaint);
    }

    // ── Alça (handle) ────────────────────────────────────────────────────
    final handlePaint = Paint()
      ..color = const Color(0xFF4C1D95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 26), width: 50, height: 28),
      math.pi,
      math.pi,
      false,
      handlePaint,
    );

    // ── Vapor subindo ─────────────────────────────────────────────────────
    final steamPaint = Paint()
      ..color = _kLavender.withOpacity(0.35 + bubble * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final steamPath = Path();
      final sx = cx - 20.0 + i * 20;
      final t = (bubble + i * 0.33) % 1.0;
      steamPath.moveTo(sx, cy - 36);
      steamPath.cubicTo(
        sx + 8, cy - 36 - t * 18,
        sx - 8, cy - 36 - t * 30,
        sx + 4, cy - 36 - t * 44,
      );
      canvas.drawPath(steamPath, steamPaint);
    }
  }

  @override
  bool shouldRepaint(_CauldronPainter o) => o.bubble != bubble;
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING DIGRAFO LABEL
// ─────────────────────────────────────────────────────────────────────────────
// Mapa dígrafo → frase curta para TTS
const _kDigraphSpeech = {
  'CH': 'C H faz o som de chá!',
  'LH': 'L H faz o som de folha!',
  'NH': 'N H faz o som de ninho!',
  'QU': 'Q U faz o som de queijo!',
  'GU': 'G U faz o som de guerra!',
};

class _DigrafoLabel extends StatelessWidget {
  final String text;
  const _DigrafoLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final speech = _kDigraphSpeech[text] ?? text;
        AudioManager().playWord(speech);
        AudioManager().playSFX(SFXType.pop);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kGold, _kGoldDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kGold.withOpacity(0.65),
              blurRadius: 12,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(color: Color(0xFF000000), blurRadius: 3, offset: Offset(0, 1)),
              Shadow(color: Color(0xFF000000), blurRadius: 3, offset: Offset(1, 0)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POTION LABORATORY BUILDING
// ─────────────────────────────────────────────────────────────────────────────
class _LabBuilding extends StatelessWidget {
  const _LabBuilding();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 110,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Telhado arredondado roxo
          Positioned(
            top: 0,
            left: 6,
            right: 6,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kLavender, _kPurpleDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(child: Text('🔬', style: TextStyle(fontSize: 18))),
            ),
          ),
          // Parede
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 32,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                border: Border.all(color: _kPurple.withOpacity(0.4), width: 2),
              ),
            ),
          ),
          // Janela cristal (com Beto)
          Positioned(
            top: 38,
            left: 10,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _kCrystal.withOpacity(0.8),
                    _kCrystal.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _kPurple.withOpacity(0.5), width: 2),
              ),
            ),
          ),
          Positioned(
            top: 38,
            right: 10,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _kCrystal.withOpacity(0.8),
                    _kCrystal.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _kPurple.withOpacity(0.5), width: 2),
              ),
            ),
          ),
          // Porta
          Positioned(
            bottom: 0,
            left: 22,
            right: 22,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: _kPurpleDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: const Center(
                child: Text('🚪', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
          // Placa
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _kGold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LAB',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAGIC SCROLL
// ─────────────────────────────────────────────────────────────────────────────
class _MagicScroll extends StatelessWidget {
  const _MagicScroll();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGoldDeep.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: _kGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('📜', style: TextStyle(fontSize: 22)),
          SizedBox(height: 2),
          Text(
            'CH·LH·NH',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 7,
              fontWeight: FontWeight.w900,
              color: Color(0xFF78350F),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD GARDEN (CHÁ, FOLHA, NINHO)
// ─────────────────────────────────────────────────────────────────────────────
class _WordGarden extends StatelessWidget {
  const _WordGarden();

  static const _plants = [
    ('🌿', 'CHÁ'),
    ('🍃', 'FOLHA'),
    ('🪺', 'NINHO'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _plants.map((p) {
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.$1, style: const TextStyle(fontSize: 20)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.$2,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 6,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CRYSTAL CLUSTER
// ─────────────────────────────────────────────────────────────────────────────
class _CrystalCluster extends StatelessWidget {
  final double glow;
  final bool small;
  const _CrystalCluster({required this.glow, this.small = false});

  @override
  Widget build(BuildContext context) {
    final scale = small ? 0.65 : 1.0;
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 50,
        height: 60,
        child: CustomPaint(
          painter: _CrystalPainter(glow),
        ),
      ),
    );
  }
}

class _CrystalPainter extends CustomPainter {
  final double glow;
  _CrystalPainter(this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    void drawCrystal(Offset tip, Offset baseL, Offset baseR, Color col) {
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(baseL.dx, baseL.dy)
        ..lineTo(baseR.dx, baseR.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(col, Colors.white, 0.4)!,
              col,
              Color.lerp(col, Colors.black, 0.2)!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromPoints(tip, baseR)),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Glow aura
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.6),
      22 + glow * 8,
      Paint()
        ..color = _kCrystal.withOpacity(0.15 + glow * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    drawCrystal(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.25, size.height * 0.55),
      Offset(size.width * 0.75, size.height * 0.55),
      _kCrystal,
    );
    drawCrystal(
      Offset(size.width * 0.18, size.height * 0.15),
      Offset(size.width * 0.0, size.height * 0.65),
      Offset(size.width * 0.36, size.height * 0.65),
      _kLavender,
    );
    drawCrystal(
      Offset(size.width * 0.82, size.height * 0.2),
      Offset(size.width * 0.64, size.height * 0.7),
      Offset(size.width * 1.0, size.height * 0.7),
      _kPurple,
    );

    // Ondas de som emitidas pelos cristais
    final wavePaint = Paint()
      ..color = _kCrystal.withOpacity(0.25 + glow * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.28),
        12.0 * i + glow * 6,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CrystalPainter o) => o.glow != glow;
}

// ─────────────────────────────────────────────────────────────────────────────
// MASCOT: Luna (raposa alquimista)
// ─────────────────────────────────────────────────────────────────────────────
class _MascotLuna extends StatelessWidget {
  final double bounce;
  const _MascotLuna({required this.bounce});

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
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFED7AA), Color(0xFFF97316)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              // Luna: raposa + avental + óculos
              const Text('🦊', style: TextStyle(fontSize: 30)),
              Positioned(
                bottom: 0,
                right: 0,
                child: const Text('🥽', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Lupa
          const Text('🔍', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPurple, width: 1.5),
            ),
            child: const Text(
              'Luna 🧪',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: _kPurpleDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MASCOT: Beto (urso de jaleco na janela)
// ─────────────────────────────────────────────────────────────────────────────
class _MascotBeto extends StatelessWidget {
  const _MascotBeto();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🐻', style: TextStyle(fontSize: 26)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kCrystal, width: 1.5),
          ),
          child: const Text(
            'Beto! 👨‍🔬',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E3A5F),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

/// Chão isométrico com caminho e detalhes roxos
class _GroundPainter extends CustomPainter {
  final Size screenSize;
  _GroundPainter(this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    // Camada de chão principal
    final ground = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_kGround, _kGroundMid, _kGroundLow],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.04,
        size.width,
        size.height * 0.16,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, ground);

    // Caminho de pedras luminosas
    final pathPaint = Paint()
      ..color = _kGold.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final roadPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.06)
      ..cubicTo(
        size.width * 0.5,
        size.height * 0.3,
        size.width * 0.45,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.85,
      );
    canvas.drawPath(roadPath, pathPaint);

    // Detalhes de pedras no chão
    final stonePaint = Paint()..color = _kLavLight.withOpacity(0.35);
    final rng = math.Random(77);
    for (int i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = size.height * 0.08 + rng.nextDouble() * size.height * 0.88;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 6 + rng.nextDouble() * 14,
          height: 4 + rng.nextDouble() * 8,
        ),
        stonePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GroundPainter o) => false;
}

/// Partículas de runas e estrelas no céu
class _RuneParticlePainter extends CustomPainter {
  final double t;
  _RuneParticlePainter(this.t);

  static final _rng = math.Random(13);
  static final _positions = List.generate(28, (_) {
    return (
      x: _rng.nextDouble(),
      y: _rng.nextDouble() * 0.65,
      size: 4.0 + _rng.nextDouble() * 10,
      speed: 0.4 + _rng.nextDouble() * 0.6,
      rune: ['✦', '✧', '◆', '⬡', '❖'][_rng.nextInt(5)],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _positions) {
      final phase = (t * p.speed + p.x) % 1.0;
      final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5) * 0.55;
      final textPainter = TextPainter(
        text: TextSpan(
          text: p.rune,
          style: TextStyle(
            fontSize: p.size,
            color: _kGold.withOpacity(opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(p.x * size.width, p.y * size.height + math.sin(phase * math.pi * 4) * 8),
      );
    }
  }

  @override
  bool shouldRepaint(_RuneParticlePainter o) => o.t != t;
}

/// Centelhas da poção subindo do caldeirão
class _SparkPainter extends CustomPainter {
  final double t;
  _SparkPainter(this.t);

  static final _rng = math.Random(99);
  static final _sparks = List.generate(16, (i) => (
    ox: -0.12 + _rng.nextDouble() * 0.24,
    phase: _rng.nextDouble(),
    speed: 0.6 + _rng.nextDouble() * 0.8,
    color: [_kGold, _kLavender, _kCrystal, Colors.white][_rng.nextInt(4)],
    size: 2.5 + _rng.nextDouble() * 4,
  ));

  @override
  void paint(Canvas canvas, Size size) {
    // caldeirão center-bottom
    final cx = size.width * 0.5;
    final cy = size.height * 0.58;

    for (final s in _sparks) {
      final phase = (t * s.speed + s.phase) % 1.0;
      if (phase < 0.05) continue; // hide at reset moment
      final x = cx + s.ox * size.width + math.sin(phase * math.pi * 3) * 18;
      final y = cy - phase * size.height * 0.35;
      final opacity = (1 - phase) * 0.9;
      canvas.drawCircle(
        Offset(x, y),
        s.size * (1 - phase * 0.5),
        Paint()..color = s.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.t != t;
}

/// Névoa mágica no chão
class _MistPainter extends CustomPainter {
  final double t;
  _MistPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final mistPaint = Paint()
      ..color = _kLavLight.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    for (int i = 0; i < 5; i++) {
      final phase = (t + i * 0.2) % 1.0;
      final x = size.width * (0.1 + i * 0.2) + math.sin(phase * math.pi * 2) * 20;
      final y = size.height * 0.3 + math.cos(phase * math.pi) * 12;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 90 + phase * 30,
          height: 28 + phase * 10,
        ),
        mistPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MistPainter o) => o.t != t;
}
