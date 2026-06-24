/**
 * phase2Syllables.js
 * -----------------------------------------------------------------------------
 * Phase 2 — Famílias silábicas CV do banco fonético v1.0.
 * Cada família agrupa 5 sílabas (consoante + 5 vogais).
 *
 * Os .wav já existem em assets/audio/syllables/{ba,be,bi,...}.wav e são
 * pinned em build-time via require().
 * -----------------------------------------------------------------------------
 */

export const FAMILIES = [
  {
    id: 'B', letter: 'B', label: 'Família do B',
    color: '#E94B4B', emoji: '🐝',
    syllables: [
      { id: 'silaba_ba', letter: 'BA', ipa: '/ba/', audio: require('../../../assets/audio/syllables/ba.wav') },
      { id: 'silaba_be', letter: 'BE', ipa: '/be/', audio: require('../../../assets/audio/syllables/be.wav') },
      { id: 'silaba_bi', letter: 'BI', ipa: '/bi/', audio: require('../../../assets/audio/syllables/bi.wav') },
      { id: 'silaba_bo', letter: 'BO', ipa: '/bo/', audio: require('../../../assets/audio/syllables/bo.wav') },
      { id: 'silaba_bu', letter: 'BU', ipa: '/bu/', audio: require('../../../assets/audio/syllables/bu.wav') },
    ],
  },
  {
    id: 'C', letter: 'C', label: 'Família do C',
    color: '#F5C518', emoji: '🐱',
    syllables: [
      { id: 'silaba_ca', letter: 'CA', ipa: '/ka/', audio: require('../../../assets/audio/syllables/ca.wav') },
      { id: 'silaba_ce', letter: 'CE', ipa: '/se/', audio: require('../../../assets/audio/syllables/ce.wav') },
      { id: 'silaba_ci', letter: 'CI', ipa: '/si/', audio: require('../../../assets/audio/syllables/ci.wav') },
      { id: 'silaba_co', letter: 'CO', ipa: '/ko/', audio: require('../../../assets/audio/syllables/co.wav') },
      { id: 'silaba_cu', letter: 'CU', ipa: '/ku/', audio: require('../../../assets/audio/syllables/cu.wav') },
    ],
  },
  {
    id: 'D', letter: 'D', label: 'Família do D',
    color: '#9AE19A', emoji: '🦕',
    syllables: [
      { id: 'silaba_da', letter: 'DA', ipa: '/da/', audio: require('../../../assets/audio/syllables/da.wav') },
      { id: 'silaba_de', letter: 'DE', ipa: '/de/', audio: require('../../../assets/audio/syllables/de.wav') },
      { id: 'silaba_di', letter: 'DI', ipa: '/di/', audio: require('../../../assets/audio/syllables/di.wav') },
      { id: 'silaba_do', letter: 'DO', ipa: '/do/', audio: require('../../../assets/audio/syllables/do.wav') },
      { id: 'silaba_du', letter: 'DU', ipa: '/du/', audio: require('../../../assets/audio/syllables/du.wav') },
    ],
  },
  {
    id: 'F', letter: 'F', label: 'Família do F',
    color: '#4BC0E9', emoji: '🦊',
    syllables: [
      { id: 'silaba_fa', letter: 'FA', ipa: '/fa/', audio: require('../../../assets/audio/syllables/fa.wav') },
      { id: 'silaba_fe', letter: 'FE', ipa: '/fe/', audio: require('../../../assets/audio/syllables/fe.wav') },
      { id: 'silaba_fi', letter: 'FI', ipa: '/fi/', audio: require('../../../assets/audio/syllables/fi.wav') },
      { id: 'silaba_fo', letter: 'FO', ipa: '/fo/', audio: require('../../../assets/audio/syllables/fo.wav') },
      { id: 'silaba_fu', letter: 'FU', ipa: '/fu/', audio: require('../../../assets/audio/syllables/fu.wav') },
    ],
  },
  {
    id: 'M', letter: 'M', label: 'Família do M',
    color: '#C977E5', emoji: '🐭',
    syllables: [
      { id: 'silaba_ma', letter: 'MA', ipa: '/ma/', audio: require('../../../assets/audio/syllables/ma.wav') },
      { id: 'silaba_me', letter: 'ME', ipa: '/me/', audio: require('../../../assets/audio/syllables/me.wav') },
      { id: 'silaba_mi', letter: 'MI', ipa: '/mi/', audio: require('../../../assets/audio/syllables/mi.wav') },
      { id: 'silaba_mo', letter: 'MO', ipa: '/mo/', audio: require('../../../assets/audio/syllables/mo.wav') },
      { id: 'silaba_mu', letter: 'MU', ipa: '/mu/', audio: require('../../../assets/audio/syllables/mu.wav') },
    ],
  },
];

export const FAMILY_IDS = FAMILIES.map((f) => f.id);
