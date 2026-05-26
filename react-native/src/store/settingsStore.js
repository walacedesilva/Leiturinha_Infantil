/**
 * settingsStore.js
 * -----------------------------------------------------------------------------
 * Preferências de UI/UX/Pedagógico + estado de Parental Gate (sessão).
 *
 * Mantido SEPARADO de progressStore e consentStore:
 *   - progressStore: jornada pedagógica (vidas, fases, medalhas)
 *   - consentStore:  LGPD (consentimento, microfone, versão de política)
 *   - settingsStore: tudo que o responsável pode CONFIGURAR (volumes,
 *                    acessibilidade, notificações, dificuldade) + auditoria
 *                    de acessos ao "Área dos Pais".
 *
 * Princípios LGPD-K / Google Play (Designed for Families):
 *   - Notificações de marketing OFF por padrão.
 *   - Sliders de áudio com defaults seguros (sem volume máximo).
 *   - Fonte para dislexia opt-in.
 *   - Reduzir movimento respeita acessibilidade WCAG 2.1.
 *   - Log de acessos ao gate fica apenas no device (auditoria local).
 * -----------------------------------------------------------------------------
 */

import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

// 5 minutos — janela em que o gate parental permanece "destravado"
// para evitar reentrada toda vez que o responsável tocar em outra opção.
export const GATE_TTL_MS = 5 * 60 * 1000;

// Máximo de eventos no log de auditoria (rotação FIFO).
const ACCESS_LOG_MAX = 50;

const initialSettings = {
  // Áudio (0..1)
  volumeMaster: 0.8,
  volumeNarration: 1.0,
  volumeSfx: 0.8,
  volumeMusic: 0.5,
  silentMode: false,        // mantém vibração/háptico, zera áudio

  // Acessibilidade visual
  textScale: 'M',           // 'P' | 'M' | 'G' | 'GG'
  dyslexiaFont: false,
  highContrast: false,
  reduceMotion: false,
  inputMethod: 'voice_touch', // 'voice_touch' | 'touch_only'

  // Pedagógico
  difficulty: 'auto',       // 'auto' | 'easy' | 'hard'
  weeklyReport: false,      // sem backend → fica off; UI marca como indisponível

  // Notificações (push) — granulares (LGPD: marketing OFF por padrão)
  notifMissions: true,
  notifNews: true,
  notifMarketing: false,
};

const initialSession = {
  gateUnlockedUntil: 0,     // epoch ms; > Date.now() ⇒ gate destravado
  accessLog: [],            // [{ ts, method: 'math'|'longPress'|'expired' }]
};

export const useSettingsStore = create(
  persist(
    (set, get) => ({
      settings: initialSettings,
      session: initialSession,

      // ── Updates de preferências ─────────────────────────────────────────
      update: (patch) =>
        set({ settings: { ...get().settings, ...patch } }),

      reset: () => set({ settings: initialSettings }),

      // ── Parental gate (sessão) ──────────────────────────────────────────
      isGateUnlocked: () => Date.now() < get().session.gateUnlockedUntil,

      unlockGate: (method = 'math') => {
        const now = Date.now();
        const log = [
          { ts: now, method },
          ...(get().session.accessLog || []),
        ].slice(0, ACCESS_LOG_MAX);
        set({
          session: {
            gateUnlockedUntil: now + GATE_TTL_MS,
            accessLog: log,
          },
        });
      },

      lockGate: () =>
        set({
          session: { ...get().session, gateUnlockedUntil: 0 },
        }),

      clearAccessLog: () =>
        set({ session: { ...get().session, accessLog: [] } }),
    }),
    {
      name: 'alfabetizacao-magica:settings',
      storage: createJSONStorage(() => AsyncStorage),
      // Não persiste a janela de unlock (segurança: sempre re-pede ao abrir).
      partialize: (state) => ({
        settings: state.settings,
        session: { accessLog: state.session.accessLog, gateUnlockedUntil: 0 },
      }),
      version: 1,
    },
  ),
);

// Helpers reutilizáveis ────────────────────────────────────────────────────
export const TEXT_SCALES = { P: 0.85, M: 1.0, G: 1.15, GG: 1.3 };

export function effectiveVolume(channel, settings) {
  if (settings.silentMode) return 0;
  const ch = {
    narration: settings.volumeNarration,
    sfx: settings.volumeSfx,
    music: settings.volumeMusic,
  }[channel] ?? 1;
  return Math.max(0, Math.min(1, settings.volumeMaster * ch));
}
