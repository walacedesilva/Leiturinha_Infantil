/**
 * progressStore.js
 * -----------------------------------------------------------------------------
 * Store global (Zustand) com persistência em AsyncStorage.
 * Controla os flags de desbloqueio dos mundos do Mapa da Jornada.
 *
 * Regra de negócio (progressão estritamente linear):
 *   vila  -> bairro -> cidade -> reino
 *
 * Um mundo só fica "unlocked" se o anterior estiver "completed".
 * -----------------------------------------------------------------------------
 */

import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Ordem canônica da jornada. NÃO reordenar sem revisar a lógica de desbloqueio.
export const WORLD_ORDER = ['vila', 'bairro', 'cidade', 'reino'];

const initialProgress = {
  vilaCompleted: false,
  bairroCompleted: false,
  cidadeCompleted: false,
  reinoCompleted: false,

  // Última fase tocada (para o CTA inteligente "Continuar X")
  lastPlayed: null,        // 'vila' | 'bairro' | 'cidade' | 'reino' | null
  lastPlayedCompleted: true,

  // Granularidade por estação dentro de cada mundo.
  // Ex.: stationsHeard.vila = ['vogal_a', 'vogal_e', ...]
  stationsHeard: {
    vila: [],
    bairro: [],
    cidade: [],
    reino: [],
  },

  // Desafios já vencidos dentro do mundo (ex.: 'B', 'C', 'D' no Bairro).
  phaseChallenges: {
    vila: [],
    bairro: [],
    cidade: [],
    reino: [],
  },
};

export const useProgressStore = create(
  persist(
    (set, get) => ({
      progress: initialProgress,

      /**
       * Retorna o status visual de um mundo: 'unlocked' | 'locked' | 'completed'.
       * Esta é a ÚNICA fonte de verdade — UI, navegação e deep links devem
       * consultar este método antes de permitir acesso.
       */
      getWorldStatus: (worldId) => {
        const { progress } = get();
        switch (worldId) {
          case 'vila':
            return progress.vilaCompleted ? 'completed' : 'unlocked';
          case 'bairro':
            if (progress.bairroCompleted) return 'completed';
            return progress.vilaCompleted ? 'unlocked' : 'locked';
          case 'cidade':
            if (progress.cidadeCompleted) return 'completed';
            return progress.bairroCompleted ? 'unlocked' : 'locked';
          case 'reino':
            if (progress.reinoCompleted) return 'completed';
            return progress.cidadeCompleted ? 'unlocked' : 'locked';
          default:
            return 'locked';
        }
      },

      /** Guarda predicado: pode navegar para a tela do mundo? */
      canEnter: (worldId) => {
        const status = get().getWorldStatus(worldId);
        return status === 'unlocked' || status === 'completed';
      },

      /** Marca uma fase como concluída (chamado pelas screens das fases). */
      completeWorld: (worldId) =>
        set((state) => {
          const key = `${worldId}Completed`;
          if (!(key in state.progress)) return state;
          return {
            progress: {
              ...state.progress,
              [key]: true,
              lastPlayed: worldId,
              lastPlayedCompleted: true,
            },
          };
        }),

      /** Registra que o usuário entrou numa fase mas ainda não terminou. */
      markPlaying: (worldId) =>
        set((state) => ({
          progress: {
            ...state.progress,
            lastPlayed: worldId,
            lastPlayedCompleted: false,
          },
        })),

      /** Sugestão do CTA flutuante "Jogar Agora / Continuar X / Explorar Mapa". */
      getCallToAction: () => {
        const { progress } = get();
        const allDone =
          progress.vilaCompleted &&
          progress.bairroCompleted &&
          progress.cidadeCompleted &&
          progress.reinoCompleted;

        if (allDone) return { label: 'Explorar Mapa', target: null };

        if (progress.lastPlayed && !progress.lastPlayedCompleted) {
          return {
            label: `Continuar ${labelOf(progress.lastPlayed)}`,
            target: progress.lastPlayed,
          };
        }

        // Próximo mundo desbloqueado e ainda não concluído
        const next = WORLD_ORDER.find(
          (id) => !get().progress[`${id}Completed`] && get().canEnter(id),
        );
        return next
          ? { label: `Jogar ${labelOf(next)}`, target: next }
          : { label: 'Explorar Mapa', target: null };
      },

      /** Reset (uso em "Configurações > Reiniciar jornada"). */
      resetProgress: () => set({ progress: initialProgress }),

      /**
       * Marca uma estação como "ouvida" dentro de um mundo (granular).
       * Idempotente: tocar várias vezes na mesma estação não duplica.
       */
      markStationHeard: (worldId, stationId) =>
        set((state) => {
          const current = state.progress.stationsHeard?.[worldId] || [];
          if (current.includes(stationId)) return state;
          return {
            progress: {
              ...state.progress,
              stationsHeard: {
                ...state.progress.stationsHeard,
                [worldId]: [...current, stationId],
              },
            },
          };
        }),

      /** Lista de IDs de estação já ouvidas no mundo. */
      getStationsHeard: (worldId) =>
        get().progress.stationsHeard?.[worldId] || [],

      /** Verifica se a criança já ouviu TODAS as estações esperadas. */
      hasHeardAll: (worldId, expectedIds) => {
        const heard = get().progress.stationsHeard?.[worldId] || [];
        return expectedIds.every((id) => heard.includes(id));
      },

      /**
       * Marca um sub-desafio do mundo como vencido (ex.: família 'B' no Bairro).
       * Idempotente.
       */
      markChallengePassed: (worldId, challengeId) =>
        set((state) => {
          const current = state.progress.phaseChallenges?.[worldId] || [];
          if (current.includes(challengeId)) return state;
          return {
            progress: {
              ...state.progress,
              phaseChallenges: {
                ...state.progress.phaseChallenges,
                [worldId]: [...current, challengeId],
              },
            },
          };
        }),

      getChallengesPassed: (worldId) =>
        get().progress.phaseChallenges?.[worldId] || [],

      hasPassedAllChallenges: (worldId, expectedIds) => {
        const passed = get().progress.phaseChallenges?.[worldId] || [];
        return expectedIds.every((id) => passed.includes(id));
      },
    }),
    {
      name: 'alfabetizacao-magica:progress',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({ progress: state.progress }),
      version: 3,
      // v1→v3: introduziu stationsHeard (v2) e phaseChallenges (v3).
      // Preserva dados antigos completando o shape novo.
      migrate: (persisted, _fromVersion) => {
        const safe = persisted || {};
        const prev = safe.progress || {};
        return {
          ...safe,
          progress: {
            ...initialProgress,
            ...prev,
            stationsHeard: {
              ...initialProgress.stationsHeard,
              ...(prev.stationsHeard || {}),
            },
            phaseChallenges: {
              ...initialProgress.phaseChallenges,
              ...(prev.phaseChallenges || {}),
            },
          },
        };
      },
    },
  ),
);

function labelOf(id) {
  switch (id) {
    case 'vila':   return 'Vila das Vogais';
    case 'bairro': return 'Bairro das Famílias';
    case 'cidade': return 'Cidade das Sílabas';
    case 'reino':  return 'Reino das Histórias';
    default:       return '';
  }
}
