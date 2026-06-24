import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/gamification_models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CONQUISTAS SCREEN — Aba 2 da Tab Bar
// Exibe todas as badges, nível atual, XP, streak e moedas.
// ═════════════════════════════════════════════════════════════════════════════

const _kGold   = Color(0xFFD97706);
const _kGoldBg = Color(0xFFFEF9C3);
const _kGreen  = Color(0xFF22C55E);
const _kBlue   = Color(0xFF3B82F6);
const _kPurple = Color(0xFF8B5CF6);
const _kGray   = Color(0xFF9CA3AF);
const _kText   = Color(0xFF1E2A38);
const _kSub    = Color(0xFF6B7280);

class ConquistasScreen extends StatelessWidget {
  const ConquistasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gam    = context.watch<GamificationService>();
    final state  = gam.state;
    final earned = state.earnedBadgeIds;
    final level  = state.level;
    final next   = state.nextLevel;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFEF9C3), Color(0xFFFFFBEB), Colors.white],
            stops: [0, 0.35, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Cabeçalho ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  earnedCount: earned.length,
                  totalCount: kAllBadges.length,
                ),
              ),
              // ── Estatísticas ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _StatsRow(state: state),
              ),
              // ── Barra de nível ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _LevelBar(
                  level: level,
                  next: next,
                  progress: state.levelProgress,
                  xp: state.xp,
                ),
              ),
              // ── Título da seção ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Text('🏅', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Minhas Conquistas  •  ${earned.length}/${kAllBadges.length}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _kText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Grade de badges ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverGrid.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: kAllBadges.length,
                  itemBuilder: (_, i) {
                    final badge = kAllBadges[i];
                    final isEarned = earned.contains(badge.id);
                    return _BadgeCard(
                      badge: badge,
                      isEarned: isEarned,
                      delay: i * 55,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int earnedCount, totalCount;

  const _Header({required this.earnedCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conquistas',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _kText,
                  ),
                ),
                Text(
                  'Continue jogando para desbloquear mais! 🌟',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: _kSub,
                  ),
                ),
              ],
            ),
          ),
          // Contador circular
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$earnedCount',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '/$totalCount',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final PlayerState state;

  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _StatPill(
            emoji: state.level.emoji,
            value: state.level.name,
            color: _kPurple,
            flex: 2,
          ),
          const SizedBox(width: 8),
          _StatPill(
            emoji: '⚡',
            value: '${state.xp} XP',
            color: _kBlue,
            flex: 1,
          ),
          const SizedBox(width: 8),
          _StatPill(
            emoji: '🔥',
            value: '${state.currentStreak}d',
            color: const Color(0xFFF97316),
            flex: 1,
          ),
          const SizedBox(width: 8),
          _StatPill(
            emoji: '🪙',
            value: '${state.coins}',
            color: _kGold,
            flex: 1,
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 400.ms);
  }
}

class _StatPill extends StatelessWidget {
  final String emoji, value;
  final Color color;
  final int flex;

  const _StatPill({
    required this.emoji,
    required this.value,
    required this.color,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARRA DE NÍVEL
// ─────────────────────────────────────────────────────────────────────────────
class _LevelBar extends StatelessWidget {
  final PlayerLevel level;
  final PlayerLevel? next;
  final double progress;
  final int xp;

  const _LevelBar({
    required this.level,
    required this.next,
    required this.progress,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                Row(
                  children: [
                    Text(level.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      'Nível ${level.level} — ${level.name}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kText,
                      ),
                    ),
                  ],
                ),
                if (next != null)
                  Text(
                    '$xp / ${next!.xpRequired} XP',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: _kSub,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: const AlwaysStoppedAnimation<Color>(_kPurple),
                ),
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 6),
              Text(
                'Próximo: ${next!.emoji} ${next!.name}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: _kSub,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate(delay: 150.ms).fadeIn(duration: 450.ms).slideY(begin: 0.2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final GameBadge badge;
  final bool isEarned;
  final int delay;

  const _BadgeCard({
    required this.badge,
    required this.isEarned,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEarned ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEarned ? _kGreen.withOpacity(0.5) : const Color(0xFFE5E7EB),
          width: isEarned ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isEarned
                ? _kGreen.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: isEarned ? 16 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji da badge
                Expanded(
                  flex: 3,
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: isEarned
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ]),
                      child: Text(
                        badge.emoji,
                        style: TextStyle(
                          fontSize: 38,
                          color: isEarned ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Nome
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        badge.name,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isEarned ? _kText : _kGray,
                        ),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge.description,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9.5,
                          color: isEarned ? _kSub : _kGray.withOpacity(0.7),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Marca de conquistado
          if (isEarned)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          // Cadeado
          if (!isEarned)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _kGray.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: _kGray,
                  size: 13,
                ),
              ),
            ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.85, 0.85),
          curve: Curves.easeOutBack,
          duration: 350.ms,
        );
  }
}
