/**
 * phase4Stories.js — Reino das Histórias (Phase 4)
 * -----------------------------------------------------------------------------
 * Três mini-histórias que reciclam o vocabulário das fases anteriores.
 *
 * Estrutura de uma história:
 *   { id, title, emoji, color, pages: [Page] }
 *
 * Page:
 *   { text, target, hint? }
 *   - text   : string com o placeholder "{target}" onde a palavra-alvo entra
 *   - target : palavra-alvo (criança lê em voz alta na atividade)
 *
 * Pedagogia:
 *   - Vocabulário restrito a sílabas CV vistas no Bairro (Fase 2).
 *   - Frases curtas (≤8 palavras) com repetição estruturada.
 *   - Sem áudio narrado embutido — a criança constrói o sentido lendo.
 * -----------------------------------------------------------------------------
 */

export const STORIES = [
  {
    id: 'bola_da_mara',
    title: 'A bola da Mara',
    emoji: '⚽',
    color: '#E94B4B',
    pages: [
      { text: 'A {target} é da Mara.',     target: 'BOLA' },
      { text: 'A Mara dá a bola pra {target}.', target: 'DUDA' },
      { text: 'A Duda joga a bola pro {target}.', target: 'BOBO' },
      { text: 'Fim! Que dia bom de {target}.', target: 'BOLA' },
    ],
  },
  {
    id: 'casa_do_caco',
    title: 'A casa do Caco',
    emoji: '🏠',
    color: '#F5C518',
    pages: [
      { text: 'O Caco mora numa {target}.', target: 'CASA' },
      { text: 'Na casa do Caco tem um {target}.', target: 'CACO' },
      { text: 'O Caco come um {target} doce.', target: 'BOLO' },
      { text: 'Que fome boa de {target}!', target: 'BOLO' },
    ],
  },
  {
    id: 'fada_da_floresta',
    title: 'A fada da floresta',
    emoji: '🧚',
    color: '#C977E5',
    pages: [
      { text: 'A {target} mora na floresta.', target: 'FADA' },
      { text: 'A fada cuida do {target}.',     target: 'CIPÓ' },
      { text: 'O macaco bebe o {target}.',     target: 'CAFÉ' },
      { text: 'A fada sorri pra {target}.',    target: 'MIMI' },
    ],
  },
];

export const STORY_IDS = STORIES.map((s) => s.id);
