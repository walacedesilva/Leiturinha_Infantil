import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../reading_game/data/encontros_content.dart';
import 'monta_silabas_screen.dart';
import 'corrida_pronuncia_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DISTRITO DOS ENCONTROS CONSONANTAIS — Mapa (Fábrica Industrial Mágica)
// Paleta: Laranja #F97316 | Dourado #FBBF24 | Verde #22C55E
// Estilo: Pixar 3D cartoon, fábrica amigável, atmosfera diurna
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// CORES
// ─────────────────────────────────────────────────────────────────────────────
const _kOrange      = Color(0xFFF97316);
const _kOrangeDark  = Color(0xFFEA580C);
const _kOrangeLight = Color(0xFFFFF7ED);
const _kGold        = Color(0xFFFBBF24);
const _kGoldDeep    = Color(0xFFD97706);
const _kGoldLight   = Color(0xFFFEF3C7);
const _kGreen       = Color(0xFF22C55E);
const _kGreenDark   = Color(0xFF16A34A);
const _kSkyTop      = Color(0xFFBAE6FD);   // azul céu
const _kSkyMid      = Color(0xFFE0F2FE);
const _kSkyBottom   = Color(0xFFFFF7ED);   // laranja suave
const _kGroundTop   = Color(0xFFF97316);
const _kGroundMid   = Color(0xFFEA580C);
const _kSteelDark   = Color(0xFF92400E);

// ─────────────────────────────────────────────────────────────────────────────
// DATA: atividades
// ─────────────────────────────────────────────────────────────────────────────
class _EncontroActivity {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final Color lightColor;
  final int totalItems;
  final bool isPortal;
  final bool comingSoon;

  const _EncontroActivity({
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

const _kActivities = <_EncontroActivity>[
  _EncontroActivity(
    id: 'fabrica_1',
    title: 'Fábrica de Palavras',
    subtitle: 'BR · CL · TR · FL · PR',
    emoji: '🏭',
    color: _kOrange,
    lightColor: _kOrangeLight,
    totalItems: 5,
    comingSoon: false,
  ),
  _EncontroActivity(
    id: 'correia_1',
    title: 'Corrida de Pronúncia',
    subtitle: 'Fale as sílabas rápido!',
    emoji: '🏎️',
    color: _kGold,
    lightColor: _kGoldLight,
    totalItems: 5,
    comingSoon: false,
  ),
  _EncontroActivity(
    id: 'arquivo_1',
    title: 'Arquivo Secreto',
    subtitle: 'Descubra as palavras escondidas',
    emoji: '📁',
    color: _kGreen,
    lightColor: const Color(0xFFF0FDF4),
    totalItems: 5,
    comingSoon: true,
  ),
  _EncontroActivity(
    id: 'portal_encontros',
    title: 'Portal Estelar',
    subtitle: 'O próximo reino te aguarda!',
    emoji: '🔮',
    color: _kGoldDeep,
    lightColor: _kGoldLight,
    totalItems: 1,
    isPortal: true,
  ),
];

// TTS map para clusters
const _kClusterSpeech = {
  'BR': 'B R faz o som de bravo!',
  'CL': 'C L faz o som de claro!',
  'TR': 'T R faz o som de trem!',
  'FL': 'F L faz o som de flor!',
  'PR': 'P R faz o som de prato!',
};

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DistritoEncontrosScreen extends StatefulWidget {
  const DistritoEncontrosScreen({super.key});

  @override
  State<DistritoEncontrosScreen> createState() =>
      _DistritoEncontrosScreenState();
}

class _DistritoEncontrosScreenState extends State<DistritoEncontrosScreen>
    with TickerProviderStateMixin {
  late final AnimationController _gearCtrl;
  late final AnimationController _gearSlowCtrl;
  late final AnimationController _conveyorCtrl;
  late final AnimationController _puffCtrl;
  late final AnimationController _betoCtrl;
  late final AnimationController _sparkCtrl;
  late final List<AnimationController> _floatCtrl;

  static const _kClusters = ['BR', 'CL', 'TR', 'FL', 'PR'];

  @override
  void initState() {
    super.initState();

    _gearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _gearSlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();

    _conveyorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _puffCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _betoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _floatCtrl = List.generate(_kClusters.length, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500 + i * 280),
      )..repeat(reverse: true);
      return ctrl;
    });
  }

  @override
  void dispose() {
    _gearCtrl.dispose();
    _gearSlowCtrl.dispose();
    _conveyorCtrl.dispose();
    _puffCtrl.dispose();
    _betoCtrl.dispose();
    _sparkCtrl.dispose();
    for (final c in _floatCtrl) c.dispose();
    super.dispose();
  }

  void _launchActivity(BuildContext context, _EncontroActivity activity) {
    if (activity.isPortal) {
      AudioManager().playSFX(SFXType.correct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '🔮 Portal Estelar — Em breve!',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kOrangeDark,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }
    if (activity.comingSoon) {
      AudioManager().playSFX(SFXType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${activity.emoji} ${activity.title} — Em breve!',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kGold,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }
    // Available activities — navigate to gameplay screens
    AudioManager().playSFX(SFXType.pop);
    if (activity.id == 'fabrica_1') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MontaSilabasScreen()),
      );
    } else if (activity.id == 'correia_1') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CorridaPronunciaScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${activity.emoji} ${activity.title} — Em breve!',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kOrange,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _kSkyBottom,
      body: Stack(
        children: [
          // ── Layer 1: Sky gradient ────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kSkyTop, _kSkyMid, _kSkyBottom, _kOrangeLight],
                  stops: [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
          ),
          // ── Layer 2: Sun ─────────────────────────────────────────────────
          Positioned(
            top: size.height * 0.04,
            right: size.width * 0.12,
            child: AnimatedBuilder(
              animation: _gearSlowCtrl,
              builder: (_, __) {
                final glow = 0.6 + _gearSlowCtrl.value * 0.4;
                return Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGold,
                    boxShadow: [
                      BoxShadow(
                        color: _kGold.withOpacity(glow * 0.6),
                        blurRadius: 28 + glow * 12,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('☀️', style: TextStyle(fontSize: 32)),
                  ),
                );
              },
            ),
          ),
          // ── Layer 3: Fluffy clouds ───────────────────────────────────────
          Positioned(
            top: size.height * 0.06,
            left: 24,
            child: const _FluffyCloud(size: 80, opacity: 0.85),
          ),
          Positioned(
            top: size.height * 0.12,
            left: size.width * 0.42,
            child: const _FluffyCloud(size: 60, opacity: 0.70),
          ),
          // ── Layer 4: Ground ──────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.48,
            child: CustomPaint(painter: _GroundPainter(size)),
          ),
          // ── Layer 5: Factory building ────────────────────────────────────
          Positioned(
            bottom: size.height * 0.28,
            right: 12,
            child: const _FactoryBuilding(),
          ),
          // ── Layer 6: Chimney puffs ───────────────────────────────────────
          AnimatedBuilder(
            animation: _puffCtrl,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.52,
              right: 44,
              child: _ChimneyPuffs(t: _puffCtrl.value),
            ),
          ),
          // ── Layer 7: Big gear (background) ──────────────────────────────
          AnimatedBuilder(
            animation: _gearSlowCtrl,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.38,
              left: size.width * 0.02,
              child: Transform.rotate(
                angle: _gearSlowCtrl.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(90, 90),
                  painter: _GearPainter(
                    color: _kOrange.withOpacity(0.3),
                    teeth: 10,
                  ),
                ),
              ),
            ),
          ),
          // ── Layer 8: Conveyor belt ───────────────────────────────────────
          AnimatedBuilder(
            animation: _conveyorCtrl,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.24,
              left: 0,
              right: 0,
              child: _ConveyorBelt(t: _conveyorCtrl.value, width: size.width),
            ),
          ),
          // ── Layer 9: Small gear (foreground right) ───────────────────────
          AnimatedBuilder(
            animation: _gearCtrl,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.30,
              right: size.width * 0.08,
              child: Transform.rotate(
                angle: -_gearCtrl.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(52, 52),
                  painter: _GearPainter(color: _kGold, teeth: 8),
                ),
              ),
            ),
          ),
          // ── Layer 10: Floating cluster labels ───────────────────────────
          ...List.generate(_kClusters.length, (i) {
            final angle = (i / _kClusters.length) * 2 * math.pi - math.pi / 2;
            final radius = size.width * 0.25;
            final cx = size.width / 2 + math.cos(angle) * radius;
            final cy = size.height * 0.50 - math.sin(angle) * radius * 0.40;
            return AnimatedBuilder(
              animation: _floatCtrl[i],
              builder: (_, __) {
                final dy = math.sin(_floatCtrl[i].value * math.pi) * 7.0;
                return Positioned(
                  left: cx - 28,
                  top: cy + dy,
                  child: _ClusterLabel(text: _kClusters[i]),
                );
              },
            );
          }),
          // ── Layer 11: Beto bear ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _betoCtrl,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.22,
              left: 20,
              child: _BetoBear(bounce: _betoCtrl.value),
            ),
          ),
          // ── Layer 12: Sparks ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: _sparkCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _SparkPainter(_sparkCtrl.value),
              ),
            ),
          ),
          // ── Layer 13: HUD ─────────────────────────────────────────────────
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
                _FabricarButton(
                  onTap: () => _launchActivity(context, _kActivities.first),
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
                  'Encontros Consonantais',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    shadows: [
                      Shadow(color: Colors.white70, blurRadius: 6),
                    ],
                  ),
                ),
                _ProgressBar(),
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
              colors: [_kGold, _kOrangeDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _kGreen, width: 3),
            boxShadow: [
              BoxShadow(
                color: _kOrange.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text('🐻', style: TextStyle(fontSize: 26)),
          ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _kGreen,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Text(
              'Nv.4',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kOrangeDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Mestre dos Encontros',
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

class _ProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Encontros: 0/5',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kOrangeDark,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Text(
              i < 0 ? '⚙️' : '🔩',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoinsXp extends StatelessWidget {
  final int coins, xp, streak;
  const _CoinsXp(
      {required this.coins, required this.xp, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Chip(icon: '🪙', value: '$coins', color: _kGold),
        const SizedBox(height: 4),
        _Chip(icon: '⭐', value: '$xp XP', color: _kOrange),
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
  const _Chip(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
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
  final List<_EncontroActivity> activities;
  final ValueChanged<_EncontroActivity> onTap;

  const _ActivitiesPanel(
      {required this.activities, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 152,
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
  final _EncontroActivity activity;
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
        width: 122,
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
            color: isPortal
                ? _kGoldDeep
                : activity.color.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPortal ? _kGoldDeep : activity.color)
                  .withOpacity(0.28),
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
                Text(activity.emoji,
                    style: const TextStyle(fontSize: 28)),
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
                color: isPortal
                    ? const Color(0xFF78350F)
                    : const Color(0xFF1F2937),
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
                    : activity.color.withOpacity(0.85),
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
// FABRICAR PALAVRAS BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _FabricarButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FabricarButton({required this.onTap});

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
              colors: [_kOrange, _kGold],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _kOrange.withOpacity(0.5),
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
                child: const Text('⚙️', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 10),
              const Text(
                'FABRICAR PALAVRAS',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.1,
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
        .scale(
          begin: const Offset(0.9, 0.9),
          curve: Curves.elasticOut,
        );
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
            color: _kOrange.withOpacity(0.2),
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
      child: SizedBox(
        width: 56,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? _kOrange.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive
                    ? _kOrangeDark
                    : const Color(0xFF94A3B8),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w800 : FontWeight.w500,
                color:
                    isActive ? _kOrangeDark : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLUSTER LABEL (flutuante, tappável)
// ─────────────────────────────────────────────────────────────────────────────
class _ClusterLabel extends StatelessWidget {
  final String text;
  const _ClusterLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final speech = _kClusterSpeech[text] ?? text;
        AudioManager().playWord(speech);
        AudioManager().playSFX(SFXType.pop);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kOrange, _kOrangeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kOrange.withOpacity(0.65),
              blurRadius: 12,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.0,
            shadows: [
              Shadow(
                color: Color(0xFF000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FACTORY BUILDING
// ─────────────────────────────────────────────────────────────────────────────
class _FactoryBuilding extends StatelessWidget {
  const _FactoryBuilding();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 140,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Chaminé (chimney)
          Positioned(
            top: 0,
            right: 18,
            child: Container(
              width: 20,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF78350F), Color(0xFF92400E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                border: Border.all(
                  color: _kGoldDeep.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Telhado
          Positioned(
            top: 32,
            left: 0,
            right: 0,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kGold, _kOrangeDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kOrange.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🏭', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
          // Corpo da fábrica
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(8)),
                border: Border.all(
                  color: _kOrange.withOpacity(0.4),
                  width: 2,
                ),
              ),
            ),
          ),
          // Janela esquerda (robô)
          Positioned(
            top: 60,
            left: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _kGold.withOpacity(0.8),
                    _kOrange.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _kOrangeDark.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
          // Janela direita (robô)
          Positioned(
            top: 60,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _kGold.withOpacity(0.8),
                    _kOrange.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _kOrangeDark.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
          // Porta da fábrica
          Positioned(
            bottom: 0,
            left: 34,
            child: Container(
              width: 32,
              height: 44,
              decoration: BoxDecoration(
                color: _kOrangeDark.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border.all(
                  color: _kOrangeDark.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          // Placa "PALAVRA FACTORY"
          Positioned(
            top: 95,
            left: 4,
            right: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _kGold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PALAVRA\nFACTORY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 6.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF78350F),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIMNEY PUFFS
// ─────────────────────────────────────────────────────────────────────────────
class _ChimneyPuffs extends StatelessWidget {
  final double t;
  const _ChimneyPuffs({required this.t});

  static const _letters = ['B', 'R', 'C', 'L'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 80,
      child: Stack(
        children: List.generate(4, (i) {
          final phase = (t + i * 0.25) % 1.0;
          final y = -phase * 70.0;
          final opacity = (1.0 - phase).clamp(0.0, 1.0);
          final scale = 0.5 + phase * 0.8;
          final x = 10.0 + i * 8.0 + math.sin(phase * math.pi * 2 + i) * 6;
          return Positioned(
            left: x,
            top: 70 + y,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kGold.withOpacity(0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _letters[i],
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color:
                            _kOrangeDark.withOpacity(opacity),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVEYOR BELT
// ─────────────────────────────────────────────────────────────────────────────
const _kBeltBlocks = ['BRA', 'CLA', 'TRO', 'FLO', 'PRA', 'BRE', 'TRE'];

class _ConveyorBelt extends StatelessWidget {
  final double t;
  final double width;
  const _ConveyorBelt({required this.t, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          // Belt track
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF78350F),
                    Color(0xFF92400E),
                    Color(0xFF78350F),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Belt stripes (animated)
          ClipRect(
            child: Positioned.fill(
              child: CustomPaint(
                painter:
                    _BeltStripePainter(t, width),
              ),
            ),
          ),
          // Blocks
          ...List.generate(_kBeltBlocks.length, (i) {
            final spacing = width / 3;
            final rawX =
                (i * spacing) - (t * spacing * 3) % (spacing * _kBeltBlocks.length);
            final x = ((rawX % (width + 80)) - 80);
            return Positioned(
              left: x,
              top: 4,
              child: _SyllableBlock(text: _kBeltBlocks[i]),
            );
          }),
        ],
      ),
    );
  }
}

class _SyllableBlock extends StatelessWidget {
  final String text;
  const _SyllableBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF9C3), Color(0xFFFEF08A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kOrangeDark, width: 2),
        boxShadow: [
          BoxShadow(
            color: _kOrangeDark.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF92400E),
          ),
        ),
      ),
    );
  }
}

class _BeltStripePainter extends CustomPainter {
  final double t;
  final double width;
  _BeltStripePainter(this.t, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final stripeSpacing = 24.0;
    final offset = (t * stripeSpacing * 3) % stripeSpacing;
    for (double x = -stripeSpacing + offset;
        x < size.width + stripeSpacing;
        x += stripeSpacing) {
      canvas.drawLine(
        Offset(x, size.height * 0.4),
        Offset(x + 12, size.height * 0.85),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BeltStripePainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// BETO BEAR
// ─────────────────────────────────────────────────────────────────────────────
class _BetoBear extends StatelessWidget {
  final double bounce;
  const _BetoBear({required this.bounce});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -bounce * 5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body glow
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Bear circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFED7AA), Color(0xFFF97316)],
              ),
              border: Border.all(color: _kGold, width: 3),
            ),
          ),
          const Text('🐻', style: TextStyle(fontSize: 34)),
          // Hard hat
          const Positioned(
            top: 2,
            child: Text('👷', style: TextStyle(fontSize: 22)),
          ),
          // Wrench
          const Positioned(
            bottom: 2,
            right: 2,
            child: Text('🔧', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLUFFY CLOUD
// ─────────────────────────────────────────────────────────────────────────────
class _FluffyCloud extends StatelessWidget {
  final double size;
  final double opacity;
  const _FluffyCloud({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(size, size * 0.55),
        painter: _CloudPainter(),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.6),
          width: size.width,
          height: size.height * 0.8),
      paint,
    );
    canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.42), size.width * 0.22, paint);
    canvas.drawCircle(
        Offset(size.width * 0.55, size.height * 0.3), size.width * 0.28, paint);
    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.42), size.width * 0.18, paint);
  }

  @override
  bool shouldRepaint(_CloudPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// GEAR PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _GearPainter extends CustomPainter {
  final Color color;
  final int teeth;
  _GearPainter({required this.color, required this.teeth});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.46;
    final innerR = outerR * 0.68;
    final toothH = outerR * 0.28;
    final holeR = innerR * 0.38;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final step = 2 * math.pi / teeth;
    for (int i = 0; i < teeth; i++) {
      final a0 = step * i;
      final a1 = a0 + step * 0.35;
      final a2 = a0 + step * 0.65;
      final a3 = a0 + step;
      if (i == 0) {
        path.moveTo(cx + innerR * math.cos(a0), cy + innerR * math.sin(a0));
      }
      path.lineTo(cx + (innerR + toothH) * math.cos(a1),
          cy + (innerR + toothH) * math.sin(a1));
      path.lineTo(cx + (innerR + toothH) * math.cos(a2),
          cy + (innerR + toothH) * math.sin(a2));
      path.lineTo(cx + innerR * math.cos(a3), cy + innerR * math.sin(a3));
    }
    path.close();
    canvas.drawPath(path, paint);

    // Center circle
    canvas.drawCircle(
      Offset(cx, cy),
      innerR,
      Paint()..color = color,
    );
    // Hole
    canvas.drawCircle(
      Offset(cx, cy),
      holeR,
      Paint()..color = Colors.white.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(_GearPainter o) => o.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// GROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _GroundPainter extends CustomPainter {
  final Size screen;
  _GroundPainter(this.screen);

  @override
  void paint(Canvas canvas, Size size) {
    // Main ground hill (orange)
    final groundPath = Path()
      ..moveTo(0, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.02,
        size.width * 0.5, size.height * 0.10,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.18,
        size.width, size.height * 0.08,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      groundPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kGroundTop, _kGroundMid, const Color(0xFFD97706)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Road/path markings
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.35),
      Offset(size.width * 0.9, size.height * 0.35),
      roadPaint,
    );

    // Small bushes
    final bushPaint = Paint()..color = _kGreen.withOpacity(0.6);
    for (final x in [0.1, 0.35, 0.65, 0.88]) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * 0.28),
        8,
        bushPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GroundPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SPARK PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _SparkPainter extends CustomPainter {
  final double t;
  _SparkPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 14; i++) {
      final phase = (t + i / 14.0) % 1.0;
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height * 0.65;
      final y = baseY - phase * 60;
      final opacity = (math.sin(phase * math.pi)).clamp(0.0, 1.0);
      final r = 2.0 + rng.nextDouble() * 2.5;

      paint.color = (i % 3 == 0 ? _kGold : i % 3 == 1 ? _kOrange : _kGreen)
          .withOpacity(opacity * 0.75);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.t != t;
}
