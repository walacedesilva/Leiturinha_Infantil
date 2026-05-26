/**
 * settingsBridge.js
 * -----------------------------------------------------------------------------
 * Pontes entre o `settingsStore` (Zustand) e serviços/módulos imperativos
 * (audioService, defaults do <Text/>). Chamado UMA VEZ a partir de App.js.
 *
 * Por que existir?
 *   - audioService é um módulo singleton, não pode usar hooks.
 *   - Defaults de <Text/> ficam globais; melhor consolidar num único lugar.
 *   - Evita imports circulares se audioService importasse o store direto.
 * -----------------------------------------------------------------------------
 */

import { Text } from 'react-native';
import { useSettingsStore, effectiveVolume } from '../store/settingsStore';
import audio from './audioService';

let unsubscribe = null;

function applyToAudio(settings) {
  if (typeof audio.setVolumeResolver === 'function') {
    audio.setVolumeResolver((channel = 'narration') =>
      effectiveVolume(channel, settings),
    );
  }
}

/**
 * Injeta preferências em Text.defaultProps para efeito GLOBAL:
 *   - dyslexiaFont: fontFamily 'OpenDyslexic-Regular' em todo <Text/>
 *   - Demais preferências (textScale, highContrast): via hook useTextStyle
 *     em cada componente, pois requerem conhecer o fontSize base.
 */
function applyToText(settings) {
  if (!Text.defaultProps) Text.defaultProps = {};
  Text.defaultProps.allowFontScaling = false;
  Text.defaultProps.maxFontSizeMultiplier = 1.6;
  // fontFamily no defaultProps.style é mesclado; o style explícito do
  // componente toma precedência — cores, pesos e tamanhos não são afetados.
  Text.defaultProps.style = settings.dyslexiaFont
    ? { fontFamily: 'OpenDyslexic-Regular' }
    : undefined;
}

/**
 * Inicializa o bridge. Idempotente — pode ser chamado várias vezes.
 */
export function initSettingsBridge() {
  if (unsubscribe) unsubscribe();

  const { settings } = useSettingsStore.getState();
  applyToText(settings);
  applyToAudio(settings);

  // Zustand vanilla: subscribe(fn) recebe (state, prevState).
  unsubscribe = useSettingsStore.subscribe((state, prev) => {
    if (state.settings !== prev?.settings) {
      applyToAudio(state.settings);
      applyToText(state.settings);
    }
  });
}

export function disposeSettingsBridge() {
  if (unsubscribe) {
    unsubscribe();
    unsubscribe = null;
  }
}
