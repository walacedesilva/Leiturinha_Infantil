import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/word_bank.dart';
import '../../../../services/audio_manager.dart';
import '../../../../services/progress_service.dart';

/// Estados possíveis do jogo para uma palavra
enum GameState {
  assembling,  // Criança está montando a palavra
  completed,   // Palavra montada corretamente — aguarda interação manual
  familyDone,  // Todas as palavras da família foram concluídas
}

/// Controlador de jogo por família silábica.
/// Não avança automaticamente: aguarda chamada explícita de [goToNextWord].
class GameLogic extends ChangeNotifier {
  final ProgressService _progressService;
  final AudioManager _audioManager;

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

  // ────────────────────────────────────────────────
  // GETTERS
  // ────────────────────────────────────────────────

  String get currentWord => _currentWord;
  SyllabicFamily get family => _family;
  List<String> get availableSyllables => List.unmodifiable(_availableSyllables);
  List<String?> get placedSyllables => List.unmodifiable(_placedSyllables);
  List<String> get targetSyllables => List.unmodifiable(_targetSyllables);
  GameState get state => _state;
  bool get isCompleted => _state == GameState.completed;
  bool get isFamilyDone => _state == GameState.familyDone;
  int get wordIndex => _currentIndex;
  int get totalWords => _pendingWords.length;

  // ────────────────────────────────────────────────
  // INICIALIZAÇÃO
  // ────────────────────────────────────────────────

  GameLogic(this._progressService, this._audioManager);

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

    // Embaralha sílabas disponíveis
    _availableSyllables = List<String>.from(_targetSyllables)..shuffle(Random());

    _state = GameState.assembling;
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
    if (_state != GameState.completed) return;

    final now = DateTime.now();
    if (_lastWordPlay != null &&
        now.difference(_lastWordPlay!).inMilliseconds < 300) return;

    _lastWordPlay = now;
    HapticFeedback.selectionClick();
    await _audioManager.playWord(_currentWord.toLowerCase());
  }

  /// Avança para a próxima palavra manualmente (botão "Próxima Palavra").
  /// Salva progresso antes de avançar.
  Future<void> goToNextWord() async {
    if (_state != GameState.completed) return;

    // Persiste progresso da palavra concluída
    await _progressService.markWordCompleted(_family.key, _currentWord);

    _currentIndex++;

    if (_currentIndex >= _pendingWords.length) {
      // Família toda concluída
      _state = GameState.familyDone;
      _currentWord = '';
      notifyListeners();
    } else {
      _loadCurrentWord();
    }
  }

  /// Reinicia a família (usado no modal de "Família Completa").
  Future<void> restartFamily() async {
    await _progressService.resetFamily(_family.key);
    initWithFamily(_family);
  }
}
