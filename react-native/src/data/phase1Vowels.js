/**
 * phase1Vowels.js
 * -----------------------------------------------------------------------------
 * 5 vogais (Phase 1). IDs alinhados ao banco fonético.
 *
 * Áudio: lookup em AUDIO_MANIFEST (gerado por
 * tools/tts/wire_audio_manifest.py). Enquanto vazio, `audio` resolve a
 * undefined → audioService faz fallback silencioso.
 *
 * Pipeline para ativar áudio:
 *   python tools\tts\generate_ssml_from_bank.py
 *   python tools\tts\azure_synthesize.py --bank
 *   python tools\tts\wire_audio_manifest.py
 * -----------------------------------------------------------------------------
 */

import { AUDIO_MANIFEST } from './audioManifest';

export const PHASE1_VOWELS = [
  { id: 'vogal_a', letter: 'A', ipa: '/a/', color: '#E94B4B', hint: 'Boca bem aberta',             audio: AUDIO_MANIFEST.vogal_a },
  { id: 'vogal_e', letter: 'E', ipa: '/e/', color: '#F5C518', hint: 'Sorriso leve',                audio: AUDIO_MANIFEST.vogal_e },
  { id: 'vogal_i', letter: 'I', ipa: '/i/', color: '#9AE19A', hint: 'Língua perto do céu da boca', audio: AUDIO_MANIFEST.vogal_i },
  { id: 'vogal_o', letter: 'O', ipa: '/o/', color: '#4BC0E9', hint: 'Lábios redondos',             audio: AUDIO_MANIFEST.vogal_o },
  { id: 'vogal_u', letter: 'U', ipa: '/u/', color: '#C977E5', hint: 'Lábios bem juntinhos',        audio: AUDIO_MANIFEST.vogal_u },
];
