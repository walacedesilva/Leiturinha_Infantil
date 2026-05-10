import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../data/adventure_content.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CONTOS MÁGICOS — Tela de Histórias Interativas com Lacunas
// Mecânica: escolha narrativa (fill-in-the-blank word choices)
// Auto-save de progresso + narração TTS pt-BR
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AdventureStoryScreen extends StatefulWidget {
  final String activityId;

  const AdventureStoryScreen({super.key, required this.activityId});

  @override
  State<AdventureStoryScreen> createState() => _AdventureStoryScreenState();
}

class _AdventureStoryScreenState extends State<AdventureStoryScreen>
    with TickerProviderStateMixin {
  late final FlutterTts _tts;
  late final AnimationController _confettiCtrl;
  late final AnimationController _bounceCtrl;

  int _storyIndex = 0;
  int _gapIndex = 0;
  List<int?> _userAnswers = [];
  _StoryPhase _phase = _StoryPhase.reading;
  bool _isSpeaking = false;

  MicroStory get _story => kMicroStories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _tts = FlutterTts();
    _tts.setLanguage('pt-BR');
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.1);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _resetStory();

    // Skip already completed stories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = context.read<ProgressService>();
      for (int i = 0; i < kMicroStories.length; i++) {
        if (progress
            .getCompletedWords(
                AdventureProgressKeys.storyKey(kMicroStories[i].id))
            .isEmpty) {
          if (mounted) setState(() => _storyIndex = i);
          return;
        }
      }
    });
  }

  void _resetStory() {
    _gapIndex = 0;
    _userAnswers = List.filled(_story.gaps.length, null);
    _phase = _StoryPhase.reading;
  }

  @override
  void dispose() {
    _tts.stop();
    _confettiCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _speakSegment(int segIdx) async {
    final text = _story.segments[segIdx].trim();
    if (text.isEmpty) return;
    setState(() => _isSpeaking = true);
    await _tts.speak(text);
  }

  Future<void> _speakFullStory() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    // Build the full story with chosen answers
    final buffer = StringBuffer();
    for (int i = 0; i < _story.segments.length; i++) {
      buffer.write(_story.segments[i]);
      if (i < _story.gaps.length && _userAnswers[i] != null) {
        buffer.write(_story.gaps[i].options[_userAnswers[i]!]);
      }
    }
    setState(() => _isSpeaking = true);
    await _tts.speak(buffer.toString());
  }

  Future<void> _onOptionTap(int optionIdx) async {
    final gap = _story.gaps[_gapIndex];
    final isCorrect = optionIdx == gap.correctIndex;

    if (isCorrect) {
      setState(() {
        _userAnswers[_gapIndex] = optionIdx;
      });
      _bounceCtrl.forward(from: 0);

      // TTS positive feedback
      await _tts.speak('Isso mesmo!');

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      if (_gapIndex < _story.gaps.length - 1) {
        setState(() {
          _gapIndex++;
          _phase = _StoryPhase.reading;
        });
      } else {
        // Story complete
        await _finishStory();
      }
    } else {
      // Wrong answer feedback
      setState(() => _phase = _StoryPhase.wrongAnswer);
      await _tts.speak(gap.hint);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _phase = _StoryPhase.reading);
    }
  }

  Future<void> _finishStory() async {
    setState(() => _phase = _StoryPhase.completed);
    _confettiCtrl.forward(from: 0);
    await _tts.speak('Parabéns! Você completou a história!');

    final progress = context.read<ProgressService>();
    final gam = context.read<GamificationService>();

    await progress.markWordCompleted(
      AdventureProgressKeys.storyKey(_story.id),
      _story.id,
    );
    await gam.addXp(25, source: 'adventure_story');
    await gam.addCoins(10);
  }

  Future<void> _nextStory() async {
    await _tts.stop();
    if (_storyIndex < kMicroStories.length - 1) {
      setState(() {
        _storyIndex++;
        _resetStory();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // Build inline rich text for the story so far (up to current gap)
  List<InlineSpan> _buildStorySpans() {
    final spans = <InlineSpan>[];
    final story = _story;
    final Color storyColor = Color(story.primaryColorValue);

    for (int i = 0; i < story.segments.length; i++) {
      if (story.segments[i].isNotEmpty) {
        spans.add(TextSpan(
          text: story.segments[i],
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            color: Color(0xFF1E3A5F),
            height: 1.6,
          ),
        ));
      }

      if (i < story.gaps.length) {
        final answered = _userAnswers[i];
        final isCurrent = i == _gapIndex;

        if (answered != null) {
          // Filled gap
          spans.add(TextSpan(
            text: ' ${story.gaps[i].options[answered]} ',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: storyColor,
              decoration: TextDecoration.underline,
              decorationColor: storyColor,
            ),
          ));
        } else if (isCurrent) {
          // Current blank (pulsing)
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _BlankWidget(color: storyColor),
          ));
        } else if (i < _gapIndex) {
          // Past blank not yet filled (shouldn't happen in normal flow)
          spans.add(TextSpan(
            text: ' ___ ',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              color: Colors.grey.shade400,
            ),
          ));
        }
        // Future blanks not shown yet
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    final storyColor = Color(story.primaryColorValue);
    final lightColor = Color(story.lightColorValue);

    return Scaffold(
      backgroundColor: lightColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _StoryHeader(
              current: _storyIndex + 1,
              total: kMicroStories.length,
              story: story,
              onBack: () {
                _tts.stop();
                Navigator.of(context).pop();
              },
            ),
            Expanded(
              child: _phase == _StoryPhase.completed
                  ? _CompletedView(
                      story: story,
                      confettiCtrl: _confettiCtrl,
                      onNext: _nextStory,
                      onListen: _speakFullStory,
                      isSpeaking: _isSpeaking,
                    )
                  : _ReadingView(
                      story: story,
                      storyColor: storyColor,
                      spans: _buildStorySpans(),
                      gapIndex: _gapIndex,
                      phase: _phase,
                      userAnswers: _userAnswers,
                      bounceCtrl: _bounceCtrl,
                      onOptionTap: _onOptionTap,
                      onListen: _speakFullStory,
                      isSpeaking: _isSpeaking,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE ENUM
// ─────────────────────────────────────────────────────────────────────────────
enum _StoryPhase { reading, wrongAnswer, completed }

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _StoryHeader extends StatelessWidget {
  final int current;
  final int total;
  final MicroStory story;
  final VoidCallback onBack;

  const _StoryHeader({
    required this.current,
    required this.total,
    required this.story,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(story.primaryColorValue);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, Color.lerp(c, Colors.black, 0.2)!],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 20),
            onPressed: onBack,
          ),
          Text(
            story.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  story.title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: current / total,
                          minHeight: 5,
                          backgroundColor: Colors.white30,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Conto $current/$total',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
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
// READING VIEW (main game area)
// ─────────────────────────────────────────────────────────────────────────────
class _ReadingView extends StatelessWidget {
  final MicroStory story;
  final Color storyColor;
  final List<InlineSpan> spans;
  final int gapIndex;
  final _StoryPhase phase;
  final List<int?> userAnswers;
  final AnimationController bounceCtrl;
  final Future<void> Function(int) onOptionTap;
  final VoidCallback onListen;
  final bool isSpeaking;

  const _ReadingView({
    required this.story,
    required this.storyColor,
    required this.spans,
    required this.gapIndex,
    required this.phase,
    required this.userAnswers,
    required this.bounceCtrl,
    required this.onOptionTap,
    required this.onListen,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    final gap = story.gaps[gapIndex];
    final isWrong = phase == _StoryPhase.wrongAnswer;

    return Column(
      children: [
        // Story text scroll area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Story text with inline gaps
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: storyColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: RichText(
                    text: TextSpan(children: spans),
                  ),
                ),
                const SizedBox(height: 16),
                // Wrong answer hint
                if (isWrong)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFCA5A5), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            gap.hint,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).shake(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        // Options panel
        _OptionsPanel(
          gap: gap,
          gapIndex: gapIndex,
          storyColor: storyColor,
          phase: phase,
          bounceCtrl: bounceCtrl,
          onOptionTap: onOptionTap,
          onListen: onListen,
          isSpeaking: isSpeaking,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPTIONS PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _OptionsPanel extends StatelessWidget {
  final StoryGap gap;
  final int gapIndex;
  final Color storyColor;
  final _StoryPhase phase;
  final AnimationController bounceCtrl;
  final Future<void> Function(int) onOptionTap;
  final VoidCallback onListen;
  final bool isSpeaking;

  const _OptionsPanel({
    required this.gap,
    required this.gapIndex,
    required this.storyColor,
    required this.phase,
    required this.bounceCtrl,
    required this.onOptionTap,
    required this.onListen,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: storyColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Qual palavra completa?',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: storyColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('🤔', style: TextStyle(fontSize: 16)),
                ],
              ),
              IconButton(
                onPressed: onListen,
                icon: Icon(
                  isSpeaking
                      ? Icons.stop_circle_rounded
                      : Icons.volume_up_rounded,
                  color: storyColor,
                  size: 22,
                ),
                tooltip: 'Ouvir história',
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Option buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              gap.options.length,
              (i) => _OptionButton(
                key: ValueKey('gap_${gapIndex}_opt_$i'),
                text: gap.options[i],
                color: storyColor,
                phase: phase,
                bounceCtrl: bounceCtrl,
                isCorrect: i == gap.correctIndex,
                onTap: () => onOptionTap(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String text;
  final Color color;
  final _StoryPhase phase;
  final AnimationController bounceCtrl;
  final bool isCorrect;
  final VoidCallback onTap;

  const _OptionButton({
    super.key,
    required this.text,
    required this.color,
    required this.phase,
    required this.bounceCtrl,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.12), color.withOpacity(0.06)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color.lerp(color, Colors.black, 0.3),
          ),
        ),
      ),
    )
        .animate(key: key)
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLANK WIDGET (pulsing placeholder in story text)
// ─────────────────────────────────────────────────────────────────────────────
class _BlankWidget extends StatelessWidget {
  final Color color;

  const _BlankWidget({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '  ???  ',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).tint(
          color: color.withOpacity(0.15),
          duration: 800.ms,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETED VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _CompletedView extends StatelessWidget {
  final MicroStory story;
  final AnimationController confettiCtrl;
  final VoidCallback onNext;
  final VoidCallback onListen;
  final bool isSpeaking;

  const _CompletedView({
    required this.story,
    required this.confettiCtrl,
    required this.onNext,
    required this.onListen,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(story.primaryColorValue);

    return Stack(
      children: [
        // Confetti painter
        Positioned.fill(
          child: AnimatedBuilder(
            animation: confettiCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(confettiCtrl.value, c),
            ),
          ),
        ),
        // Content
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(story.emoji, style: const TextStyle(fontSize: 72))
                    .animate()
                    .scale(curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  '🎉 História Completa!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: c,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.withOpacity(0.3), width: 2),
                  ),
                  child: Text(
                    story.moral,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      color: Color(0xFF1E3A5F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RewardBadge(
                        icon: '⭐',
                        label: '+25 XP',
                        color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    _RewardBadge(
                        icon: '🪙',
                        label: '+10',
                        color: const Color(0xFF06B6D4)),
                  ],
                ),
                const SizedBox(height: 20),
                // Listen full story
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onListen,
                    icon: Icon(
                      isSpeaking
                          ? Icons.stop_circle_rounded
                          : Icons.volume_up_rounded,
                    ),
                    label: Text(
                      isSpeaking ? 'Parar narração' : 'Ouvir história completa',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c,
                      side: BorderSide(color: c, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'Próxima História! 🚀',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFETTI PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double t;
  final Color accent;

  static final _rng = math.Random(7);
  static final _pieces = List.generate(
    40,
    (i) => (
      x: _rng.nextDouble(),
      startY: -0.05 - _rng.nextDouble() * 0.2,
      speed: 0.4 + _rng.nextDouble() * 0.6,
      size: 6.0 + _rng.nextDouble() * 8,
      angle: _rng.nextDouble() * 2 * math.pi,
      colorIdx: _rng.nextInt(5),
    ),
  );

  static const _colors = [
    Color(0xFFFBBF24),
    Color(0xFF06B6D4),
    Color(0xFFEF4444),
    Color(0xFF22C55E),
    Color(0xFF8B5CF6),
  ];

  _ConfettiPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pieces) {
      final progress = (t * p.speed) % 1.0;
      final y = (p.startY + progress * 1.3) * size.height;
      if (y < 0 || y > size.height) continue;
      final x = p.x * size.width + math.sin(progress * math.pi * 4) * 20;
      final paint = Paint()
        ..color = _colors[p.colorIdx].withOpacity(0.8 * (1 - progress * 0.5))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + progress * math.pi * 2);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED REWARD BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _RewardBadge extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _RewardBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
