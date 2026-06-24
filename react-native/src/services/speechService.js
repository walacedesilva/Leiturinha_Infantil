/**
 * speechService.js
 * -----------------------------------------------------------------------------
 * Wrapper de ASR (Automatic Speech Recognition) à prova de ausência de módulo
 * nativo. Tenta carregar, em ordem:
 *
 *   1. expo-speech-recognition (recomendado para Expo/RN moderno)
 *   2. @react-native-voice/voice (legado, suporte amplo)
 *   3. Fallback: simulação determinística (mesma string esperada após delay)
 *      — permite desenvolver UI/UX sem hardware/permissões.
 *
 * API pública:
 *   - isAvailable() : boolean
 *   - getEngine()   : 'expo' | 'voice' | 'mock'
 *   - requestPermission() : Promise<boolean>
 *   - listen({ lang='pt-BR', mockAnswer=null, timeoutMs=5000 })
 *       → Promise<{ transcript, confidence, engine, simulated }>
 *   - cancel() : Promise<void>
 *
 * IMPORTANTE: O serviço NÃO checa consentimento. Quem consome (UI) deve
 * validar `useConsentStore.consent.microphoneAllowed` ANTES de chamar listen().
 * -----------------------------------------------------------------------------
 */

let ExpoSR = null;
let Voice = null;

try { ExpoSR = require('expo-speech-recognition'); } catch {}
if (!ExpoSR) {
  try { Voice = require('@react-native-voice/voice').default; } catch {}
}

const ENGINE = ExpoSR ? 'expo' : Voice ? 'voice' : 'mock';

let currentSession = null; // { resolve, reject, timer, cleanup }

function clearSession() {
  if (!currentSession) return;
  if (currentSession.timer) clearTimeout(currentSession.timer);
  if (currentSession.cleanup) currentSession.cleanup();
  currentSession = null;
}

/* ---------- API ---------- */

export function isAvailable() { return ENGINE !== 'mock'; }
export function getEngine()   { return ENGINE; }

export async function requestPermission() {
  if (ENGINE === 'expo') {
    try {
      const r = await ExpoSR.ExpoSpeechRecognitionModule
        .requestPermissionsAsync?.();
      return r?.granted ?? r?.status === 'granted' ?? false;
    } catch { return false; }
  }
  if (ENGINE === 'voice') {
    // Voice não tem API formal de pedido — assume granted após primeira use.
    return true;
  }
  return true; // mock sempre "granted"
}

/**
 * Inicia uma sessão de captura.
 * Resolve com { transcript, confidence, engine, simulated }.
 * Rejeita com Error('timeout' | 'error' | 'cancelled' | ...).
 */
export function listen({ lang = 'pt-BR', mockAnswer = null, timeoutMs = 5000 } = {}) {
  cancel(); // garante apenas uma sessão ativa

  return new Promise((resolve, reject) => {
    const session = { resolve, reject, timer: null, cleanup: null };
    currentSession = session;

    session.timer = setTimeout(() => {
      clearSession();
      reject(new Error('timeout'));
    }, timeoutMs);

    if (ENGINE === 'mock') {
      // Simulação: devolve o que foi pedido (mockAnswer) após ~900ms.
      setTimeout(() => {
        if (currentSession !== session) return;
        clearSession();
        resolve({
          transcript: (mockAnswer || '').toString(),
          confidence: 0.99,
          engine: 'mock',
          simulated: true,
        });
      }, 900);
      return;
    }

    if (ENGINE === 'expo') {
      const Mod = ExpoSR.ExpoSpeechRecognitionModule;
      const subs = [];
      const off = () => subs.forEach((s) => s?.remove?.());

      const onResult = (e) => {
        // interimResults=false mas garantimos que só processamos resultado final
        if (e?.isFinal === false) return;
        const r = e?.results?.[0];
        if (!r) return;
        if (currentSession !== session) return;
        clearSession();
        off();
        try { Mod.stop?.(); } catch {}
        resolve({
          transcript: r.transcript || '',
          confidence: r.confidence ?? null,
          engine: 'expo',
          simulated: false,
        });
      };
      const onError = (e) => {
        if (currentSession !== session) return;
        clearSession();
        off();
        reject(new Error(e?.error || 'error'));
      };

      // expo-speech-recognition v56 usa Mod.addListener (NativeModule API)
      subs.push(Mod.addListener?.('result', onResult));
      subs.push(Mod.addListener?.('error', onError));
      session.cleanup = off;

      try {
        Mod.start({
          lang,
          interimResults: false,
          maxAlternatives: 1,
          continuous: false,
        });
      } catch (e) {
        clearSession();
        off();
        reject(e);
      }
      return;
    }

    if (ENGINE === 'voice') {
      const onResults = (e) => {
        const transcript = e?.value?.[0] || '';
        if (currentSession !== session) return;
        clearSession();
        Voice.removeAllListeners?.();
        Voice.stop?.();
        resolve({ transcript, confidence: null, engine: 'voice', simulated: false });
      };
      const onError = (e) => {
        if (currentSession !== session) return;
        clearSession();
        Voice.removeAllListeners?.();
        reject(new Error(e?.error?.message || 'error'));
      };
      Voice.onSpeechResults = onResults;
      Voice.onSpeechError = onError;
      session.cleanup = () => Voice.removeAllListeners?.();

      Voice.start(lang).catch((err) => {
        clearSession();
        Voice.removeAllListeners?.();
        reject(err);
      });
      return;
    }
  });
}

export async function cancel() {
  if (!currentSession) return;
  const s = currentSession;
  clearSession();
  try {
    if (ENGINE === 'expo')  ExpoSR.ExpoSpeechRecognitionModule.stop?.();
    if (ENGINE === 'voice') await Voice.stop?.();
  } catch {}
  try { s.reject(new Error('cancelled')); } catch {}
}

export default { isAvailable, getEngine, requestPermission, listen, cancel };
