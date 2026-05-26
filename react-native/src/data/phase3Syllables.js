/**
 * phase3Syllables.js
 * -----------------------------------------------------------------------------
 * Phase 3 — As 11 famílias silábicas restantes (G, J, L, N, P, R, S, T, V, X, Z).
 * Complementa a Phase 2 (B, C, D, F, M) do BairroScreen.
 *
 * Nota: J não tem JE, V não tem VU, X não tem XE, Z não tem ZI — esses
 * fonemas não têm arquivos .wav em assets/audio/syllables/ e não aparecem
 * nas palavras do banco de dados.
 * -----------------------------------------------------------------------------
 */

export const FAMILIES_PHASE3 = [
  {
    id: 'G', letter: 'G', label: 'Família do G',
    color: '#4BC0E9', emoji: '🐊',
    syllables: [
      { id: 'silaba_ga', letter: 'GA', ipa: '/ga/', audio: require('../../../assets/audio/syllables/ga.wav') },
      { id: 'silaba_ge', letter: 'GE', ipa: '/ʒe/', audio: require('../../../assets/audio/syllables/ge.wav') },
      { id: 'silaba_gi', letter: 'GI', ipa: '/ʒi/', audio: require('../../../assets/audio/syllables/gi.wav') },
      { id: 'silaba_go', letter: 'GO', ipa: '/go/', audio: require('../../../assets/audio/syllables/go.wav') },
      { id: 'silaba_gu', letter: 'GU', ipa: '/gu/', audio: require('../../../assets/audio/syllables/gu.wav') },
    ],
  },
  {
    id: 'J', letter: 'J', label: 'Família do J',
    color: '#E94B4B', emoji: '🦁',
    syllables: [
      { id: 'silaba_ja', letter: 'JA', ipa: '/ʒa/', audio: require('../../../assets/audio/syllables/ja.wav') },
      { id: 'silaba_ji', letter: 'JI', ipa: '/ʒi/', audio: require('../../../assets/audio/syllables/ji.wav') },
      { id: 'silaba_jo', letter: 'JO', ipa: '/ʒo/', audio: require('../../../assets/audio/syllables/jo.wav') },
      { id: 'silaba_ju', letter: 'JU', ipa: '/ʒu/', audio: require('../../../assets/audio/syllables/ju.wav') },
    ],
  },
  {
    id: 'L', letter: 'L', label: 'Família do L',
    color: '#9AE19A', emoji: '🦋',
    syllables: [
      { id: 'silaba_la', letter: 'LA', ipa: '/la/', audio: require('../../../assets/audio/syllables/la.wav') },
      { id: 'silaba_le', letter: 'LE', ipa: '/le/', audio: require('../../../assets/audio/syllables/le.wav') },
      { id: 'silaba_li', letter: 'LI', ipa: '/li/', audio: require('../../../assets/audio/syllables/li.wav') },
      { id: 'silaba_lo', letter: 'LO', ipa: '/lo/', audio: require('../../../assets/audio/syllables/lo.wav') },
      { id: 'silaba_lu', letter: 'LU', ipa: '/lu/', audio: require('../../../assets/audio/syllables/lu.wav') },
    ],
  },
  {
    id: 'N', letter: 'N', label: 'Família do N',
    color: '#C977E5', emoji: '🐰',
    syllables: [
      { id: 'silaba_na', letter: 'NA', ipa: '/na/', audio: require('../../../assets/audio/syllables/na.wav') },
      { id: 'silaba_ne', letter: 'NE', ipa: '/ne/', audio: require('../../../assets/audio/syllables/ne.wav') },
      { id: 'silaba_ni', letter: 'NI', ipa: '/ni/', audio: require('../../../assets/audio/syllables/ni.wav') },
      { id: 'silaba_no', letter: 'NO', ipa: '/no/', audio: require('../../../assets/audio/syllables/no.wav') },
      { id: 'silaba_nu', letter: 'NU', ipa: '/nu/', audio: require('../../../assets/audio/syllables/nu.wav') },
    ],
  },
  {
    id: 'P', letter: 'P', label: 'Família do P',
    color: '#F5C518', emoji: '🐧',
    syllables: [
      { id: 'silaba_pa', letter: 'PA', ipa: '/pa/', audio: require('../../../assets/audio/syllables/pa.wav') },
      { id: 'silaba_pe', letter: 'PE', ipa: '/pe/', audio: require('../../../assets/audio/syllables/pe.wav') },
      { id: 'silaba_pi', letter: 'PI', ipa: '/pi/', audio: require('../../../assets/audio/syllables/pi.wav') },
      { id: 'silaba_po', letter: 'PO', ipa: '/po/', audio: require('../../../assets/audio/syllables/po.wav') },
      { id: 'silaba_pu', letter: 'PU', ipa: '/pu/', audio: require('../../../assets/audio/syllables/pu.wav') },
    ],
  },
  {
    id: 'R', letter: 'R', label: 'Família do R',
    color: '#E94B4B', emoji: '🚀',
    syllables: [
      { id: 'silaba_ra', letter: 'RA', ipa: '/ʀa/', audio: require('../../../assets/audio/syllables/ra.wav') },
      { id: 'silaba_re', letter: 'RE', ipa: '/ʀe/', audio: require('../../../assets/audio/syllables/re.wav') },
      { id: 'silaba_ri', letter: 'RI', ipa: '/ʀi/', audio: require('../../../assets/audio/syllables/ri.wav') },
      { id: 'silaba_ro', letter: 'RO', ipa: '/ʀo/', audio: require('../../../assets/audio/syllables/ro.wav') },
      { id: 'silaba_ru', letter: 'RU', ipa: '/ʀu/', audio: require('../../../assets/audio/syllables/ru.wav') },
    ],
  },
  {
    id: 'S', letter: 'S', label: 'Família do S',
    color: '#9AE19A', emoji: '🐍',
    syllables: [
      { id: 'silaba_sa', letter: 'SA', ipa: '/sa/', audio: require('../../../assets/audio/syllables/sa.wav') },
      { id: 'silaba_se', letter: 'SE', ipa: '/se/', audio: require('../../../assets/audio/syllables/se.wav') },
      { id: 'silaba_si', letter: 'SI', ipa: '/si/', audio: require('../../../assets/audio/syllables/si.wav') },
      { id: 'silaba_so', letter: 'SO', ipa: '/so/', audio: require('../../../assets/audio/syllables/so.wav') },
      { id: 'silaba_su', letter: 'SU', ipa: '/su/', audio: require('../../../assets/audio/syllables/su.wav') },
    ],
  },
  {
    id: 'T', letter: 'T', label: 'Família do T',
    color: '#4BC0E9', emoji: '🐢',
    syllables: [
      { id: 'silaba_ta', letter: 'TA', ipa: '/ta/', audio: require('../../../assets/audio/syllables/ta.wav') },
      { id: 'silaba_te', letter: 'TE', ipa: '/te/', audio: require('../../../assets/audio/syllables/te.wav') },
      { id: 'silaba_ti', letter: 'TI', ipa: '/ti/', audio: require('../../../assets/audio/syllables/ti.wav') },
      { id: 'silaba_to', letter: 'TO', ipa: '/to/', audio: require('../../../assets/audio/syllables/to.wav') },
      { id: 'silaba_tu', letter: 'TU', ipa: '/tu/', audio: require('../../../assets/audio/syllables/tu.wav') },
    ],
  },
  {
    id: 'V', letter: 'V', label: 'Família do V',
    color: '#C977E5', emoji: '🌺',
    syllables: [
      { id: 'silaba_va', letter: 'VA', ipa: '/va/', audio: require('../../../assets/audio/syllables/va.wav') },
      { id: 'silaba_ve', letter: 'VE', ipa: '/ve/', audio: require('../../../assets/audio/syllables/ve.wav') },
      { id: 'silaba_vi', letter: 'VI', ipa: '/vi/', audio: require('../../../assets/audio/syllables/vi.wav') },
      { id: 'silaba_vo', letter: 'VO', ipa: '/vo/', audio: require('../../../assets/audio/syllables/vo.wav') },
    ],
  },
  {
    id: 'X', letter: 'X', label: 'Família do X',
    color: '#F5C518', emoji: '🎸',
    syllables: [
      { id: 'silaba_xa', letter: 'XA', ipa: '/ʃa/', audio: require('../../../assets/audio/syllables/xa.wav') },
      { id: 'silaba_xi', letter: 'XI', ipa: '/ʃi/', audio: require('../../../assets/audio/syllables/xi.wav') },
      { id: 'silaba_xo', letter: 'XO', ipa: '/ʃo/', audio: require('../../../assets/audio/syllables/xo.wav') },
      { id: 'silaba_xu', letter: 'XU', ipa: '/ʃu/', audio: require('../../../assets/audio/syllables/xu.wav') },
    ],
  },
  {
    id: 'Z', letter: 'Z', label: 'Família do Z',
    color: '#9AE19A', emoji: '⚡',
    syllables: [
      { id: 'silaba_za', letter: 'ZA', ipa: '/za/', audio: require('../../../assets/audio/syllables/za.wav') },
      { id: 'silaba_ze', letter: 'ZE', ipa: '/ze/', audio: require('../../../assets/audio/syllables/ze.wav') },
      { id: 'silaba_zo', letter: 'ZO', ipa: '/zo/', audio: require('../../../assets/audio/syllables/zo.wav') },
      { id: 'silaba_zu', letter: 'ZU', ipa: '/zu/', audio: require('../../../assets/audio/syllables/zu.wav') },
    ],
  },
];

export const FAMILY_IDS_PHASE3 = FAMILIES_PHASE3.map((f) => f.id);
