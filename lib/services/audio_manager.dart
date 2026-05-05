import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  // Singleton
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _syllablePlayer = AudioPlayer();
  final AudioPlayer _wordPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // Configurações iniciais se necessário (como setar modo do player)
    await _syllablePlayer.setReleaseMode(ReleaseMode.stop);
    await _wordPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    
    _isInitialized = true;
  }

  // Toca o som de uma sílaba (ex: assets/audio/syllables/ga.mp3)
  Future<void> playSyllable(String syllable) async {
    try {
      final fileName = '${syllable.toLowerCase()}.mp3';
      await _syllablePlayer.play(AssetSource('audio/syllables/$fileName'));
    } catch (e) {
      debugPrint('Erro ao tocar sílaba $syllable: $e');
    }
  }

  // Toca o som de uma palavra completa (ex: assets/audio/words/gato.mp3)
  Future<void> playWord(String word) async {
    try {
      final fileName = '${word.toLowerCase()}.mp3';
      await _wordPlayer.play(AssetSource('audio/words/$fileName'));
    } catch (e) {
      debugPrint('Erro ao tocar palavra $word: $e');
    }
  }

  // Toca um efeito sonoro (ex: correct, pop, wrong)
  Future<void> playSFX(String type) async {
    try {
      final fileName = '${type.toLowerCase()}.mp3';
      await _sfxPlayer.play(AssetSource('audio/sfx/$fileName'));
    } catch (e) {
      debugPrint('Erro ao tocar sfx $type: $e');
    }
  }
}
