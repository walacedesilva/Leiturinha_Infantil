/**
 * wordBank.js
 * -----------------------------------------------------------------------------
 * Banco de palavras para o fluxo de formação de palavras.
 * 16 famílias × 5 palavras = 80 palavras (espelho do word_bank.dart Flutter).
 *
 * Cada família inclui cor (mesma do arquivo de sílabas correspondente) e as
 * 5 palavras com breakdown silábico e require() do áudio correspondente.
 *
 * Os .wav em assets/audio/words/ são placeholders silenciosos até que o
 * pipeline TTS gere os arquivos finais.
 * -----------------------------------------------------------------------------
 */

export const WORD_BANK = [
  {
    id: 'B', color: '#E94B4B',
    words: [
      { word: 'BALA', syllables: ['BA', 'LA'], audio: require('../../../assets/audio/words/bala.wav') },
      { word: 'BELO', syllables: ['BE', 'LO'], audio: require('../../../assets/audio/words/belo.wav') },
      { word: 'BICO', syllables: ['BI', 'CO'], audio: require('../../../assets/audio/words/bico.wav') },
      { word: 'BOLO', syllables: ['BO', 'LO'], audio: require('../../../assets/audio/words/bolo.wav') },
      { word: 'BULE', syllables: ['BU', 'LE'], audio: require('../../../assets/audio/words/bule.wav') },
    ],
  },
  {
    id: 'C', color: '#F5C518',
    words: [
      { word: 'CAMA', syllables: ['CA', 'MA'], audio: require('../../../assets/audio/words/cama.wav') },
      { word: 'CEDO', syllables: ['CE', 'DO'], audio: require('../../../assets/audio/words/cedo.wav') },
      { word: 'CIMA', syllables: ['CI', 'MA'], audio: require('../../../assets/audio/words/cima.wav') },
      { word: 'COCO', syllables: ['CO', 'CO'], audio: require('../../../assets/audio/words/coco.wav') },
      { word: 'CUBO', syllables: ['CU', 'BO'], audio: require('../../../assets/audio/words/cubo.wav') },
    ],
  },
  {
    id: 'D', color: '#9AE19A',
    words: [
      { word: 'DAMA', syllables: ['DA', 'MA'], audio: require('../../../assets/audio/words/dama.wav') },
      { word: 'DEDO', syllables: ['DE', 'DO'], audio: require('../../../assets/audio/words/dedo.wav') },
      { word: 'DINO', syllables: ['DI', 'NO'], audio: require('../../../assets/audio/words/dino.wav') },
      { word: 'DONO', syllables: ['DO', 'NO'], audio: require('../../../assets/audio/words/dono.wav') },
      { word: 'DUNA', syllables: ['DU', 'NA'], audio: require('../../../assets/audio/words/duna.wav') },
    ],
  },
  {
    id: 'F', color: '#4BC0E9',
    words: [
      { word: 'FADA', syllables: ['FA', 'DA'], audio: require('../../../assets/audio/words/fada.wav') },
      { word: 'FENO', syllables: ['FE', 'NO'], audio: require('../../../assets/audio/words/feno.wav') },
      { word: 'FILA', syllables: ['FI', 'LA'], audio: require('../../../assets/audio/words/fila.wav') },
      { word: 'FOCA', syllables: ['FO', 'CA'], audio: require('../../../assets/audio/words/foca.wav') },
      { word: 'FURO', syllables: ['FU', 'RO'], audio: require('../../../assets/audio/words/furo.wav') },
    ],
  },
  {
    id: 'G', color: '#4BC0E9',
    words: [
      { word: 'GATO', syllables: ['GA', 'TO'], audio: require('../../../assets/audio/words/gato.wav') },
      { word: 'GELO', syllables: ['GE', 'LO'], audio: require('../../../assets/audio/words/gelo.wav') },
      { word: 'GIRA', syllables: ['GI', 'RA'], audio: require('../../../assets/audio/words/gira.wav') },
      { word: 'GOLA', syllables: ['GO', 'LA'], audio: require('../../../assets/audio/words/gola.wav') },
      { word: 'GURI', syllables: ['GU', 'RI'], audio: require('../../../assets/audio/words/guri.wav') },
    ],
  },
  {
    id: 'J', color: '#E94B4B',
    words: [
      { word: 'JACA', syllables: ['JA', 'CA'], audio: require('../../../assets/audio/words/jaca.wav') },
      { word: 'JATO', syllables: ['JA', 'TO'], audio: require('../../../assets/audio/words/jato.wav') },
      { word: 'JIPE', syllables: ['JI', 'PE'], audio: require('../../../assets/audio/words/jipe.wav') },
      { word: 'JOGO', syllables: ['JO', 'GO'], audio: require('../../../assets/audio/words/jogo.wav') },
      { word: 'JUBA', syllables: ['JU', 'BA'], audio: require('../../../assets/audio/words/juba.wav') },
    ],
  },
  {
    id: 'L', color: '#9AE19A',
    words: [
      { word: 'LAMA', syllables: ['LA', 'MA'], audio: require('../../../assets/audio/words/lama.wav') },
      { word: 'LEVE', syllables: ['LE', 'VE'], audio: require('../../../assets/audio/words/leve.wav') },
      { word: 'LIMA', syllables: ['LI', 'MA'], audio: require('../../../assets/audio/words/lima.wav') },
      { word: 'LONA', syllables: ['LO', 'NA'], audio: require('../../../assets/audio/words/lona.wav') },
      { word: 'LUPA', syllables: ['LU', 'PA'], audio: require('../../../assets/audio/words/lupa.wav') },
    ],
  },
  {
    id: 'M', color: '#C977E5',
    words: [
      { word: 'MALA', syllables: ['MA', 'LA'], audio: require('../../../assets/audio/words/mala.wav') },
      { word: 'MESA', syllables: ['ME', 'SA'], audio: require('../../../assets/audio/words/mesa.wav') },
      { word: 'MICO', syllables: ['MI', 'CO'], audio: require('../../../assets/audio/words/mico.wav') },
      { word: 'MOLA', syllables: ['MO', 'LA'], audio: require('../../../assets/audio/words/mola.wav') },
      { word: 'MULA', syllables: ['MU', 'LA'], audio: require('../../../assets/audio/words/mula.wav') },
    ],
  },
  {
    id: 'N', color: '#C977E5',
    words: [
      { word: 'NABO', syllables: ['NA', 'BO'], audio: require('../../../assets/audio/words/nabo.wav') },
      { word: 'NENE', syllables: ['NE', 'NE'], audio: require('../../../assets/audio/words/nene.wav') },
      { word: 'NIDO', syllables: ['NI', 'DO'], audio: require('../../../assets/audio/words/nido.wav') },
      { word: 'NOTA', syllables: ['NO', 'TA'], audio: require('../../../assets/audio/words/nota.wav') },
      { word: 'NUCA', syllables: ['NU', 'CA'], audio: require('../../../assets/audio/words/nuca.wav') },
    ],
  },
  {
    id: 'P', color: '#F5C518',
    words: [
      { word: 'PATO', syllables: ['PA', 'TO'], audio: require('../../../assets/audio/words/pato.wav') },
      { word: 'PENA', syllables: ['PE', 'NA'], audio: require('../../../assets/audio/words/pena.wav') },
      { word: 'PICO', syllables: ['PI', 'CO'], audio: require('../../../assets/audio/words/pico.wav') },
      { word: 'POLO', syllables: ['PO', 'LO'], audio: require('../../../assets/audio/words/polo.wav') },
      { word: 'PUMA', syllables: ['PU', 'MA'], audio: require('../../../assets/audio/words/puma.wav') },
    ],
  },
  {
    id: 'R', color: '#E94B4B',
    words: [
      { word: 'RABO', syllables: ['RA', 'BO'], audio: require('../../../assets/audio/words/rabo.wav') },
      { word: 'REDE', syllables: ['RE', 'DE'], audio: require('../../../assets/audio/words/rede.wav') },
      { word: 'RIMA', syllables: ['RI', 'MA'], audio: require('../../../assets/audio/words/rima.wav') },
      { word: 'RODA', syllables: ['RO', 'DA'], audio: require('../../../assets/audio/words/roda.wav') },
      { word: 'RUGA', syllables: ['RU', 'GA'], audio: require('../../../assets/audio/words/ruga.wav') },
    ],
  },
  {
    id: 'S', color: '#9AE19A',
    words: [
      { word: 'SAPO', syllables: ['SA', 'PO'], audio: require('../../../assets/audio/words/sapo.wav') },
      { word: 'SELA', syllables: ['SE', 'LA'], audio: require('../../../assets/audio/words/sela.wav') },
      { word: 'SINO', syllables: ['SI', 'NO'], audio: require('../../../assets/audio/words/sino.wav') },
      { word: 'SOPA', syllables: ['SO', 'PA'], audio: require('../../../assets/audio/words/sopa.wav') },
      { word: 'SUCO', syllables: ['SU', 'CO'], audio: require('../../../assets/audio/words/suco.wav') },
    ],
  },
  {
    id: 'T', color: '#4BC0E9',
    words: [
      { word: 'TATU', syllables: ['TA', 'TU'], audio: require('../../../assets/audio/words/tatu.wav') },
      { word: 'TEMA', syllables: ['TE', 'MA'], audio: require('../../../assets/audio/words/tema.wav') },
      { word: 'TIPO', syllables: ['TI', 'PO'], audio: require('../../../assets/audio/words/tipo.wav') },
      { word: 'TOCA', syllables: ['TO', 'CA'], audio: require('../../../assets/audio/words/toca.wav') },
      { word: 'TUBA', syllables: ['TU', 'BA'], audio: require('../../../assets/audio/words/tuba.wav') },
    ],
  },
  {
    id: 'V', color: '#C977E5',
    words: [
      { word: 'VACA', syllables: ['VA', 'CA'], audio: require('../../../assets/audio/words/vaca.wav') },
      { word: 'VALE', syllables: ['VA', 'LE'], audio: require('../../../assets/audio/words/vale.wav') },
      { word: 'VELA', syllables: ['VE', 'LA'], audio: require('../../../assets/audio/words/vela.wav') },
      { word: 'VIDA', syllables: ['VI', 'DA'], audio: require('../../../assets/audio/words/vida.wav') },
      { word: 'VOTO', syllables: ['VO', 'TO'], audio: require('../../../assets/audio/words/voto.wav') },
    ],
  },
  {
    id: 'X', color: '#F5C518',
    words: [
      { word: 'XALE', syllables: ['XA', 'LE'], audio: require('../../../assets/audio/words/xale.wav') },
      { word: 'XICA', syllables: ['XI', 'CA'], audio: require('../../../assets/audio/words/xica.wav') },
      { word: 'XIXI', syllables: ['XI', 'XI'], audio: require('../../../assets/audio/words/xixi.wav') },
      { word: 'XOTE', syllables: ['XO', 'TE'], audio: require('../../../assets/audio/words/xote.wav') },
      { word: 'XUXU', syllables: ['XU', 'XU'], audio: require('../../../assets/audio/words/xuxu.wav') },
    ],
  },
  {
    id: 'Z', color: '#9AE19A',
    words: [
      { word: 'ZAGA', syllables: ['ZA', 'GA'], audio: require('../../../assets/audio/words/zaga.wav') },
      { word: 'ZAPE', syllables: ['ZA', 'PE'], audio: require('../../../assets/audio/words/zape.wav') },
      { word: 'ZERO', syllables: ['ZE', 'RO'], audio: require('../../../assets/audio/words/zero.wav') },
      { word: 'ZONA', syllables: ['ZO', 'NA'], audio: require('../../../assets/audio/words/zona.wav') },
      { word: 'ZULU', syllables: ['ZU', 'LU'], audio: require('../../../assets/audio/words/zulu.wav') },
    ],
  },
];

/** Mapa indexado por id de família para lookup O(1). */
export const WORD_BANK_BY_ID = Object.fromEntries(
  WORD_BANK.map((f) => [f.id, f]),
);

/** Retorna as palavras de uma família ou [] se não encontrada. */
export function getWordsForFamily(familyId) {
  return WORD_BANK_BY_ID[familyId]?.words ?? [];
}

/** Retorna a cor primária da família ou fallback cinza. */
export function getFamilyColor(familyId) {
  return WORD_BANK_BY_ID[familyId]?.color ?? '#888888';
}
