import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/gamification_models.dart';
import '../../../../services/session_tracking_service.dart';

/// Tela mostrada à criança ao final de cada sessão de jogo.
/// Linguagem lúdica, visual, com emojis e próximo desafio.
class SessionSummaryScreen extends StatelessWidget {
  final GameSession session;
  final int coinsEarned;
  final int xpEarned;
  final List<String> newBadgeIds;
  final String nextChallenge;  // sugestão de próximo passo
  final VoidCallback onContinue;

  const SessionSummaryScreen({
    super.key,
    required this.session,
    required this.coinsEarned,
    required this.xpEarned,
    required this.newBadgeIds,
    required this.nextChallenge,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = session.averageAccuracy;
    final stars = accuracy >= 0.90
        ? 3
        : accuracy >= 0.70
            ? 2
            : 1;
    final minutes = (session.durationSeconds / 60).round().clamp(1, 99);

    return Scaffold(
      backgroundColor: const Color(0xFF5BC8F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Topo animado ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Título
                    Text(
                      _headline(stars),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 12),

                    // Estrelas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            i < stars ? '⭐' : '☆',
                            style: const TextStyle(fontSize: 40),
                          )
                              .animate(delay: Duration(milliseconds: 200 + i * 150))
                              .scale(
                                  begin: const Offset(0.2, 0.2),
                                  duration: 400.ms,
                                  curve: Curves.elasticOut),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Card de resultados
                    _ResultCard(
                      words: session.wordsValidated,
                      minutes: minutes,
                      accuracy: accuracy,
                    ),

                    const SizedBox(height: 16),

                    // Recompensas ganhas
                    if (coinsEarned > 0 || xpEarned > 0)
                      _RewardRow(coins: coinsEarned, xp: xpEarned)
                          .animate(delay: 400.ms)
                          .slideY(begin: 0.4, duration: 400.ms),

                    // Badges novos
                    if (newBadgeIds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NewBadges(badgeIds: newBadgeIds)
                          .animate(delay: 600.ms)
                          .fadeIn(duration: 400.ms),
                    ],

                    const SizedBox(height: 20),

                    // Próximo desafio
                    _NextChallengeCard(text: nextChallenge)
                        .animate(delay: 700.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Botão continuar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2979FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Continuar aventura! 🚀',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              )
                  .animate(delay: 900.ms)
                  .slideY(begin: 0.5, duration: 400.ms, curve: Curves.easeOut),
            ),
          ],
        ),
      ),
    );
  }

  String _headline(int stars) {
    return switch (stars) {
      3 => 'Incrível! 🎉',
      2 => 'Muito bem! 🌟',
      _ => 'Continue assim! 💪',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS INTERNOS
// ─────────────────────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final int words;
  final int minutes;
  final double accuracy;

  const _ResultCard({
    required this.words,
    required this.minutes,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(emoji: '📖', value: '$words', label: 'palavras'),
          _Stat(emoji: '⏱️', value: '$minutes', label: 'minutos'),
          _Stat(
            emoji: '🎯',
            value: '${(accuracy * 100).toStringAsFixed(0)}%',
            label: 'acertos',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _Stat({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF2979FF),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  final int coins;
  final int xp;
  const _RewardRow({required this.coins, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Text(
            '+$coins moedas',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFFF57F17),
            ),
          ),
          const SizedBox(width: 20),
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            '+$xp XP',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewBadges extends StatelessWidget {
  final List<String> badgeIds;
  const _NewBadges({required this.badgeIds});

  @override
  Widget build(BuildContext context) {
    final badges = badgeIds
        .map((id) => getBadgeById(id))
        .whereType<GameBadge>()
        .toList();
    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const Text(
          '🏅 Nova conquista!',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: badges
              .map(
                (b) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(b.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(
                        b.name,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _NextChallengeCard extends StatelessWidget {
  final String text;
  const _NextChallengeCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.6), width: 2),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1A237E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
