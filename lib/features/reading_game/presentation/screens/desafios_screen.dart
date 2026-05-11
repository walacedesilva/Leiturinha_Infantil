import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../navigation/nav_shell.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/gamification_models.dart';
import 'praca_central_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DESAFIOS SCREEN — Aba 1 da Tab Bar
// Mostra missões diárias e desafios baseados no progresso real do jogador.
// ═════════════════════════════════════════════════════════════════════════════

const _kOrange     = Color(0xFFF97316);
const _kOrangeDark = Color(0xFFEA580C);
const _kOrangeBg   = Color(0xFFFFF7ED);
const _kGold       = Color(0xFFD97706);
const _kGreen      = Color(0xFF22C55E);
const _kBlue       = Color(0xFF3B82F6);
const _kPurple     = Color(0xFF8B5CF6);
const _kGray       = Color(0xFF9CA3AF);
const _kText       = Color(0xFF1E2A38);
const _kSub        = Color(0xFF6B7280);

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE MISSÃO
// ─────────────────────────────────────────────────────────────────────────────

class _Mission {
  final String icon;
  final String title;
  final String desc;
  final int target;
  final Color color;
  final Color bgColor;

  const _Mission({
    required this.icon,
    required this.title,
    required this.desc,
    required this.target,
    required this.color,
    required this.bgColor,
  });
}

const _kMissions = <_Mission>[
  _Mission(
    icon: '🎯',
    title: 'Pronúncia Perfeita',
    desc: 'Pronuncie 10 palavras corretamente',
    target: 10,
    color: _kOrange,
    bgColor: _kOrangeBg,
  ),
  _Mission(
    icon: '📅',
    title: 'Estudante Dedicado',
    desc: 'Pratique por 5 dias seguidos',
    target: 5,
    color: _kBlue,
    bgColor: Color(0xFFDBEAFE),
  ),
  _Mission(
    icon: '⭐',
    title: 'Acumulador de XP',
    desc: 'Alcance 100 pontos de experiência',
    target: 100,
    color: _kPurple,
    bgColor: Color(0xFFEDE9FE),
  ),
  _Mission(
    icon: '🏅',
    title: 'Caçador de Badges',
    desc: 'Desbloqueie 5 conquistas',
    target: 5,
    color: _kGold,
    bgColor: Color(0xFFFEF9C3),
  ),
  _Mission(
    icon: '🪙',
    title: 'Poupador',
    desc: 'Acumule 50 moedas',
    target: 50,
    color: _kGreen,
    bgColor: Color(0xFFF0FDF4),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DesafiosScreen extends StatelessWidget {
  const DesafiosScreen({super.key});

  int _progressFor(int i, PlayerState s) {
    return switch (i) {
      0 => s.totalWordsValidated,
      1 => s.currentStreak,
      2 => s.xp,
      3 => s.earnedBadgeIds.length,
      4 => s.coins,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final gam   = context.watch<GamificationService>();
    final state = gam.state;

    // Missão em destaque = a mais próxima de completar (mas não concluída)
    int featuredIndex = 0;
    double bestRatio = -1;
    for (var i = 0; i < _kMissions.length; i++) {
      final m   = _kMissions[i];
      final cur = _progressFor(i, state).clamp(0, m.target);
      final r   = cur / m.target;
      if (r < 1.0 && r > bestRatio) {
        bestRatio    = r;
        featuredIndex = i;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7ED), Color(0xFFFFFBF5), Colors.white],
            stops: [0, 0.35, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _DesafiosHeader(streak: state.currentStreak),
              ),
              // ── Destaque do dia ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FeaturedChallenge(
                  mission: _kMissions[featuredIndex],
                  current: _progressFor(featuredIndex, state)
                      .clamp(0, _kMissions[featuredIndex].target),
                  onGoPlay: () =>
                      NavTabController.maybeOf(context)?.setTab(0),
                ),
              ),
              // ── Título missões ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: const Text(
                    '📋 Todas as Missões',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _kText,
                    ),
                  ),
                ),
              ),
              // ── Lista de missões ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.separated(
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: _kMissions.length,
                  itemBuilder: (_, i) {
                    final m   = _kMissions[i];
                    final cur = _progressFor(i, state).clamp(0, m.target);
                    return _MissionCard(
                      mission: m,
                      current: cur,
                      delay: 80 + i * 60,
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
class _DesafiosHeader extends StatelessWidget {
  final int streak;

  const _DesafiosHeader({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Desafios',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _kText,
                  ),
                ),
                const Text(
                  'Complete as missões e ganhe recompensas! 🎁',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: _kSub,
                  ),
                ),
              ],
            ),
          ),
          // Streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                Text(
                  '$streak',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'dias',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9,
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
// DESAFIO DO DIA (featured card)
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedChallenge extends StatelessWidget {
  final _Mission mission;
  final int current;
  final VoidCallback onGoPlay;

  const _FeaturedChallenge({
    required this.mission,
    required this.current,
    required this.onGoPlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = current >= mission.target;
    final progress = (current / mission.target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              mission.color,
              Color.lerp(mission.color, Colors.black, 0.15)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: mission.color.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label do dia
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '⭐ Desafio do Dia',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  mission.icon,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        mission.desc,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Barra de progresso
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDone
                            ? '✅ Concluído!'
                            : '$current / ${mission.target}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Botão "Jogar"
                GestureDetector(
                  onTap: isDone ? null : onGoPlay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDone ? '🎉 Feito!' : 'Jogar →',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDone ? _kGreen : mission.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MISSION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _MissionCard extends StatelessWidget {
  final _Mission mission;
  final int current;
  final int delay;

  const _MissionCard({
    required this.mission,
    required this.current,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDone   = current >= mission.target;
    final progress = (current / mission.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone
              ? _kGreen.withOpacity(0.4)
              : const Color(0xFFF3F4F6),
          width: isDone ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: mission.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(mission.icon,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDone ? _kGreen : _kText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mission.desc,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: _kSub,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF3F4F6),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDone ? _kGreen : mission.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDone ? '✅' : '$current/${mission.target}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDone ? _kGreen : _kGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
