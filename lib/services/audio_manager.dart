import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de efeitos sonoros pre-definidos
enum SFXType { correct, balloons, pop, error }

/// Singleton gerenciador de audio 100% offline.
/// Usa TTS do Android (pt-BR) para silabas e palavras;
/// AudioPlayer para SFX com WAV de tons reais.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  
  AudioManager._internal() {
    initVolumeSettings();
  }

  final FlutterTts _tts = FlutterTts();
  final List<AudioPlayer> _activePlayers = [];

  bool _ttsReady = false;

  // Variáveis de volume dinâmicas
  double _masterVolume = 0.8;
  double _sfxVolume = 0.7;
  double _narrationVolume = 0.9;
  double _musicVolume = 0.5;

  /// Inicializa e carrega os volumes do SharedPreferences
  Future<void> initVolumeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _masterVolume = prefs.getDouble('cfg_master_volume') ?? 0.8;
      _sfxVolume = prefs.getDouble('cfg_sfx_volume') ?? 0.7;
      _narrationVolume = prefs.getDouble('cfg_narration_volume') ?? 0.9;
      _musicVolume = prefs.getDouble('cfg_music_volume') ?? 0.5;
      
      await _tts.setVolume(_narrationVolume * _masterVolume);
    } catch (e) {
      debugPrint('[AudioManager] Erro ao carregar SharedPreferences de volume: $e');
    }
  }

  // Getters para os volumes atuais
  double get masterVolume => _masterVolume;
  double get sfxVolume => _sfxVolume;
  double get narrationVolume => _narrationVolume;
  double get musicVolume => _musicVolume;

  // Setters dinâmicos
  void setMasterVolume(double val) {
    _masterVolume = val;
    _tts.setVolume(_narrationVolume * _masterVolume);
  }

  void setNarrationVolume(double val) {
    _narrationVolume = val;
    _tts.setVolume(_narrationVolume * _masterVolume);
  }

  void setSfxVolume(double val) {
    _sfxVolume = val;
  }

  void setMusicVolume(double val) {
    _musicVolume = val;
  }

  // Debounce para playSyllableInstant (150ms)
  DateTime? _lastSyllablePlay;
  String? _lastSyllablePlayed;

  /// Aplica as configurações de voz infantil a qualquer instância [FlutterTts].
  /// Pitch 1.30 simula a Frequência Fundamental de criança de 4-7 anos (~280-320Hz).
  /// Seleciona preferencialmente as vozes pt-br-x-ptd ou pt-br-x-pte (suaves, femininas).
  /// Deve ser chamado uma vez após criar a instância TTS.
  static Future<void> applyChildVoice(FlutterTts tts) async {
    try {
      await tts.setLanguage('pt-BR');

      final dynamic voices = await tts.getVoices;
      Map<String, String>? targetVoice;

      if (voices != null) {
        // Prefere vozes ptd/pte por serem suaves e de alta qualidade
        for (var v in voices) {
          if (v is Map) {
            final name = v['name']?.toString() ?? '';
            final locale = v['locale']?.toString() ?? '';
            if (locale.toLowerCase().contains('pt-br')) {
              if (name.contains('pt-br-x-ptd') || name.contains('pt-br-x-pte')) {
                targetVoice = {'name': name, 'locale': locale};
                break;
              }
            }
          }
        }
        // Fallback: qualquer voz pt-BR disponível
        if (targetVoice == null) {
          for (var v in voices) {
            if (v is Map) {
              final name = v['name']?.toString() ?? '';
              final locale = v['locale']?.toString() ?? '';
              if (locale.toLowerCase().contains('pt-br')) {
                targetVoice = {'name': name, 'locale': locale};
                break;
              }
            }
          }
        }
      }

      if (targetVoice != null) {
        debugPrint('[TTS] Voz infantil: ${targetVoice['name']}');
        await tts.setVoice(targetVoice);
      }
    } catch (e) {
      debugPrint('[TTS] Erro ao configurar voz infantil: $e');
    }

    await tts.setSpeechRate(0.45);
    // Pitch 1.30 eleva o tom sobre a voz feminina base para simular voz infantil
    await tts.setPitch(1.30);
    await tts.setVolume(1.0);
  }

  Future<void> _ensureTTS() async {
    if (_ttsReady) {
      await _tts.setVolume(_narrationVolume * _masterVolume);
      return;
    }
    await AudioManager.applyChildVoice(_tts);
    await _tts.setVolume(_narrationVolume * _masterVolume);
    _ttsReady = true;
  }

  Future<void> _ensureChildVoice() async {
    await _ensureTTS();
    await _tts.setPitch(1.30);
    await _tts.setSpeechRate(0.45);
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
      await _ensureChildVoice();
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
      await _ensureChildVoice();
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
      await _tts.setPitch(1.30);
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
      try {
        await _tts.setSpeechRate(0.45);
      } catch (e) {
        debugPrint('TTS: falha ao restaurar velocidade: $e');
      }
    }
  }

  /// Fala uma frase completa (diálogo) com pitch ajustado ao perfil do personagem.
  Future<void> speakSentence(String sentence, {required bool isChild}) async {
    try {
      await _ensureTTS();
      await _tts.stop();
      if (isChild) {
        await _tts.setPitch(1.30);
        await _tts.setSpeechRate(0.45);
      } else {
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.50);
      }
      await _tts.speak(sentence);
    } catch (e) {
      debugPrint('TTS speakSentence: $sentence - $e');
      _fallbackFeedback();
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
      await player.setVolume(_sfxVolume * _masterVolume);
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
