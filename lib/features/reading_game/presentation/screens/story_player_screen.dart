import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/audio_manager.dart';
import '../../data/story_models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// STORY PLAYER SCREEN — Motor de Histórias Interativas
// Suporta: voice_trigger | touch_drag | branching_choice | creative_resolution
// ═════════════════════════════════════════════════════════════════════════════

enum _Phase { dialogue, interaction, feedback, choiceDialogue, completed }

class StoryPlayerScreen extends StatefulWidget {
  final StoryModel story;
  const StoryPlayerScreen({super.key, required this.story});

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  late StoryAct _act;
  _Phase _phase = _Phase.dialogue;
  int _dialogueIdx = 0;
  int _attempts = 0;

  // Feedback (success or fail dialogue)
  List<StoryDialogue> _feedbackDialogue = [];
  int _feedbackIdx = 0;
  String? _pendingNextAct;
  bool _feedbackIsSuccess = false;

  // Branching choice
  List<StoryDialogue> _choiceDialogue = [];
  int _choiceDialogueIdx = 0;
  String? _choiceNextAct;

  // ── Voice ──────────────────────────────────────────────────────────────────
  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  bool _isListening = false;
  String _lastSpeech = '';

  // ── Touch-drag match ───────────────────────────────────────────────────────
  // Maps itemId → targetId (correctly placed items)
  final Map<String, String> _correctMatches = {};

  // ── Touch-drag sequence ────────────────────────────────────────────────────
  // Maps slotIndex → itemId
  final Map<int, String> _sequenceSlots = {};

  // ── Touch-drag path ────────────────────────────────────────────────────────
  int _traceNextNode = 0;
  final List<Offset> _tracePoints = [];

  // ── Creative drawing ───────────────────────────────────────────────────────
  final List<List<Offset>> _drawStrokes = [];
  List<Offset> _currentStroke = [];
  Color _brushColor = const Color(0xFF4ECDC4);

  // ── Creative voice recording ───────────────────────────────────────────────
  bool _isRecording = false;
  int _recordCountdown = 0;
  Timer? _recordTimer;

  // ── Background ─────────────────────────────────────────────────────────────
  static const _bgGradients = [
    [Color(0xFFF97316), Color(0xFFD97706), Color(0xFFB45309)], // 0: safari
    [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF6D28D9)], // 1: cozinha
    [Color(0xFF3B82F6), Color(0xFF1D4ED8), Color(0xFF1E3A8A)], // 2: planetas
    [Color(0xFF14B8A6), Color(0xFF0F766E), Color(0xFF0F5A54)], // 3: teatro
    [Color(0xFF10B981), Color(0xFF059669), Color(0xFF064E3B)], // 4: jardim
    [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF312E81)], // 5: floresta sussurros
    [Color(0xFF6366F1), Color(0xFFF59E0B), Color(0xFF1E1B4B)], // 6: trovão amigo
  ];

  int _storyIndex = 0;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _act = widget.story.acts.first;
    _storyIndex = _resolveStoryIndex();
    _initStt();
    _brushColor = const Color(0xFF4ECDC4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playActiveDialogue();
    });
  }

  void _playActiveDialogue() {
    StoryDialogue? d;
    if (_phase == _Phase.dialogue) {
      if (_act.dialogue.isNotEmpty && _dialogueIdx < _act.dialogue.length) {
        d = _act.dialogue[_dialogueIdx];
      }
    } else if (_phase == _Phase.feedback) {
      if (_feedbackDialogue.isNotEmpty && _feedbackIdx < _feedbackDialogue.length) {
        d = _feedbackDialogue[_feedbackIdx];
      }
    } else if (_phase == _Phase.choiceDialogue) {
      if (_choiceDialogue.isNotEmpty && _choiceDialogueIdx < _choiceDialogue.length) {
        d = _choiceDialogue[_choiceDialogueIdx];
      }
    }

    if (d != null) {
      final isNarrator = d.character.toLowerCase().contains('narrator');
      AudioManager().speakSentence(d.text, isChild: !isNarrator);
    }
  }

  int _resolveStoryIndex() {
    final id = widget.story.id.toLowerCase();
    if (id.contains('safari')) return 0;
    if (id.contains('cozinha')) return 1;
    if (id.contains('planeta')) return 2;
    if (id.contains('teatro')) return 3;
    if (id.contains('jardim')) return 4;
    if (id.contains('whispering') || id.contains('sussurros')) return 5;
    if (id.contains('thunder') || id.contains('trovao')) return 6;
    return 0;
  }

  Timer? _sttSafetyTimer;

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize(
      onError: (e) {
        debugPrint('[STT] initialize onError: $e');
        if (mounted && _isListening) {
          _stopListening();
        }
      },
      onStatus: (status) {
        debugPrint('[STT] initialize onStatus: $status');
        if (mounted && (status == 'done' || status == 'notListening') && _isListening) {
          _stopListening();
        }
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _sttSafetyTimer?.cancel();
    _stt.stop();
    AudioManager().speakSentence('', isChild: false); // Silencia fala ao sair
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────────────────────

  void _goToAct(String? actId) {
    if (actId == null) {
      _complete();
      return;
    }
    final next = widget.story.findAct(actId);
    if (next == null) {
      _complete();
      return;
    }
    setState(() {
      _act = next;
      _phase = _Phase.dialogue;
      _dialogueIdx = 0;
      _attempts = 0;
      _correctMatches.clear();
      _sequenceSlots.clear();
      _traceNextNode = 0;
      _tracePoints.clear();
      _drawStrokes.clear();
      _currentStroke = [];
      _feedbackDialogue = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playActiveDialogue();
    });
  }

  void _complete() {
    setState(() => _phase = _Phase.completed);
    final gam = context.read<GamificationService>();
    gam.addCoins(widget.story.rewards.coins);
    gam.addXp(widget.story.rewards.xp);
  }

  // ── Dialogue advance ───────────────────────────────────────────────────────
  void _advanceDialogue() {
    if (_dialogueIdx < _act.dialogue.length - 1) {
      setState(() => _dialogueIdx++);
      _playActiveDialogue();
    } else {
      setState(() => _phase = _Phase.interaction);
      AudioManager().speakSentence(_act.interaction.instruction, isChild: false);
    }
  }

  // ── Feedback advance ───────────────────────────────────────────────────────
  void _advanceFeedback() {
    if (_feedbackIdx < _feedbackDialogue.length - 1) {
      setState(() => _feedbackIdx++);
      _playActiveDialogue();
    } else {
      _afterFeedback(_pendingNextAct);
    }
  }

  void _afterFeedback(String? nextAct) {
    if (nextAct != null) {
      _goToAct(nextAct);
    } else {
      // re-enter interaction
      setState(() {
        _phase = _Phase.interaction;
        _feedbackDialogue = [];
        _feedbackIdx = 0;
      });
    }
  }

  // ── Success ────────────────────────────────────────────────────────────────
  void _onSuccess() {
    AudioManager().playSFX(SFXType.correct);
    final dial = _act.interaction.successDialogue;
    final next = _act.interaction.nextActOnSuccess;
    if (dial.isNotEmpty) {
      setState(() {
        _feedbackDialogue = dial;
        _feedbackIdx = 0;
        _pendingNextAct = next;
        _feedbackIsSuccess = true;
        _phase = _Phase.feedback;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playActiveDialogue();
      });
    } else {
      _goToAct(next);
    }
  }

  // ── Fail ───────────────────────────────────────────────────────────────────
  void _onFail() {
    AudioManager().playSFX(SFXType.error);
    _attempts++;
    final interaction = _act.interaction;
    final dial = interaction.getFailDialogue(_attempts);
    final fallback = interaction.isFallback(_attempts);
    final nextAct = interaction.getFailNextAct(_attempts);

    setState(() {
      _feedbackDialogue = dial;
      _feedbackIdx = 0;
      _pendingNextAct = fallback ? nextAct : null;
      _feedbackIsSuccess = false;
      _phase = _Phase.feedback;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playActiveDialogue();
    });
  }

  // ── Skip ───────────────────────────────────────────────────────────────────
  void _onSkip() {
    AudioManager().playSFX(SFXType.correct);
    final dial = _act.interaction.skipDialogue;
    final next = _act.interaction.nextActOnSkip;
    if (dial.isNotEmpty) {
      setState(() {
        _feedbackDialogue = dial;
        _feedbackIdx = 0;
        _pendingNextAct = next;
        _feedbackIsSuccess = true;
        _phase = _Phase.feedback;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playActiveDialogue();
      });
    } else {
      _goToAct(next);
    }
  }

  // ── Choice advance ─────────────────────────────────────────────────────────
  void _advanceChoiceDialogue() {
    if (_choiceDialogueIdx < _choiceDialogue.length - 1) {
      setState(() => _choiceDialogueIdx++);
      _playActiveDialogue();
    } else {
      _goToAct(_choiceNextAct);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _startListening() async {
    if (!_sttAvailable || _isListening) return;
    setState(() { _isListening = true; _lastSpeech = ''; });

    _sttSafetyTimer?.cancel();
    _sttSafetyTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isListening) {
        debugPrint('[STT] Safety timeout of 30s reached in Story Player');
        _stopListening();
      }
    });

    try {
      await _stt.listen(
        onResult: (result) {
          if (mounted) {
            setState(() => _lastSpeech = result.recognizedWords);
            if (result.finalResult) {
              debugPrint('[STT] finalResult received in Story Player: ${result.recognizedWords}');
              _stopListening();
            }
          }
        },
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 12),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('[STT] listen error in Story Player: $e');
    }
  }

  void _stopListening() {
    if (!_isListening) return;
    _sttSafetyTimer?.cancel();
    _sttSafetyTimer = null;
    _stt.stop();
    setState(() => _isListening = false);
    _validateSpeech();
  }

  void _validateSpeech() {
    final target = _act.interaction.targetPhrase.toLowerCase().trim();
    final heard = _lastSpeech.toLowerCase().trim();
    if (heard.isEmpty) { _onFail(); return; }

    // Word overlap strategy
    final targetWords = target
        .replaceAll(RegExp(r'[^a-záéíóúâêîôûãõç\s]', caseSensitive: false), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();
    final heardWords = heard
        .replaceAll(RegExp(r'[^a-záéíóúâêîôûãõç\s]', caseSensitive: false), '')
        .split(RegExp(r'\s+'))
        .toSet();

    int matches = 0;
    for (final tw in targetWords) {
      if (heardWords.any((hw) => hw.contains(tw) || tw.contains(hw))) {
        matches++;
      }
    }
    final ratio = targetWords.isEmpty ? 1.0 : matches / targetWords.length;
    final tolerance = _act.interaction.tolerance;

    // Also accept if heard text contains any part of target (for onomatopoeias)
    final heardContainsR = heard.contains(RegExp(r'r{2,}|rr', caseSensitive: false));
    final targetIsOnomatopoeia = target.length <= 8 &&
        !target.contains(' ') &&
        RegExp(r'[aeiouy]').allMatches(target).length < 2;

    final passed = ratio >= tolerance ||
        (targetIsOnomatopoeia && heardContainsR) ||
        heard.contains(target.split(' ').first.toLowerCase());

    if (passed) {
      _onSuccess();
    } else {
      _onFail();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = _bgGradients[_storyIndex % _bgGradients.length];

    if (_phase == _Phase.completed) {
      return _CompletionScreen(story: widget.story, colors: colors);
    }

    return Scaffold(
      backgroundColor: colors[2],
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _ProgressBar(
                  acts: widget.story.acts,
                  currentActId: _act.id,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _Content(
                    act: _act,
                    phase: _phase,
                    dialogueIdx: _dialogueIdx,
                    feedbackDialogue: _feedbackDialogue,
                    feedbackIdx: _feedbackIdx,
                    feedbackIsSuccess: _feedbackIsSuccess,
                    choiceDialogue: _choiceDialogue,
                    choiceDialogueIdx: _choiceDialogueIdx,
                    story: widget.story,
                    colors: colors,
                    onAdvanceDialogue: _advanceDialogue,
                    onAdvanceFeedback: _advanceFeedback,
                    onAdvanceChoiceDialogue: _advanceChoiceDialogue,
                    onSuccess: _onSuccess,
                    onFail: _onFail,
                    onSkip: _onSkip,
                    // Voice
                    isListening: _isListening,
                    lastSpeech: _lastSpeech,
                    sttAvailable: _sttAvailable,
                    onStartListening: _startListening,
                    onStopListening: _stopListening,
                    // Drag match
                    correctMatches: _correctMatches,
                    onMatchUpdate: (matches) => setState(() {
                      _correctMatches.clear();
                      _correctMatches.addAll(matches);
                    }),
                    onMatchComplete: _onSuccess,
                    onMatchFail: _onFail,
                    // Drag sequence
                    sequenceSlots: _sequenceSlots,
                    onSequenceUpdate: (slots) => setState(() {
                      _sequenceSlots.clear();
                      _sequenceSlots.addAll(slots);
                    }),
                    onSequenceComplete: _onSuccess,
                    onSequenceFail: _onFail,
                    // Drag path
                    traceNextNode: _traceNextNode,
                    tracePoints: _tracePoints,
                    onTracedNode: (i) => setState(() => _traceNextNode = i + 1),
                    onTraceComplete: _onSuccess,
                    onTracePointAdded: (p) => setState(() => _tracePoints.add(p)),
                    // Branching choice
                    onChoiceSelected: (optionRaw) {
                      final consequence = optionRaw['consequence'] as Map<String, dynamic>? ?? {};
                      final dial = (consequence['dialogue'] as List? ?? [])
                          .whereType<Map<String, dynamic>>()
                          .map(StoryDialogue.fromJson)
                          .toList();
                      final next = _act.interaction.nextActOnSuccess;
                      setState(() {
                        _choiceDialogue = dial;
                        _choiceDialogueIdx = 0;
                        _choiceNextAct = next;
                        _phase = _Phase.choiceDialogue;
                      });
                    },
                    // Creative
                    isRecording: _isRecording,
                    recordCountdown: _recordCountdown,
                    onStartRecording: _startRecording,
                    onStopRecording: _stopRecording,
                    drawStrokes: _drawStrokes,
                    currentStroke: _currentStroke,
                    brushColor: _brushColor,
                    onStrokeStart: (p) => setState(() { _currentStroke = [p]; }),
                    onStrokeUpdate: (p) => setState(() => _currentStroke.add(p)),
                    onStrokeEnd: () => setState(() {
                      if (_currentStroke.isNotEmpty) {
                        _drawStrokes.add(List.from(_currentStroke));
                        _currentStroke = [];
                      }
                    }),
                    onBrushColorChange: (c) => setState(() => _brushColor = c),
                    onCreativeComplete: _onSkip,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startRecording() {
    setState(() { _isRecording = true; _recordCountdown = _act.interaction.maxDuration; });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _recordCountdown--);
      if (_recordCountdown <= 0) { t.cancel(); _stopRecording(); }
    });
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    setState(() { _isRecording = false; _recordCountdown = 0; });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROGRESS BAR
// ═════════════════════════════════════════════════════════════════════════════
class _ProgressBar extends StatelessWidget {
  final List<StoryAct> acts;
  final String currentActId;
  final VoidCallback onBack;

  const _ProgressBar({required this.acts, required this.currentActId, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final current = acts.indexWhere((a) => a.id == currentActId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: List.generate(acts.length, (i) {
                final done = i < current;
                final active = i == current;
                return Expanded(
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: done || active
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${current + 1}/${acts.length}',
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13,
              color: Colors.white70, fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CONTENT — organiza os widgets por fase
// ═════════════════════════════════════════════════════════════════════════════
class _Content extends StatelessWidget {
  final StoryAct act;
  final StoryModel story;
  final _Phase phase;
  final int dialogueIdx;
  final List<StoryDialogue> feedbackDialogue;
  final int feedbackIdx;
  final bool feedbackIsSuccess;
  final List<StoryDialogue> choiceDialogue;
  final int choiceDialogueIdx;
  final List<Color> colors;

  final VoidCallback onAdvanceDialogue;
  final VoidCallback onAdvanceFeedback;
  final VoidCallback onAdvanceChoiceDialogue;
  final VoidCallback onSuccess;
  final VoidCallback onFail;
  final VoidCallback onSkip;

  // Voice
  final bool isListening;
  final String lastSpeech;
  final bool sttAvailable;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  // Drag match
  final Map<String, String> correctMatches;
  final void Function(Map<String, String>) onMatchUpdate;
  final VoidCallback onMatchComplete;
  final VoidCallback onMatchFail;

  // Drag sequence
  final Map<int, String> sequenceSlots;
  final void Function(Map<int, String>) onSequenceUpdate;
  final VoidCallback onSequenceComplete;
  final VoidCallback onSequenceFail;

  // Drag path
  final int traceNextNode;
  final List<Offset> tracePoints;
  final void Function(int) onTracedNode;
  final VoidCallback onTraceComplete;
  final void Function(Offset) onTracePointAdded;

  // Branching choice
  final void Function(Map<String, dynamic>) onChoiceSelected;

  // Creative
  final bool isRecording;
  final int recordCountdown;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final List<List<Offset>> drawStrokes;
  final List<Offset> currentStroke;
  final Color brushColor;
  final void Function(Offset) onStrokeStart;
  final void Function(Offset) onStrokeUpdate;
  final VoidCallback onStrokeEnd;
  final void Function(Color) onBrushColorChange;
  final VoidCallback onCreativeComplete;

  const _Content({
    required this.act,
    required this.story,
    required this.phase,
    required this.dialogueIdx,
    required this.feedbackDialogue,
    required this.feedbackIdx,
    required this.feedbackIsSuccess,
    required this.choiceDialogue,
    required this.choiceDialogueIdx,
    required this.colors,
    required this.onAdvanceDialogue,
    required this.onAdvanceFeedback,
    required this.onAdvanceChoiceDialogue,
    required this.onSuccess,
    required this.onFail,
    required this.onSkip,
    required this.isListening,
    required this.lastSpeech,
    required this.sttAvailable,
    required this.onStartListening,
    required this.onStopListening,
    required this.correctMatches,
    required this.onMatchUpdate,
    required this.onMatchComplete,
    required this.onMatchFail,
    required this.sequenceSlots,
    required this.onSequenceUpdate,
    required this.onSequenceComplete,
    required this.onSequenceFail,
    required this.traceNextNode,
    required this.tracePoints,
    required this.onTracedNode,
    required this.onTraceComplete,
    required this.onTracePointAdded,
    required this.onChoiceSelected,
    required this.isRecording,
    required this.recordCountdown,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.drawStrokes,
    required this.currentStroke,
    required this.brushColor,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
    required this.onBrushColorChange,
    required this.onCreativeComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Narrative text ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _NarrativeCard(act: act, colors: colors),
        ),
        const SizedBox(height: 12),
        // ── Dialogue or Interaction ──
        Expanded(
          child: switch (phase) {
            _Phase.dialogue => _DialogueArea(
                act: act,
                story: story,
                dialogueIdx: dialogueIdx,
                onTap: onAdvanceDialogue,
              ),
            _Phase.feedback => _DialogueArea(
                act: act,
                story: story,
                dialogueIdx: feedbackIdx,
                dialogues: feedbackDialogue,
                isSuccess: feedbackIsSuccess,
                onTap: onAdvanceFeedback,
              ),
            _Phase.choiceDialogue => _DialogueArea(
                act: act,
                story: story,
                dialogueIdx: choiceDialogueIdx,
                dialogues: choiceDialogue,
                isSuccess: true,
                onTap: onAdvanceChoiceDialogue,
              ),
            _Phase.interaction => _InteractionArea(
                act: act,
                story: story,
                colors: colors,
                isListening: isListening,
                lastSpeech: lastSpeech,
                sttAvailable: sttAvailable,
                onStartListening: onStartListening,
                onStopListening: onStopListening,
                correctMatches: correctMatches,
                onMatchUpdate: onMatchUpdate,
                onMatchComplete: onMatchComplete,
                onMatchFail: onMatchFail,
                sequenceSlots: sequenceSlots,
                onSequenceUpdate: onSequenceUpdate,
                onSequenceComplete: onSequenceComplete,
                onSequenceFail: onSequenceFail,
                traceNextNode: traceNextNode,
                tracePoints: tracePoints,
                onTracedNode: onTracedNode,
                onTraceComplete: onTraceComplete,
                onTracePointAdded: onTracePointAdded,
                onChoiceSelected: onChoiceSelected,
                isRecording: isRecording,
                recordCountdown: recordCountdown,
                onStartRecording: onStartRecording,
                onStopRecording: onStopRecording,
                drawStrokes: drawStrokes,
                currentStroke: currentStroke,
                brushColor: brushColor,
                onStrokeStart: onStrokeStart,
                onStrokeUpdate: onStrokeUpdate,
                onStrokeEnd: onStrokeEnd,
                onBrushColorChange: onBrushColorChange,
                onCreativeComplete: onCreativeComplete,
                onSkip: onSkip,
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// NARRATIVE CARD
// ═════════════════════════════════════════════════════════════════════════════
class _NarrativeCard extends StatelessWidget {
  final StoryAct act;
  final List<Color> colors;
  const _NarrativeCard({required this.act, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            act.title,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          _HighlightedText(
            text: act.text.narrative,
            highlights: act.text.highlightWords,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// highlighted text with word styling
class _HighlightedText extends StatelessWidget {
  final String text;
  final List<String> highlights;
  const _HighlightedText({required this.text, required this.highlights});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final spans = <InlineSpan>[];
        final words = line.split(' ');
        for (final word in words) {
          final clean = word.replaceAll(RegExp(r'[^\w\-]'), '');
          final isHigh = highlights.any((h) =>
              h.toLowerCase() == clean.toLowerCase() ||
              h.toLowerCase().contains(clean.toLowerCase()));
          spans.add(TextSpan(
            text: '$word ',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: isHigh ? FontWeight.w800 : FontWeight.w500,
              color: isHigh ? Colors.white : Colors.white.withOpacity(0.85),
              backgroundColor: isHigh ? Colors.white.withOpacity(0.15) : null,
            ),
          ));
        }
        return RichText(text: TextSpan(children: spans));
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIALOGUE AREA
// ═════════════════════════════════════════════════════════════════════════════
class _DialogueArea extends StatelessWidget {
  final StoryAct act;
  final StoryModel story;
  final int dialogueIdx;
  final List<StoryDialogue>? dialogues;
  final bool isSuccess;
  final VoidCallback onTap;

  const _DialogueArea({
    required this.act,
    required this.story,
    required this.dialogueIdx,
    this.dialogues,
    this.isSuccess = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dials = dialogues ?? act.dialogue;
    if (dials.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onTap());
      return const SizedBox.shrink();
    }
    final d = dials[dialogueIdx < dials.length ? dialogueIdx : dials.length - 1];
    final character = story.findCharacter(d.character);
    final emoji = character?.emoji ?? '🎤';
    final name = character?.name ?? d.character;
    final isLast = dialogueIdx >= dials.length - 1;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character bubble
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isSuccess ? Colors.greenAccent : Colors.white).withOpacity(0.35),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  d.text,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 16),
          // Next indicator
          if (isLast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continuar',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 600.ms)
          else
            Text(
              'Toque para continuar',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INTERACTION AREA — dispatches to the right widget by type
// ═════════════════════════════════════════════════════════════════════════════
class _InteractionArea extends StatelessWidget {
  final StoryAct act;
  final StoryModel story;
  final List<Color> colors;
  final bool isListening;
  final String lastSpeech;
  final bool sttAvailable;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final Map<String, String> correctMatches;
  final void Function(Map<String, String>) onMatchUpdate;
  final VoidCallback onMatchComplete;
  final VoidCallback onMatchFail;
  final Map<int, String> sequenceSlots;
  final void Function(Map<int, String>) onSequenceUpdate;
  final VoidCallback onSequenceComplete;
  final VoidCallback onSequenceFail;
  final int traceNextNode;
  final List<Offset> tracePoints;
  final void Function(int) onTracedNode;
  final VoidCallback onTraceComplete;
  final void Function(Offset) onTracePointAdded;
  final void Function(Map<String, dynamic>) onChoiceSelected;
  final bool isRecording;
  final int recordCountdown;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final List<List<Offset>> drawStrokes;
  final List<Offset> currentStroke;
  final Color brushColor;
  final void Function(Offset) onStrokeStart;
  final void Function(Offset) onStrokeUpdate;
  final VoidCallback onStrokeEnd;
  final void Function(Color) onBrushColorChange;
  final VoidCallback onCreativeComplete;
  final VoidCallback onSkip;

  const _InteractionArea({
    required this.act,
    required this.story,
    required this.colors,
    required this.isListening,
    required this.lastSpeech,
    required this.sttAvailable,
    required this.onStartListening,
    required this.onStopListening,
    required this.correctMatches,
    required this.onMatchUpdate,
    required this.onMatchComplete,
    required this.onMatchFail,
    required this.sequenceSlots,
    required this.onSequenceUpdate,
    required this.onSequenceComplete,
    required this.onSequenceFail,
    required this.traceNextNode,
    required this.tracePoints,
    required this.onTracedNode,
    required this.onTraceComplete,
    required this.onTracePointAdded,
    required this.onChoiceSelected,
    required this.isRecording,
    required this.recordCountdown,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.drawStrokes,
    required this.currentStroke,
    required this.brushColor,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
    required this.onBrushColorChange,
    required this.onCreativeComplete,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final inter = act.interaction;
    final isPairs = inter.items.isNotEmpty && inter.items.first.containsKey('correctPair');
    return switch (inter.type) {
      'touch_hold_breath' => _HoldBreathInteraction(
          instruction: inter.instruction,
          onComplete: onMatchComplete,
          onFail: onMatchFail,
          color: colors[0],
        ),
      'tap_rhythm_sequence' => _RhythmSequenceInteraction(
          instruction: inter.instruction,
          onComplete: onMatchComplete,
          onFail: onMatchFail,
          color: colors[0],
        ),
      'voice_trigger' => _VoiceTrigger(
          instruction: inter.instruction,
          targetPhrase: inter.targetPhrase,
          isListening: isListening,
          lastSpeech: lastSpeech,
          sttAvailable: sttAvailable,
          onStart: onStartListening,
          onStop: onStopListening,
          onSkip: onSkip,
          color: colors[0],
        ),
      'touch_drag' when inter.isDragPath => _DragPathInteraction(
          pathNodes: inter.pathNodes,
          instruction: inter.instruction,
          traceNextNode: traceNextNode,
          onTracedNode: onTracedNode,
          onComplete: onMatchComplete,
          onTracePointAdded: onTracePointAdded,
          tracePoints: tracePoints,
          color: colors[0],
        ),
      'touch_drag' when inter.isDragSequence => _DragSequenceInteraction(
          items: inter.items,
          instruction: inter.instruction,
          sequenceSlots: sequenceSlots,
          onUpdate: onSequenceUpdate,
          onComplete: onSequenceComplete,
          onFail: onSequenceFail,
          onSkip: onSkip,
          color: colors[0],
        ),
      'touch_drag' when isPairs => _DragPairsInteraction(
          items: inter.items,
          instruction: inter.instruction,
          onComplete: onMatchComplete,
          onFail: onMatchFail,
          onSkip: onSkip,
          color: colors[0],
        ),
      'touch_drag' => _DragMatchInteraction(
          items: inter.items,
          targets: inter.targets,
          instruction: inter.instruction,
          correctMatches: correctMatches,
          onUpdate: onMatchUpdate,
          onComplete: onMatchComplete,
          onFail: onMatchFail,
          onSkip: onSkip,
          color: colors[0],
        ),
      'branching_choice' => _BranchingChoice(
          options: inter.options,
          instruction: inter.instruction,
          onSelected: onChoiceSelected,
          color: colors[0],
        ),
      'creative_resolution' when inter.subtype == 'choice_of_two' => _ChoiceOfTwoInteraction(
          instruction: inter.instruction,
          options: inter.options,
          colors: colors,
          isRecording: isRecording,
          recordCountdown: recordCountdown,
          onStartRecording: onStartRecording,
          onStopRecording: onStopRecording,
          drawStrokes: drawStrokes,
          currentStroke: currentStroke,
          brushColor: brushColor,
          onStrokeStart: onStrokeStart,
          onStrokeUpdate: onStrokeUpdate,
          onStrokeEnd: onStrokeEnd,
          onBrushColorChange: onBrushColorChange,
          onDone: onCreativeComplete,
          onSkip: onSkip,
        ),
      'creative_resolution' when inter.subtype == 'drawing' => _DrawingInteraction(
          instruction: inter.instruction,
          brushColors: inter.brushColors,
          strokes: drawStrokes,
          currentStroke: currentStroke,
          selectedColor: brushColor,
          onStrokeStart: onStrokeStart,
          onStrokeUpdate: onStrokeUpdate,
          onStrokeEnd: onStrokeEnd,
          onColorChange: onBrushColorChange,
          onDone: onCreativeComplete,
          color: colors[0],
        ),
      'creative_resolution' when inter.subtype == 'music_selection_and_collection' => _MusicSelectionAndCollection(
          instruction: inter.instruction,
          musicOptions: (inter.raw['musicOptions'] as List? ?? []).whereType<Map<String, dynamic>>().toList(),
          collectable: inter.raw['collectable'] as Map<String, dynamic>? ?? {},
          onDone: onCreativeComplete,
          color: colors[0],
        ),
      _ => _VoiceRecordingInteraction(
          instruction: inter.instruction,
          prompt: inter.prompt,
          maxDuration: inter.maxDuration,
          isRecording: isRecording,
          countdown: recordCountdown,
          onStart: onStartRecording,
          onStop: onStopRecording,
          onDone: onCreativeComplete,
          color: colors[0],
        ),
    };
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VOICE TRIGGER
// ═════════════════════════════════════════════════════════════════════════════
class _VoiceTrigger extends StatelessWidget {
  final String instruction;
  final String targetPhrase;
  final bool isListening;
  final String lastSpeech;
  final bool sttAvailable;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onSkip;
  final Color color;

  const _VoiceTrigger({
    required this.instruction,
    required this.targetPhrase,
    required this.isListening,
    required this.lastSpeech,
    required this.sttAvailable,
    required this.onStart,
    required this.onStop,
    required this.onSkip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"$targetPhrase"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Mic button
          GestureDetector(
            onTap: isListening ? onStop : (sttAvailable ? onStart : onSkip),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? Colors.red.shade400 : color,
                boxShadow: [
                  BoxShadow(
                    color: (isListening ? Colors.red : color).withOpacity(0.45),
                    blurRadius: isListening ? 30 : 16,
                    spreadRadius: isListening ? 8 : 0,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 44,
              ),
            ).animate(
              onPlay: isListening
                  ? (c) => c.repeat(reverse: true)
                  : (c) => c.stop(),
            ).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.08, 1.08),
              duration: 600.ms,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isListening
                ? 'Ouvindo... Toque para parar'
                : sttAvailable
                    ? 'Toque no microfone e fale!'
                    : 'Microfone indisponível — toque para continuar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          if (lastSpeech.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ouvi: "$lastSpeech"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                color: Colors.white70, fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Pular',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DRAG MATCH (items → targets)
// ═════════════════════════════════════════════════════════════════════════════
class _DragMatchInteraction extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> targets;
  final String instruction;
  final Map<String, String> correctMatches;
  final void Function(Map<String, String>) onUpdate;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  final VoidCallback onSkip;
  final Color color;

  const _DragMatchInteraction({
    required this.items,
    required this.targets,
    required this.instruction,
    required this.correctMatches,
    required this.onUpdate,
    required this.onComplete,
    required this.onFail,
    required this.onSkip,
    required this.color,
  });

  @override
  State<_DragMatchInteraction> createState() => _DragMatchInteractionState();
}

class _DragMatchInteractionState extends State<_DragMatchInteraction> {
  // pending matches (not yet validated)
  final Map<String, String> _pending = {};
  String? _lastError;

  List<Map<String, dynamic>> get _unplacedItems =>
      widget.items.where((i) => !widget.correctMatches.containsKey(i['id'])).toList();

  void _checkAll() {
    if (_pending.length + widget.correctMatches.length < widget.items.length) return;
    final combined = {...widget.correctMatches, ..._pending};

    // validate pending
    bool allCorrect = true;
    for (final entry in _pending.entries) {
      final item = widget.items.firstWhere((i) => i['id'] == entry.key, orElse: () => {});
      if (item['correctTarget'] != entry.value) {
        allCorrect = false;
        break;
      }
    }
    if (allCorrect) {
      widget.onUpdate(combined);
      setState(() => _pending.clear());
      if (combined.length >= widget.items.length) widget.onComplete();
    } else {
      setState(() {
        _lastError = 'Ops! Um dos animais está no lugar errado!';
        _pending.clear();
      });
      widget.onFail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(widget.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          // Targets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.targets.map((t) {
              final placed = {...widget.correctMatches, ..._pending}.entries
                  .where((e) => e.value == t['id'])
                  .map((e) => e.key)
                  .toList();
              return DragTarget<String>(
                onWillAcceptWithDetails: (d) => !widget.correctMatches.containsKey(d.data),
                onAcceptWithDetails: (d) {
                  setState(() => _pending[d.data] = t['id'] as String);
                  _checkAll();
                },
                builder: (ctx, candidates, rejects) {
                  return Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: candidates.isNotEmpty
                          ? widget.color.withOpacity(0.3)
                          : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: placed.isNotEmpty
                            ? Colors.greenAccent
                            : widget.color.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (placed.isNotEmpty)
                          Text('✅', style: const TextStyle(fontSize: 28))
                        else
                          Icon(Icons.add_rounded,
                              color: Colors.white.withOpacity(0.5), size: 28),
                        const SizedBox(height: 4),
                        Text(
                          t['label'] as String? ?? '',
                          style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 12,
                            fontWeight: FontWeight.bold, color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Draggable items
          if (_unplacedItems.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _unplacedItems.map((item) {
                return Draggable<String>(
                  data: item['id'] as String,
                  feedback: _ItemChip(item: item, color: widget.color, opacity: 0.9),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _ItemChip(item: item, color: widget.color),
                  ),
                  child: _ItemChip(item: item, color: widget.color),
                );
              }).toList(),
            ),
          if (_lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_lastError!,
                  style: const TextStyle(color: Colors.orangeAccent,
                      fontFamily: 'Nunito', fontSize: 13)),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onSkip,
            child: Text('Pular', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                color: Colors.white.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color color;
  final double opacity;
  const _ItemChip({required this.item, required this.color, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.6), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_emojiForItem(item), style: const TextStyle(fontSize: 28)),
            Text(
              item['label'] as String? ?? '',
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 11,
                fontWeight: FontWeight.bold, color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emojiForItem(Map<String, dynamic> item) {
    final id = (item['id'] as String? ?? '').toLowerCase();
    if (id.contains('leao')) return '🦁';
    if (id.contains('sapo')) return '🐸';
    if (id.contains('passaro') || id.contains('piu')) return '🐦';
    if (id.contains('leite')) return '🥛';
    if (id.contains('mel')) return '🍯';
    if (id.contains('farinha')) return '🌾';
    if (id.contains('pimenta')) return '🌶️';
    return '🎯';
  }
}

class _DragPairsInteraction extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String instruction;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  final VoidCallback onSkip;
  final Color color;

  const _DragPairsInteraction({
    required this.items,
    required this.instruction,
    required this.onComplete,
    required this.onFail,
    required this.onSkip,
    required this.color,
  });

  @override
  State<_DragPairsInteraction> createState() => _DragPairsInteractionState();
}

class _DragPairsInteractionState extends State<_DragPairsInteraction> {
  late List<Map<String, dynamic>> _unplaced;
  final Map<int, List<Map<String, dynamic>>> _slots = {0: [], 1: [], 2: []};
  final Set<int> _completedSlots = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _unplaced = List.from(widget.items);
  }

  void _onAccept(int slotIdx, Map<String, dynamic> item) {
    if (_completedSlots.contains(slotIdx)) return;
    setState(() {
      _slots[slotIdx]!.add(item);
      _unplaced.removeWhere((i) => i['id'] == item['id']);
      _error = null;
    });

    final slotItems = _slots[slotIdx]!;
    if (slotItems.length == 2) {
      final item1 = slotItems[0];
      final item2 = slotItems[1];
      final matches = item1['correctPair'] == item2['id'] || item1['rhymeGroup'] == item2['rhymeGroup'];
      if (matches) {
        setState(() {
          _completedSlots.add(slotIdx);
        });
        AudioManager().playSFX(SFXType.correct);
        if (_completedSlots.length == 3) {
          widget.onComplete();
        }
      } else {
        AudioManager().playSFX(SFXType.error);
        setState(() {
          _error = 'Ops! "${item1['label']}" e "${item2['label']}" não rimam!';
        });
        // Recua após atraso curto para que a criança veja o erro
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _slots[slotIdx]!.clear();
            _unplaced.add(item1);
            _unplaced.add(item2);
            _error = null;
          });
          widget.onFail();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            widget.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Canteiros (Slots)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) {
              final isLocked = _completedSlots.contains(i);
              final slotItems = _slots[i] ?? [];
              return DragTarget<Map<String, dynamic>>(
                onWillAcceptWithDetails: (details) {
                  return !isLocked && slotItems.length < 2 && !_slots.values.any((list) => list.any((item) => item['id'] == details.data['id']));
                },
                onAcceptWithDetails: (details) => _onAccept(i, details.data),
                builder: (ctx, candidates, _) {
                  return Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      color: candidates.isNotEmpty
                          ? widget.color.withOpacity(0.35)
                          : (isLocked ? Colors.green.withOpacity(0.15) : Colors.white.withOpacity(0.10)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLocked
                            ? Colors.greenAccent
                            : (candidates.isNotEmpty ? Colors.white : widget.color.withOpacity(0.40)),
                        width: 2.5,
                      ),
                      boxShadow: [
                        if (isLocked)
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: isLocked
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🌸', style: TextStyle(fontSize: 36))
                                        .animate()
                                        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), curve: Curves.bounceOut, duration: 600.ms),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${slotItems[0]['label']}\n❤\n${slotItems[1]['label']}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(2, (slotIdx) {
                                    final hasItem = slotIdx < slotItems.length;
                                    return Container(
                                      width: 80,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: hasItem ? widget.color.withOpacity(0.2) : Colors.black.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: hasItem ? widget.color : Colors.white24,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: hasItem
                                            ? Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(_emojiForJardimItem(slotItems[slotIdx]), style: const TextStyle(fontSize: 18)),
                                                  Text(
                                                    slotItems[slotIdx]['label'] as String? ?? '',
                                                    style: const TextStyle(
                                                      fontFamily: 'Nunito',
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Icon(Icons.add_rounded, color: Colors.white30, size: 20),
                                      ),
                                    );
                                  }),
                                ),
                        ),
                        Positioned(
                          top: 4,
                          left: 8,
                          child: Text(
                            'Canteiro ${i + 1}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? Colors.greenAccent : Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 24),
          // Unplaced Draggables
          if (_unplaced.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _unplaced.map((item) {
                return Draggable<Map<String, dynamic>>(
                  data: item,
                  feedback: _JardimSeedChip(item: item, color: widget.color, opacity: 0.9),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _JardimSeedChip(item: item, color: widget.color),
                  ),
                  child: _JardimSeedChip(item: item, color: widget.color),
                );
              }).toList(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Pular canteiro',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _emojiForJardimItem(Map<String, dynamic> item) {
    final id = (item['id'] as String? ?? '').toLowerCase();
    if (id.contains('flor')) return '🌸';
    if (id.contains('amor')) return '💖';
    if (id.contains('lua')) return '🌙';
    if (id.contains('chuva')) return '🌧️';
    if (id.contains('sol')) return '☀️';
    if (id.contains('caracol')) return '🐌';
    return '🌱';
  }
}

class _JardimSeedChip extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color color;
  final double opacity;

  const _JardimSeedChip({required this.item, required this.color, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 84,
        height: 72,
        decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.6), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_DragPairsInteractionState._emojiForJardimItem(item), style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              item['label'] as String? ?? '',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DRAG SEQUENCE (items with correctOrder → numbered slots)
// ═════════════════════════════════════════════════════════════════════════════
class _DragSequenceInteraction extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String instruction;
  final Map<int, String> sequenceSlots;
  final void Function(Map<int, String>) onUpdate;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  final VoidCallback onSkip;
  final Color color;

  const _DragSequenceInteraction({
    required this.items,
    required this.instruction,
    required this.sequenceSlots,
    required this.onUpdate,
    required this.onComplete,
    required this.onFail,
    required this.onSkip,
    required this.color,
  });

  @override
  State<_DragSequenceInteraction> createState() =>
      _DragSequenceInteractionState();
}

class _DragSequenceInteractionState extends State<_DragSequenceInteraction> {
  Map<int, String> _slots = {};
  String? _error;

  List<Map<String, dynamic>> get _realItems =>
      widget.items.where((i) => i['correctOrder'] != null).toList();

  List<Map<String, dynamic>> get _unplaced =>
      _realItems.where((i) => !_slots.values.contains(i['id'])).toList();

  void _checkComplete() {
    if (_slots.length < _realItems.length) return;
    bool correct = true;
    for (final item in _realItems) {
      final expectedSlot = (item['correctOrder'] as num).toInt();
      if (_slots[expectedSlot] != item['id']) {
        correct = false;
        break;
      }
    }
    if (correct) {
      widget.onUpdate(_slots);
      widget.onComplete();
    } else {
      setState(() {
        _error = 'Hmm! A ordem não está certa. Tente novamente!';
        _slots = {};
      });
      widget.onFail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(widget.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          // Slots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_realItems.length, (i) {
              final slotNum = i + 1;
              final placedId = _slots[slotNum];
              final placedItem = placedId != null
                  ? _realItems.firstWhere((it) => it['id'] == placedId, orElse: () => {})
                  : null;
              return DragTarget<String>(
                onWillAcceptWithDetails: (d) => !_slots.values.contains(d.data),
                onAcceptWithDetails: (d) {
                  setState(() => _slots[slotNum] = d.data);
                  _checkComplete();
                },
                builder: (ctx, candidates, _) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: candidates.isNotEmpty
                          ? widget.color.withOpacity(0.3)
                          : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: placedItem != null
                            ? Colors.greenAccent
                            : widget.color.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: placedItem != null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _emojiForItem(placedItem),
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    Text(
                                      placedItem['label'] as String? ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  '$slotNum',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 4,
                          left: 6,
                          child: Text(
                            '$slotNum',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          if (_unplaced.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _unplaced.map((item) {
                return Draggable<String>(
                  data: item['id'] as String,
                  feedback: _SequenceChip(item: item, color: widget.color, opacity: 0.9),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _SequenceChip(item: item, color: widget.color),
                  ),
                  child: _SequenceChip(item: item, color: widget.color),
                );
              }).toList(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.orangeAccent,
                      fontFamily: 'Nunito', fontSize: 13)),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onSkip,
            child: Text('Pular', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                color: Colors.white.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }

  String _emojiForItem(Map<String, dynamic> item) {
    final id = (item['id'] as String? ?? '').toLowerCase();
    if (id.contains('leite')) return '🥛';
    if (id.contains('mel')) return '🍯';
    if (id.contains('farinha')) return '🌾';
    return '🧪';
  }
}

class _SequenceChip extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color color;
  final double opacity;
  const _SequenceChip({required this.item, required this.color, this.opacity = 1.0});

  static String _emojiForItem(Map<String, dynamic> item) {
    final id = (item['id'] as String? ?? '').toLowerCase();
    if (id.contains('leite')) return '🥛';
    if (id.contains('mel')) return '🍯';
    if (id.contains('farinha')) return '🌾';
    if (id.contains('pimenta')) return '🌶️';
    return '🧪';
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.6), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_emojiForItem(item), style: const TextStyle(fontSize: 24)),
            Text(
              item['label'] as String? ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 10,
                fontWeight: FontWeight.bold, color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DRAG PATH (trace through nodes)
// ═════════════════════════════════════════════════════════════════════════════
class _DragPathInteraction extends StatelessWidget {
  final List<Map<String, dynamic>> pathNodes;
  final String instruction;
  final int traceNextNode;
  final void Function(int) onTracedNode;
  final VoidCallback onComplete;
  final void Function(Offset) onTracePointAdded;
  final List<Offset> tracePoints;
  final Color color;

  const _DragPathInteraction({
    required this.pathNodes,
    required this.instruction,
    required this.traceNextNode,
    required this.onTracedNode,
    required this.onComplete,
    required this.onTracePointAdded,
    required this.tracePoints,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(builder: (ctx, constraints) {
              return GestureDetector(
                onPanUpdate: (d) {
                  onTracePointAdded(d.localPosition);
                  // Check if any untraced node is near the finger
                  if (traceNextNode < pathNodes.length) {
                    final node = pathNodes[traceNextNode];
                    final pos = Offset(
                      (node['position']['x'] as num).toDouble() * constraints.maxWidth,
                      (node['position']['y'] as num).toDouble() * constraints.maxHeight,
                    );
                    if ((d.localPosition - pos).distance < 36) {
                      onTracedNode(traceNextNode);
                      if (traceNextNode + 1 >= pathNodes.length) onComplete();
                    }
                  }
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _PathPainter(
                    nodes: pathNodes,
                    tracedCount: traceNextNode,
                    tracePoints: tracePoints,
                    color: color,
                  ),
                ),
              );
            }),
          ),
          Text(
            'Trace o caminho tocando nas estrelas em ordem!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito', fontSize: 12,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Map<String, dynamic>> nodes;
  final int tracedCount;
  final List<Offset> tracePoints;
  final Color color;

  const _PathPainter({
    required this.nodes,
    required this.tracedCount,
    required this.tracePoints,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw trace trail
    if (tracePoints.length > 1) {
      final tracePaint = Paint()
        ..color = color.withOpacity(0.5)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = ui.Path();
      path.moveTo(tracePoints.first.dx, tracePoints.first.dy);
      for (final p in tracePoints.skip(1)) path.lineTo(p.dx, p.dy);
      canvas.drawPath(path, tracePaint);
    }

    // Draw connections
    if (nodes.length > 1) {
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < nodes.length - 1; i++) {
        final a = _nodePos(nodes[i], size);
        final b = _nodePos(nodes[i + 1], size);
        canvas.drawLine(a, b, linePaint);
      }
    }

    // Draw nodes
    for (int i = 0; i < nodes.length; i++) {
      final pos = _nodePos(nodes[i], size);
      final traced = i < tracedCount;
      final active = i == tracedCount;

      // Glow for active
      if (active) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(pos, 28, glowPaint);
      }

      // Circle
      final circlePaint = Paint()
        ..color = traced ? Colors.greenAccent : (active ? color : Colors.white.withOpacity(0.3));
      canvas.drawCircle(pos, 22, circlePaint);

      // Label
      final nodeMap = nodes[i];
      final label = nodeMap['label'] as String? ?? '';
      final nodeColor = nodeMap['color'] as String?;
      final textColor = traced || active ? const Color(0xFF0F0A1E) : Colors.white70;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  Offset _nodePos(Map<String, dynamic> node, Size size) {
    final pos = node['position'] as Map<String, dynamic>? ?? {};
    return Offset(
      (pos['x'] as num?)?.toDouble() ?? 0.5 * size.width,
      (pos['y'] as num?)?.toDouble() ?? 0.5 * size.height,
    );
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.tracedCount != tracedCount || old.tracePoints.length != tracePoints.length;
}

// ═════════════════════════════════════════════════════════════════════════════
// BRANCHING CHOICE
// ═════════════════════════════════════════════════════════════════════════════
class _BranchingChoice extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String instruction;
  final void Function(Map<String, dynamic>) onSelected;
  final Color color;

  const _BranchingChoice({
    required this.options,
    required this.instruction,
    required this.onSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 16,
                  fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          ...options.asMap().entries.map((entry) {
            final opt = entry.value;
            final isLeft = entry.key % 2 == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => onSelected(opt),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.35),
                        color.withOpacity(0.15),
                      ],
                      begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                      end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _choiceEmoji(opt['id'] as String? ?? ''),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt['label'] as String? ?? '',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 18),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms)
                    .slideX(begin: isLeft ? -0.05 : 0.05, end: 0),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _choiceEmoji(String id) {
    final low = id.toLowerCase();
    if (low.contains('leao')) return '🦁';
    if (low.contains('sapo')) return '🐸';
    if (low.contains('rapida') || low.contains('fast')) return '⚡';
    if (low.contains('turistica') || low.contains('scenic')) return '🌟';
    if (low.contains('doce')) return '🍰';
    if (low.contains('salgado')) return '🧀';
    return '✨';
  }
}

class _ChoiceOfTwoInteraction extends StatefulWidget {
  final String instruction;
  final List<Map<String, dynamic>> options;
  final List<Color> colors;

  // Voice recording props
  final bool isRecording;
  final int recordCountdown;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  // Drawing props
  final List<List<Offset>> drawStrokes;
  final List<Offset> currentStroke;
  final Color brushColor;
  final void Function(Offset) onStrokeStart;
  final void Function(Offset) onStrokeUpdate;
  final VoidCallback onStrokeEnd;
  final void Function(Color) onBrushColorChange;

  // General callbacks
  final VoidCallback onDone;
  final VoidCallback onSkip;

  const _ChoiceOfTwoInteraction({
    required this.instruction,
    required this.options,
    required this.colors,
    required this.isRecording,
    required this.recordCountdown,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.drawStrokes,
    required this.currentStroke,
    required this.brushColor,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
    required this.onBrushColorChange,
    required this.onDone,
    required this.onSkip,
  });

  @override
  State<_ChoiceOfTwoInteraction> createState() => _ChoiceOfTwoInteractionState();
}

class _ChoiceOfTwoInteractionState extends State<_ChoiceOfTwoInteraction> {
  String? _selectedOptionId;

  @override
  Widget build(BuildContext context) {
    if (_selectedOptionId == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: widget.options.map((opt) {
                final isVoice = opt['subtype'] == 'voice_recording';
                final color = isVoice ? const Color(0xFFEC4899) : const Color(0xFF4ECDC4);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOptionId = opt['id'] as String),
                    child: Container(
                      height: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: color.withOpacity(0.6), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.15),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isVoice ? '🎤' : '🎨', style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            opt['label'] as String? ?? '',
                            textAlign: TextAlign.center,
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
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: widget.onSkip,
              child: Text(
                'Pular atividade',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedOpt = widget.options.firstWhere((o) => o['id'] == _selectedOptionId);
    final isVoice = selectedOpt['subtype'] == 'voice_recording';

    return Column(
      children: [
        // Botão para voltar à escolha
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedOptionId = null),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70),
              label: const Text(
                'Escolher outro',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ),
        Expanded(
          child: isVoice
              ? _VoiceRecordingInteraction(
                  instruction: selectedOpt['instruction'] as String? ?? widget.instruction,
                  prompt: selectedOpt['prompt'] as String? ?? 'Fale...',
                  maxDuration: (selectedOpt['maxDuration'] as num?)?.toInt() ?? 20,
                  isRecording: widget.isRecording,
                  countdown: widget.recordCountdown,
                  onStart: widget.onStartRecording,
                  onStop: widget.onStopRecording,
                  onDone: widget.onDone,
                  color: widget.colors[0],
                )
              : _DrawingInteraction(
                  instruction: selectedOpt['instruction'] as String? ?? widget.instruction,
                  brushColors: (selectedOpt['canvas']?['brushColors'] as List? ?? []).map((c) => c.toString()).toList(),
                  strokes: widget.drawStrokes,
                  currentStroke: widget.currentStroke,
                  selectedColor: widget.brushColor,
                  onStrokeStart: widget.onStrokeStart,
                  onStrokeUpdate: widget.onStrokeUpdate,
                  onStrokeEnd: widget.onStrokeEnd,
                  onColorChange: widget.onBrushColorChange,
                  onDone: widget.onDone,
                  color: widget.colors[0],
                ),
        ),
      ],
    );
  }
}

class _MusicSelectionAndCollection extends StatefulWidget {
  final String instruction;
  final List<Map<String, dynamic>> musicOptions;
  final Map<String, dynamic> collectable;
  final VoidCallback onDone;
  final Color color;

  const _MusicSelectionAndCollection({
    required this.instruction,
    required this.musicOptions,
    required this.collectable,
    required this.onDone,
    required this.color,
  });

  @override
  State<_MusicSelectionAndCollection> createState() => _MusicSelectionAndCollectionState();
}

class _MusicSelectionAndCollectionState extends State<_MusicSelectionAndCollection> {
  String? _selectedMusicId;

  @override
  Widget build(BuildContext context) {
    final rhymePairs = widget.collectable['rhymePairs'] as List? ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Instruction
          Text(
            widget.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Bouquet Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0.35),
                  widget.color.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.color.withOpacity(0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🌸', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 8),
                    Text(
                      'Buquê de Rimas',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('🌸', style: TextStyle(fontSize: 26)),
                  ],
                ),
                const SizedBox(height: 12),
                ...rhymePairs.map((pair) {
                  final words = pair.toString().split('/');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        words.join(' ❤ '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 20),
          // Music title
          const Text(
            'Escolha uma música para o seu jardim:',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          // Music Options row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.musicOptions.map((opt) {
              final isSelected = _selectedMusicId == opt['id'];
              final icon = opt['icon'] as String? ?? '🎵';
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMusicId = opt['id'] as String);
                  AudioManager().playSFX(SFXType.balloons); // Delightful SFX preview feedback!
                },
                child: Container(
                  width: 86,
                  height: 94,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.color.withOpacity(0.35)
                        : Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.greenAccent : Colors.white24,
                      width: 2.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.25),
                          blurRadius: 10,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(
                        opt['label'] as String? ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade400,
              foregroundColor: const Color(0xFF0F0A1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Pronto! Salvar',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.04, 1.04), duration: 1000.ms),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CREATIVE — VOICE RECORDING
// ═════════════════════════════════════════════════════════════════════════════
class _VoiceRecordingInteraction extends StatelessWidget {
  final String instruction;
  final String prompt;
  final int maxDuration;
  final bool isRecording;
  final int countdown;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onDone;
  final Color color;

  const _VoiceRecordingInteraction({
    required this.instruction,
    required this.prompt,
    required this.maxDuration,
    required this.isRecording,
    required this.countdown,
    required this.onStart,
    required this.onStop,
    required this.onDone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 16,
                  fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(prompt, textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                    fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.8))),
          ),
          const SizedBox(height: 24),
          // Mic button
          GestureDetector(
            onTap: isRecording ? onStop : onStart,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red.shade400 : color,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? Colors.red : color).withOpacity(0.45),
                    blurRadius: isRecording ? 30 : 16,
                    spreadRadius: isRecording ? 8 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white, size: 36),
                  if (isRecording)
                    Text('$countdown',
                        style: const TextStyle(fontFamily: 'Nunito',
                            fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isRecording ? 'Gravando... toque para parar' : 'Toque para gravar!',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                color: Colors.white.withOpacity(0.7)),
          ),
          if (!isRecording) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onDone,
              child: Text('Pular gravação',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                      color: Colors.white.withOpacity(0.5))),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade400,
                foregroundColor: const Color(0xFF0F0A1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 20),
                  SizedBox(width: 6),
                  Text('Pronto!', style: TextStyle(fontFamily: 'Nunito',
                      fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CREATIVE — DRAWING
// ═════════════════════════════════════════════════════════════════════════════
class _DrawingInteraction extends StatelessWidget {
  final String instruction;
  final List<String> brushColors;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color selectedColor;
  final void Function(Offset) onStrokeStart;
  final void Function(Offset) onStrokeUpdate;
  final VoidCallback onStrokeEnd;
  final void Function(Color) onColorChange;
  final VoidCallback onDone;
  final Color color;

  const _DrawingInteraction({
    required this.instruction,
    required this.brushColors,
    required this.strokes,
    required this.currentStroke,
    required this.selectedColor,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
    required this.onColorChange,
    required this.onDone,
    required this.color,
  });

  Color _parseHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = brushColors.isNotEmpty
        ? brushColors
        : ['#FF6B6B', '#4ECDC4', '#FFE66D', '#A8E6CF', '#FF8B94'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          // Canvas
          Expanded(
            child: GestureDetector(
              onPanStart: (d) => onStrokeStart(d.localPosition),
              onPanUpdate: (d) => onStrokeUpdate(d.localPosition),
              onPanEnd: (_) => onStrokeEnd(),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.5), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CustomPaint(
                    painter: _DrawingPainter(
                      strokes: strokes,
                      currentStroke: currentStroke,
                      color: selectedColor,
                    ),
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Color palette
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: palette.map((hex) {
              final c = _parseHex(hex);
              return GestureDetector(
                onTap: () => onColorChange(c),
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedColor == c ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(color: c.withOpacity(0.4), blurRadius: 6),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade400,
              foregroundColor: const Color(0xFF0F0A1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, size: 18),
                SizedBox(width: 6),
                Text('Pronto!', style: TextStyle(fontFamily: 'Nunito',
                    fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color color;

  const _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    void drawStroke(List<Offset> pts, Color c) {
      if (pts.length < 2) return;
      final paint = Paint()
        ..color = c
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = ui.Path();
      path.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) path.lineTo(p.dx, p.dy);
      canvas.drawPath(path, paint);
    }

    for (final s in strokes) drawStroke(s, color);
    drawStroke(currentStroke, color);
  }

  @override
  bool shouldRepaint(_DrawingPainter old) =>
      old.strokes.length != strokes.length ||
      old.currentStroke.length != currentStroke.length;
}

// ═════════════════════════════════════════════════════════════════════════════
// COMPLETION SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _CompletionScreen extends StatelessWidget {
  final StoryModel story;
  final List<Color> colors;

  const _CompletionScreen({required this.story, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors[2],
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 72))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1),
                        duration: 800.ms),
                const SizedBox(height: 16),
                const Text(
                  'História Concluída!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  story.metadata.title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 32),
                // Rewards
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RewardChip(icon: '⭐', label: '+${story.rewards.xp} XP',
                        color: const Color(0xFFFBBF24)),
                    const SizedBox(width: 12),
                    _RewardChip(icon: '🪙', label: '+${story.rewards.coins}',
                        color: const Color(0xFF06B6D4)),
                  ],
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colors[0],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Voltar às Histórias',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ).animate().fadeIn(duration: 700.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _RewardChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          )),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HOLD BREATH INTERACTION (touch_hold_breath)
// ═════════════════════════════════════════════════════════════════════════════
class _HoldBreathInteraction extends StatefulWidget {
  final String instruction;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  final Color color;

  const _HoldBreathInteraction({
    required this.instruction,
    required this.onComplete,
    required this.onFail,
    required this.color,
  });

  @override
  State<_HoldBreathInteraction> createState() => _HoldBreathInteractionState();
}

class _HoldBreathInteractionState extends State<_HoldBreathInteraction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;
  int _completedCycles = 0;
  String _statusText = 'Toque e segure para respirar';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4 seconds in, 4 seconds out
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isHolding) {
          HapticFeedback.mediumImpact();
          _controller.reverse();
          setState(() {
            _statusText = 'Solte devagar... expire...';
          });
        } else {
          _controller.stop();
        }
      } else if (status == AnimationStatus.dismissed) {
        if (_isHolding) {
          HapticFeedback.mediumImpact();
          _controller.forward();
          setState(() {
            _completedCycles++;
            _statusText = 'Respire fundo... inspire...';
          });
          if (_completedCycles >= 3) {
            widget.onComplete();
          }
        } else {
          _controller.stop();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_completedCycles >= 3) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isHolding = true;
      _statusText = 'Respire fundo... inspire...';
    });
    _controller.forward(from: _controller.value);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_completedCycles >= 3) return;
    setState(() {
      _isHolding = false;
      _statusText = 'Não pare agora! Segure para respirar';
    });
    _controller.animateTo(0.0, duration: const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Progress Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final active = index < _completedCycles;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.greenAccent : Colors.white24,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          // The Breath Circle
          Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 1.0 + (_controller.value * 0.6);
                final opacity = 0.2 + (_controller.value * 0.3);
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glowing wave
                      Container(
                        width: 140 * scale,
                        height: 140 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withOpacity(opacity),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.4),
                              blurRadius: 30 * scale,
                              spreadRadius: 5 * scale,
                            ),
                          ],
                        ),
                      ),
                      // Inner button
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isHolding
                                ? [Colors.greenAccent, Colors.teal]
                                : [widget.color, widget.color.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isHolding ? Colors.teal : widget.color)
                                  .withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.umbrella_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Status Text
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RHYTHM SEQUENCE INTERACTION (tap_rhythm_sequence)
// ═════════════════════════════════════════════════════════════════════════════
class _RhythmSequenceInteraction extends StatefulWidget {
  final String instruction;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  final Color color;

  const _RhythmSequenceInteraction({
    required this.instruction,
    required this.onComplete,
    required this.onFail,
    required this.color,
  });

  @override
  State<_RhythmSequenceInteraction> createState() => _RhythmSequenceInteractionState();
}

class _RhythmSequenceInteractionState extends State<_RhythmSequenceInteraction> {
  final List<String> _target = ['ping', 'pong', 'plim'];
  final List<String> _currentInput = [];
  int _activePulseIndex = -1; // Index of drop to pulse if they make a mistake

  void _onDropTap(String type) {
    HapticFeedback.mediumImpact();
    // Play distinctive sound based on drop
    if (type == 'ping') {
      AudioManager().playSFX(SFXType.correct); // Play a sweet pitch chime
    } else if (type == 'pong') {
      AudioManager().playSFX(SFXType.correct);
    } else {
      AudioManager().playSFX(SFXType.correct);
    }

    setState(() {
      _currentInput.add(type);
      _activePulseIndex = -1;
    });

    // Check progress
    final currentIdx = _currentInput.length - 1;
    if (_currentInput[currentIdx] != _target[currentIdx]) {
      // Mistake!
      HapticFeedback.vibrate();
      setState(() {
        _currentInput.clear();
        // Guide them: highlight correct drop index (PING)
        _activePulseIndex = 0;
      });
      widget.onFail();
    } else if (_currentInput.length == _target.length) {
      // Success!
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Sequence Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_target.length, (idx) {
              final done = idx < _currentInput.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 32,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: done ? Colors.greenAccent : Colors.white24,
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          // The Cloud + Hanging Raindrops
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // Cloud visual representation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_queue_rounded, size: 54, color: Colors.white70)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .slideY(begin: 0, end: -0.05, duration: 2.seconds),
                  ],
                ),
                const SizedBox(height: 24),
                // Drops
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRaindrop('PING', Colors.blue.shade300, 'ping', 0),
                    _buildRaindrop('PONG', Colors.green.shade300, 'pong', 1),
                    _buildRaindrop('PLIM', Colors.amber.shade300, 'plim', 2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaindrop(String label, Color color, String type, int index) {
    final shouldPulse = _activePulseIndex == index;
    return GestureDetector(
      onTap: () => _onDropTap(type),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 98,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(38),
                topRight: Radius.circular(38),
                bottomLeft: Radius.circular(38),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ).animate(
            onPlay: shouldPulse ? (c) => c.repeat(reverse: true) : null,
          ).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.15, 1.15),
            duration: 600.ms,
          ),
          const SizedBox(height: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
