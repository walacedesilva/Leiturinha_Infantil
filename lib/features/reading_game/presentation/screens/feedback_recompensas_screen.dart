import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/app_colors.dart';
import '../../../../services/gamification_models.dart';
import '../../../../services/speech_validator.dart';
import 'avatar_personalizacao_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class FeedbackRecompensasScreen extends StatefulWidget {
  final String word;
  final List<String> syllables;
  final ValidationResult validation;

  /// Reward earned for this word (may be zero coins/xp on skip).
  final RewardEvent reward;

  /// Player state AFTER reward was applied.
  final PlayerState playerState;

  /// Optional preview of the next word, e.g. "CA-BE-LO".
  final String? nextWordPreview;

  final VoidCallback onNextWord;
  final VoidCallback onRepeat;
  final VoidCallback onMenu;

  const FeedbackRecompensasScreen({
    super.key,
    required this.word,
    required this.syllables,
    required this.validation,
    required this.reward,
    required this.playerState,
    this.nextWordPreview,
    required this.onNextWord,
    required this.onRepeat,
    required this.onMenu,
  });

  @override
  State<FeedbackRecompensasScreen> createState() =>
      _FeedbackRecompensasScreenState();
}

class _FeedbackRecompensasScreenState extends State<FeedbackRecompensasScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    // Style-guide: haptic feedback on successful word
    if (widget.validation.isSuccess) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  bool get _isExcellent =>
      widget.validation.status == ValidationStatus.excellent;

  String get _mascotMessage {
    final syllabized = widget.syllables.join('-');
    return _isExcellent
        ? 'Incrível! Você falou\n$syllabized perfeitamente! ✨'
        : 'Muito bem! Você falou\n$syllabized direitinho! 👍';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Stack(
        children: [
          // Fundo — gradiente lilas -> quente (prototipo)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF5F3FF), Color(0xFFFDF4FF), Color(0xFFFFF7ED)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // ── Confetti layer ────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(progress: _confettiCtrl.value),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // back button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 12),
                    child: _CircleBackButton(onTap: widget.onMenu),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      children: [
                        // ── Mascot + speech bubble ────────────────────
                        _MascotSection(
                          message: _mascotMessage,
                          isExcellent: _isExcellent,
                        ),

                        const SizedBox(height: 24),

                        // ── Reward cards ──────────────────────────────
                        _RewardRow(
                          coins: widget.reward.coins,
                          xp: widget.reward.xp,
                          newBadgeIds: widget.reward.newBadgeIds,
                        ),

                        const SizedBox(height: 20),

                        // ── XP level bar ──────────────────────────────
                        _XpLevelBar(playerState: widget.playerState),

                        const SizedBox(height: 28),

                        // ── Action buttons ────────────────────────────
                        _ActionButtons(
                          onNextWord: widget.onNextWord,
                          onRepeat: widget.onRepeat,
                          onMenu: widget.onMenu,
                        ),
                        // ── Personalizar Avatar ───────────────────────────────────────
                        const SizedBox(height: 12),
                        _CustomizeChip(),
                        // ── Next word preview ─────────────────────────
                        if (widget.nextWordPreview != null) ...[
                          const SizedBox(height: 16),
                          _NextWordChip(preview: widget.nextWordPreview!),
                        ],

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
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
// CONFETTI PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double progress; // 0..1

  _ConfettiPainter({required this.progress});

  static final List<_ConfettiPiece> _pieces = _generatePieces();

  static List<_ConfettiPiece> _generatePieces() {
    final rnd = math.Random(7);
    const colors = [
      Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047),
      Color(0xFFFFB300), Color(0xFF8E24AA), Color(0xFF00ACC1),
      Color(0xFFF06292), Color(0xFF26A69A), Color(0xFFFF7043),
      Color(0xFF5E35B1),
    ];
    return List.generate(60, (i) {
      final color = colors[rnd.nextInt(colors.length)];
      final isStrip = rnd.nextBool();
      return _ConfettiPiece(
        startX: rnd.nextDouble(),        // fraction of width
        fanAngle: (rnd.nextDouble() - 0.5) * math.pi * 1.1, // -55°..55°
        speed: 0.35 + rnd.nextDouble() * 0.65,
        color: color,
        size: isStrip ? Size(4 + rnd.nextDouble() * 8, 2 + rnd.nextDouble() * 4)
                      : Size(5 + rnd.nextDouble() * 8, 5 + rnd.nextDouble() * 8),
        isStrip: isStrip,
        rotation: rnd.nextDouble() * math.pi * 2,
        rotationSpeed: (rnd.nextDouble() - 0.5) * math.pi * 6,
        delay: rnd.nextDouble() * 0.4,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pieces) {
      final t = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      // Only show in top 55% of screen
      final maxY = size.height * 0.55;
      final cx = size.width * 0.5 + math.sin(p.fanAngle) * maxY * t * p.speed;
      final cy = maxY * t * p.speed * math.cos(p.fanAngle < 0 ? -p.fanAngle * 0.3 : p.fanAngle * 0.3);

      final opacity = t < 0.7 ? 1.0 : (1.0 - t) / 0.3;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation + p.rotationSpeed * t);

      if (p.isStrip) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size.width, height: p.size.height),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size.width, height: p.size.height),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _ConfettiPiece {
  final double startX;
  final double fanAngle;
  final double speed;
  final Color color;
  final Size size;
  final bool isStrip;
  final double rotation;
  final double rotationSpeed;
  final double delay;

  const _ConfettiPiece({
    required this.startX,
    required this.fanAngle,
    required this.speed,
    required this.color,
    required this.size,
    required this.isStrip,
    required this.rotation,
    required this.rotationSpeed,
    required this.delay,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCLE BACK BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF5A5A5A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MASCOT SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _MascotSection extends StatelessWidget {
  final String message;
  final bool isExcellent;

  const _MascotSection({required this.message, required this.isExcellent});

  @override
  Widget build(BuildContext context) {
    // Star sparkle offsets relative to mascot center
    const sparkles = <_Sparkle>[
      _Sparkle(dx: -88, dy: -10, delay: 0),
      _Sparkle(dx: -70, dy: 28, delay: 120),
      _Sparkle(dx: 80, dy: -14, delay: 60),
      _Sparkle(dx: 75, dy: 26, delay: 180),
      _Sparkle(dx: -40, dy: 55, delay: 90),
      _Sparkle(dx: 50, dy: 55, delay: 150),
    ];

    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Sparkle stars
          ...sparkles.map((s) => Positioned(
                left: 140 + s.dx,   // 140 = rough center within 280 wide stack
                top: 128 + s.dy,    // 128 = mascot vertical center
                child: _StarSparkle(delay: Duration(milliseconds: s.delay)),
              )),

          // Speech bubble (above mascot)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _SpeechBubble(message: message),
          ),

          // Bear mascot
          Positioned(
            bottom: 8,
            child: _Bear(isExcellent: isExcellent),
          ),
        ],
      ),
    );
  }
}

class _Sparkle {
  final double dx;
  final double dy;
  final int delay;
  const _Sparkle({required this.dx, required this.dy, required this.delay});
}

class _StarSparkle extends StatelessWidget {
  final Duration delay;
  const _StarSparkle({required this.delay});

  @override
  Widget build(BuildContext context) {
    return const Text('✦', style: TextStyle(fontSize: 18, color: Color(0xFFFFD700)))
        .animate(
          delay: delay,
          onPlay: (c) => c.repeat(reverse: true),
        )
        .scaleXY(
          begin: 0.5,
          end: 1.3,
          duration: 800.ms,
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: 300.ms);
  }
}

// ── Speech bubble ────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String message;
  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: CustomPaint(
        painter: _BubblePainter(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18), // space for tail
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Color(0xFF2D2D2D),
              height: 1.3,
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: -0.2, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const r = 20.0;
    const tailH = 16.0;
    const tailW = 24.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height - tailH);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(r));

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final shadow = Paint()
      ..color = const Color(0x22000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Shadow
    canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadow);
    // Bubble body
    canvas.drawRRect(rrect, paint);

    // Tail (pointing down-center)
    final cx = size.width / 2;
    final tailPath = Path()
      ..moveTo(cx - tailW / 2, size.height - tailH)
      ..lineTo(cx, size.height)
      ..lineTo(cx + tailW / 2, size.height - tailH)
      ..close();
    canvas.drawPath(tailPath, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter _) => false;
}

// ── Bear mascot ──────────────────────────────────────────────────────────────

class _Bear extends StatelessWidget {
  final bool isExcellent;
  const _Bear({required this.isExcellent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFFFECB3),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFD54F),
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          isExcellent ? '🐻' : '🐨',
          style: const TextStyle(fontSize: 90),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1.0, 1.0),
          duration: 550.ms,
          curve: Curves.easeOutBack,
          delay: 200.ms,
        )
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 1400.ms, curve: Curves.easeInOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARD ROW
// ─────────────────────────────────────────────────────────────────────────────

class _RewardRow extends StatelessWidget {
  final int coins;
  final int xp;
  final List<String> newBadgeIds;

  const _RewardRow({
    required this.coins,
    required this.xp,
    required this.newBadgeIds,
  });

  @override
  Widget build(BuildContext context) {
    final badges = newBadgeIds
        .map((id) => getBadgeById(id))
        .whereType<GameBadge>()
        .toList();

    final items = <Widget>[
      if (coins > 0)
        _RewardCard(
          emoji: '🪙',
          value: '+$coins',
          label: 'moedas',
          color: const Color(0xFFFFF8E1),
          border: const Color(0xFFFFD54F),
          delay: 0,
        ),
      if (xp > 0)
        _RewardCard(
          emoji: '⭐',
          value: '+$xp XP',
          label: 'pontos',
          color: const Color(0xFFE3F2FD),
          border: const Color(0xFF90CAF9),
          delay: 120,
        ),
      for (final b in badges)
        _RewardCard(
          emoji: b.emoji,
          value: 'Badge',
          label: '"${b.name}"\ndesbloqueado!',
          color: const Color(0xFFF3E5F5),
          border: const Color(0xFFCE93D8),
          delay: 240,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .map((w) => Flexible(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: w,
              )))
          .toList(),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final Color border;
  final int delay;

  const _RewardCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.border,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF37474F),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              color: Color(0xFF78909C),
              height: 1.2,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: 480.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// XP LEVEL BAR
// ─────────────────────────────────────────────────────────────────────────────

class _XpLevelBar extends StatelessWidget {
  final PlayerState playerState;
  const _XpLevelBar({required this.playerState});

  @override
  Widget build(BuildContext context) {
    final level = playerState.level;
    final next = playerState.nextLevel;
    final progress = playerState.levelProgress;
    final xp = playerState.xp;
    final nextXp = next?.xpRequired ?? xp;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                level.emoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nível ${level.level}: ${level.name}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF37474F),
                    ),
                  ),
                  Text(
                    next != null ? '$xp/$nextXp XP' : 'Nível máximo!',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Color(0xFF78909C),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (next != null)
                Text(
                  'Próx: ${next.name} ${next.emoji}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Color(0xFF9575CD),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Animated bar
          // XP bar — spec: height 24px, gradient fill, gold border
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (_, val, __) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: val,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: 350.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTONS
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onNextWord;
  final VoidCallback onRepeat;
  final VoidCallback onMenu;

  const _ActionButtons({
    required this.onNextWord,
    required this.onRepeat,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Próxima Palavra (primary, wider) — spec: verde #22C55E ──────────────
        Expanded(
          flex: 5,
          child: _ActionBtn(
            label: 'Próxima\nPalavra',
            icon: Icons.arrow_forward_rounded,
            bgColor: const Color(0xFF22C55E),
            delay: 0,
            onTap: onNextWord,
          ),
        ),
        const SizedBox(width: 10),
        // ── Repetir — spec: amarelo #FBBF24 ──────────────────────────
        Expanded(
          flex: 4,
          child: _ActionBtn(
            label: 'Repetir',
            icon: Icons.replay_rounded,
            bgColor: const Color(0xFFFBBF24),
            delay: 80,
            onTap: onRepeat,
          ),
        ),
        const SizedBox(width: 10),
        // ── Menu — spec: rosa #EC4899 ────────────────────────────────
        Expanded(
          flex: 4,
          child: _ActionBtn(
            label: 'Menu',
            icon: Icons.home_rounded,
            bgColor: const Color(0xFFEC4899),
            delay: 160,
            onTap: onMenu,
          ),
        ),
      ],
    )
        .animate(delay: 500.ms)
        .slideY(begin: 0.4, duration: 450.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final int delay;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEXT WORD CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _NextWordChip extends StatelessWidget {
  final String preview;
  const _NextWordChip({required this.preview});

  @override
  Widget build(BuildContext context) {
    // spec: fundo #DBEAFE, texto #1E40AF, borderRadius 16, Bold 18px
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                color: Color(0xFF1E40AF),
              ),
              children: [
                const TextSpan(
                  text: 'Em breve: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: preview,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: 650.ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.3, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOMIZE CHIP  (nav → AvatarPersonalizacaoScreen)
// ─────────────────────────────────────────────────────────────────────────────

class _CustomizeChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        AppPageRoute(page: const AvatarPersonalizacaoScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.principal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.principal.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('🎨', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              'Personalizar Avatar',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.principal,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: 700.ms)
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }
}
