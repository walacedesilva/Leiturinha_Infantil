import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/gamification_models.dart';

/// Popup flutuante que aparece ao ganhar moedas/XP/badge.
/// Exibir com showRewardToast(context, event).
class RewardToast extends StatelessWidget {
  final RewardEvent event;
  const RewardToast({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D).withOpacity(0.92),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (event.coins > 0) ...[
                    const Text('🪙', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text(
                      '+${event.coins}',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (event.xp > 0) ...[
                    const Text('⭐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '+${event.xp} XP',
                      style: const TextStyle(
                        color: Color(0xFF90EE90),
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (event.hasBadge) ...[
                    const SizedBox(width: 12),
                    const Text('🏅', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text(
                      'Conquista!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            )
            .animate()
            .slideY(begin: -0.5, duration: 300.ms, curve: Curves.easeOut)
            .fadeIn(duration: 200.ms),
          ),
        ),
      ),
    );
  }
}

/// Mostra o RewardToast como overlay temporário (2.5s).
void showRewardToast(BuildContext context, RewardEvent event) {
  if (!event.hasReward && !event.hasBadge) return;
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => RewardToast(event: event),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2500), () {
    if (entry.mounted) entry.remove();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra de XP compacta para o header do menu
// ─────────────────────────────────────────────────────────────────────────────

class XpBar extends StatelessWidget {
  final int xp;
  final int coins;
  final VoidCallback? onTap;

  const XpBar({super.key, required this.xp, required this.coins, this.onTap});

  @override
  Widget build(BuildContext context) {
    final level = getLevelForXp(xp);
    final next = getNextLevel(xp);
    final progress = xpProgressInLevel(xp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(level.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  level.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 2),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFB8860B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF6EC6FF),
                  ),
                ),
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 2),
              Text(
                '$xp / ${next.xpRequired} XP',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de badge individual
// ─────────────────────────────────────────────────────────────────────────────

class BadgeCard extends StatelessWidget {
  final GameBadge badge;
  final bool earned;

  const BadgeCard({super.key, required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: earned ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: earned
              ? Colors.amber.withOpacity(0.15)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: earned ? Colors.amber.withOpacity(0.5) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge.emoji,
              style: TextStyle(
                fontSize: 32,
                color: earned ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: earned ? Colors.black87 : Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: earned ? Colors.black54 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
