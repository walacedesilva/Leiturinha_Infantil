import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/speech_validator.dart';
import '../../domain/game_logic.dart';
import '../widgets/gamification_widgets.dart';
import '../widgets/mic_button.dart';
import 'praca_central_screen.dart';
import 'session_summary_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────

const _kSky        = Color(0xFFE0F2FE);
const _kCraneYellow= Color(0xFFFBBF24);
const _kCraneSteel = Color(0xFF475569);
const _kBlockAmber = Color(0xFFFBBF24);
const _kBlockShadow= Color(0xFFD97706);
const _kSlotDash   = Color(0xFF94A3B8);
const _kSlotFill   = Color(0xFFF0FDF4);
const _kGreen      = Color(0xFF22C55E);
const _kBlue       = Color(0xFF0284C7);
const _kOrange     = Color(0xFFF97316);

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SyllableCraneScreen extends StatefulWidget {
  const SyllableCraneScreen({super.key});

  @override
  State<SyllableCraneScreen> createState() => _SyllableCraneScreenState();
}

class _SyllableCraneScreenState extends State<SyllableCraneScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _hookSwingCtrl;
  late final AnimationController _blockBobCtrl;
  late final AnimationController _successCtrl;

  // ── Game state helpers ────────────────────────────────────────────────────
  bool _rewardShown = false;
  bool _nextEnabled = false;

  @override
  void initState() {
    super.initState();

    _hookSwingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _blockBobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _hookSwingCtrl.dispose();
    _blockBobCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Tap to place logic ────────────────────────────────────────────────────

  void _onBlockTapped(BuildContext context, GameLogic gl, String syllable) {
    final nextSlot = gl.placedSyllables.indexWhere((s) => s == null);
    if (nextSlot < 0) return;

    HapticFeedback.lightImpact();
    gl.onSyllableDropped(syllable, nextSlot);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<GameLogic>(
      builder: (context, gl, _) {
        // ── Reward toast ───────────────────────────────────────────────────
        if (gl.isValidated && gl.lastReward != null && !_rewardShown) {
          _rewardShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showRewardToast(context, gl.lastReward!);
          });
        }
        if (!gl.isValidated) _rewardShown = false;

        // ── Next word button delay ─────────────────────────────────────────
        final isPostAssembly =
            gl.isCompleted || gl.isValidating || gl.isValidated;
        if (isPostAssembly && !_nextEnabled) {
          Future.delayed(const Duration(milliseconds: 500),
              () { if (mounted) setState(() => _nextEnabled = true); });
        }
        if (!isPostAssembly) _nextEnabled = false;

        // ── Family done ────────────────────────────────────────────────────
        if (gl.isFamilyDone) {
          return Scaffold(
            backgroundColor: _kSky,
            body: _FamilyDoneView(gl: gl),
          );
        }

        // ── Loading ────────────────────────────────────────────────────────
        if (gl.currentWord.isEmpty) {
          return const Scaffold(
            backgroundColor: _kSky,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAssembling = gl.state == GameState.assembling;

        // Expected syllable for highlighting
        final nextSlot = gl.placedSyllables.indexWhere((s) => s == null);
        final expectedSyl = nextSlot >= 0 && nextSlot < gl.targetSyllables.length
            ? gl.targetSyllables[nextSlot]
            : null;

        return Scaffold(
          backgroundColor: _kSky,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                _TopBar(gl: gl),

                // ── Main play area ───────────────────────────────────────
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Sky / cloud background
                      Positioned.fill(
                        child: CustomPaint(painter: _SkyPainter()),
                      ),

                      // Crane arm (top-right, decorative)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _CraneArm(swingCtrl: _hookSwingCtrl),
                      ),

                      // Main content
                      Positioned.fill(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Space for crane arm
                            const SizedBox(height: 68),

                            // Mascot speech bubble
                            _MascotBubble(gl: gl).animate()
                              .fadeIn(duration: 350.ms)
                              .slideX(begin: -0.12, end: 0, duration: 350.ms),

                            const SizedBox(height: 20),

                            // Syllable blocks (assembling) or post-assembly content
                            if (isAssembling)
                              _SyllableBlocksArea(
                                gl: gl,
                                bobCtrl: _blockBobCtrl,
                                expectedSyl: expectedSyl,
                                onTap: (syl) =>
                                    _onBlockTapped(context, gl, syl),
                              )
                            else
                              _PostAssemblyArea(
                                gl: gl,
                                nextEnabled: _nextEnabled,
                                onAdvance: () async {
                                  setState(() => _nextEnabled = false);
                                  await gl.goToNextWord();
                                },
                              ),

                            const Spacer(),

                            // Word foundation (slots)
                            _WordFoundation(gl: gl),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom buttons ───────────────────────────────────────
                _BottomBar(gl: gl, isPostAssembly: isPostAssembly),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKY BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradient sky
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFBAE6FD), Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Clouds (simple ellipses)
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.70);
    _drawCloud(canvas, cloudPaint, 60, 40, 50);
    _drawCloud(canvas, cloudPaint, size.width * 0.45, 22, 38);
    _drawCloud(canvas, cloudPaint, size.width * 0.25, 80, 30);
  }

  void _drawCloud(Canvas canvas, Paint p, double cx, double cy, double r) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2.5, height: r), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * 0.5, cy - r * 0.3), width: r * 1.8, height: r * 0.9), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.5, cy - r * 0.2), width: r * 1.6, height: r * 0.8), p);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CRANE ARM
// ─────────────────────────────────────────────────────────────────────────────

class _CraneArm extends StatelessWidget {
  final AnimationController swingCtrl;
  const _CraneArm({required this.swingCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: swingCtrl,
      builder: (_, __) {
        final t = swingCtrl.value;
        return CustomPaint(
          size: const Size(160, 130),
          painter: _CranePainter(hookSwing: t),
        );
      },
    );
  }
}

class _CranePainter extends CustomPainter {
  final double hookSwing; // 0..1

  const _CranePainter({required this.hookSwing});

  @override
  void paint(Canvas canvas, Size size) {
    final steelPaint = Paint()
      ..color = _kCraneSteel
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final yellowPaint = Paint()
      ..color = _kCraneYellow
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cablePaint = Paint()
      ..color = const Color(0xFF78716C)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final hookPaint = Paint()
      ..color = _kCraneSteel
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Tower: vertical at right edge
    const towerX = 140.0;
    canvas.drawLine(
        const Offset(towerX, 10), Offset(towerX, 120), steelPaint);

    // Horizontal arm extending left
    canvas.drawLine(
        const Offset(30, 18), Offset(towerX, 18), yellowPaint);

    // Diagonal support brace: from top of tower to mid-arm
    canvas.drawLine(
        const Offset(75, 18), Offset(towerX, 55), steelPaint);

    // Cable from arm end (30, 18) swinging slightly
    final swingOffset = (hookSwing - 0.5) * 14.0;
    final hookBase = Offset(30 + swingOffset * 0.3, 18);
    final hookEnd  = Offset(30 + swingOffset, 85);

    canvas.drawLine(hookBase, hookEnd, cablePaint);

    // Hook J-shape
    canvas.drawArc(
      Rect.fromCenter(center: hookEnd + const Offset(4, 0), width: 12, height: 12),
      math.pi,
      math.pi * 0.8,
      false,
      hookPaint,
    );

    // Magnetic pad below hook
    final magnetPaint = Paint()
      ..color = _kCraneYellow
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: hookEnd + const Offset(0, -4), width: 20, height: 8),
        const Radius.circular(3),
      ),
      magnetPaint,
    );
  }

  @override
  bool shouldRepaint(_CranePainter old) => old.hookSwing != hookSwing;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GameLogic gl;
  const _TopBar({required this.gl});

  @override
  Widget build(BuildContext context) {
    final done  = gl.wordIndex;
    final total = gl.totalWords;
    final pct   = total == 0 ? 0.0 : done / total;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kSky,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0369A1),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Progress section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('🏗️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      'Palavra ${done + 1} de $total',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFBAE6FD),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kGreen),
                  ),
                ),
              ],
            ),
          ),

          // Word count pill
          Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGreen.withOpacity(0.30)),
            ),
            child: Text(
              '$done/$total',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _kGreen,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MASCOT SPEECH BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _MascotBubble extends StatelessWidget {
  final GameLogic gl;
  const _MascotBubble({required this.gl});

  String get _bubbleText {
    if (gl.isValidated && gl.lastValidation != null) {
      return gl.lastValidation!.isSuccess
          ? 'Muito bem! 🎉'
          : 'Tente falar: ${gl.targetSyllables.join('-')}';
    }
    if (gl.isCompleted || gl.isValidating) {
      return 'Agora fale: ${gl.currentWord}!';
    }
    return 'Monte: ${gl.targetSyllables.join('-')}!';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mascot avatar with hard hat
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: _kCraneYellow, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _kCraneYellow.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🐻', style: TextStyle(fontSize: 28)),
                ),
              ),
              // Hard hat
              const Positioned(
                top: -8,
                left: 8,
                child: Text('⛑️', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),

          const SizedBox(width: 10),

          // Speech bubble
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_bubbleText),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _bubbleText,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A5F),
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
// SYLLABLE BLOCKS AREA
// ─────────────────────────────────────────────────────────────────────────────

class _SyllableBlocksArea extends StatelessWidget {
  final GameLogic gl;
  final AnimationController bobCtrl;
  final String? expectedSyl;
  final void Function(String) onTap;

  const _SyllableBlocksArea({
    required this.gl,
    required this.bobCtrl,
    required this.expectedSyl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final syllables = gl.availableSyllables;

    if (syllables.isEmpty) return const SizedBox(height: 80);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: syllables.asMap().entries.map((e) {
          final idx = e.key;
          final syl = e.value;
          final isExpected = syl == expectedSyl;

          return _WoodenBlock(
            syllable: syl,
            isExpected: isExpected,
            bobCtrl: bobCtrl,
            bobOffset: idx * 0.3,
            onTap: () => onTap(syl),
          )
              .animate(delay: Duration(milliseconds: 80 * idx))
              .fadeIn(duration: 350.ms)
              .scaleXY(begin: 0.6, end: 1.0, curve: Curves.elasticOut, duration: 500.ms);
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WOODEN BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _WoodenBlock extends StatelessWidget {
  final String syllable;
  final bool isExpected;
  final AnimationController bobCtrl;
  final double bobOffset;
  final VoidCallback onTap;

  const _WoodenBlock({
    required this.syllable,
    required this.isExpected,
    required this.bobCtrl,
    required this.bobOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bobCtrl,
      builder: (_, child) {
        final t = ((bobCtrl.value + bobOffset) % 1.0);
        final bobY = math.sin(t * math.pi) * (isExpected ? 6.0 : 3.5);
        return Transform.translate(
          offset: Offset(0, -bobY),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isExpected
                  ? [const Color(0xFF4ADE80), _kGreen]
                  : [_kBlockAmber, const Color(0xFFF59E0B)],
            ),
            border: Border.all(
              color: isExpected ? _kGreen : _kBlockShadow,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isExpected ? _kGreen : _kBlockShadow).withOpacity(0.55),
                blurRadius: isExpected ? 18 : 10,
                offset: const Offset(0, 5),
              ),
              // Bottom wood face
              const BoxShadow(
                color: Color(0x40000000),
                blurRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Wood grain lines
              Positioned(
                top: 10,
                left: 8,
                right: 8,
                child: Column(
                  children: [
                    Container(
                      height: 1.5,
                      color: Colors.white.withOpacity(0.20),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 1.5,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ],
                ),
              ),
              // Syllable text
              Center(
                child: Text(
                  syllable,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Glow ring for expected block
              if (isExpected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.60),
                        width: 2,
                      ),
                    ),
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
// POST-ASSEMBLY AREA (assembled word + feedback)
// ─────────────────────────────────────────────────────────────────────────────

class _PostAssemblyArea extends StatelessWidget {
  final GameLogic gl;
  final bool nextEnabled;
  final VoidCallback onAdvance;

  const _PostAssemblyArea({
    required this.gl,
    required this.nextEnabled,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Assembled word display
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gl.isValidated && gl.lastValidation?.isSuccess == true
                    ? [const Color(0xFF4ADE80), _kGreen]
                    : [_kBlockAmber, const Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (gl.isValidated && gl.lastValidation?.isSuccess == true
                          ? _kGreen
                          : _kBlockShadow)
                      .withOpacity(0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (gl.isValidated && gl.lastValidation?.isSuccess == true)
                  const Text('⭐', style: TextStyle(fontSize: 28))
                else
                  const Text('🔨', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(
                  gl.currentWord,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (gl.isValidated && gl.lastValidation?.isSuccess == true)
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 28)
                else
                  const Icon(Icons.volume_up_rounded,
                      color: Colors.white70, size: 24),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .scaleXY(
                  begin: 0.85,
                  end: 1.0,
                  duration: 450.ms,
                  curve: Curves.elasticOut),

          // Validation feedback card
          if (gl.isValidated && gl.lastValidation != null) ...[
            const SizedBox(height: 14),
            ValidationFeedbackCard(
              key: const ValueKey('crane_feedback'),
              data: _buildFeedbackData(
                  gl.lastValidation!, gl.canRetryValidation),
              onRetry: () => gl.startSpeechValidation(),
              onAdvance: onAdvance,
            )
                .animate()
                .slideY(begin: 0.2, end: 0, duration: 350.ms)
                .fadeIn(duration: 300.ms),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD FOUNDATION (dashed slots)
// ─────────────────────────────────────────────────────────────────────────────

class _WordFoundation extends StatelessWidget {
  final GameLogic gl;
  const _WordFoundation({required this.gl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Foundation label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('🏗️', style: TextStyle(fontSize: 12)),
              SizedBox(width: 4),
              Text(
                'FUNDAÇÃO DA PALAVRA',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kSlotDash,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Slot row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: gl.targetSyllables.asMap().entries.map((e) {
              final idx = e.key;
              final target = e.value;
              final placed = idx < gl.placedSyllables.length
                  ? gl.placedSyllables[idx]
                  : null;
              final isNext = placed == null &&
                  idx ==
                      gl.placedSyllables.indexWhere((s) => s == null);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _Slot(
                  syllable: placed,
                  isNext: isNext,
                  expectedLength: target.length,
                )
                    .animate(delay: Duration(milliseconds: 50 * idx))
                    .fadeIn(duration: 300.ms),
              );
            }).toList(),
          ),

          // Construction ground line
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), _kCraneSteel, Color(0xFFF59E0B)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final String? syllable;
  final bool isNext;
  final int expectedLength;

  const _Slot({
    required this.syllable,
    required this.isNext,
    required this.expectedLength,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = syllable != null;
    final width = (expectedLength * 24.0 + 32).clamp(56.0, 96.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: width,
      height: 58,
      decoration: BoxDecoration(
        color: isFilled ? _kSlotFill : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFilled ? _kGreen : (isNext ? _kOrange : _kSlotDash),
          width: 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: isFilled
            ? [
                BoxShadow(
                  color: _kGreen.withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: isFilled
          ? Center(
              child: Text(
                syllable!,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15803D),
                ),
              ),
            )
              .animate()
              .scaleXY(begin: 0.5, end: 1.0, duration: 250.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 200.ms)
          : isNext
              ? Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _kOrange.withOpacity(0.60),
                    ),
                  ),
                )
              : CustomPaint(
                  painter: _DashedBorderPainter(
                    color: _kSlotDash.withOpacity(0.40),
                    borderRadius: 12,
                  ),
                ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  const _DashedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashLength = 6.0;
    const gapLength  = 5.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        Radius.circular(borderRadius),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR — "Ouvir Modelo" + "FALAR" mic
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final GameLogic gl;
  final bool isPostAssembly;

  const _BottomBar({required this.gl, required this.isPostAssembly});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // "Ouvir Modelo" — blue, always visible
          Expanded(
            child: GestureDetector(
              onTap: () => AudioManager().playWord(gl.currentWord.toLowerCase()),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: _kBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBlue.withOpacity(0.30)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up_rounded,
                        color: _kBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Ouvir Modelo',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // "FALAR" mic button — orange gradient when active
          _FalarButton(gl: gl, isPostAssembly: isPostAssembly),
        ],
      ),
    );
  }
}

class _FalarButton extends StatelessWidget {
  final GameLogic gl;
  final bool isPostAssembly;

  const _FalarButton({required this.gl, required this.isPostAssembly});

  @override
  Widget build(BuildContext context) {
    final isRecording  = gl.isValidating;
    final isEnabled    = isPostAssembly && !gl.isValidated;
    final isValidated  = gl.isValidated;

    // Colors
    late List<Color> gradient;
    late Color shadow;
    late Widget icon;
    late String label;
    VoidCallback? onTap;

    if (isRecording) {
      gradient = [const Color(0xFFF87171), const Color(0xFFEF4444)];
      shadow   = const Color(0xFFEF4444);
      icon     = const Icon(Icons.stop_rounded, color: Colors.white, size: 26);
      label    = 'Ouvindo...';
      onTap    = () => gl.cancelSpeechValidation();
    } else if (isValidated) {
      gradient = [const Color(0xFF4ADE80), _kGreen];
      shadow   = _kGreen;
      icon     = const Icon(Icons.arrow_forward_rounded,
          color: Colors.white, size: 26);
      label    = 'Próxima';
      onTap    = null; // handled by feedback card
    } else if (isEnabled) {
      gradient = [const Color(0xFFFB923C), _kOrange];
      shadow   = _kOrange;
      icon     = const Icon(Icons.mic_rounded, color: Colors.white, size: 26);
      label    = 'FALAR';
      onTap    = () => gl.startSpeechValidation();
    } else {
      // Disabled during assembly
      gradient = [const Color(0xFFD1D5DB), const Color(0xFF9CA3AF)];
      shadow   = Colors.transparent;
      icon     = const Icon(Icons.mic_rounded, color: Colors.white70, size: 26);
      label    = 'FALAR';
      onTap    = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: 130,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadow.withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(
          target: isEnabled && !isRecording ? 1 : 0,
          onPlay: (c) => isEnabled && !isRecording ? c.repeat(reverse: true) : null,
        )
        .scaleXY(
            begin: 1.0,
            end: 1.04,
            duration: 800.ms,
            curve: Curves.easeInOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAMILY DONE VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _FamilyDoneView extends StatefulWidget {
  final GameLogic gl;
  const _FamilyDoneView({required this.gl});

  @override
  State<_FamilyDoneView> createState() => _FamilyDoneViewState();
}

class _FamilyDoneViewState extends State<_FamilyDoneView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = widget.gl.lastSession;
      if (session == null) {
        // Sessão não iniciada (ex: todas as palavras já concluídas) — volta à tela anterior
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(
            session: session,
            coinsEarned: widget.gl.sessionCoins,
            xpEarned: widget.gl.sessionXp,
            newBadgeIds: widget.gl.sessionBadges,
            nextChallenge: 'Continue construindo palavras! 🏗️',
            onContinue: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const PracaCentralScreen()),
              (route) => false,
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 72))
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          const Text(
            'Família Completa!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E3A5F),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEEDBACK DATA BUILDER (mirrors game_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

ValidationFeedbackData _buildFeedbackData(
    ValidationResult r, bool canRetry) {
  if (r.spellingType != SpellingType.none) {
    return switch (r.spellingType) {
      SpellingType.letterSpelling => ValidationFeedbackData(
          emoji: '🔤',
          title: 'Soletrando!',
          message: r.spellingExplanation,
          confidence: 0.0,
          backgroundColor: const Color(0xFFFFF3E0),
          borderColor: Colors.deepOrange,
          titleColor: Colors.deepOrange,
          showRetry: canRetry,
          nextAction: 'retry',
          advanceLabel: 'Pular',
        ),
      SpellingType.separatedLetters => ValidationFeedbackData(
          emoji: '🔗',
          title: 'Junte as Letras!',
          message: r.spellingExplanation,
          confidence: 0.0,
          backgroundColor: const Color(0xFFFFF9E6),
          borderColor: Colors.amber,
          titleColor: Colors.orange,
          showRetry: canRetry,
          nextAction: 'retry',
          advanceLabel: 'Pular',
        ),
      SpellingType.supportVowel => ValidationFeedbackData(
          emoji: '👄',
          title: 'Quase Lá!',
          message: r.spellingExplanation,
          confidence: 0.0,
          backgroundColor: const Color(0xFFFFF3E0),
          borderColor: Colors.orange,
          titleColor: Colors.orange,
          showRetry: canRetry,
          nextAction: 'retry',
          advanceLabel: 'Pular',
        ),
      SpellingType.none => ValidationFeedbackData(
          emoji: '🔄',
          title: 'Tente Mais Uma Vez',
          message: r.feedbackMessage,
          confidence: r.confidence,
          backgroundColor: const Color(0xFFFFF3F3),
          borderColor: Colors.deepOrange,
          titleColor: Colors.deepOrange,
          showRetry: canRetry,
          nextAction: 'retry',
          advanceLabel: 'Pular',
        ),
    };
  }

  return switch (r.status) {
    ValidationStatus.excellent => ValidationFeedbackData(
        emoji: '🌟',
        title: 'Excelente!',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFE8F8E8),
        borderColor: Colors.green,
        titleColor: Colors.green,
        showRetry: false,
        nextAction: 'advance',
        advanceLabel: 'Próxima Palavra!',
      ),
    ValidationStatus.almostThere => ValidationFeedbackData(
        emoji: '👍',
        title: 'Quase Lá!',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFFFF9E6),
        borderColor: Colors.amber,
        titleColor: Colors.orange,
        showRetry: canRetry,
        nextAction: 'advance',
        advanceLabel: 'Continuar',
      ),
    ValidationStatus.tryAgain => ValidationFeedbackData(
        emoji: '🔄',
        title: 'Tente Mais Uma Vez',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFFFF3F3),
        borderColor: Colors.deepOrange,
        titleColor: Colors.deepOrange,
        showRetry: canRetry,
        nextAction: 'retry',
        advanceLabel: 'Pular',
      ),
    ValidationStatus.listenRepeat => ValidationFeedbackData(
        emoji: '🎧',
        title: 'Vamos Ouvir Juntos',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFEFF5FF),
        borderColor: Colors.blueAccent,
        titleColor: Colors.blueAccent,
        showRetry: canRetry,
        nextAction: 'reinforce',
        advanceLabel: 'Próxima Palavra',
      ),
  };
}
