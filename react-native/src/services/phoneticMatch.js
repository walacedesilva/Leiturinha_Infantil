/**
 * phoneticMatch.js
 * -----------------------------------------------------------------------------
 * Comparação fonética tolerante para fala infantil em pt-BR.
 *
 * Por que não exact match?
 *   - Crianças 4-7 anos têm articulação em desenvolvimento.
 *   - ASR introduz variação ortográfica ("ba" pode virar "bá", "vá", "pá").
 *   - Penalizar match exato gera frustração e abandono.
 *
 * Estratégia:
 *   1. Normalizar (lowercase, sem acento, sem pontuação, trim).
 *   2. Reduzir confusões fonéticas comuns (k→c, qu→k, ph→f, lh→y, nh→ñ…).
 *   3. Levenshtein normalizada.
 *   4. Aceita também: prefixo, sufixo ou contém o alvo (criança fala mais do
 *      que pedimos: "BA, sim, BA!").
 *   5. Bonus: variantes silábicas comuns (ba/bah/baa).
 *
 * Retorna: { ok, score, reason, normalizedSaid, normalizedTarget }
 *   score ∈ [0, 1]  — 1.0 = perfeito.
 *   ok = score ≥ threshold (default 0.75).
 * -----------------------------------------------------------------------------
 */

const DEFAULT_THRESHOLD = 0.75;

function stripDiacritics(s) {
  return s.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
}

function normalize(s) {
  if (!s) return '';
  let t = stripDiacritics(String(s).toLowerCase()).trim();
  // pontuação fora
  t = t.replace(/[.,!?;:"'`´~^()\[\]{}…]/g, '');
  // colapsa espaços
  t = t.replace(/\s+/g, ' ');
  // confusões grafofonéticas comuns
  t = t
    .replace(/qu/g, 'k')
    .replace(/c([eéií])/g, 's$1')
    .replace(/c/g, 'k')
    .replace(/ç/g, 's')
    .replace(/ph/g, 'f')
    .replace(/lh/g, 'y')
    .replace(/nh/g, 'ñ')
    .replace(/rr/g, 'r')
    .replace(/ss/g, 's')
    .replace(/x/g, 'sh')
    .replace(/z/g, 's');
  // colapsa vogais repetidas (baa → ba)
  t = t.replace(/([aeiou])\1+/g, '$1');
  return t;
}

function levenshtein(a, b) {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;
  const v0 = new Array(b.length + 1);
  const v1 = new Array(b.length + 1);
  for (let i = 0; i <= b.length; i++) v0[i] = i;
  for (let i = 0; i < a.length; i++) {
    v1[0] = i + 1;
    for (let j = 0; j < b.length; j++) {
      const cost = a[i] === b[j] ? 0 : 1;
      v1[j + 1] = Math.min(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
    }
    for (let j = 0; j <= b.length; j++) v0[j] = v1[j];
  }
  return v1[b.length];
}

export function matchPhonetic(said, target, { threshold = DEFAULT_THRESHOLD } = {}) {
  const ns = normalize(said);
  const nt = normalize(target);

  if (!nt) {
    return { ok: false, score: 0, reason: 'no-target', normalizedSaid: ns, normalizedTarget: nt };
  }
  if (!ns) {
    return { ok: false, score: 0, reason: 'empty', normalizedSaid: ns, normalizedTarget: nt };
  }

  // Match exato pós-normalização
  if (ns === nt) {
    return { ok: true, score: 1.0, reason: 'exact', normalizedSaid: ns, normalizedTarget: nt };
  }

  // Contém o alvo (criança falou frase em volta)
  if (ns.includes(nt) || nt.includes(ns)) {
    return { ok: true, score: 0.92, reason: 'contains', normalizedSaid: ns, normalizedTarget: nt };
  }

  // Tokens: pega o token mais próximo do alvo
  const tokens = ns.split(' ').filter(Boolean);
  let bestScore = 0;
  let bestToken = ns;
  for (const tok of tokens.length ? tokens : [ns]) {
    const dist = levenshtein(tok, nt);
    const maxLen = Math.max(tok.length, nt.length);
    const score = maxLen === 0 ? 0 : 1 - dist / maxLen;
    if (score > bestScore) { bestScore = score; bestToken = tok; }
  }

  return {
    ok: bestScore >= threshold,
    score: Number(bestScore.toFixed(3)),
    reason: bestScore >= threshold ? 'fuzzy' : 'too-distant',
    normalizedSaid: bestToken,
    normalizedTarget: nt,
  };
}

export default { matchPhonetic, normalize };
