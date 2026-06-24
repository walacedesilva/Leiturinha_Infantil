import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/speech_validator.dart';
import 'word_practice_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VOWEL PRACTICE SCREEN
// 390x844 mobile canvas — background: DBEAFE→white gradient
// ─────────────────────────────────────────────────────────────────────────────

class VowelPracticeScreen extends StatefulWidget {
  final String vowel;
  final Color primary;
  final Color light;
  final Color dark;
  final String examplePhrase; // e.g. "A de ABACAXI!"
  final String objectEmoji;   // e.g. "🍎"

  const VowelPracticeScreen({
    super.key,
    required this.vowel,
    required this.primary,
    required this.light,
    required this.dark,
    required this.examplePhrase,
    required this.objectEmoji,
  });

  @override
  State<VowelPracticeScreen> createState() => _VowelPracticeScreenState();
}

class _VowelPracticeScreenState extends State<VowelPracticeScreen>
    with TickerProviderStateMixin {
  // Bouncing emoji
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  // Mic pulse rings
  late final AnimationController _pulseCtrl;

  // Floating gold stars
  late final AnimationController _starsCtrl;

  // Vowel ambient glow pulse
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // Vowel tap glow
  bool _vowelTapped = false;

  // Mic / speech state
  bool _isListening = false;
  bool _listenSuccess = false;
  bool _listenFail = false;
  String _partialTranscript = '';

  String get _feedbackLabel {
    if (_isListening) return 'OUVINDO... 👂';
    if (_listenSuccess) return 'INCRÍVEL! ⭐';
    if (_listenFail) return 'TENTE DE NOVO! 💪';
    return 'TOQUE PARA FALAR';
  }

  Color get _feedbackLabelColor {
    if (_listenSuccess) return const Color(0xFF16A34A);
    if (_listenFail) return const Color(0xFFDC2626);
    if (_isListening) return const Color(0xFFEA580C);
    return const Color(0xFF6B7280);
  }

  List<Color> get _micGradient {
    if (_isListening) return [const Color(0xFFF87171), const Color(0xFFEF4444)];
    if (_listenSuccess) return [const Color(0xFF4ADE80), const Color(0xFF22C55E)];
    return [const Color(0xFFFBBF24), const Color(0xFFF97316)];
  }

  Color get _micRingColor {
    if (_isListening) return const Color(0xFFEF4444);
    if (_listenSuccess) return const Color(0xFF22C55E);
    return const Color(0xFFF97316);
  }

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -20)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    SpeechValidator().cancelListening();
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    _starsCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onTapVowel() {
    HapticFeedback.mediumImpact();
    setState(() => _vowelTapped = true);
    AudioManager().playWord(widget.vowel);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _vowelTapped = false);
    });
  }

  Future<void> _onTapMic() async {
    if (_isListening) {
      // Toque de novo cancela
      await SpeechValidator().stopListening();
      if (mounted) {
        setState(() {
          _isListening = false;
          _partialTranscript = '';
        });
      }
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
      _listenSuccess = false;
      _listenFail = false;
      _partialTranscript = '';
    });

    await SpeechValidator().startListening(
      targetWord: widget.vowel,
      syllables: [widget.vowel],
      level: ValidationLevel.beginner,
      timeout: const Duration(seconds: 8),
      onPartial: (partial) {
        if (mounted) setState(() => _partialTranscript = partial);
      },
      onValidated: (result) {
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        final ok = result.isSuccess;
        setState(() {
          _isListening = false;
          _partialTranscript = '';
          _listenSuccess = ok;
          _listenFail = !ok;
        });
        if (ok) {
          AudioManager().playWord('Muito bem!');
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => WordPracticeScreen(
                  vowel: widget.vowel,
                  primary: widget.primary,
                  light: widget.light,
                  dark: widget.dark,
                ),
                transitionsBuilder: (_, animation, __, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          });
        } else {
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted) setState(() { _listenSuccess = false; _listenFail = false; });
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFDBEAFE),
              Colors.white,
              widget.light.withOpacity(0.18),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Layer 0: Floating gold stars (full screen)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _starsCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _FloatingStarsPainter(_starsCtrl.value),
                    ),
                  ),
                ),
              ),

              // Layer 1: Main column
              Column(
                children: [
                  _buildHeader(context),
                  const Spacer(flex: 1),
                  _buildSpeechBubble(),
                  const SizedBox(height: 20),
                  _buildVowelArea(),
                  const Spacer(flex: 2),
                  _buildMicButton(),
                  const SizedBox(height: 8),
                  if (_isListening && _partialTranscript.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '"$_partialTranscript"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _feedbackLabel,
                      key: ValueKey(_feedbackLabel),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _feedbackLabelColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: widget.primary.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: widget.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Vogal ${widget.vowel}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: widget.dark,
                shadows: [
                  Shadow(
                    color: widget.primary.withOpacity(0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => AudioManager().playWord(widget.examplePhrase),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.volume_up_rounded, color: widget.primary, size: 22),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Speech bubble ────────────────────────────────────────────────────────────

  Widget _buildSpeechBubble() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.primary.withOpacity(0.22),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.objectEmoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Text(
                widget.examplePhrase,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: widget.primary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        // Triangle tail pointing down toward vowel
        CustomPaint(
          painter: _BubbleTailPainter(color: Colors.white),
          size: const Size(22, 11),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 450.ms).slideY(begin: -0.08, end: 0);
  }

  // ── Vowel area ───────────────────────────────────────────────────────────────

  Widget _buildVowelArea() {
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient glow ring (outer)
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 210 + _glowAnim.value * 18,
              height: 210 + _glowAnim.value * 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.primary.withOpacity(0.06 + _glowAnim.value * 0.05),
              ),
            ),
          ),
          // Ambient glow ring (inner)
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 182 + _glowAnim.value * 12,
              height: 182 + _glowAnim.value * 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.primary.withOpacity(0.09 + _glowAnim.value * 0.07),
              ),
            ),
          ),
          // Main vowel circle (tappable)
          GestureDetector(
            onTap: _onTapVowel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [
                    Color.lerp(Colors.white, widget.primary, 0.55)!,
                    widget.primary,
                    widget.dark,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primary.withOpacity(_vowelTapped ? 0.85 : 0.40),
                    blurRadius: _vowelTapped ? 52 : 28,
                    spreadRadius: _vowelTapped ? 10 : 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.50),
                    blurRadius: 12,
                    spreadRadius: -4,
                    offset: const Offset(-6, -6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.vowel,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 98,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .scaleXY(begin: 0.0, end: 1.0, duration: 550.ms, curve: Curves.elasticOut),
          // Bouncing emoji — top-right
          Positioned(
            top: 14,
            right: 10,
            child: AnimatedBuilder(
              animation: _bounceAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _bounceAnim.value),
                child: child,
              ),
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.objectEmoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 350.ms),
        ],
      ),
    );
  }

  // ── Mic button ────────────────────────────────────────────────────────────────

  Widget _buildMicButton() {
    return SizedBox(
      width: 260,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3 expanding pulse rings
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final t = (_pulseCtrl.value + i / 3.0) % 1.0;
                final size = 120.0 + t * 90.0;
                final opacity = (1.0 - t) * (_isListening ? 0.55 : 0.38);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _micRingColor.withOpacity(opacity),
                      width: _isListening ? 3.5 : 2.5,
                    ),
                  ),
                );
              },
            );
          }),
          // Button
          GestureDetector(
            onTap: _onTapMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _micGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: _micRingColor.withOpacity(0.55),
                    blurRadius: _isListening ? 40 : 28,
                    spreadRadius: _isListening ? 6 : 2,
                    offset: const Offset(0, 8),
                  ),
                  const BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 54,
                shadows: const [
                  Shadow(
                    color: Color(0x44000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .scaleXY(
                begin: 0.0,
                end: 1.0,
                duration: 620.ms,
                delay: 350.ms,
                curve: Curves.elasticOut,
              ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEECH BUBBLE TAIL
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  const _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING GOLD STARS PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _StarConfig {
  final double x;
  final double phase;
  final double size;
  final double speed;

  _StarConfig(math.Random rng)
      : x = rng.nextDouble(),
        phase = rng.nextDouble(),
        size = 7.0 + rng.nextDouble() * 10.0,
        speed = 0.45 + rng.nextDouble() * 0.55;
}

class _FloatingStarsPainter extends CustomPainter {
  final double t;

  static final _rng = math.Random(37); // fixed seed → stable layout
  static final List<_StarConfig> _stars =
      List.generate(7, (_) => _StarConfig(_rng));

  _FloatingStarsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final progress = (t * star.speed + star.phase) % 1.0;
      final y = size.height * (1.0 - progress);
      // Fade in at bottom, hold, fade out at top
      final opacity = progress < 0.15
          ? progress / 0.15
          : progress > 0.80
              ? (1.0 - progress) / 0.20
              : 1.0;
      final tp = TextPainter(
        text: TextSpan(
          text: '⭐',
          style: TextStyle(
            fontSize: star.size,
            color: const Color(0xFFFBBF24).withOpacity((opacity * 0.82).clamp(0.0, 1.0)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(star.x * size.width - star.size / 2, y - star.size / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_FloatingStarsPainter old) => old.t != t;
}
