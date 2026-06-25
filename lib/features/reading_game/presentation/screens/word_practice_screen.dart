import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../../services/speech_validator.dart';

// =============================================================================
// DATA
// =============================================================================

class _WordData {
  final String word;
  final String emoji;
  final List<String> syllables;
  final String hint;
  const _WordData(this.word, this.emoji, this.syllables, this.hint);
}

const _kWords = <String, List<_WordData>>{
  'A': [
    _WordData('ABACAXI', '🍎', ['A', 'BA', 'CA', 'XI'], 'Fale devagar: A-ba-cá-xi'),
    _WordData('AVIÃO',   '✈️', ['A', 'VI', 'ÃO'],       'Atenção para o ÃO no final'),
    _WordData('ANEL',    '💍', ['A', 'NEL'],              'Curto e rápido: A-nel!'),
  ],
  'E': [
    _WordData('ESTRELA',  '⭐', ['ES', 'TRE', 'LA'],      'ES-TRE-LA!'),
    _WordData('ELEFANTE', '🐘', ['E', 'LE', 'FAN', 'TE'], 'E-le-fan-te, quatro sílabas'),
    _WordData('ESCOLA',   '🏫', ['ES', 'CO', 'LA'],       'ES-CO-LA'),
  ],
  'I': [
    _WordData('ILHA',   '🏝️', ['I', 'LHA'],       'I-lha, rápido!'),
    _WordData('ÍMÃ',    '🧲', ['I', 'MÃ'],         'I-mã, atenção ao til!'),
    _WordData('IGREJA', '⛪', ['I', 'GRE', 'JA'], 'I-GRE-JA'),
  ],
  'O': [
    _WordData('OLHO',   '👁️', ['O', 'LHO'],         'O-lho, simples!'),
    _WordData('ÔNIBUS', '🚌', ['Ô', 'NI', 'BUS'],   'Ô-ni-bus, três sílabas'),
    _WordData('OVO',    '🥚', ['O', 'VO'],           'O-vo!'),
  ],
  'U': [
    _WordData('UVA',    '🍇', ['U', 'VA'],           'U-va!'),
    _WordData('URSO',   '🐻', ['UR', 'SO'],          'UR-so!'),
    _WordData('UMBIGO', '👶', ['UM', 'BI', 'GO'],    'Um-bi-go, três sílabas'),
  ],
};

// =============================================================================
// ENUM
// =============================================================================

enum _Phase { preparing, listening, success, partial, fail, complete }

// =============================================================================
// SCREEN
// =============================================================================

class WordPracticeScreen extends StatefulWidget {
  final String vowel;
  final Color primary;
  final Color light;
  final Color dark;

  const WordPracticeScreen({
    super.key,
    required this.vowel,
    required this.primary,
    required this.light,
    required this.dark,
  });

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen>
    with TickerProviderStateMixin {
  // ── Data ──────────────────────────────────────────────────────────────────
  late final List<_WordData> _words;

  // ── State ─────────────────────────────────────────────────────────────────
  int _wordIndex = 0;
  int _attempts = 0;
  final List<bool> _completedWords = [false, false, false];
  _Phase _phase = _Phase.preparing;
  String _partialTranscript = '';
  String _heardTranscript  = '';
  int _lastCoins = 0;
  int _lastXp    = 0;

  // ── Animations ────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    AudioManager().playMusic('jogo');
    _words = _kWords[widget.vowel] ?? _kWords['A']!;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Announce first word via TTS on entry
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) AudioManager().playWord(_words[0].word);
    });
  }

  @override
  void dispose() {
    SpeechValidator().cancelListening();
    _pulseCtrl.dispose();
    _confettiCtrl.dispose();
    AudioManager().playMusic('mapa');
    super.dispose();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  _WordData get _current => _words[_wordIndex];
  bool get _isLastWord   => _wordIndex == _words.length - 1;

  String get _syllabicDisplay => _current.syllables.join('-');

  // ── Audio helpers ─────────────────────────────────────────────────────────
  void _playModel()     => AudioManager().playWord(_current.word);
  void _playModelSlow() => AudioManager().playWordSlow(_current.word);

  // ── Mic handler ───────────────────────────────────────────────────────────
  Future<void> _onTapMic() async {
    // Tapping while listening cancels
    if (_phase == _Phase.listening) {
      await SpeechValidator().stopListening();
      if (mounted) {
        setState(() {
          _phase = _Phase.preparing;
          _partialTranscript = '';
        });
      }
      return;
    }
    if (_phase != _Phase.preparing) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.listening;
      _attempts++;
      _partialTranscript = '';
    });

    await SpeechValidator().startListening(
      targetWord: _current.word.toLowerCase(),
      syllables: _current.syllables.map((s) => s.toLowerCase()).toList(),
      level: ValidationLevel.beginner,
      timeout: const Duration(seconds: 6),
      onPartial: (p) {
        if (mounted) setState(() => _partialTranscript = p);
      },
      onValidated: (result) async {
        if (!mounted) return;
        HapticFeedback.mediumImpact();

        if (result.isSuccess) {
          // ── Award XP/coins ─────────────────────────────────────────
          final gam = context.read<GamificationService>();
          final reward = await gam.onWordValidated(
            accuracy:     result.confidence,
            attemptNumber: _attempts,
            isDualFamily:  false,
            familyKey:    'vogal_${widget.vowel}',
            wordWasNew:   !_completedWords[_wordIndex],
          );
          if (!mounted) return;
          // Persist word completion so VilaDasVogaisScreen can track progress
          context.read<ProgressService>().markWordCompleted(
            'vogal_${widget.vowel}', _current.word);

          setState(() {
            _phase = _Phase.success;
            _completedWords[_wordIndex] = true;
            _lastCoins = reward.coins;
            _lastXp    = reward.xp;
            _partialTranscript = '';
          });
          _confettiCtrl.forward(from: 0);
          AudioManager().playWord('Muito bem!');

          // ── Auto-advance after 2.2 s ───────────────────────────────
          Future.delayed(const Duration(milliseconds: 2200), () {
            if (!mounted) return;
            if (_isLastWord) {
              // Bonus for completing all words of this vowel
              context.read<GamificationService>()
                  .onFamilyCompleted('vogal_${widget.vowel}');
              setState(() => _phase = _Phase.complete);
              _confettiCtrl.forward(from: 0);
            } else {
              setState(() {
                _wordIndex++;
                _attempts = 0;
                _phase = _Phase.preparing;
                _partialTranscript = '';
              });
              AudioManager().playWord(_words[_wordIndex].word);
            }
          });
        } else {
          final newPhase =
              result.confidence > 0.30 ? _Phase.partial : _Phase.fail;
          setState(() {
            _phase = newPhase;
            _heardTranscript  = result.transcript;
            _partialTranscript = '';
          });
        }
      },
    );
  }

  void _retry() {
    setState(() {
      _phase = _Phase.preparing;
      _partialTranscript = '';
      _heardTranscript  = '';
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isListening = _phase == _Phase.listening;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [widget.light, Colors.white, Colors.white],
            stops: const [0.0, 0.50, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Confetti ──────────────────────────────────────────────
              if (_phase == _Phase.success || _phase == _Phase.complete)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _confettiCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _ConfettiPainter(
                          _confettiCtrl.value,
                          widget.primary,
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Main column ───────────────────────────────────────────
              Column(
                children: [
                  _buildHeader(context),
                  _buildProgressRow(),
                  const SizedBox(height: 10),
                  Expanded(child: _buildWordCards()),
                  _buildMicArea(isListening),
                  const SizedBox(height: 24),
                ],
              ),

              // ── Feedback overlays ─────────────────────────────────────
              if (_phase == _Phase.success)  _buildSuccessSheet(),
              if (_phase == _Phase.partial)  _buildPartialSheet(),
              if (_phase == _Phase.fail)     _buildFailSheet(),
              if (_phase == _Phase.complete) _buildCompleteModal(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final done  = _completedWords.where((c) => c).length;
    final total = _words.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: widget.primary, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          // Title + sub
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Casinha do ${widget.vowel}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: widget.dark,
                  ),
                ),
                Text(
                  'Palavra ${_wordIndex + 1} de $total',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.primary.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          // Mini progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done/$total',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: widget.primary,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 64,
                height: 7,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: done / total,
                    backgroundColor: widget.primary.withOpacity(0.15),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Progress dots ─────────────────────────────────────────────────────────

  Widget _buildProgressRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_words.length, (i) {
          final done   = _completedWords[i];
          final active = i == _wordIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width:  active ? 30 : 12,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: done
                  ? const Color(0xFF22C55E)
                  : active
                      ? widget.primary
                      : widget.primary.withOpacity(0.20),
            ),
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 9)
                : null,
          );
        }),
      ),
    );
  }

  // ── Word cards ────────────────────────────────────────────────────────────

  Widget _buildWordCards() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      children: List.generate(_words.length, (i) {
        final word   = _words[i];
        final active = i == _wordIndex;
        final done   = _completedWords[i];

        if (active) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, 0),
                end:   Offset.zero,
              ).animate(CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _ActiveWordCard(
              key: ValueKey('active_$i'),
              word: word,
              primary: widget.primary,
              dark: widget.dark,
              isSuccess: _phase == _Phase.success,
              onTapHear: _playModel,
            ),
          );
        }

        return Opacity(
          opacity: done ? 0.82 : 0.38,
          child: Transform.scale(
            scale: 0.92,
            alignment: Alignment.topCenter,
            child: _InactiveWordCard(
              word: word,
              primary: widget.primary,
              done: done,
            ),
          ),
        );
      }),
    );
  }

  // ── Mic area ──────────────────────────────────────────────────────────────

  Widget _buildMicArea(bool isListening) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hint / partial text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _phase == _Phase.listening && _partialTranscript.isNotEmpty
              ? Padding(
                  key: const ValueKey('partial'),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                  child: Text(
                    '"$_partialTranscript"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF374151),
                    ),
                  ),
                )
              : _phase == _Phase.preparing
                  ? Padding(
                      key: const ValueKey('hint'),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                      child: Text(
                        _attempts >= 2 ? _current.hint : 'Fale: $_syllabicDisplay',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.dark.withOpacity(0.60),
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('empty'), height: 26),
        ),
        const SizedBox(height: 6),

        // Mic button + rings
        GestureDetector(
          onTap:
              (_phase == _Phase.preparing || _phase == _Phase.listening)
                  ? _onTapMic
                  : null,
          child: SizedBox(
            width: 190,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse rings
                if (_phase == _Phase.preparing ||
                    _phase == _Phase.listening)
                  ...List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final t = (_pulseCtrl.value + i / 3.0) % 1.0;
                        final size = 88.0 + t * 54.0;
                        final opacity = (1.0 - t) *
                            (isListening ? 0.55 : 0.28);
                        return Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (isListening
                                      ? const Color(0xFFEF4444)
                                      : widget.primary)
                                  .withOpacity(opacity),
                              width: isListening ? 3.0 : 2.0,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                // Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isListening
                          ? [
                              const Color(0xFFF87171),
                              const Color(0xFFEF4444)
                            ]
                          : [
                              widget.primary.withOpacity(0.9),
                              widget.dark
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: (isListening
                                ? const Color(0xFFEF4444)
                                : widget.primary)
                            .withOpacity(0.48),
                        blurRadius: isListening ? 32 : 16,
                        spreadRadius: isListening ? 4 : 0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ).animate().scaleXY(
              begin: 0.0,
              end: 1.0,
              duration: 500.ms,
              delay: 200.ms,
              curve: Curves.elasticOut,
            ),

        // "Ouvir modelo" / "Devagar" buttons
        if (_phase == _Phase.preparing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SmallButton(
                  icon: Icons.volume_up_rounded,
                  label: 'Ouvir',
                  color: widget.primary,
                  onTap: _playModel,
                ),
                const SizedBox(width: 10),
                _SmallButton(
                  icon: Icons.slow_motion_video_rounded,
                  label: 'Devagar',
                  color: widget.dark,
                  onTap: _playModelSlow,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Success sheet ─────────────────────────────────────────────────────────

  Widget _buildSuccessSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: Color(0xFFF0FDF4),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, -6))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
            Text(
              'Isso! ${_current.word}! Muito bem!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF15803D),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardChip(icon: '🪙', value: '+$_lastCoins'),
                const SizedBox(width: 12),
                _RewardChip(icon: '⭐', value: '+$_lastXp XP'),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      )
          .animate()
          .slideY(begin: 1.0, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
          .fadeIn(duration: 250.ms),
    );
  }

  // ── Partial sheet ─────────────────────────────────────────────────────────

  Widget _buildPartialSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBEB),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, -6))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤔', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            const Text(
              'Quase lá! Tente de novo',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB45309),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _current.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                color: Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  label: '🔊 Ouvir modelo',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    _playModel();
                    _retry();
                  },
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  label: '🐌 Devagar',
                  color: const Color(0xFFD97706),
                  onTap: () {
                    _playModelSlow();
                    _retry();
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _retry,
              child: Text(
                'Tentar de novo →',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  color: widget.primary,
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .slideY(begin: 1.0, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
          .fadeIn(duration: 250.ms),
    );
  }

  // ── Fail sheet ────────────────────────────────────────────────────────────

  Widget _buildFailSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: Color(0xFFEFF6FF),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, -6))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💪', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            const Text(
              'Vamos praticar juntos?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'A palavra é: $_syllabicDisplay',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: Color(0xFF1E40AF),
              ),
            ),
            if (_heardTranscript.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Você disse: "$_heardTranscript"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  label: '🔊 Ouvir palavra',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    _playModel();
                    _retry();
                  },
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  label: '✂️ Por sílabas',
                  color: const Color(0xFF1D4ED8),
                  onTap: () {
                    _playModelSlow();
                    _retry();
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _retry,
              child: Text(
                'Tentar de novo →',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  color: widget.primary,
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .slideY(begin: 1.0, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
          .fadeIn(duration: 250.ms),
    );
  }

  // ── Complete modal ────────────────────────────────────────────────────────

  Widget _buildCompleteModal(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xBB000000),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 48,
                    offset: Offset(0, 14),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 66)),
                  const SizedBox(height: 10),
                  Text(
                    'PARABÉNS!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: widget.primary,
                    ),
                  ),
                  Text(
                    'Você dominou a vogal ${widget.vowel}!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: widget.dark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Word checklist
                  ..._words.asMap().entries.map((e) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E),
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 15),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${e.value.emoji}  ${e.value.word}',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                  // Rewards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _RewardChip(icon: '🪙', value: '+10 bônus'),
                      SizedBox(width: 10),
                      _RewardChip(icon: '⭐', value: '+20 XP'),
                      SizedBox(width: 10),
                      _RewardChip(icon: '🏆', value: 'Badge!'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15),
                            side: BorderSide(color: widget.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            // Pop WordPractice + VowelInterior → VilaDasVogais
                            final nav = Navigator.of(context);
                            nav.pop();
                            nav.pop();
                          },
                          child: Text(
                            '🗺️ Mapa',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              color: widget.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15),
                            backgroundColor: widget.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            setState(() {
                              _wordIndex = 0;
                              _attempts  = 0;
                              for (int k = 0;
                                  k < _completedWords.length;
                                  k++) {
                                _completedWords[k] = false;
                              }
                              _phase = _Phase.preparing;
                              _partialTranscript = '';
                              _heardTranscript  = '';
                            });
                            AudioManager().playWord(_words[0].word);
                          },
                          child: const Text(
                            '🔄 Repetir',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .scaleXY(
              begin: 0.88,
              end: 1.0,
              duration: 380.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}

// =============================================================================
// ACTIVE WORD CARD
// =============================================================================

class _ActiveWordCard extends StatelessWidget {
  final _WordData word;
  final Color primary;
  final Color dark;
  final bool isSuccess;
  final VoidCallback onTapHear;

  const _ActiveWordCard({
    super.key,
    required this.word,
    required this.primary,
    required this.dark,
    required this.isSuccess,
    required this.onTapHear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapHear,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSuccess
                ? [const Color(0xFF4ADE80), const Color(0xFF22C55E)]
                : [primary.withOpacity(0.90), dark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isSuccess ? const Color(0xFF22C55E) : primary)
                  .withOpacity(0.48),
              blurRadius: isSuccess ? 34 : 20,
              spreadRadius: isSuccess ? 4 : 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(word.emoji,
                style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word.word,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    word.syllables.join('-'),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            if (isSuccess)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 32)
            else
              const Icon(Icons.volume_up_rounded,
                  color: Color(0xAAFFFFFF), size: 24),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// INACTIVE WORD CARD
// =============================================================================

class _InactiveWordCard extends StatelessWidget {
  final _WordData word;
  final Color primary;
  final bool done;

  const _InactiveWordCard({
    required this.word,
    required this.primary,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done
              ? const Color(0xFF86EFAC)
              : primary.withOpacity(0.18),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(word.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              word.word,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: done
                    ? const Color(0xFF15803D)
                    : const Color(0xFFD1D5DB),
              ),
            ),
          ),
          done
              ? const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF22C55E), size: 24)
              : const Text('🔒', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

// =============================================================================
// SMALL HELPER WIDGETS
// =============================================================================

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String icon;
  final String value;

  const _RewardChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFFBBF24), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CONFETTI PAINTER
// =============================================================================

class _Particle {
  final double x;
  final double phase;
  final double size;
  final double speed;
  final Color color;

  _Particle(math.Random rng, Color primary)
      : x     = rng.nextDouble(),
        phase  = rng.nextDouble(),
        size   = 6.0 + rng.nextDouble() * 9.0,
        speed  = 0.28 + rng.nextDouble() * 0.72,
        color  = [
          primary,
          const Color(0xFFFBBF24),
          const Color(0xFF34D399),
          const Color(0xFFF472B6),
          const Color(0xFF60A5FA),
          const Color(0xFFA78BFA),
        ][rng.nextInt(6)];
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final Color primary;

  static final _rng = math.Random(7);
  static List<_Particle>? _cache;
  static Color? _cacheColor;

  _ConfettiPainter(this.t, this.primary) {
    if (_cache == null || _cacheColor != primary) {
      _cache = List.generate(22, (_) => _Particle(_rng, primary));
      _cacheColor = primary;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _cache!) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final y       = size.height * progress;
      final opacity =
          progress > 0.82 ? (1.0 - progress) / 0.18 : 1.0;
      final wobble  =
          math.sin(progress * math.pi * 5 + p.phase * 8) * 22;
      final paint   = Paint()
        ..color = p.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
          p.x * size.width + wobble, y - p.size / 2);
      canvas.rotate(progress * math.pi * 3 + p.phase);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
