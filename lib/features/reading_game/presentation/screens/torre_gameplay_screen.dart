import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../../services/speech_validator.dart';
import 'torre_do_conhecimento_screen.dart';
import 'torre_celebracao_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TORRE GAMEPLAY — Desafio por Andar
// Apresenta o desafio de leitura para o andar atual da torre.
// ═══════════════════════════════════════════════════════════════════════════

const _kGold      = Color(0xFFD97706);
const _kGoldLight = Color(0xFFFBBF24);
const _kGoldBg    = Color(0xFFFEF3C7);
const _kCyan      = Color(0xFF06B6D4);
const _kCyanLight = Color(0xFFCCFBFE);
const _kPurple    = Color(0xFF8B5CF6);
const _kText      = Color(0xFF1F2937);
const _kSub       = Color(0xFF6B7280);
const _kParchment = Color(0xFFFFF8EE);

// ─── Sample challenges per floor ─────────────────────────────────────────────
class _Challenge {
  final String phrase;
  final String illustration;
  final String tip;

  const _Challenge({
    required this.phrase,
    required this.illustration,
    required this.tip,
  });
}

const _kChallenges = <int, List<_Challenge>>{
  1: [
    _Challenge(phrase: 'A ARA É ALTA', illustration: '🦜', tip: 'Leia cada letra devagar!'),
    _Challenge(phrase: 'O ELO É OVAL', illustration: '⭕', tip: 'As vogais fazem música!'),
    _Challenge(phrase: 'UVA E OVO', illustration: '🍇', tip: 'Muito bem! Continue!'),
    _Challenge(phrase: 'ILHA E OCA', illustration: '🏝️', tip: 'Quase lá!'),
    _Challenge(phrase: 'EU OUÇ O ECO', illustration: '🔊', tip: 'Incrível!'),
  ],
  2: [
    _Challenge(phrase: 'O BEBÊ BEBE', illustration: '👶', tip: 'Repita a sílaba BA!'),
    _Challenge(phrase: 'A BOLA É BOA', illustration: '⚽', tip: 'Toque nas sílabas!'),
    _Challenge(phrase: 'O CACO CAI', illustration: '🏺', tip: 'CA como em CASA!'),
    _Challenge(phrase: 'O DADO É DAR', illustration: '🎲', tip: 'DA como em DATA!'),
    _Challenge(phrase: 'O DADO DADO', illustration: '🎯', tip: 'Excelente!'),
  ],
  3: [
    _Challenge(phrase: 'A FACA FAZ', illustration: '🔪', tip: 'FA como em FADA!'),
    _Challenge(phrase: 'O FOGO FOGE', illustration: '🔥', tip: 'Cuidado com o fogo!'),
    _Challenge(phrase: 'A GATA GEME', illustration: '🐱', tip: 'GA como em GATO!'),
    _Challenge(phrase: 'O GALO GAL', illustration: '🐓', tip: 'Quase um campeão!'),
    _Challenge(phrase: 'FIGO E GOIABA', illustration: '🍈', tip: 'Delicioso!'),
  ],
  4: [
    _Challenge(phrase: 'O JABUTI JÁ', illustration: '🐢', tip: 'JA como em JADE!'),
    _Challenge(phrase: 'A JOIA É JAULA', illustration: '💎', tip: 'Continue!'),
    _Challenge(phrase: 'A LAMA É LEVE', illustration: '🌊', tip: 'LA como em LÁPIS!'),
    _Challenge(phrase: 'O LEÃO LATE', illustration: '🦁', tip: 'LE como em LEVE!'),
    _Challenge(phrase: 'JOGO E LAMA', illustration: '🎮', tip: 'Uau!'),
  ],
  5: [
    _Challenge(phrase: 'A MAMÃE AMA', illustration: '👩', tip: 'MA como em MAÇÃ!'),
    _Challenge(phrase: 'O MACACO RI', illustration: '🐒', tip: 'Macaco alegre!'),
    _Challenge(phrase: 'A NATA É NOVA', illustration: '🥛', tip: 'NA como em NAVIO!'),
    _Challenge(phrase: 'O NAVIO NAD A', illustration: '🚢', tip: 'Navegue nas sílabas!'),
    _Challenge(phrase: 'MAPA E NAVIO', illustration: '🗺️', tip: 'Explorador!'),
  ],
  6: [
    _Challenge(phrase: 'O PATO PULA', illustration: '🦆', tip: 'PA como em PAPAI!'),
    _Challenge(phrase: 'A PIPA VEI O', illustration: '🪁', tip: 'Pipa no céu!'),
    _Challenge(phrase: 'A RATO ROSA', illustration: '🐀', tip: 'RA como em RABO!'),
    _Challenge(phrase: 'O SAPO SOBE', illustration: '🐸', tip: 'SA como em SAPATO!'),
    _Challenge(phrase: 'POTE E RODA', illustration: '🏺', tip: 'Perfeito!'),
  ],
  7: [
    _Challenge(phrase: 'O TATU TOCA', illustration: '🎵', tip: 'TA como em TATU!'),
    _Challenge(phrase: 'A TELA É TOLA', illustration: '🖼️', tip: 'Continue!'),
    _Challenge(phrase: 'A VACA VEI O', illustration: '🐄', tip: 'VA como em VACA!'),
    _Challenge(phrase: 'O VASO É VELHO', illustration: '🏺', tip: 'VE como em VENTO!'),
    _Challenge(phrase: 'TELA E VACA', illustration: '🎨', tip: 'Artista das sílabas!'),
  ],
  8: [
    _Challenge(phrase: 'O CHEFE CHORA', illustration: '👨‍💼', tip: 'CH como em CHAVE!'),
    _Challenge(phrase: 'A CHUVA CAI', illustration: '🌧️', tip: 'CHU como em CHUVA!'),
    _Challenge(phrase: 'O LHAMA LATE', illustration: '🦙', tip: 'LH como em LHAMA!'),
    _Challenge(phrase: 'O NINHO É NOVO', illustration: '🐦', tip: 'NH como em NINHO!'),
    _Challenge(phrase: 'QUEIJO E QUI', illustration: '🧀', tip: 'QU como em QUEIJO!'),
  ],
  9: [
    _Challenge(phrase: 'O BRAÇO BRINCA', illustration: '💪', tip: 'BR como em BRAVO!'),
    _Challenge(phrase: 'A BRIGA BREVE', illustration: '⚔️', tip: 'Continue!'),
    _Challenge(phrase: 'A CLARO CLARÃO', illustration: '☀️', tip: 'CL como em CLARO!'),
    _Challenge(phrase: 'O TREM TROCA', illustration: '🚂', tip: 'TR como em TREM!'),
    _Challenge(phrase: 'FLOR E BRISA', illustration: '🌸', tip: 'FL como em FLOR!'),
  ],
  10: [
    _Challenge(phrase: 'O GATO CORRE PELO MATO', illustration: '🐱', tip: 'Leia devagar e com calma!'),
    _Challenge(phrase: 'A MENINA BEBE SUCO FRIO', illustration: '🍹', tip: 'Você consegue!'),
    _Challenge(phrase: 'O PATO NADA NO LAGO CLARO', illustration: '🦆', tip: 'Quase mestre!'),
    _Challenge(phrase: 'BETO LEVA O LIVRO PARA CASA', illustration: '🐻', tip: 'Incrível progresso!'),
    _Challenge(phrase: 'EU SOU UM LEITOR MESTRE!', illustration: '👑', tip: 'Você chegou ao topo!'),
  ],
};

// ═══════════════════════════════════════════════════════════════════════════
// MIC STATE
// ═══════════════════════════════════════════════════════════════════════════

enum _MicState { idle, listening, success, fail }

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class TorreGameplayScreen extends StatefulWidget {
  final TowerFloor floor;

  const TorreGameplayScreen({super.key, required this.floor});

  @override
  State<TorreGameplayScreen> createState() => _TorreGameplayScreenState();
}

class _TorreGameplayScreenState extends State<TorreGameplayScreen>
    with TickerProviderStateMixin {
  int _challengeIndex = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  late final AnimationController _pulseCtrl;
  late final AnimationController _feedbackCtrl;

  // Audio / Mic
  _MicState _micState = _MicState.idle;
  String _liveTranscript = '';
  bool _isSpeaking = false;
  final _speechValidator = SpeechValidator();

  List<_Challenge> get _challenges =>
      _kChallenges[widget.floor.number] ??
      [const _Challenge(phrase: 'LEIA COM CALMA', illustration: '📖', tip: 'Você consegue!')];

  _Challenge get _current => _challenges[_challengeIndex];

  int get _total => _challenges.length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Announce first phrase on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) AudioManager().playWord(_current.phrase.toLowerCase());
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _feedbackCtrl.dispose();
    AudioManager().dispose();
    _speechValidator.cancelListening().catchError((_) {});
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-záàâãéêíóôõúç ]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _validatePhrase(String transcript, String phraseText) {
    final heard = _norm(transcript);
    final target = _norm(phraseText);
    final targetWords = target.split(' ').where((w) => w.length > 1).toList();
    if (targetWords.isEmpty) return heard.isNotEmpty;
    final matched = targetWords.where((w) => heard.contains(w)).length;
    return matched / targetWords.length >= 0.5;
  }

  // ── TTS ─────────────────────────────────────────────────────────────────────

  Future<void> _onHearModel() async {
    if (_isSpeaking) {
      AudioManager().dispose(); // stops current TTS
      setState(() => _isSpeaking = false);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _isSpeaking = true);
    await AudioManager().playWord(_current.phrase.toLowerCase());
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _onHearModelSlow() async {
    HapticFeedback.lightImpact();
    setState(() => _isSpeaking = true);
    await AudioManager().playWordSlow(_current.phrase.toLowerCase());
    if (mounted) setState(() => _isSpeaking = false);
  }

  // ── Mic / STT ───────────────────────────────────────────────────────────────

  Future<void> _onTapMic() async {
    if (_showFeedback) return;

    // Cancel if already listening
    if (_micState == _MicState.listening) {
      await _speechValidator.stopListening();
      if (mounted) setState(() {
        _micState = _MicState.idle;
        _liveTranscript = '';
      });
      return;
    }

    // Stop TTS first
    AudioManager().dispose();
    HapticFeedback.mediumImpact();
    setState(() {
      _micState = _MicState.listening;
      _liveTranscript = '';
      _isSpeaking = false;
    });

    final phraseText = _current.phrase;
    final words = _norm(phraseText).split(' ').where((w) => w.isNotEmpty).toList();

    await _speechValidator.startListening(
      targetWord: phraseText.toLowerCase(),
      syllables: words,
      level: ValidationLevel.beginner,
      timeout: const Duration(seconds: 12),
      onPartial: (partial) {
        if (mounted) setState(() => _liveTranscript = partial);
      },
      onValidated: (result) {
        if (!mounted) return;
        final success = _validatePhrase(result.transcript, phraseText);
        if (success) {
          AudioManager().playSFX(SFXType.correct);
          HapticFeedback.mediumImpact();
          setState(() {
            _micState = _MicState.success;
            _liveTranscript = result.transcript;
          });
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _onCorrect();
          });
        } else {
          AudioManager().playSFX(SFXType.error);
          HapticFeedback.mediumImpact();
          setState(() {
            _micState = _MicState.fail;
            _liveTranscript = result.transcript.isEmpty
                ? 'Não ouvi... tente de novo!'
                : result.transcript;
          });
          // Reset after 2s so child can try again
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() {
              _micState = _MicState.idle;
              _liveTranscript = '';
            });
          });
        }
      },
    );
  }

  void _onCorrect() async {
    setState(() {
      _showFeedback = true;
      _isCorrect = true;
      _micState = _MicState.idle;
      _liveTranscript = '';
    });
    await _feedbackCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _feedbackCtrl.reset();
    if (_challengeIndex < _total - 1) {
      setState(() {
        _challengeIndex++;
        _showFeedback = false;
      });
      // Announce next phrase
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) AudioManager().playWord(_current.phrase.toLowerCase());
      });
    } else {
      // Floor complete!
      if (mounted) _onFloorComplete();
    }
  }

  void _onNeedHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HelpSheet(challenge: _current),
    );
  }

  void _onFloorComplete() {
    final gam = context.read<GamificationService>();
    gam.addXp(20);
    gam.addCoins(10);

    final isLastFloor = widget.floor.number == 10;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => TorreCelebracaoScreen(
          floor: widget.floor,
          isLastFloor: isLastFloor,
        ),
        transitionsBuilder: (_, anim, __, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
          return ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: FadeTransition(opacity: anim, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8EE), Color(0xFFFEF3C7), Color(0xFFDBEAFE)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              _TopBar(
                floor: widget.floor,
                current: _challengeIndex + 1,
                total: _total,
              ),
              // ── Beto speech bubble ───────────────────────────────────────
              _BetoTip(tip: _current.tip),
              const SizedBox(height: 8),
              // ── Progress dots ────────────────────────────────────────────
              _ProgressDots(current: _challengeIndex, total: _total),
              const SizedBox(height: 12),
              // ── Vertical ladder (left) + Challenge card (main) ──────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MiniLadder(
                      currentFloor: widget.floor.number,
                      totalFloors: 10,
                    ),
                    Expanded(
                      child: _ChallengeCard(
                        challenge: _current,
                        showFeedback: _showFeedback,
                        isCorrect: _isCorrect,
                        pulseCtrl: _pulseCtrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── Action buttons ───────────────────────────────────────────
              _ActionBar(
                onMic: _onTapMic,
                onHear: _onHearModel,
                onHearSlow: _onHearModelSlow,
                onHelp: _onNeedHelp,
                pulseCtrl: _pulseCtrl,
                micState: _micState,
                liveTranscript: _liveTranscript,
                isSpeaking: _isSpeaking,
              ),
              const SizedBox(height: 100), // tab bar clearance
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final TowerFloor floor;
  final int current;
  final int total;

  const _TopBar({
    required this.floor,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: _kText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Andar ${floor.number}: ${floor.title}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _kText,
                  ),
                ),
                Text(
                  'Frase $current de $total',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: _kSub,
                  ),
                ),
              ],
            ),
          ),
          // Hint button
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => _HintDialog(),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kPurple.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('?', style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _kPurple,
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hint dialog ────────────────────────────────────────────────────────────

class _HintDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💡', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            const Text(
              'Dica',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _kText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque nas palavras para ouvir!\nLeia cada sílaba devagar.\nUse o botão 🔊 para ouvir o modelo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: _kSub,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _kPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Entendi!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BETO TIP
// ═══════════════════════════════════════════════════════════════════════════

class _BetoTip extends StatelessWidget {
  final String tip;

  const _BetoTip({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('🐻', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kGold.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Text(
                tip,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROGRESS DOTS
// ═══════════════════════════════════════════════════════════════════════════

class _ProgressDots extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final done = i < current;
        final active = i == current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: done
                ? _kGoldLight
                : active
                    ? _kCyan
                    : const Color(0xFFE5E7EB),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _kCyan.withOpacity(0.4),
                      blurRadius: 6,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MINI LADDER (left sidebar showing floors 1-10)
// ═══════════════════════════════════════════════════════════════════════════

class _MiniLadder extends StatelessWidget {
  final int currentFloor;
  final int totalFloors;

  const _MiniLadder({required this.currentFloor, required this.totalFloors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalFloors, (i) {
          final floorNum = totalFloors - i; // top to bottom = 10 to 1
          final completed = floorNum < currentFloor;
          final active = floorNum == currentFloor;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: active ? 28 : 20,
                  height: active ? 28 : 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? _kGoldLight
                        : active
                            ? _kCyan
                            : const Color(0xFFE5E7EB),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: _kCyan.withOpacity(0.5),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: completed
                        ? const Icon(Icons.check_rounded,
                            size: 12, color: Colors.white)
                        : active
                            ? Text(
                                '$floorNum',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                  ),
                ),
                if (i < totalFloors - 1)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: completed
                          ? _kGoldLight.withOpacity(0.5)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHALLENGE CARD
// ═══════════════════════════════════════════════════════════════════════════

class _ChallengeCard extends StatelessWidget {
  final _Challenge challenge;
  final bool showFeedback;
  final bool isCorrect;
  final AnimationController pulseCtrl;

  const _ChallengeCard({
    required this.challenge,
    required this.showFeedback,
    required this.isCorrect,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (context, _) {
        final pulse = 1.0 + pulseCtrl.value * 0.006;
        return Transform.scale(
          scale: showFeedback ? 1.0 : pulse,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: showFeedback
                  ? (isCorrect
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFF1F2))
                  : _kParchment,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: showFeedback
                    ? (isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                    : _kGoldLight.withOpacity(0.4),
                width: showFeedback ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (showFeedback && isCorrect
                          ? const Color(0xFF22C55E)
                          : _kGoldLight)
                      .withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scroll decoration top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _kGoldLight.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration
                      Text(
                        challenge.illustration,
                        style: const TextStyle(fontSize: 52),
                      )
                          .animate(key: ValueKey(challenge.phrase))
                          .scaleXY(begin: 0.6, end: 1.0, duration: 400.ms)
                          .fade(),
                      const SizedBox(height: 16),
                      // Phrase
                      _PhraseDisplay(
                        phrase: challenge.phrase,
                        showFeedback: showFeedback,
                        isCorrect: isCorrect,
                      ),
                      const SizedBox(height: 12),
                      // Feedback overlay
                      if (showFeedback)
                        _FeedbackBadge(isCorrect: isCorrect)
                            .animate()
                            .scaleXY(
                                begin: 0.6,
                                end: 1.0,
                                duration: 300.ms,
                                curve: Curves.easeOutBack)
                            .fade(),
                    ],
                  ),
                ),
                // Scroll decoration bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _kGoldLight.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhraseDisplay extends StatelessWidget {
  final String phrase;
  final bool showFeedback;
  final bool isCorrect;

  const _PhraseDisplay({
    required this.phrase,
    required this.showFeedback,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final words = phrase.split(' ');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: words
          .asMap()
          .entries
          .map(
            (entry) => GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                AudioManager().playSyllableInstant(entry.value.toLowerCase());
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _colorForWord(entry.key, words.length),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: phrase.length > 20 ? 16 : 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Color _colorForWord(int index, int total) {
    const colors = [
      Color(0xFFF97316),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF22C55E),
      Color(0xFFD97706),
      Color(0xFFEC4899),
    ];
    return colors[index % colors.length];
  }
}

class _FeedbackBadge extends StatelessWidget {
  final bool isCorrect;

  const _FeedbackBadge({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                    .withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isCorrect ? '⭐' : '💪',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 6),
          Text(
            isCorrect ? 'Perfeito! Subindo...' : 'Tente de novo!',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTION BAR
// ═══════════════════════════════════════════════════════════════════════════

class _ActionBar extends StatelessWidget {
  final VoidCallback onMic;
  final VoidCallback onHear;
  final VoidCallback onHearSlow;
  final VoidCallback onHelp;
  final AnimationController pulseCtrl;
  final _MicState micState;
  final String liveTranscript;
  final bool isSpeaking;

  const _ActionBar({
    required this.onMic,
    required this.onHear,
    required this.onHearSlow,
    required this.onHelp,
    required this.pulseCtrl,
    required this.micState,
    required this.liveTranscript,
    required this.isSpeaking,
  });

  Color get _micColor => switch (micState) {
    _MicState.idle      => _kGoldLight,
    _MicState.listening => Colors.redAccent,
    _MicState.success   => const Color(0xFF22C55E),
    _MicState.fail      => const Color(0xFFF97316),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Live transcript while listening
        if (liveTranscript.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _micColor.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    micState == _MicState.listening
                        ? Icons.graphic_eq_rounded
                        : Icons.record_voice_over_rounded,
                    size: 14,
                    color: _micColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '"$liveTranscript"',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: _micColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              // Hear model button (toggles fast/slow on long press)
              GestureDetector(
                onTap: onHear,
                onLongPress: onHearSlow,
                child: Container(
                  width: 60,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSpeaking
                        ? _kCyan.withOpacity(0.20)
                        : _kCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSpeaking ? _kCyan : _kCyan.withOpacity(0.3),
                      width: isSpeaking ? 2 : 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                        color: _kCyan,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSpeaking ? 'Parar' : 'Ouvir',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _kCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Main mic button
              Expanded(
                child: AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (context, _) {
                    final isListening = micState == _MicState.listening;
                    final scale = micState == _MicState.idle
                        ? 1.0 + pulseCtrl.value * 0.03
                        : isListening
                            ? 1.0 + pulseCtrl.value * 0.05
                            : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: onMic,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: switch (micState) {
                                _MicState.idle      => const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                                _MicState.listening => const [Colors.redAccent, Color(0xFFDC2626)],
                                _MicState.success   => const [Color(0xFF22C55E), Color(0xFF16A34A)],
                                _MicState.fail      => const [Color(0xFFF97316), Color(0xFFEA580C)],
                              },
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _micColor.withOpacity(0.55),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                switch (micState) {
                                  _MicState.idle      => Icons.mic_rounded,
                                  _MicState.listening => Icons.stop_rounded,
                                  _MicState.success   => Icons.check_circle_rounded,
                                  _MicState.fail      => Icons.refresh_rounded,
                                },
                                color: Colors.white,
                                size: 26,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                switch (micState) {
                                  _MicState.idle      => 'LER AGORA',
                                  _MicState.listening => 'OUVINDO...',
                                  _MicState.success   => 'INCRÍVEL! ⭐',
                                  _MicState.fail      => 'TENTE DE NOVO',
                                },
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Help
              _SideButton(
                icon: '🆘',
                label: 'Ajuda',
                color: _kPurple,
                onTap: onHelp,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SideButton({
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
        width: 60,
        height: 64,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
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

// ═══════════════════════════════════════════════════════════════════════════
// HELP SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _HelpSheet extends StatelessWidget {
  final _Challenge challenge;

  const _HelpSheet({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('🐻', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text(
            'Beto te ajuda!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _kText,
            ),
          ),
          const SizedBox(height: 16),
          // Show syllables
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: challenge.phrase
                .split(' ')
                .map(
                  (word) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kGoldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGoldLight, width: 1.5),
                    ),
                    child: Text(
                      word,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _kGold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            challenge.tip,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: _kSub,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Vou tentar! 💪',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
