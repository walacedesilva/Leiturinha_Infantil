import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/word_bank.dart';
import '../../../../services/audio_manager.dart';
import '../../../../services/storage_service.dart';

class GameLogic extends ChangeNotifier {
  final StorageService _storageService;
  final AudioManager _audioManager;
  
  List<String> _words = [];
  int _currentIndex = 0;
  
  String _currentWord = '';
  List<String> _targetSyllables = [];
  
  // Sílabas disponíveis para escolha
  List<String> _availableSyllables = [];
  
  // Sílabas já posicionadas corretamente
  List<String?> _placedSyllables = [];
  
  bool _showCelebration = false;

  GameLogic(this._storageService, this._audioManager) {
    _initGame();
  }

  String get currentWord => _currentWord;
  List<String> get availableSyllables => _availableSyllables;
  List<String?> get placedSyllables => _placedSyllables;
  bool get showCelebration => _showCelebration;
  List<String> get targetSyllables => _targetSyllables;

  void _initGame() {
    _words = WordBank.getWordList();
    _currentIndex = _storageService.getCurrentIndex();
    
    // Se terminou todas as palavras, volta do início
    if (_currentIndex >= _words.length) {
      _currentIndex = 0;
      _storageService.saveCurrentIndex(_currentIndex);
    }
    
    _loadCurrentWord();
  }

  void _loadCurrentWord() {
    _currentWord = _words[_currentIndex];
    _targetSyllables = WordBank.getSyllablesForWord(_currentWord);
    
    // Inicializa os slots como vazios
    _placedSyllables = List<String?>.filled(_targetSyllables.length, null);
    
    // Embaralha as sílabas
    _availableSyllables = List<String>.from(_targetSyllables);
    _availableSyllables.shuffle(Random());
    
    _showCelebration = false;
    notifyListeners();
  }

  // Tenta posicionar uma sílaba em um slot
  void onSyllableDropped(String syllable, int slotIndex) {
    // Verifica se a sílaba é a correta para aquele slot específico
    if (_targetSyllables[slotIndex] == syllable) {
      // Acertou a sílaba
      _placedSyllables[slotIndex] = syllable;
      _availableSyllables.remove(syllable);
      
      _audioManager.playSyllable(syllable);
      HapticFeedback.lightImpact();
      
      notifyListeners();
      
      _checkWordCompletion();
    } else {
      // Errou a sílaba
      _audioManager.playSFX('wrong');
      HapticFeedback.vibrate();
    }
  }

  Future<void> _checkWordCompletion() async {
    // Se não há mais sílabas nulas, a palavra foi concluída
    if (!_placedSyllables.contains(null)) {
      _showCelebration = true;
      notifyListeners();
      
      await _storageService.addCompletedWord(_currentWord);
      await _storageService.addScore(10);
      
      // Tocar som de sucesso e a palavra
      await _audioManager.playSFX('correct');
      await Future.delayed(const Duration(milliseconds: 500));
      await _audioManager.playWord(_currentWord);
      
      // Avançar após 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      _nextWord();
    }
  }

  void _nextWord() {
    _currentIndex++;
    if (_currentIndex >= _words.length) {
      _currentIndex = 0; // Loop (poderia ser uma tela de vitória)
    }
    _storageService.saveCurrentIndex(_currentIndex);
    _loadCurrentWord();
  }

  void playWordAudio() {
    _audioManager.playWord(_currentWord);
  }
}
