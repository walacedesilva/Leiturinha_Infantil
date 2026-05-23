/**
 * consentStore.js
 * -----------------------------------------------------------------------------
 * Store independente para consentimento parental e LGPD.
 *
 * Mantido SEPARADO do progressStore porque:
 *   - Domínios diferentes (compliance vs. progressão pedagógica).
 *   - Reset de jornada NÃO deve revogar consentimento — e vice-versa.
 *   - Política pode evoluir (policyVersion) sem migrar dados de progresso.
 *
 * Princípio LGPD adotado:
 *   - Todos os dados (progresso, áudios capturados) ficam APENAS no device.
 *   - Microfone é opt-in granular (mesmo após consentimento geral).
 *   - Revogação restaura estado pré-consentimento (volta para ConsentScreen).
 * -----------------------------------------------------------------------------
 */

import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Sempre que o texto da política mudar, INCREMENTAR esta constante.
// Usuários com policyVersion anterior verão a tela de consentimento de novo.
export const CURRENT_POLICY_VERSION = 1;

const initialConsent = {
  hasConsented: false,
  consentedAt: null,         // epoch ms
  policyVersion: null,       // versão aceita
  microphoneAllowed: false,  // opt-in granular para ASR
  guardianName: null,        // opcional, livre, sem PII obrigatória
};

export const useConsentStore = create(
  persist(
    (set, get) => ({
      consent: initialConsent,

      /** Concede consentimento parental geral. Não ativa microfone. */
      grant: (guardianName = null) =>
        set({
          consent: {
            ...get().consent,
            hasConsented: true,
            consentedAt: Date.now(),
            policyVersion: CURRENT_POLICY_VERSION,
            guardianName: guardianName || null,
          },
        }),

      /** Opt-in granular para microfone (após consentimento geral). */
      setMicrophone: (allowed) =>
        set({ consent: { ...get().consent, microphoneAllowed: !!allowed } }),

      /** Revoga consentimento. App volta para ConsentScreen. */
      revoke: () => set({ consent: { ...initialConsent } }),

      /**
       * Verifica se o consentimento atual é válido para a política vigente.
       * Se a política mudou, o usuário precisa reconfirmar.
       */
      isCurrentPolicyAccepted: () => {
        const c = get().consent;
        return c.hasConsented && c.policyVersion === CURRENT_POLICY_VERSION;
      },
    }),
    {
      name: 'alfabetizacao-magica:consent',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({ consent: state.consent }),
      version: 1,
    },
  ),
);
