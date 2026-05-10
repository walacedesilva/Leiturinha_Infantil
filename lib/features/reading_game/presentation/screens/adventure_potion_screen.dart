import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../reading_game/data/digrafos_content.dart';
import 'digrafos_celebration_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CALDEIRÃO MÁGICO — Combinar dígrafos arrastando letras
// Paleta: Roxo #8B5CF6, Lavanda, Dourado #FBBF24
// ═════════════════════════════════════════════════════════════════════════════

const _kPurple     = Color(0xFF8B5CF6);
const _kPurpleDark = Color(0xFF6D28D9);
const _kLavender   = Color(0xFFA78BFA);
const _kLavLight   = Color(0xFFEDE9FE);
const _kGold       = Color(0xFFFBBF24);
const _kGoldDeep   = Color(0xFFD97706);
const _kTeal       = Color(0xFF14B8A6);

// letras-distrator que aparecem ao redor do caldeirão
const _kDistractors = ['R', 'S', 'T', 'M', 'P', 'V', 'B', 'Z'];

class AdventurePotionScreen extends StatefulWidget {
  const AdventurePotionScreen({super.key});

  @override
  State<AdventurePotionScreen> createState() => _AdventurePotionScreenState();
}

class _AdventurePotionScreenState extends State<AdventurePotionScreen>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  int _currentIndex = 0;
  bool _letter1Dropped = false;
  bool _letter2Dropped = false;
  bool _showSuccess    = false;
  bool _showError      = false;
  bool _advancingNext  = false;
  String _draggedLetter = '';

  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _bubbleCtrl;
  late final AnimationController _successCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _mascotCtrl;

  DigrafoEntry get _current => kDigrafoEntries[_currentIndex];
  int get _total => kDigrafoEntries.length;

  @override
  void initState() {
    super.initState();
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bubbleCtrl.dispose();
    _successCtrl.dispose();
    _pulseCtrl.dispose();
    _mascotCtrl.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────────────────
  void _onLetterDropped(String letter, bool isTarget1) {
    final isCorrect = isTarget1
        ? letter == _current.letter1
        : letter == _current.letter2;

    if (!isCorrect) {
      AudioManager().playSFX(SFXType.error);
      setState(() {
        _showError = true;
        _draggedLetter = letter;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _showError = false);
      });
      return;
    }

    setState(() {
      if (isTarget1) {
        _letter1Dropped = true;
      } else {
        _letter2Dropped = true;
      }
    });

    if (_letter1Dropped && _letter2Dropped) {
      _onCombined();
    }
  }

  Future<void> _onCombined() async {
    setState(() => _showSuccess = true);
    _successCtrl.forward(from: 0);
    AudioManager().playSFX(SFXType.correct);
    AudioManager().playWord(_current.combined);

    // Gamification
    if (mounted) {
      final gam = context.read<GamificationService>();
      final progress = context.read<ProgressService>();
      await gam.addXp(20);
      await gam.addCoins(8);
      progress.markWordCompleted('digraph_${_current.combined}', _current.combined);
    }

    // Auto-advance after 3s (button tap also triggers earlier)
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted || _advancingNext) return;
    _advanceToNext();
  }

  void _onNext() {
    if (_advancingNext) return;
    _advancingNext = true;
    _advanceToNext();
  }

  void _advanceToNext() {
    if (!mounted) return;
    final isLast = _currentIndex >= _total - 1;
    if (!isLast) {
      setState(() {
        _currentIndex++;
        _letter1Dropped = false;
        _letter2Dropped = false;
        _showSuccess = false;
        _advancingNext = false;
      });
      _successCtrl.reset();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DigrafosCelebrationScreen()),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Build letter pool: target letters + random distractors (no repeats)
    final rng = math.Random(_currentIndex * 7);
    final distractors = List.of(_kDistractors)..shuffle(rng);
    final letters = [_current.letter1, _current.letter2, ...distractors.take(5)];
    letters.shuffle(rng);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1040),
      body: Stack(
        children: [
          // Background: blurred lab
          Positioned.fill(child: _LabBackground()),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _TopBar(current: _currentIndex + 1, total: _total),
                const SizedBox(height: 8),
                // Luna mascot + speech bubble
                AnimatedBuilder(
                  animation: _mascotCtrl,
                  builder: (_, __) => _LunaMascot(
                    instruction: _current.instruction,
                    bounce: _mascotCtrl.value,
                  ),
                ),
                const SizedBox(height: 12),
                // Cauldron + drop zones
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _bubbleCtrl,
                        builder: (_, __) => _CauldronWidget(
                          bubble: _bubbleCtrl.value,
                          letter1: _current.letter1,
                          letter2: _current.letter2,
                          letter1Placed: _letter1Dropped,
                          letter2Placed: _letter2Dropped,
                          combined: _current.combined,
                          showSuccess: _showSuccess,
                          soundHint: _current.soundHint,
                          exampleEmoji: _current.emoji,
                          exampleWord: _current.exampleWord,
                          onDropLetter1: (l) => _onLetterDropped(l, true),
                          onDropLetter2: (l) => _onLetterDropped(l, false),
                          onNext: _onNext,
                          isLast: _currentIndex >= _total - 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Letter pool
                _LetterPool(
                  letters: letters,
                  targetLetters: [_current.letter1, _current.letter2],
                  letter1Placed: _letter1Dropped,
                  letter2Placed: _letter2Dropped,
                  pulseAnim: _pulseCtrl,
                ),
                const SizedBox(height: 12),
                // Bottom progress + hint
                _BottomBar(
                  current: _currentIndex + 1,
                  total: _total,
                  soundHint: _current.soundHint,
                  digraph: _current.combined,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Error overlay
          if (_showError)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    '❌ $_draggedLetter não é aqui!',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEF4444),
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                  ).animate().shake(duration: 400.ms).fadeOut(delay: 500.ms),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAB BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────
class _LabBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E1040),
            Color(0xFF2D1B69),
            Color(0xFF1E1040),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: CustomPaint(painter: _LabShelfPainter()),
    );
  }
}

class _LabShelfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Shelf lines
    final shelfPaint = Paint()
      ..color = const Color(0xFF3B1F6E)
      ..strokeWidth = 3;
    for (final y in [0.18, 0.36]) {
      canvas.drawLine(Offset(0, size.height * y), Offset(size.width, size.height * y), shelfPaint);
    }

    // Potion bottles on shelves
    final bottleColors = [
      const Color(0xFF60A5FA),
      const Color(0xFF34D399),
      const Color(0xFFA78BFA),
      const Color(0xFFFBBF24),
      const Color(0xFFEF4444),
      const Color(0xFF60A5FA),
    ];

    final rng = math.Random(42);
    for (int row = 0; row < 2; row++) {
      final y = size.height * (row == 0 ? 0.06 : 0.22);
      for (int i = 0; i < 6; i++) {
        final x = size.width * (0.06 + i * 0.16);
        final col = bottleColors[(row * 3 + i) % bottleColors.length];
        final h = 24.0 + rng.nextDouble() * 16;
        // Bottle body
        final bodyRect = Rect.fromLTWH(x - 8, y, 16, h);
        canvas.drawRRect(
          RRect.fromRectAndCorners(bodyRect,
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          Paint()..color = col.withOpacity(0.35),
        );
        // Bottle liquid (filled portion)
        final liquidH = h * (0.3 + rng.nextDouble() * 0.5);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x - 7, y + h - liquidH, 14, liquidH),
            bottomLeft: const Radius.circular(3),
            bottomRight: const Radius.circular(3),
          ),
          Paint()..color = col.withOpacity(0.55),
        );
        // Bottle neck
        canvas.drawRect(
          Rect.fromLTWH(x - 4, y - 6, 8, 8),
          Paint()..color = col.withOpacity(0.4),
        );
        // Cork
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y - 7), width: 10, height: 6),
          Paint()..color = const Color(0xFF92400E).withOpacity(0.7),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LabShelfPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int current, total;
  const _TopBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Caldeirão Mágico 🧪',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Dígrafos: $current/$total',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kLavender,
                  ),
                ),
              ],
            ),
          ),
          // Hint button
          Tooltip(
            message: 'Dígrafos são letras abraçadas!',
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kGold.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _kGold.withOpacity(0.5), width: 1.5),
              ),
              child: const Text('?', style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _kGold,
              )),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LUNA MASCOT + SPEECH BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _LunaMascot extends StatelessWidget {
  final String instruction;
  final double bounce;
  const _LunaMascot({required this.instruction, required this.bounce});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Transform.translate(
            offset: Offset(0, -bounce * 5),
            child: Stack(
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
                        color: _kPurple.withOpacity(0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const Text('🦊', style: TextStyle(fontSize: 30)),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: Text('🥽', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                instruction,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3B0764),
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
// CAULDRON WIDGET (central, com drop zones)
// ─────────────────────────────────────────────────────────────────────────────
class _CauldronWidget extends StatelessWidget {
  final double bubble;
  final String letter1, letter2, combined, soundHint, exampleEmoji, exampleWord;
  final bool letter1Placed, letter2Placed, showSuccess;
  final ValueChanged<String> onDropLetter1, onDropLetter2;
  final VoidCallback? onNext;
  final bool isLast;

  const _CauldronWidget({
    required this.bubble,
    required this.letter1,
    required this.letter2,
    required this.combined,
    required this.soundHint,
    required this.exampleEmoji,
    required this.exampleWord,
    required this.letter1Placed,
    required this.letter2Placed,
    required this.showSuccess,
    required this.onDropLetter1,
    required this.onDropLetter2,
    this.onNext,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drop zones (targets) above cauldron
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DropTarget(
              label: letter1,
              isPlaced: letter1Placed,
              showSuccess: showSuccess,
              combined: combined,
              onAccept: onDropLetter1,
              isFirst: true,
            ),
            // Arrow between slots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.add_rounded,
                color: letter1Placed && letter2Placed
                    ? _kGold
                    : Colors.white.withOpacity(0.4),
                size: 28,
              ),
            ),
            _DropTarget(
              label: letter2,
              isPlaced: letter2Placed,
              showSuccess: showSuccess,
              combined: combined,
              onAccept: onDropLetter2,
              isFirst: false,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Cauldron body
        SizedBox(
          width: 160,
          height: 140,
          child: CustomPaint(painter: _BigCauldronPainter(bubble)),
        ),
        // Success overlay — exemplo de palavra
        if (showSuccess) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kGold, _kGoldDeep]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withOpacity(0.6),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(exampleEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$combined! $soundHint',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      exampleWord,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
          if (onNext != null) ...[  
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(
                isLast ? Icons.celebration_rounded : Icons.arrow_forward_rounded,
                size: 22,
              ),
              label: Text(
                isLast ? 'Finalizar! 🎉' : 'Próximo dígrafo',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: _kPurple.withOpacity(0.5),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(
              begin: 0.4,
              curve: Curves.easeOut,
            ),
          ],
        ],
      ],
    );
  }
}

class _DropTarget extends StatelessWidget {
  final String label, combined;
  final bool isPlaced, showSuccess, isFirst;
  final ValueChanged<String> onAccept;

  const _DropTarget({
    required this.label,
    required this.isPlaced,
    required this.showSuccess,
    required this.combined,
    required this.onAccept,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = isPlaced ? _kGold : _kPurple;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !isPlaced,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (ctx, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isPlaced
                ? _kGold.withOpacity(0.2)
                : hovering
                    ? _kPurple.withOpacity(0.4)
                    : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPlaced ? _kGold : (hovering ? _kLavender : Colors.white.withOpacity(0.3)),
              width: 2.5,
            ),
            boxShadow: isPlaced
                ? [BoxShadow(color: _kGold.withOpacity(0.5), blurRadius: 14, spreadRadius: 3)]
                : null,
          ),
          child: Center(
            child: Text(
              isPlaced ? label : '?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: isPlaced ? _kGold : Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BigCauldronPainter extends CustomPainter {
  final double bubble;
  _BigCauldronPainter(this.bubble);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.6;

    // Legs
    final legPaint = Paint()
      ..color = const Color(0xFF4C1D95)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 35, cy + 32), Offset(cx - 46, cy + 60), legPaint);
    canvas.drawLine(Offset(cx + 35, cy + 32), Offset(cx + 46, cy + 60), legPaint);

    // Body gradient
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [Color(0xFF7C3AED), Color(0xFF4C1D95), Color(0xFF2E1065)],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 110, height: 92));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 110, height: 90),
      bodyPaint,
    );

    // Rim
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 8), width: 118, height: 30),
      Paint()
        ..color = const Color(0xFF6D28D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Liquid (purple-teal gradient, glowing)
    final liquidColor1 = Color.lerp(
      const Color(0xFF8B5CF6), _kTeal, bubble)!;
    final liquidColor2 = Color.lerp(
      _kTeal, const Color(0xFFFBBF24), bubble * 0.3)!;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 6 - bubble * 4),
        width: 92,
        height: 32,
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [liquidColor1, liquidColor2],
        ).createShader(Rect.fromCenter(
          center: Offset(cx, cy - 6),
          width: 92,
          height: 32,
        ))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    // Glow effect on rim
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 8), width: 120, height: 32),
      Paint()
        ..color = liquidColor1.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Bubbles on surface
    final rng = math.Random(42);
    final bubblePaint = Paint()..color = Colors.white.withOpacity(0.55);
    for (int i = 0; i < 6; i++) {
      final bx = cx - 36.0 + rng.nextDouble() * 72;
      final by = cy - 8.0 - bubble * 5 + math.sin(bubble * math.pi + i) * 4;
      final br = 2.5 + rng.nextDouble() * 5;
      canvas.drawCircle(Offset(bx, by), br, bubblePaint);
    }

    // Handle
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 32), width: 64, height: 34),
      math.pi, math.pi, false,
      Paint()
        ..color = const Color(0xFF4C1D95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Steam wisps
    final steamPaint = Paint()
      ..color = _kLavender.withOpacity(0.3 + bubble * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final sx = cx - 24.0 + i * 24;
      final t = (bubble + i * 0.33) % 1.0;
      final path = Path()
        ..moveTo(sx, cy - 44)
        ..cubicTo(sx + 10, cy - 44 - t * 20, sx - 10, cy - 44 - t * 36, sx + 5, cy - 44 - t * 54);
      canvas.drawPath(path, steamPaint);
    }
  }

  @override
  bool shouldRepaint(_BigCauldronPainter o) => o.bubble != bubble;
}

// ─────────────────────────────────────────────────────────────────────────────
// LETTER POOL (draggable blocks)
// ─────────────────────────────────────────────────────────────────────────────
class _LetterPool extends StatelessWidget {
  final List<String> letters;
  final List<String> targetLetters;
  final bool letter1Placed, letter2Placed;
  final AnimationController pulseAnim;

  const _LetterPool({
    required this.letters,
    required this.targetLetters,
    required this.letter1Placed,
    required this.letter2Placed,
    required this.pulseAnim,
  });

  bool _isTarget(String l) => targetLetters.contains(l);
  bool _isPlaced(String l) =>
      (l == targetLetters[0] && letter1Placed) ||
      (l == targetLetters[1] && letter2Placed);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: letters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final letter = letters[i];
          final isTarget = _isTarget(letter);
          final placed = _isPlaced(letter);

          if (placed) {
            return Opacity(
              opacity: 0.3,
              child: _LetterBlock(letter: letter, isTarget: false, pulse: 0),
            );
          }

          return AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Draggable<String>(
              data: letter,
              feedback: Material(
                color: Colors.transparent,
                child: _LetterBlock(
                  letter: letter,
                  isTarget: isTarget,
                  pulse: isTarget ? pulseAnim.value : 0,
                  scale: 1.15,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _LetterBlock(letter: letter, isTarget: isTarget, pulse: 0),
              ),
              child: _LetterBlock(
                letter: letter,
                isTarget: isTarget,
                pulse: isTarget ? pulseAnim.value : 0,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LetterBlock extends StatelessWidget {
  final String letter;
  final bool isTarget;
  final double pulse;
  final double scale;

  const _LetterBlock({
    required this.letter,
    required this.isTarget,
    required this.pulse,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final glowOpacity = isTarget ? 0.35 + pulse * 0.35 : 0.0;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isTarget
                ? [_kGold, _kGoldDeep]
                : [const Color(0xFF4C1D95), const Color(0xFF3B0764)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTarget ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isTarget ? _kGold : _kPurple).withOpacity(glowOpacity + 0.2),
              blurRadius: isTarget ? 12 + pulse * 8 : 4,
              spreadRadius: isTarget ? 2 : 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isTarget ? const Color(0xFF1C1917) : Colors.white,
              shadows: isTarget
                  ? [Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 4)]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int current, total;
  final String soundHint;
  final String digraph;

  const _BottomBar({
    required this.current,
    required this.total,
    required this.soundHint,
    required this.digraph,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                AudioManager().playSFX(SFXType.pop);
                AudioManager().playWord(soundHint);
              },
              icon: const Icon(Icons.volume_up_rounded),
              label: Text(
                'Ouvir som do $digraph',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kTeal,
                side: const BorderSide(color: _kTeal, width: 2),
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Poções: $current/$total',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kLavender,
                ),
              ),
              Row(
                children: List.generate(
                  total,
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      i < current ? '🧪' : '🫙',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
