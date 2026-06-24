/**
 * phase3Clusters.js — Cidade dos Encontros (Phase 3)
 * -----------------------------------------------------------------------------
 * Encontros consonantais (CCV) alinhados ao banco fonético oficial.
 * 5 famílias × 3 sílabas = 15 itens. IDs (`encontro_bra`, `encontro_cle`...)
 * batem 1:1 com o banco → pipeline TTS cobre 100% desta fase.
 *
 * Áudio: lookup em AUDIO_MANIFEST (gerado por wire_audio_manifest.py).
 * -----------------------------------------------------------------------------
 */

import { AUDIO_MANIFEST } from './audioManifest';

function syll(id, letter, ipa) {
  return { id, letter, ipa, audio: AUDIO_MANIFEST[id] };
}

export const CLUSTERS = [
  {
    id: 'BR',
    letter: 'BR',
    label: 'Cluster BR',
    color: '#E94B4B',
    emoji: '🚂',
    hint: 'Como em "braço", "brinco"',
    syllables: [
      syll('encontro_bra', 'BRA', '/bɾa/'),
      syll('encontro_bre', 'BRE', '/bɾe/'),
      syll('encontro_bri', 'BRI', '/bɾi/'),
    ],
  },
  {
    id: 'CL',
    letter: 'CL',
    label: 'Cluster CL',
    color: '#F5C518',
    emoji: '🪨',
    hint: 'Como em "claro", "clima"',
    syllables: [
      syll('encontro_cla', 'CLA', '/kla/'),
      syll('encontro_cle', 'CLE', '/kle/'),
      syll('encontro_cli', 'CLI', '/kli/'),
    ],
  },
  {
    id: 'TR',
    letter: 'TR',
    label: 'Cluster TR',
    color: '#9AE19A',
    emoji: '🚜',
    hint: 'Como em "trator", "três"',
    syllables: [
      syll('encontro_tra', 'TRA', '/tɾa/'),
      syll('encontro_tre', 'TRE', '/tɾe/'),
      syll('encontro_tri', 'TRI', '/tɾi/'),
    ],
  },
  {
    id: 'FL',
    letter: 'FL',
    label: 'Cluster FL',
    color: '#4BC0E9',
    emoji: '🌸',
    hint: 'Como em "flor", "floco"',
    syllables: [
      syll('encontro_fla', 'FLA', '/fla/'),
      syll('encontro_fle', 'FLE', '/fle/'),
      syll('encontro_flo', 'FLO', '/flo/'),
    ],
  },
  {
    id: 'GR',
    letter: 'GR',
    label: 'Cluster GR',
    color: '#C977E5',
    emoji: '🦍',
    hint: 'Como em "grande", "grão"',
    syllables: [
      syll('encontro_gra', 'GRA', '/gɾa/'),
      syll('encontro_gre', 'GRE', '/gɾe/'),
      syll('encontro_gro', 'GRO', '/gɾo/'),
    ],
  },
];

export const CLUSTER_IDS = CLUSTERS.map((c) => c.id);
