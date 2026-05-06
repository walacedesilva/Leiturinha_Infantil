import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/word_bank.dart';
import '../../../services/audio_manager.dart';
import '../../../services/gamification_service.dart';
import '../../../services/gamification_models.dart';
import '../../../services/progress_service.dart';
import '../../../services/speech_validator.dart';

/// Estados possíveis do jogo para uma palavra
enum GameState {
  assembling,    // Criança está montando a palavra
  completed,     // Palavra montada — aguarda interação manual
  validating,    // Microfone ativo — ouvindo a pronúncia
  validated,     // Resultado de validação disponível
  familyDone,    // Todas as palavras da família foram concluídas
}

/// Controlador de jogo por família silábica.
/// Não avança automaticamente: aguarda chamada explícita de [goToNextWord].
class GameLogic extends ChangeNotifier {
  final ProgressService _progressService;
  final AudioManager _audioManager;
  final GamificationService gamification;

  // Família atual (definida ao entrar na tela de jogo)
  late SyllabicFamily _family;
  late List<WordEntry> _pendingWords;
  int _currentIndex = 0;

  // Estado da palavra atual
  GameState _state = GameState.assembling;
  String _currentWord = '';
  List<String> _targetSyllables = [];
  List<String> _availableSyllables = [];
  List<String?> _placedSyllables = [];

  // Debounce para playFormedWord
  DateTime? _lastWordPlay;

  // Config da sessão (pode ser dual-family)
  DualFamilyConfig? _dualConfig;

  // Validação fonética
  ValidationResult? _lastValidation;
  String _partialTranscript = '';
  int _validationAttempts = 0;
  static const int _maxAttempts = 3;
  ValidationLevel validationLevel = ValidationLevel.beginner;

  // ────────────────────────────────────────────────
  // GETTERS
  // ────────────────────────────────────────────────

  String get currentWord => _currentWord;
  SyllabicFamily get family => _family;
  String get sessionLabel => _dualConfig?.displayLabel ?? _family.label;
  List<String> get availableSyllables => List.unmodifiable(_availableSyllables);
  List<String?> get placedSyllables => List.unmodifiable(_placedSyllables);
  List<String> get targetSyllables => List.unmodifiable(_targetSyllables);
  GameState get state => _state;
  bool get isCompleted => _state == GameState.completed;
  bool get isValidating => _state == GameState.validating;
  bool get isValidated => _state == GameState.validated;
  bool get isFamilyDone => _state == GameState.familyDone;
  int get wordIndex => _currentIndex;
  int get totalWords => _pendingWords.length;
  ValidationResult? get lastValidation => _lastValidation;
  String get partialTranscript => _partialTranscript;
  int get validationAttempts => _validationAttempts;
  bool get canRetryValidation => _validationAttempts < _maxAttempts;

  // ────────────────────────────────────────────────
  // INICIALIZAÇÃO
  // ────────────────────────────────────────────────

  // Último evento de recompensa (para exibir animação na UI)
  RewardEvent? lastReward;

  GameLogic(this._progressService, this._audioManager, this.gamification);

  /// Inicializa com uma família silábica específica.
  /// Filtra palavras já concluídas para retomar de onde parou.
  void initWithFamily(SyllabicFamily family) {
    _family = family;
    final completed = _progressService.getCompletedWords(family.key);

    // Palavras ainda não concluídas ficam pendentes
    _pendingWords = family.words
        .where((e) => !completed.contains(e.word))
        .toList();

    _currentIndex = 0;

    if (_pendingWords.isEmpty) {
      // Família já completa — mostrar tela de conclusão
      _state = GameState.familyDone;
      _currentWord = '';
      notifyListeners();
    } else {
      _loadCurrentWord();
    }
  }

  void _loadCurrentWord() {
    final entry = _pendingWords[_currentIndex];
    _currentWord = entry.word;
    _targetSyllables = List<String>.from(entry.syllables);
    _placedSyllables = List<String?>.filled(_targetSyllables.length, null);
    _availableSyllables = List<String>.from(_targetSyllables)..shuffle(Random());
    _state = GameState.assembling;
    _lastValidation = null;
    _partialTranscript = '';
    _validationAttempts = 0;
    notifyListeners();
  }

  // ────────────────────────────────────────────────
  // INTERAÇÕES DE JOGO
  // ────────────────────────────────────────────────

  /// Tenta encaixar uma sílaba num slot. Ignorado se palavra já completa.
  void onSyllableDropped(String syllable, int slotIndex) {
    if (_state != GameState.assembling) return;

    if (_targetSyllables[slotIndex] == syllable) {
      // Sílaba correta
      _placedSyllables[slotIndex] = syllable;
      _availableSyllables.remove(syllable);
      _audioManager.playSyllable(syllable.toLowerCase());
      HapticFeedback.lightImpact();
      notifyListeners();
      _checkWordCompletion();
    } else {
      // Sílaba errada
      _audioManager.playSFX(SFXType.error);
      HapticFeedback.vibrate();
    }
  }

  /// Verifica se todos os slots foram preenchidos corretamente.
  Future<void> _checkWordCompletion() async {
    if (_placedSyllables.contains(null)) return;

    // Palavra completa → travar estado
    _state = GameState.completed;
    notifyListeners();

    // Toca SFX de acerto + balões
    await _audioManager.playSFX(SFXType.correct);
    await _audioManager.playSFX(SFXType.balloons);
  }

  /// Toca a palavra já formada sob demanda (ícone 🔊).
  /// Aplica debounce de 300ms para evitar toque duplo acidental.
  Future<void> playFormedWord() async {
    if (_state != GameState.completed && _state != GameState.validated) return;

    final now = DateTime.now();
    if (_lastWordPlay != null &&
        now.difference(_lastWordPlay!).inMilliseconds < 300) return;

    _lastWordPlay = now;
    HapticFeedback.selectionClick();
    await _audioManager.playWord(_currentWord.toLowerCase());
  }

  // ────────────────────────────────────────────────
  // VALIDAÇÃO FONÉTICA
  // ────────────────────────────────────────────────

  /// Inicia captura e validação de voz da criança.
  Future<void> startSpeechValidation({
    ValidationLevel? level,
  }) async {
    debugPrint('[GAME] startSpeechValidation(): state=$_state, attempts=$_validationAttempts/$_maxAttempts, word="$_currentWord"');
    if (_state != GameState.completed && _state != GameState.validated) {
      debugPrint('[GAME] startSpeechValidation(): estado inválido ($_state) — ignorado');
      return;
    }
    if (_validationAttempts >= _maxAttempts) {
      debugPrint('[GAME] startSpeechValidation(): tentativas esgotadas — ignorado');
      return;
    }

    _state = GameState.validating;
    _partialTranscript = '';
    _validationAttempts++;
    debugPrint('[GAME] → estado: validating (tentativa $_validationAttempts)');
    notifyListeners();

    await SpeechValidator().startListening(
      targetWord: _currentWord,
      syllables: _targetSyllables,
      level: level ?? validationLevel,
      onPartial: (partial) {
        debugPrint('[GAME] onPartial: "$partial"');
        _partialTranscript = partial;
        notifyListeners();
      },
      onValidated: (result) async {
        debugPrint('[GAME] onValidated: status=${result.status}, confidence=${result.confidence.toStringAsFixed(2)}, transcript="${result.transcript}"');

        // Se o STT falhou tecnicamente (sem fala), não conta como tentativa real
        final isTechnicalFailure = result.status == ValidationStatus.listenRepeat &&
            result.transcript.isEmpty &&
            (result.detectedVariations.contains('stt_nao_iniciou') ||
                result.detectedVariations.contains('stt_indisponivel') ||
                result.detectedVariations.contains('silencio'));
        if (isTechnicalFailure) {
          debugPrint('[GAME] falha técnica (sem fala real) → devolvendo tentativa');
          _validationAttempts = (_validationAttempts - 1).clamp(0, _maxAttempts);
        }

        // ── Gamificação: recompensa apenas em acertos ──────────────────
        if (result.isSuccess && !isTechnicalFailure) {
          lastReward = await gamification.onWordValidated(
            accuracy: result.confidence,
            attemptNumber: _validationAttempts,
            isDualFamily: _dualConfig?.isDual ?? false,
            familyKey: _family.key,
            wordWasNew: true,
          );
          debugPrint('[GAME] recompensa: +${lastReward!.coins} moedas, +${lastReward!.xp} XP');
        } else {
          lastReward = null;
        }

        _lastValidation = result;
        _state = GameState.validated;
        debugPrint('[GAME] → estado: validated (attempts=$_validationAttempts)');
        HapticFeedback.mediumImpact();
        notifyListeners();
      },
    );
  }

  /// Cancela validação em andamento e retorna ao estado completed.
  Future<void> cancelSpeechValidation() async {
    debugPrint('[GAME] cancelSpeechValidation(): state=$_state');
    if (_state != GameState.validating) return;
    await SpeechValidator().cancelListening();
    _state = GameState.completed;
    _partialTranscript = '';
    debugPrint('[GAME] → estado: completed (cancelado)');
    notifyListeners();
  }

  /// Avança para a próxima palavra manualmente (botão "Próxima Palavra").
  /// Salva progresso apenas em sessões de família única.
  Future<void> goToNextWord() async {
    if (_state != GameState.completed && _state != GameState.validated) return;

    // Sessões dual-family não rastreiam progresso individual
    if (_dualConfig == null || !_dualConfig!.isDual) {
      await _progressService.markWordCompleted(_family.key, _currentWord);
    }

    _currentIndex++;

    if (_currentIndex >= _pendingWords.length) {
      // Família toda concluída
      _state = GameState.familyDone;
      _currentWord = '';
      // Recompensa por completar a família
      if (_dualConfig == null || !_dualConfig!.isDual) {
        gamification.onFamilyCompleted(_family.key);
      }
      notifyListeners();
    } else {
      _loadCurrentWord();
    }
  }

  /// Reinicia a sessão atual (família única ou dual).
  Future<void> restartFamily() async {
    if (_dualConfig != null && _dualConfig!.isDual) {
      initWithDualFamilies(_dualConfig!);
      return;
    }
    await _progressService.resetFamily(_family.key);
    initWithFamily(_family);
  }

  /// Inicia uma sessão a partir de um [DualFamilyConfig] (uma ou duas famílias).
  /// Substitui o fluxo anterior — [initWithFamilyAndSyllables] mantido para compat.
  void initWithDualFamilies(DualFamilyConfig config) {
    _family = config.primary;
    _dualConfig = config;

    final allWords = WordBank.filterByDualFamilies(
      config.primary,
      config.activePrimary,
      config.secondary,
      config.activeSecondary,
    );

    if (allWords.isEmpty) {
      _state = GameState.familyDone;
      _currentWord = '';
      notifyListeners();
      return;
    }

    _pendingWords = List.from(allWords)..shuffle(Random());
    _currentIndex = 0;
    _loadCurrentWord();
  }

  /// Compat: chama [initWithDualFamilies] internamente.
  void initWithFamilyAndSyllables(
    SyllabicFamily family,
    List<String> activeSyllables,
  ) {
    _family = family;

    var filtered = WordBank.filterBySyllables(family, activeSyllables);
    if (filtered.isEmpty) {
      // fallback: usa palavras não concluídas sem filtro de sílabas
      final completed = _progressService.getCompletedWords(family.key);
      filtered = family.words
          .where((e) => !completed.contains(e.word))
          .toList();
    } else {
      // Remove já concluídas do lote filtrado
      final completed = _progressService.getCompletedWords(family.key);
      final remaining = filtered
          .where((e) => !completed.contains(e.word))
          .toList();
      filtered = remaining.isNotEmpty ? remaining : filtered;
    }

    _pendingWords = List.from(filtered)..shuffle(Random());
    _currentIndex = 0;

    if (_pendingWords.isEmpty) {
      _state = GameState.familyDone;
      _currentWord = '';
      notifyListeners();
    } else {
      _loadCurrentWord();
    }
  }
}
