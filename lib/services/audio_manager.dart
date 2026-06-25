import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SFXType { correct, balloons, pop, error, coin }

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

  // Canais dedicados de trilha de fundo e ambiente de história (loop contínuo).
  AudioPlayer? _musicPlayer;
  String? _currentMusic;
  AudioPlayer? _ambientPlayer;
  String? _currentAmbient;

  // Controle de pausa durante gravação no microfone.
  bool _micPausedMusic = false;
  bool _micPausedAmbient = false;

  // Índice de áudios gravados (.mp3) presentes nos assets.
  final Map<String, String> _sylAssets = {};
  final Map<String, String> _wordAssets = {};
  bool _indexLoaded = false;

  double _masterVolume = 0.8;
  double _sfxVolume = 0.7;
  double _narrationVolume = 0.9;
  double _musicVolume = 0.5;

  Future<void> initVolumeSettings() async {
    await _configureAudioContext();
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

  /// Configura o contexto de áudio global para que os sons NÃO disputem o
  /// "audio focus" entre si. Sem isso, no Android tocar um efeito (ex.: o
  /// preview do slider de volume) pausava a música de fundo, que só voltava
  /// quando o foco era devolvido ("para e depois de um tempo volta").
  Future<void> _configureAudioContext() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none, // não rouba foco
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e) {
      debugPrint('[AudioManager] audio context: $e');
    }
  }

  double get masterVolume => _masterVolume;
  double get sfxVolume => _sfxVolume;
  double get narrationVolume => _narrationVolume;
  double get musicVolume => _musicVolume;

  void setMasterVolume(double val) {
    _masterVolume = val;
    _tts.setVolume(_narrationVolume * _masterVolume);
    _musicPlayer?.setVolume(_musicVolume * _masterVolume);
    _ambientPlayer?.setVolume(_musicVolume * _masterVolume * 0.7);
  }

  void setNarrationVolume(double val) {
    _narrationVolume = val;
    _tts.setVolume(_narrationVolume * _masterVolume);
  }

  void setSfxVolume(double val) => _sfxVolume = val;

  void setMusicVolume(double val) {
    _musicVolume = val;
    _musicPlayer?.setVolume(_musicVolume * _masterVolume);
    _ambientPlayer?.setVolume(_musicVolume * _masterVolume * 0.7);
  }

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
      // Só considera carregado se realmente indexou algo. Se o manifesto
      // falhar ou vier vazio, mantém false para tentar de novo na próxima.
      if (_sylAssets.isNotEmpty || _wordAssets.isNotEmpty) _indexLoaded = true;
    } catch (e) {
      debugPrint('[AudioManager] indice de audio: $e');
    }
  }

  /// Verifica se um asset existe no bundle (independe do AssetManifest).
  /// [assetKey] deve incluir o prefixo 'assets/'.
  Future<bool> _assetExists(String assetKey) async {
    try {
      await rootBundle.load(assetKey);
      return true;
    } catch (_) {
      return false;
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
    final lower = syllable.toLowerCase();
    await _ensureIndex();
    // 1) gravação indexada pelo manifesto
    if (await _playAsset(_sylAssets[lower])) return;
    // 2) gravação pelo caminho convencional (caso o índice tenha falhado)
    if (await _assetExists('assets/audio/syllables/$lower.mp3') &&
        await _playAsset('audio/syllables/$lower.mp3')) return;
    // 3) só então TTS (último recurso) — caixa baixa p/ não soletrar
    await _speak(lower, _VoiceProfile.syllable, stopFirst: false);
  }

  Future<void> playSyllable(String syllable) => playSyllableInstant(syllable);

  /// Palavra/letra/frase curta. Usa audio gravado se houver; senao TTS com
  /// entonacao automatica ('?' pergunta, '!' animada).
  Future<void> playWord(String word) async {
    final lower = word.toLowerCase();
    await _ensureIndex();
    if (await _playAsset(_wordAssets[lower])) return;
    // Palavra de uma só (sem espaço): tenta gravação convencional antes do TTS.
    if (!lower.contains(' ') &&
        await _assetExists('assets/audio/words/$lower.mp3') &&
        await _playAsset('audio/words/$lower.mp3')) {
      return;
    }
    await _speak(lower, _profileForPhrase(word));
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
      SFXType.coin => 'coin.wav',
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

  // ───────────────────────────────────────────────────────────────────────
  // TRILHA SONORA DE FUNDO (assets/audio/music/<name>.mp3)
  // ───────────────────────────────────────────────────────────────────────

  /// Toca uma trilha de tela em loop. Ex.: playMusic('menu'), playMusic('mapa').
  /// Ignora a chamada se a mesma faixa já estiver tocando (não reinicia ao
  /// navegar entre telas que pedem a mesma trilha). Silencioso se o arquivo
  /// ainda não existir.
  Future<void> playMusic(String name, {bool loop = true}) async {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return;
    if (_currentMusic == n && _musicPlayer != null) return;
    await stopMusic();
    try {
      final p = AudioPlayer();
      _musicPlayer = p;
      _currentMusic = n;
      await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await p.setVolume(_musicVolume * _masterVolume);
      await p.play(AssetSource('audio/music/$n.mp3'));
    } catch (e) {
      debugPrint('[AudioManager] music $n: $e');
      _currentMusic = null;
    }
  }

  Future<void> stopMusic() async {
    final p = _musicPlayer;
    _musicPlayer = null;
    _currentMusic = null;
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (_) {}
  }

  // ───────────────────────────────────────────────────────────────────────
  // AMBIENTE DE HISTÓRIA (caminho vindo do JSON: 'assets/...' ou relativo)
  // ───────────────────────────────────────────────────────────────────────

  /// Toca o ambiente de uma cena em loop. Aceita o caminho completo do JSON
  /// (com ou sem o prefixo 'assets/'). Silencioso se o arquivo não existir.
  Future<void> playAmbient(String? assetPath, {bool loop = true}) async {
    if (assetPath == null || assetPath.trim().isEmpty) {
      await stopAmbient();
      return;
    }
    final path =
        assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;
    if (_currentAmbient == path && _ambientPlayer != null) return;
    await stopAmbient();
    // Tenta o caminho do JSON; se falhar, recorre a audio/ambient/<arquivo>.
    final fallback = 'audio/ambient/${path.split('/').last}';
    for (final candidate in <String>[path, if (fallback != path) fallback]) {
      try {
        final p = AudioPlayer();
        _ambientPlayer = p;
        _currentAmbient = path;
        await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
        await p.setVolume(_musicVolume * _masterVolume * 0.7);
        await p.play(AssetSource(candidate));
        return;
      } catch (e) {
        debugPrint('[AudioManager] ambient $candidate: $e');
        try {
          await _ambientPlayer?.dispose();
        } catch (_) {}
        _ambientPlayer = null;
        _currentAmbient = null;
      }
    }
  }

  Future<void> stopAmbient() async {
    final p = _ambientPlayer;
    _ambientPlayer = null;
    _currentAmbient = null;
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (_) {}
  }

  /// Pausa só a trilha de fundo (ex.: ao entrar numa história, deixando o
  /// ambiente da cena assumir). Use resumeMusic() ao voltar.
  Future<void> pauseMusic() async {
    try {
      await _musicPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    try {
      await _musicPlayer?.resume();
    } catch (_) {}
  }

  /// Pausa TODOS os sons durante a gravação no microfone (música, ambiente e
  /// fala TTS), para não interferir no reconhecimento. Só marca para retomar o
  /// que de fato estava tocando — assim não liga música indevida (ex.: numa
  /// história a trilha já estava pausada e deve continuar pausada).
  Future<void> pauseForMic() async {
    try {
      await _tts.stop();
    } catch (_) {}
    if (_musicPlayer != null && _musicPlayer!.state == PlayerState.playing) {
      _micPausedMusic = true;
      try {
        await _musicPlayer!.pause();
      } catch (_) {}
    }
    if (_ambientPlayer != null && _ambientPlayer!.state == PlayerState.playing) {
      _micPausedAmbient = true;
      try {
        await _ambientPlayer!.pause();
      } catch (_) {}
    }
  }

  /// Retoma o que foi pausado por [pauseForMic] (somente esses canais).
  Future<void> resumeFromMic() async {
    if (_micPausedMusic) {
      _micPausedMusic = false;
      try {
        await _musicPlayer?.resume();
      } catch (_) {}
    }
    if (_micPausedAmbient) {
      _micPausedAmbient = false;
      try {
        await _ambientPlayer?.resume();
      } catch (_) {}
    }
  }

  /// Pausa trilha e ambiente (ex.: app foi para segundo plano).
  Future<void> pauseBackground() async {
    try {
      await _musicPlayer?.pause();
    } catch (_) {}
    try {
      await _ambientPlayer?.pause();
    } catch (_) {}
  }

  /// Retoma trilha e ambiente que estavam tocando.
  Future<void> resumeBackground() async {
    try {
      await _musicPlayer?.resume();
    } catch (_) {}
    try {
      await _ambientPlayer?.resume();
    } catch (_) {}
  }

  void _fallbackFeedback() => HapticFeedback.mediumImpact();

  void dispose() {
    _tts.stop();
    for (final p in _activePlayers) {
      p.dispose();
    }
    _activePlayers.clear();
    _musicPlayer?.dispose();
    _musicPlayer = null;
    _currentMusic = null;
    _ambientPlayer?.dispose();
    _ambientPlayer = null;
    _currentAmbient = null;
  }
}
