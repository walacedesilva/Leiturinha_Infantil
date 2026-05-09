import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Tipos de efeitos sonoros pre-definidos
enum SFXType { correct, balloons, pop, error }

/// Singleton gerenciador de audio 100% offline.
/// Usa TTS do Android (pt-BR) para silabas e palavras;
/// AudioPlayer para SFX com WAV de tons reais.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final FlutterTts _tts = FlutterTts();
  final List<AudioPlayer> _activePlayers = [];

  bool _ttsReady = false;

  // Debounce para playSyllableInstant (150ms)
  DateTime? _lastSyllablePlay;
  String? _lastSyllablePlayed;

  Future<void> _ensureTTS() async {
    if (_ttsReady) return;
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
    await _tts.setVolume(1.0);
    _ttsReady = true;
  }

  /// Pre-carrega TTS para as silabas da sessao atual.
  Future<void> preloadSyllables(List<String> syllables) async {
    await _ensureTTS();
    debugPrint('TTS pronto - ${syllables.length} silabas na sessao');
  }

  /// Alias mantido para compatibilidade com GameLogic.
  Future<void> preloadAssets(List<String> syllables) =>
      preloadSyllables(syllables);

  /// Toca silaba com debounce de 150ms.
  Future<void> playSyllableInstant(String syllable) async {
    final now = DateTime.now();
    if (_lastSyllablePlayed == syllable &&
        _lastSyllablePlay != null &&
        now.difference(_lastSyllablePlay!).inMilliseconds < 150) return;

    _lastSyllablePlay = now;
    _lastSyllablePlayed = syllable;

    try {
      await _ensureTTS();
      await _tts.speak(syllable.toUpperCase());
    } catch (e) {
      debugPrint('TTS silaba: $syllable - $e');
      _fallbackFeedback();
    }
  }

  /// Fala a silaba (usado internamente pelo GameLogic).
  Future<void> playSyllable(String syllable) =>
      playSyllableInstant(syllable);

  /// Fala a palavra completa.
  Future<void> playWord(String word) async {
    try {
      await _ensureTTS();
      await _tts.stop();
      await _tts.speak(word.toUpperCase());
    } catch (e) {
      debugPrint('TTS palavra: $word - $e');
      _fallbackFeedback();
    }
  }

  /// Fala a palavra completa em velocidade reduzida (0.25x) para aprendizado.
  Future<void> playWordSlow(String word) async {
    try {
      await _ensureTTS();
      await _tts.stop();
      await _tts.setSpeechRate(0.25);
      await _tts.speak(word.toUpperCase());
      // Restaura velocidade normal após conclusão
      _tts.setCompletionHandler(() async {
        await _tts.setSpeechRate(0.45);
      });
    } catch (e) {
      debugPrint('TTS palavra lenta: $word - $e');
      _fallbackFeedback();
      // Garante restauração da velocidade em caso de erro
      try { await _tts.setSpeechRate(0.45); } catch (_) {}
    }
  }

  /// Toca efeito sonoro em player descartavel.
  Future<void> playSFX(SFXType type) async {
    final file = switch (type) {
      SFXType.correct => 'correct.wav',
      SFXType.balloons => 'balloons.wav',
      SFXType.pop => 'pop.wav',
      SFXType.error => 'error.wav',
    };
    try {
      final player = AudioPlayer();
      _activePlayers.add(player);
      await player.play(AssetSource('audio/sfx/$file'));
      player.onPlayerComplete.first.then((_) {
        player.dispose();
        _activePlayers.remove(player);
      });
    } catch (e) {
      debugPrint('SFX: $file - $e');
    }
  }

  void _fallbackFeedback() => HapticFeedback.mediumImpact();

  void dispose() {
    _tts.stop();
    for (final p in _activePlayers) {
      p.dispose();
    }
    _activePlayers.clear();
  }
}
