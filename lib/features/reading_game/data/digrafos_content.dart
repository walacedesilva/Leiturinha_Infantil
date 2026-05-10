// ═════════════════════════════════════════════════════════════════════════════
// DÍGRAFOS CONTENT — dados para as atividades do Distrito dos Dígrafos
// ═════════════════════════════════════════════════════════════════════════════

/// Um dígrafo (par de letras) com suas palavras-exemplo.
class DigrafoEntry {
  final String letter1;      // ex: 'C'
  final String letter2;      // ex: 'H'
  final String combined;     // ex: 'CH'
  final String soundHint;    // ex: 'Som de X!'
  final String emoji;        // ex: '☕'
  final String exampleWord;  // ex: 'CHÁ'
  final String instruction;  // fala da Luna

  const DigrafoEntry({
    required this.letter1,
    required this.letter2,
    required this.combined,
    required this.soundHint,
    required this.emoji,
    required this.exampleWord,
    required this.instruction,
  });
}

const kDigrafoEntries = <DigrafoEntry>[
  DigrafoEntry(
    letter1: 'C',
    letter2: 'H',
    combined: 'CH',
    soundHint: 'Som de X (shh)!',
    emoji: '☕',
    exampleWord: 'CHÁ',
    instruction: 'Junte C com H para formar CH!',
  ),
  DigrafoEntry(
    letter1: 'L',
    letter2: 'H',
    combined: 'LH',
    soundHint: 'Som molhado!',
    emoji: '🍃',
    exampleWord: 'FOLHA',
    instruction: 'Junte L com H para formar LH!',
  ),
  DigrafoEntry(
    letter1: 'N',
    letter2: 'H',
    combined: 'NH',
    soundHint: 'Som nasal!',
    emoji: '🪺',
    exampleWord: 'NINHO',
    instruction: 'Junte N com H para formar NH!',
  ),
  DigrafoEntry(
    letter1: 'Q',
    letter2: 'U',
    combined: 'QU',
    soundHint: 'Som de K!',
    emoji: '🧀',
    exampleWord: 'QUEIJO',
    instruction: 'Junte Q com U para formar QU!',
  ),
  DigrafoEntry(
    letter1: 'G',
    letter2: 'U',
    combined: 'GU',
    soundHint: 'Som de G duro!',
    emoji: '🎸',
    exampleWord: 'GUERRA',
    instruction: 'Junte G com U para formar GU!',
  ),
];

/// Palavras para o Jardim das Palavras, agrupadas por dígrafo.
class GardenWord {
  final String digraph;     // ex: 'CH'
  final String word;        // ex: 'CHÁ'
  final String emoji;
  final String complement;  // sílaba complementar a exibir na borboleta

  const GardenWord({
    required this.digraph,
    required this.word,
    required this.emoji,
    required this.complement,
  });
}

const kGardenWords = <GardenWord>[
  GardenWord(digraph: 'CH', word: 'CHÁ',    emoji: '☕', complement: 'Á'),
  GardenWord(digraph: 'CH', word: 'CHUVA',  emoji: '🌧️', complement: 'UVA'),
  GardenWord(digraph: 'CH', word: 'CHAVE',  emoji: '🗝️', complement: 'AVE'),
  GardenWord(digraph: 'LH', word: 'FOLHA',  emoji: '🍃', complement: 'FO'),
  GardenWord(digraph: 'LH', word: 'ABELHA', emoji: '🐝', complement: 'ABE'),
  GardenWord(digraph: 'NH', word: 'NINHO',  emoji: '🪺', complement: 'NI'),
  GardenWord(digraph: 'NH', word: 'PINHO',  emoji: '🌲', complement: 'PI'),
  GardenWord(digraph: 'QU', word: 'QUEIJO', emoji: '🧀', complement: 'EI'),
  GardenWord(digraph: 'GU', word: 'GUERRA', emoji: '⚔️', complement: 'ERRA'),
  GardenWord(digraph: 'GU', word: 'AGULHA', emoji: '🪡', complement: 'A·LHA'),
];
