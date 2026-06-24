import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'torre_do_conhecimento_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TORRE CELEBRAÇÃO — Conquista do Andar / Topo
// Celebração épica após completar um andar ou a torre inteira
// ═══════════════════════════════════════════════════════════════════════════

const _kGold       = Color(0xFFD97706);
const _kGoldLight  = Color(0xFFFBBF24);
const _kGoldBg     = Color(0xFFFEF3C7);
const _kCyan       = Color(0xFF06B6D4);
const _kPurple     = Color(0xFF8B5CF6);
const _kText       = Color(0xFF1F2937);
const _kSub        = Color(0xFF6B7280);

class TorreCelebracaoScreen extends StatefulWidget {
  final TowerFloor floor;
  final bool isLastFloor;

  const TorreCelebracaoScreen({
    super.key,
    required this.floor,
    this.isLastFloor = false,
  });

  @override
  State<TorreCelebracaoScreen> createState() =>
      _TorreCelebracaoScreenState();
}

class _TorreCelebracaoScreenState extends State<TorreCelebracaoScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_confettiCtrl, _pulseCtrl]),
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.isLastFloor
                    ? const [
                        Color(0xFFFEF3C7),
                        Color(0xFFFBBF24),
                        Color(0xFFEDE9FE),
                      ]
                    : const [
                        Color(0xFFCCFBFE),
                        Color(0xFFFEF3C7),
                        Color(0xFFEDE9FE),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Confetti particles
                  ..._buildConfetti(_confettiCtrl.value, context),
                  // Main content
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    child: Column(
                      children: [
                        // Crown / Trophy
                        _CrownHeader(
                          isLastFloor: widget.isLastFloor,
                          pulseValue: _pulseCtrl.value,
                        ),
                        const SizedBox(height: 20),
                        // Title
                        _Title(
                          floor: widget.floor,
                          isLastFloor: widget.isLastFloor,
                        ),
                        const SizedBox(height: 24),
                        // Mascots celebrating
                        _CelebrationMascots(isLastFloor: widget.isLastFloor),
                        const SizedBox(height: 24),
                        // Rewards card
                        _RewardsCard(
                          floor: widget.floor,
                          isLastFloor: widget.isLastFloor,
                        ),
                        const SizedBox(height: 24),
                        // Action buttons
                        _ActionButtons(
                          isLastFloor: widget.isLastFloor,
                          floor: widget.floor,
                          onContinue: _onContinue,
                          onViewDiploma: widget.isLastFloor
                              ? _onViewDiploma
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onContinue() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onViewDiploma() {
    showDialog(
      context: context,
      builder: (_) => _DiplomaDialog(),
    );
  }

  List<Widget> _buildConfetti(double t, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final confetti = <Widget>[];
    const emojis = ['⭐', '✨', '🌟', '🎉', '🎊', '💫', '🏆', '🌈'];
    for (int i = 0; i < 20; i++) {
      final progress = (t + i / 20) % 1.0;
      final x = (i / 20) * size.width + (progress * 40 - 20);
      final y = progress * size.height * 1.2 - size.height * 0.1;
      final opacity = progress < 0.1
          ? progress / 0.1
          : progress > 0.9
              ? (1 - progress) / 0.1
              : 1.0;
      confetti.add(
        Positioned(
          left: x.clamp(0, size.width - 30),
          top: y,
          child: Opacity(
            opacity: (opacity * 0.85).clamp(0.0, 1.0),
            child: Text(
              emojis[i % emojis.length],
              style: TextStyle(fontSize: 18.0 + (i % 3) * 6),
            ),
          ),
        ),
      );
    }
    return confetti;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CROWN HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _CrownHeader extends StatelessWidget {
  final bool isLastFloor;
  final double pulseValue;

  const _CrownHeader({required this.isLastFloor, required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + pulseValue * 0.08;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isLastFloor
                ? const [Color(0xFFFBBF24), Color(0xFFF59E0B)]
                : const [Color(0xFF06B6D4), Color(0xFF0891B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isLastFloor ? _kGoldLight : _kCyan).withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 8,
            )
          ],
        ),
        child: Center(
          child: Text(
            isLastFloor ? '👑' : '⭐',
            style: const TextStyle(fontSize: 56),
          ),
        ),
      ),
    )
        .animate()
        .scaleXY(begin: 0.4, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack)
        .fade(begin: 0, end: 1, duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TITLE
// ═══════════════════════════════════════════════════════════════════════════

class _Title extends StatelessWidget {
  final TowerFloor floor;
  final bool isLastFloor;

  const _Title({required this.floor, required this.isLastFloor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isLastFloor ? 'PARABÉNS,' : 'Andar ${floor.number} concluído!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kSub,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isLastFloor ? 'LEITOR MESTRE! 🏆' : '${floor.emoji} ${floor.title}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isLastFloor ? 28 : 22,
            fontWeight: FontWeight.w900,
            color: _kText,
          ),
        ),
        if (isLastFloor) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGoldLight, Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Você conquistou o topo da torre!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CELEBRATION MASCOTS
// ═══════════════════════════════════════════════════════════════════════════

class _CelebrationMascots extends StatelessWidget {
  final bool isLastFloor;

  const _CelebrationMascots({required this.isLastFloor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Beto with diploma (last floor) or thumbs up
        Column(
          children: [
            if (isLastFloor)
              const Text('📜', style: TextStyle(fontSize: 24)),
            const Text('🐻', style: TextStyle(fontSize: 44)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kGoldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kGoldLight, width: 1),
              ),
              child: Text(
                isLastFloor ? 'LEITOR\nMESTRE!' : '👍',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _kGold,
                ),
              ),
            ),
          ],
        )
            .animate(delay: 400.ms)
            .scaleXY(
                begin: 0.5,
                end: 1.0,
                duration: 500.ms,
                curve: Curves.easeOutBack),
        const SizedBox(width: 16),
        // Avatar placeholder (center, raised)
        Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _kGoldLight.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Center(
                child: Text('⭐', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kGoldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Você!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        )
            .animate(delay: 200.ms)
            .scaleXY(
                begin: 0.5,
                end: 1.0,
                duration: 600.ms,
                curve: Curves.easeOutBack),
        const SizedBox(width: 16),
        // Luna and Zeca
        Column(
          children: [
            Row(
              children: [
                const Text('🦊', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 4),
                const Text('🐰', style: TextStyle(fontSize: 28)),
              ],
            ),
            const Text('🎉 🎊', style: TextStyle(fontSize: 16)),
          ],
        )
            .animate(delay: 500.ms)
            .scaleXY(
                begin: 0.5,
                end: 1.0,
                duration: 500.ms,
                curve: Curves.easeOutBack),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REWARDS CARD
// ═══════════════════════════════════════════════════════════════════════════

class _RewardsCard extends StatelessWidget {
  final TowerFloor floor;
  final bool isLastFloor;

  const _RewardsCard({required this.floor, required this.isLastFloor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kGoldLight.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Recompensas',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _kText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RewardChip(
                icon: '🪙',
                value: isLastFloor ? '+100 moedas' : '+10 moedas',
                color: _kGold,
              ),
              _RewardChip(
                icon: '⭐',
                value: isLastFloor ? '+200 XP' : '+20 XP',
                color: _kPurple,
              ),
            ],
          ),
          if (isLastFloor) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _RewardChip(
                  icon: '👑',
                  value: 'Coroa Dourada',
                  color: _kGold,
                ),
                _RewardChip(
                  icon: '🏰',
                  value: 'Reino Acessível',
                  color: _kCyan,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            _RewardChip(
              icon: floor.emoji,
              value: 'Andar ${floor.number} desbloqueado!',
              color: floor.color,
              wide: true,
            ),
          ],
        ],
      ),
    )
        .animate(delay: 600.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.3, end: 0);
  }
}

class _RewardChip extends StatelessWidget {
  final String icon;
  final String value;
  final Color color;
  final bool wide;

  const _RewardChip({
    required this.icon,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 20 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
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
// ACTION BUTTONS
// ═══════════════════════════════════════════════════════════════════════════

class _ActionButtons extends StatelessWidget {
  final bool isLastFloor;
  final TowerFloor floor;
  final VoidCallback onContinue;
  final VoidCallback? onViewDiploma;

  const _ActionButtons({
    required this.isLastFloor,
    required this.floor,
    required this.onContinue,
    this.onViewDiploma,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary
        GestureDetector(
          onTap: onContinue,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLastFloor
                    ? const [Color(0xFFFBBF24), Color(0xFFF59E0B)]
                    : const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (isLastFloor ? _kGoldLight : _kCyan)
                      .withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                isLastFloor ? '🏰 IR PARA O REINO' : '⬆️ PRÓXIMO ANDAR',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        if (isLastFloor && onViewDiploma != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewDiploma,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _kGoldLight.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Center(
                child: Text(
                  '📜 Ver diploma',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kGold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    )
        .animate(delay: 800.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.3, end: 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIPLOMA DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _DiplomaDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF9C3), Colors.white, Color(0xFFFEF9C3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: _kGoldLight, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'DIPLOMA',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _kGold,
                letterSpacing: 4,
              ),
            ),
            Container(
              height: 2,
              color: _kGoldLight,
              margin: const EdgeInsets.symmetric(vertical: 12),
            ),
            const Text(
              'Este diploma certifica que',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: _kSub,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'LEITOR MESTRE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: _kText,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'concluiu todos os 10 andares\nda Torre do Conhecimento\ncom excelência e dedicação!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: _kSub,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('⭐', style: TextStyle(fontSize: 20)),
                Text('🐻', style: TextStyle(fontSize: 20)),
                Text('🦊', style: TextStyle(fontSize: 20)),
                Text('🐰', style: TextStyle(fontSize: 20)),
                Text('⭐', style: TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scaleXY(begin: 0.7, end: 1.0, duration: 350.ms, curve: Curves.easeOutBack);
  }
}
