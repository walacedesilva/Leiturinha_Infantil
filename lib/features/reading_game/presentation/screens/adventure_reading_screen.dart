import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../../services/speech_validator.dart';
import '../../data/adventure_content.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TRILHA DAS FRASES — Tela de Leitura Progressiva
// Foco: fluência leitora, ritmo, confiança
// TTS pt-BR nativo + validação de progresso por frase
// ═════════════════════════════════════════════════════════════════════════════

// Mapeamento de atividade → subconjunto de frases
Map<String, List<ReadingPhrase>> _phrasesByActivity = {
  'reading_1': kReadingPhrases
      .where((p) =>
          p.level == AdventureLevel.beginner || p.level == AdventureLevel.easy)
      .toList(),
  'reading_2': kReadingPhrases
      .where((p) =>
          p.level == AdventureLevel.medium || p.level == AdventureLevel.hard || p.level == AdventureLevel.advanced)
      .toList(),
};

List<ReadingPhrase> _phrasesFor(String activityId) =>
    _phrasesByActivity[activityId] ?? kReadingPhrases;

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AdventureReadingScreen extends StatefulWidget {
  final String activityId;

  const AdventureReadingScreen({super.key, required this.activityId});

  @override
  State<AdventureReadingScreen> createState() => _AdventureReadingScreenState();
}

enum _MicState { idle, listening, success, fail }

class _AdventureReadingScreenState extends State<AdventureReadingScreen>
    with SingleTickerProviderStateMixin {
  late final FlutterTts _tts;
  late final List<ReadingPhrase> _phrases;
  late final AnimationController _starCtrl;
  final _speechValidator = SpeechValidator();

  int _current = 0;
  _PhraseState _state = _PhraseState.idle;
  bool _showHint = false;
  bool _isSpeaking = false;

  // Mic / STT state
  _MicState _micState = _MicState.idle;
  String _liveTranscript = '';
  String _feedbackMsg = '';
  String _feedbackEmoji = '';

  @override
  void initState() {
    super.initState();
    _phrases = _phrasesFor(widget.activityId);

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _tts = FlutterTts();
    _tts.setLanguage('pt-BR');
    _tts.setSpeechRate(0.5); // slower for children
    _tts.setPitch(1.1);
    _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    // Skip to first non-completed phrase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = context.read<ProgressService>();
      for (int i = 0; i < _phrases.length; i++) {
        if (progress
            .getCompletedWords(AdventureProgressKeys.phraseKey(_phrases[i].id))
            .isEmpty) {
          setState(() => _current = i);
          return;
        }
      }
      // All done
      setState(() => _current = _phrases.length - 1);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _starCtrl.dispose();
    _speechValidator.cancelListening().catchError((_) {});
    super.dispose();
  }

  // ── STT helpers ───────────────────────────────────────────────────────────

  /// Normaliza string para comparação: minúsculas, sem pontuação, sem acentos básicos.
  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-záàâãéêíóôõúç ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Valida se o transcript da criança cobre pelo menos 50% das palavras da frase.
  bool _validateSentence(String transcript, String phraseText) {
    final heard = _norm(transcript);
    final target = _norm(phraseText);
    final targetWords = target.split(' ').where((w) => w.length > 1).toList();
    if (targetWords.isEmpty) return heard.isNotEmpty;
    final matched = targetWords.where((w) => heard.contains(w)).length;
    return matched / targetWords.length >= 0.5;
  }

  Future<void> _startMic() async {
    if (_micState == _MicState.listening) {
      await _speechValidator.stopListening();
      setState(() => _micState = _MicState.idle);
      return;
    }
    await _tts.stop();
    setState(() {
      _micState = _MicState.listening;
      _liveTranscript = '';
      _feedbackMsg = '';
      _feedbackEmoji = '';
      _isSpeaking = false;
    });

    final phrase = _phrases[_current];
    final words = _norm(phrase.text).split(' ').where((w) => w.isNotEmpty).toList();

    await _speechValidator.startListening(
      targetWord: phrase.text,
      syllables: words,
      level: ValidationLevel.beginner,
      timeout: const Duration(seconds: 12),
      onPartial: (partial) {
        if (mounted) setState(() => _liveTranscript = partial);
      },
      onValidated: (result) {
        if (!mounted) return;
        final success = _validateSentence(result.transcript, phrase.text);
        setState(() {
          _liveTranscript = result.transcript;
          if (success) {
            _micState = _MicState.success;
            _feedbackMsg = 'Muito bem! Você leu!';
            _feedbackEmoji = '🌟';
          } else if (result.transcript.isEmpty) {
            _micState = _MicState.fail;
            _feedbackMsg = 'Não ouvi... tente de novo!';
            _feedbackEmoji = '🎙️';
          } else {
            _micState = _MicState.fail;
            _feedbackMsg = 'Quase! Tente novamente.';
            _feedbackEmoji = '💪';
          }
        });
        if (success) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _markCompleted();
          });
        }
      },
    );
  }

  Future<void> _speak() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    final text = _phrases[_current].text.replaceAll('.', '').toLowerCase();
    await _tts.speak(text);
  }

  Future<void> _markCompleted() async {
    final phrase = _phrases[_current];
    final progress = context.read<ProgressService>();
    final gam = context.read<GamificationService>();

    await _tts.stop();
    setState(() {
      _state = _PhraseState.celebrating;
      _isSpeaking = false;
    });

    // Save progress
    await progress.markWordCompleted(
      AdventureProgressKeys.phraseKey(phrase.id),
      phrase.id,
    );
    await gam.addXp(15, source: 'adventure_phrase');
    await gam.addCoins(5);

    _starCtrl.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    setState(() {
      _state = _PhraseState.idle;
      _showHint = false;
    });

    if (_current < _phrases.length - 1) {
      setState(() => _current++);
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(
        onContinue: () {
          Navigator.of(context).pop(); // dialog
          Navigator.of(context).pop(); // screen
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();
    final phrase = _phrases[_current];
    final isCompleted = progress
        .getCompletedWords(AdventureProgressKeys.phraseKey(phrase.id))
        .isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFE),
      body: SafeArea(
        child: Column(
          children: [
            _ReadingHeader(
              current: _current + 1,
              total: _phrases.length,
              level: phrase.level,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Phase emoji + illustration
                    _PhraseIllustration(
                      emoji: phrase.emoji,
                      isCompleted: isCompleted,
                    ),
                    const SizedBox(height: 24),
                    // Main phrase display
                    _PhraseCard(
                      phrase: phrase,
                      state: _state,
                      starCtrl: _starCtrl,
                    ),
                    const SizedBox(height: 16),
                    // Keyword chips
                    _KeywordChips(keywords: phrase.keywords),
                    const SizedBox(height: 12),
                    // Hint toggle
                    if (_showHint) ...[
                      _HintBox(hint: phrase.hint),
                      const SizedBox(height: 12),
                    ],
                    TextButton.icon(
                      onPressed: () => setState(() => _showHint = !_showHint),
                      icon: Icon(
                        _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
                        color: const Color(0xFFF59E0B),
                        size: 18,
                      ),
                      label: Text(
                        _showHint ? 'Esconder dica' : 'Ver dica',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Action buttons
            _ActionBar(
              isCompleted: isCompleted,
              isSpeaking: _isSpeaking,
              state: _state,
              micState: _micState,
              liveTranscript: _liveTranscript,
              feedbackMsg: _feedbackMsg,
              feedbackEmoji: _feedbackEmoji,
              onListen: _speak,
              onMic: _startMic,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE ENUM
// ─────────────────────────────────────────────────────────────────────────────
enum _PhraseState { idle, celebrating }

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _ReadingHeader extends StatelessWidget {
  final int current;
  final int total;
  final AdventureLevel level;
  final VoidCallback onBack;

  const _ReadingHeader({
    required this.current,
    required this.total,
    required this.level,
    required this.onBack,
  });

  static const _levelLabels = {
    AdventureLevel.beginner: ('Iniciante', Color(0xFF22C55E)),
    AdventureLevel.easy: ('Fácil', Color(0xFF06B6D4)),
    AdventureLevel.medium: ('Médio', Color(0xFFF59E0B)),
    AdventureLevel.hard: ('Difícil', Color(0xFFEF4444)),
    AdventureLevel.advanced: ('Avançado', Color(0xFF8B5CF6)),
  };

  @override
  Widget build(BuildContext context) {
    final lvl = _levelLabels[level]!;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0E7490)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 20),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📖 Trilha das Frases',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
                          minHeight: 6,
                          backgroundColor: Colors.white30,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$current/$total',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: lvl.$2.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: lvl.$2, width: 1.5),
            ),
            child: Text(
              lvl.$1,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHRASE ILLUSTRATION
// ─────────────────────────────────────────────────────────────────────────────
class _PhraseIllustration extends StatelessWidget {
  final String emoji;
  final bool isCompleted;

  const _PhraseIllustration({required this.emoji, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isCompleted
              ? [const Color(0xFF86EFAC), const Color(0xFF22C55E)]
              : [const Color(0xFFCFFAFE), const Color(0xFF06B6D4)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF06B6D4))
                .withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          isCompleted ? '⭐' : emoji,
          style: const TextStyle(fontSize: 56),
        ),
      ),
    )
        .animate(key: ValueKey(emoji))
        .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut)
        .fadeIn();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHRASE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PhraseCard extends StatelessWidget {
  final ReadingPhrase phrase;
  final _PhraseState state;
  final AnimationController starCtrl;

  const _PhraseCard({
    required this.phrase,
    required this.state,
    required this.starCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: starCtrl,
      builder: (_, __) {
        final isCelebrating = state == _PhraseState.celebrating;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: isCelebrating
                ? const Color(0xFFF0FDF4)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCelebrating
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF06B6D4).withOpacity(0.35),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCelebrating
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF06B6D4))
                    .withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Text(
                    phrase.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3A5F),
                      height: 1.4,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (isCelebrating) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '✅ Muito bem! Você leu!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              // Celebration stars
              if (isCelebrating)
                ..._buildStars(starCtrl.value),
            ],
          ),
        );
      },
    )
        .animate(key: ValueKey(phrase.id))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15, curve: Curves.easeOut);
  }

  List<Widget> _buildStars(double t) {
    return List.generate(6, (i) {
      final angle = (i / 6) * 2 * math.pi;
      final radius = 70.0 * t;
      return Positioned(
        left: 80 + math.cos(angle) * radius,
        top: 20 + math.sin(angle) * radius,
        child: Opacity(
          opacity: (1 - t).clamp(0, 1),
          child: Text(
            i % 2 == 0 ? '⭐' : '✨',
            style: TextStyle(fontSize: 16 * (1 - t * 0.5)),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KEYWORD CHIPS
// ─────────────────────────────────────────────────────────────────────────────
class _KeywordChips extends StatelessWidget {
  final List<String> keywords;

  const _KeywordChips({required this.keywords});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: keywords
          .map(
            (kw) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF06B6D4).withOpacity(0.5), width: 1.5),
              ),
              child: Text(
                kw,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0E7490),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HINT BOX
// ─────────────────────────────────────────────────────────────────────────────
class _HintBox extends StatelessWidget {
  final String hint;

  const _HintBox({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.6)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Color(0xFF78350F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BAR
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final bool isCompleted;
  final bool isSpeaking;
  final _PhraseState state;
  final _MicState micState;
  final String liveTranscript;
  final String feedbackMsg;
  final String feedbackEmoji;
  final VoidCallback onListen;
  final VoidCallback onMic;

  const _ActionBar({
    required this.isCompleted,
    required this.isSpeaking,
    required this.state,
    required this.micState,
    required this.liveTranscript,
    required this.feedbackMsg,
    required this.feedbackEmoji,
    required this.onListen,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    final bool busy = state == _PhraseState.celebrating;

    // Mic button appearance
    final Color micColor = switch (micState) {
      _MicState.listening => const Color(0xFFEF4444),
      _MicState.success   => const Color(0xFF22C55E),
      _MicState.fail      => const Color(0xFFF59E0B),
      _MicState.idle      => isCompleted
          ? const Color(0xFF22C55E)
          : const Color(0xFF06B6D4),
    };

    final IconData micIcon = switch (micState) {
      _MicState.listening => Icons.stop_circle_rounded,
      _MicState.success   => Icons.check_circle_rounded,
      _MicState.fail      => Icons.mic_rounded,
      _MicState.idle      => isCompleted
          ? Icons.check_circle_rounded
          : Icons.mic_rounded,
    };

    final String micLabel = switch (micState) {
      _MicState.listening => 'Ouvindo... (toque para parar)',
      _MicState.success   => '🌟 Incrível! Você leu!',
      _MicState.fail      => feedbackMsg.isEmpty ? 'Tentar de novo 🎙️' : feedbackMsg,
      _MicState.idle      => isCompleted
          ? 'Já li! Próxima ✈️'
          : 'Toque para ler em voz alta',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Live transcript bubble ───────────────────────────────────────
          if (micState == _MicState.listening || liveTranscript.isNotEmpty) ...
            [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: micState == _MicState.success
                      ? const Color(0xFFF0FDF4)
                      : micState == _MicState.fail
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: micColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      micState == _MicState.listening ? '🎙️' : feedbackEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        micState == _MicState.listening
                            ? (liveTranscript.isEmpty
                                ? 'Pode falar...'
                                : liveTranscript)
                            : feedbackMsg,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color.lerp(micColor, Colors.black, 0.4),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (micState == _MicState.listening)
                      _PulseDot(color: micColor),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          // ── TTS button ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy || micState == _MicState.listening ? null : onListen,
              icon: Icon(
                isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                size: 22,
              ),
              label: Text(
                isSpeaking ? 'Parar' : 'Ouvir a frase',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF06B6D4),
                side: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── Microphone button ─────────────────────────────────────────────
          GestureDetector(
            onTap: busy ? null : onMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    micColor,
                    Color.lerp(micColor, Colors.black, 0.15)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: micColor.withOpacity(0.45),
                    blurRadius: micState == _MicState.listening ? 20 : 8,
                    spreadRadius: micState == _MicState.listening ? 4 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(micIcon, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      micLabel,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bolinha pulsante que indica gravação ativa
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.4 + _c.value * 0.6),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETION DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _CompletionDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const _CompletionDialog({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64))
                .animate()
                .scale(curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text(
              'Trilha Completa!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Você leu todas as frases!\nSua leitura está ficando incrível! 🌟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardBadge(icon: '⭐', label: '+90 XP', color: const Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                _RewardBadge(icon: '🪙', label: '+30', color: const Color(0xFF06B6D4)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Continuar Aventura! 🚀',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
