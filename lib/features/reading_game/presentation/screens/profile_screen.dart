import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/gamification_models.dart';
import '../../../../services/gamification_service.dart';
import '../widgets/gamification_widgets.dart';

/// Tela de perfil: mostra nível, XP, moedas, streak e todas as badges.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5BC8F5),
        foregroundColor: Colors.white,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<GamificationService>(
        builder: (context, gam, _) {
          final state = gam.state;
          final level = getLevelForXp(state.xp);
          final next = getNextLevel(state.xp);
          final progress = xpProgressInLevel(state.xp);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Nível atual ─────────────────────────────────────────
                _SectionCard(
                  child: Column(
                    children: [
                      Text(
                        level.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        level.name,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      Text(
                        'Nível ${level.level}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Barra de XP
                      Row(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6EC6FF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            next != null
                                ? '${state.xp}/${next.xpRequired} XP'
                                : '${state.xp} XP (máx)',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Estatísticas ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        emoji: '🪙',
                        label: 'Moedas',
                        value: '${state.coins}',
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatChip(
                        emoji: '🔥',
                        label: 'Streak',
                        value: '${state.currentStreak} dias',
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatChip(
                        emoji: '📖',
                        label: 'Palavras',
                        value: '${state.totalWordsValidated}',
                        color: const Color(0xFF5BC8F5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Conquistas ───────────────────────────────────────────
                const Text(
                  'Conquistas',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kAllBadges.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, i) {
                    final badge = kAllBadges[i];
                    final earned = state.earnedBadgeIds.contains(badge.id);
                    return BadgeCard(badge: badge, earned: earned);
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color.withOpacity(0.9).computeLuminance() > 0.5
                  ? Colors.black87
                  : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
