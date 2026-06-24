/**
 * useA11y.js
 * -----------------------------------------------------------------------------
 * Hooks reativos para preferências de acessibilidade.
 * Use-os em componentes que precisem reagir em tempo real às mudanças
 * do `settingsStore` feitas pelo responsável na tela de Ajustes.
 * -----------------------------------------------------------------------------
 */

import { useMemo } from 'react';
import { useSettingsStore, TEXT_SCALES } from '../store/settingsStore';

/**
 * @returns {boolean} true se o responsável pediu "Reduzir movimento".
 */
export function useReduceMotion() {
  return useSettingsStore((s) => s.settings.reduceMotion);
}

/**
 * Retorna a duração efetiva de uma animação respeitando "Reduzir movimento".
 * @param {number} ms duração nominal em milissegundos
 * @returns {number} ms ajustados (0 quando reduceMotion = true)
 */
export function useAnimDuration(ms) {
  const reduce = useReduceMotion();
  return reduce ? 0 : ms;
}

/**
 * @returns {number} multiplicador de escala de texto (0.85 .. 1.3).
 */
export function useTextScale() {
  return useSettingsStore((s) => TEXT_SCALES[s.settings.textScale] ?? 1.0);
}

/**
 * @returns {object} objeto pronto para o prop `style` de <Text/>.
 *                   inclui fonte para dislexia + alto contraste opt-in.
 */
export function useTextStyle(baseFontSize = 14) {
  const settings = useSettingsStore((s) => s.settings);
  return useMemo(() => {
    const scale = TEXT_SCALES[settings.textScale] ?? 1.0;
    return {
      fontSize: Math.round(baseFontSize * scale),
      // OpenDyslexic-Regular.otf carregada em App.js via expo-font.
      // Quando não carregada ainda, RN usa fallback do sistema sem erro.
      fontFamily: settings.dyslexiaFont ? 'OpenDyslexic-Regular' : undefined,
      color: settings.highContrast ? '#FFFFFF' : undefined,
    };
  }, [baseFontSize, settings.textScale, settings.dyslexiaFont, settings.highContrast]);
}

/**
 * @returns {{ master:number, narration:number, sfx:number, music:number, silent:boolean }}
 */
export function useAudioPrefs() {
  const s = useSettingsStore((st) => st.settings);
  return {
    master: s.volumeMaster,
    narration: s.volumeNarration,
    sfx: s.volumeSfx,
    music: s.volumeMusic,
    silent: s.silentMode,
  };
}
