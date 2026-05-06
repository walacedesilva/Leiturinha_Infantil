import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Tipos de efeitos sonoros pré-definidos
enum SFXType { correct, balloons, pop, error }

/// Singleton gerenciador de áudio 100% offline.
/// Usa TTS do Android (pt-BR) para sílabas e palavras,
/// e AudioPlayer para SFX com WAV reais.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final FlutterTts _tts = FlutterTts();

  // Mantém referências ativas para evitar GC prematuro durante SFX
  final List<AudioPlayer> _activePlayers = [];

  bool _ttsReady = false;

  Future<void> _ensureTTS() async {
    if (_ttsReady) return;
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(0.45); // lento para crianças
    await _tts.setPitch(1.1); // voz ligeiramente mais aguda
    await _tts.setVolume(1.0);
    _ttsReady = true;
  }

  /// Pré-carrega TTS. Sílabas e palavras usam TTS — sem arquivos de áudio.
  Future<void> preloadAssets(List<String> syllables) async {
    await _ensureTTS();
    debugPrint('?? AudioManager TTS pronto (${syllables.length} sílabas declaradas)');
  }

  /// Fala a sílaba usando TTS pt-BR.
  Future<void> playSyllable(String syllable) async {
    try {
      await _ensureTTS();
      await _tts.speak(syllable.toUpperCase());
    } catch (e) {
      debugPrint('?? TTS falhou para sílaba: $syllable — $e');
      _fallbackFeedback();
    }
  }

  /// Fala a palavra usando TTS pt-BR.
  Future<void> playWord(String word) async {
    try {
      await _ensureTTS();
      await _tts.stop();
      await _tts.speak(word.toUpperCase());
    } catch (e) {
      debugPrint('?? TTS falhou para palavra: $word — $e');
      _fallbackFeedback();
    }
  }

  /// Toca efeito sonoro (WAV com tom real) em player descartável.
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
      debugPrint('?? SFX falhou: $file — $e');
    }
  }

  /// Fallback tátil caso o áudio falhe (segurança offline)
  void _fallbackFeedback() {
    HapticFeedback.mediumImpact();
  }

  /// Libera recursos
  void dispose() {
    _tts.stop();
    for (final p in _activePlayers) {
      p.dispose();
    }
    _activePlayers.clear();
  }
}
