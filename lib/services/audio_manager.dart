import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SFXType { correct, balloons, pop, error }

/// Perfil de prosódia (velocidade + tom) por contexto de fala.
class _VoiceProfile {
  final double rate;
  final double pitch;
  const _VoiceProfile(this.rate, this.pitch);

  static const syllable = _VoiceProfile(0.42, 1.14);
  static const word = _VoiceProfile(0.50, 1.12);
  static const wordSlow = _VoiceProfile(0.32, 1.12);
  static const question = _VoiceProfile(0.50, 1.20);
  static const praise = _VoiceProfile(0.58, 1.26);
  static const lively = _VoiceProfile(0.54, 1.18);
  static const encourage = _VoiceProfile(0.46, 1.10);
  static const sentenceChild = _VoiceProfile(0.46, 1.16);
  static const sentenceAdult = _VoiceProfile(0.52, 1.0);
}

/// Gerenciador de áudio (singleton).
/// Pronúncia: toca primeiro o áudio gravado (assets/audio/.../<x>.mp3) quando
/// existir; senão, recorre ao TTS pt-BR com prosódia por contexto. A fala TTS
/// usa caixa natural (nunca CAIXA ALTA, que faz o engine soletrar letras).
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal() {
    initVolumeSettings();
  }

  final FlutterTts _tts = FlutterTts();
  final List<AudioPlayer> _activePlayers = [];
  bool _ttsReady = false;

  // Índice de áudios gravados (.mp3) presentes nos assets.
  final Map<String, String> _sylAssets = {};
  final Map<String, String> _wordAssets = {};
  bool _indexLoaded = false;

  double _masterVolume = 0.8;
  double _sfxVolume = 0.7;
  double _narrationVolume = 0.9;
  double _musicVolume = 0.5;

  Future<void> initVolumeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _masterVolume = prefs.getDouble('cfg_master_volume') ?? 0.8;
      _sfxVolume = prefs.getDouble('cfg_sfx_volume') ?? 0.7;
      _narrationVolume = prefs.getDouble('cfg_narration_volume') ?? 0.9;
      _musicVolume = prefs.getDouble('cfg_music_volume') ?? 0.5;
      await _tts.setVolume(_narrationVolume * _masterVolume);
    } catch (e) {
      debugPrint('[AudioManager] Erro ao carregar volumes: $e');
    }
  }

  double get masterVolume => _masterVolume;
  double get sfxVolume => _sfxVolume;
  double get narrationVolume => _narrationVolume;
  double get musicVolume => _musicVolume;

  void setMasterVolume(double val) {
    _masterVolume = val;
    _tts.setVolume(_narrationVolume * _masterVolume);
  }

  void setNarrationVolume(double val) {
    _narrationVolume = val;
    _tts.setVolume(_narrationVolume * _masterVolume);
  }

  void setSfxVolume(double val) => _sfxVolume = val;
  void setMusicVolume(double val) => _musicVolume = val;

  DateTime? _lastSyllablePlay;
  String? _lastSyllablePlayed;

  /// Voz infantil para qualquer [FlutterTts]: pt-br-x-ptd/pte quando houver e
  /// tom base inteligível (1.12). A prosódia fina é aplicada por chamada.
  static Future<void> applyChildVoice(FlutterTts tts) async {
    try {
      await tts.setLanguage('pt-BR');
      final dynamic voices = await tts.getVoices;
      Map<String, String>? target;
      if (voices != null) {
        for (var v in voices) {
          if (v is Map) {
            final name = v['name']?.toString() ?? '';
            final locale = v['locale']?.toString() ?? '';
            if (locale.toLowerCase().contains('pt-br') &&
                (name.contains('pt-br-x-ptd') ||
                    name.contains('pt-br-x-pte'))) {
              target = {'name': name, 'locale': locale};
              break;
            }
          }
        }
        if (target == null) {
          for (var v in voices) {
            if (v is Map) {
              final name = v['name']?.toString() ?? '';
              final locale = v['locale']?.toString() ?? '';
              if (locale.toLowerCase().contains('pt-br')) {
                target = {'name': name, 'locale': locale};
                break;
              }
            }
          }
        }
      }
      if (target != null) await tts.setVoice(target);
    } catch (e) {
      debugPrint('[TTS] Erro ao configurar voz: $e');
    }
    await tts.setSpeechRate(0.48);
    await tts.setPitch(1.12);
    await tts.setVolume(1.0);
  }

  Future<void> _ensureTTS() async {
    if (_ttsReady) return;
    await AudioManager.applyChildVoice(_tts);
    _ttsReady = true;
  }

  /// Carrega (uma vez) o índice de áudios gravados .mp3 do manifesto.
  Future<void> _ensureIndex() async {
    if (_indexLoaded) return;
    _indexLoaded = true;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final key in manifest.listAssets()) {
        if (!key.endsWith('.mp3')) continue;
        final path = key.startsWith('assets/') ? key.substring(7) : key;
        final stem = key.split('/').last.replaceAll('.mp3', '').toLowerCase();
        if (key.contains('/audio/syllables/')) {
          _sylAssets[stem] = path;
        } else if (key.contains('/audio/words/')) {
          _wordAssets[stem] = path;
        }
      }
    } catch (e) {
      debugPrint('[AudioManager] indice de audio: $e');
    }
  }

  /// Toca um asset gravado. Retorna true se conseguiu iniciar.
  Future<bool> _playAsset(String? path) async {
    if (path == null) return false;
    try {
      final player = AudioPlayer();
      _activePlayers.add(player);
      await player.setVolume(_narrationVolume * _masterVolume);
      await player.play(AssetSource(path));
      player.onPlayerComplete.first.then((_) {
        player.dispose();
        _activePlayers.remove(player);
      });
      return true;
    } catch (e) {
      debugPrint('[AudioManager] asset $path: $e');
      return false;
    }
  }

  /// Núcleo da fala TTS: aplica rate/pitch do perfil e fala em caixa natural.
  Future<void> _speak(String text, _VoiceProfile p,
      {bool stopFirst = true}) async {
    if (text.trim().isEmpty) {
      if (stopFirst) await _tts.stop();
      return;
    }
    try {
      await _ensureTTS();
      if (stopFirst) await _tts.stop();
      await _tts.setPitch(p.pitch);
      await _tts.setSpeechRate(p.rate);
      await _tts.setVolume(_narrationVolume * _masterVolume);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[TTS] falha "$text": $e');
      _fallbackFeedback();
    }
  }

  _VoiceProfile _profileForPhrase(String text) {
    final t = text.trimRight();
    if (t.endsWith('?')) return _VoiceProfile.question;
    if (t.endsWith('!')) return _VoiceProfile.lively;
    return _VoiceProfile.word;
  }

  Future<void> preloadSyllables(List<String> syllables) async {
    await _ensureTTS();
    await _ensureIndex();
  }

  Future<void> preloadAssets(List<String> syllables) =>
      preloadSyllables(syllables);

  Future<void> playSyllableInstant(String syllable) async {
    final now = DateTime.now();
    if (_lastSyllablePlayed == syllable &&
        _lastSyllablePlay != null &&
        now.difference(_lastSyllablePlay!).inMilliseconds < 150) return;
    _lastSyllablePlay = now;
    _lastSyllablePlayed = syllable;
    await _ensureIndex();
    if (await _playAsset(_sylAssets[syllable.toLowerCase()])) return;
    await _speak(syllable.toLowerCase(), _VoiceProfile.syllable,
        stopFirst: false);
  }

  Future<void> playSyllable(String syllable) => playSyllableInstant(syllable);

  /// Palavra/letra/frase curta. Usa audio gravado se houver; senao TTS com
  /// entonacao automatica ('?' pergunta, '!' animada).
  Future<void> playWord(String word) async {
    await _ensureIndex();
    if (await _playAsset(_wordAssets[word.toLowerCase()])) return;
    await _speak(word.toLowerCase(), _profileForPhrase(word));
  }

  Future<void> playWordSlow(String word) =>
      _speak(word.toLowerCase(), _VoiceProfile.wordSlow);

  Future<void> speakPraise(String text) =>
      _speak(text.toLowerCase(), _VoiceProfile.praise);

  Future<void> speakEncouragement(String text) =>
      _speak(text.toLowerCase(), _VoiceProfile.encourage);

  Future<void> speakQuestion(String text) =>
      _speak(text.toLowerCase(), _VoiceProfile.question);

  Future<void> speakSentence(String sentence, {required bool isChild}) =>
      _speak(sentence,
          isChild ? _VoiceProfile.sentenceChild : _VoiceProfile.sentenceAdult);

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

  /// Toca um clipe nomeado de assets/audio/sfx/<name>.mp3 (ex.: rugido "leao").
  /// Fica em silencio se o arquivo ainda nao existir (fallback seguro).
  Future<void> playClip(String name) async {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return;
    try {
      final player = AudioPlayer();
      _activePlayers.add(player);
      await player.setVolume(_sfxVolume * _masterVolume);
      await player.play(AssetSource('audio/sfx/$n.mp3'));
      player.onPlayerComplete.first.then((_) {
        player.dispose();
        _activePlayers.remove(player);
      });
    } catch (e) {
      debugPrint('[AudioManager] clip $n: $e');
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
