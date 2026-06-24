/**
 * audioService.js
 * -----------------------------------------------------------------------------
 * Wrapper de reprodução de áudio que NÃO trava o app caso `expo-av` não esteja
 * instalado (projeto pode ainda não ter o módulo nativo).
 *
 *  - Se `expo-av` existir → toca o asset de verdade.
 *  - Senão → log + Promise resolvida (UI permanece reativa).
 *
 * Uso:
 *    import audio from '../services/audioService';
 *    await audio.play(require('../../assets/audio/syllables/vogal_a.wav'));
 *    await audio.stopAll();
 * -----------------------------------------------------------------------------
 */

let AudioMod = null;
try {
  // eslint-disable-next-line global-require
  AudioMod = require('expo-av').Audio;
} catch (_e) {
  AudioMod = null;
}

// Configura o modo de áudio do Android/iOS assim que o módulo estiver disponível.
// Sem isso, o Android pode rotear o som pelo ear-piece (silencioso) ou ignorar playback.
if (AudioMod) {
  AudioMod.setAudioModeAsync({
    allowsRecordingIOS: false,
    playsInSilentModeIOS: true,
    shouldDuckAndroid: false,
    staysActiveInBackground: false,
    playThroughEarpieceAndroid: false, // garante saída pelo alto-falante
  }).catch(() => {});
}

const activeSounds = new Set();

// Resolver de volume injetado pelo settingsBridge.
// Recebe um canal ('narration' | 'sfx' | 'music') e devolve 0..1.
// Default: volume neutro (1.0) quando o bridge ainda não inicializou.
let volumeResolver = () => 1.0;

export function setVolumeResolver(fn) {
  if (typeof fn === 'function') volumeResolver = fn;
}

async function play(source, opts = {}) {
  const { rate = 0.9, channel = 'narration', volume: volumeOverride } = opts;
  // Volume final = (override explícito) OU (resolver do canal).
  const volume = (typeof volumeOverride === 'number')
    ? volumeOverride
    : volumeResolver(channel);

  // Fallback silencioso quando:
  //  - o asset ainda não foi gerado (source == null), OU
  //  - o módulo nativo `expo-av` não está instalado, OU
  //  - volume zero (modo silencioso) — economiza I/O.
  if (!source || !AudioMod || volume <= 0) {
    return new Promise((r) => setTimeout(r, 600));
  }
  try {
    const { sound } = await AudioMod.Sound.createAsync(source, {
      shouldPlay: true,
      rate,
      volume,
      shouldCorrectPitch: true, // preserva timbre infantil ao reduzir rate
    });
    activeSounds.add(sound);
    return new Promise((resolve) => {
      sound.setOnPlaybackStatusUpdate((status) => {
        if (status.didJustFinish) {
          sound.unloadAsync().catch(() => {});
          activeSounds.delete(sound);
          resolve();
        }
      });
    });
  } catch (e) {
    console.warn('[audioService] play failed:', e?.message);
    return null;
  }
}

async function stopAll() {
  for (const s of activeSounds) {
    try { await s.stopAsync(); } catch (_) {}
    try { await s.unloadAsync(); } catch (_) {}
  }
  activeSounds.clear();
}

export default { play, stopAll, setVolumeResolver, isNative: !!AudioMod };
