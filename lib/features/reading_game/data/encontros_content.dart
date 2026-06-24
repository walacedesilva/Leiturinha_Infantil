// ═════════════════════════════════════════════════════════════════════════════
// ENCONTROS CONSONANTAIS — Conteúdo de dados
// Encontros: BR, CL, TR, FL, PR, GR, BL, CR
// ═════════════════════════════════════════════════════════════════════════════

class EncontroEntry {
  final String cluster;      // "BR"
  final String soundHint;    // "BR faz o som de bravo!"
  final String emoji;        // "🦁"
  final String exampleWord;  // "BRAVO"
  final String syllable;     // "BRA"
  final String instruction;  // "Arraste BR + A para fazer BRA!"

  const EncontroEntry({
    required this.cluster,
    required this.soundHint,
    required this.emoji,
    required this.exampleWord,
    required this.syllable,
    required this.instruction,
  });
}

class FactoryWord {
  final String cluster; // "BR"
  final String word;    // "BRASIL"
  final String emoji;   // "🇧🇷"
  final String meaning; // "nosso país"

  const FactoryWord({
    required this.cluster,
    required this.word,
    required this.emoji,
    required this.meaning,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 5 encontros principais da fábrica
// ─────────────────────────────────────────────────────────────────────────────
const kEncontroEntries = <EncontroEntry>[
  EncontroEntry(
    cluster: 'BR',
    soundHint: 'B + R juntos fazem BR de BRAVO!',
    emoji: '🦁',
    exampleWord: 'BRAVO',
    syllable: 'BRA',
    instruction: 'Coloque B e R na esteira para fazer BR!',
  ),
  EncontroEntry(
    cluster: 'CL',
    soundHint: 'C + L juntos fazem CL de CLARO!',
    emoji: '☀️',
    exampleWord: 'CLARO',
    syllable: 'CLA',
    instruction: 'Coloque C e L na esteira para fazer CL!',
  ),
  EncontroEntry(
    cluster: 'TR',
    soundHint: 'T + R juntos fazem TR de TREM!',
    emoji: '🚂',
    exampleWord: 'TREM',
    syllable: 'TRE',
    instruction: 'Coloque T e R na esteira para fazer TR!',
  ),
  EncontroEntry(
    cluster: 'FL',
    soundHint: 'F + L juntos fazem FL de FLOR!',
    emoji: '🌸',
    exampleWord: 'FLOR',
    syllable: 'FLO',
    instruction: 'Coloque F e L na esteira para fazer FL!',
  ),
  EncontroEntry(
    cluster: 'PR',
    soundHint: 'P + R juntos fazem PR de PRATO!',
    emoji: '🍽️',
    exampleWord: 'PRATO',
    syllable: 'PRA',
    instruction: 'Coloque P e R na esteira para fazer PR!',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Palavras da correia de sílabas
// ─────────────────────────────────────────────────────────────────────────────
const kFactoryWords = <FactoryWord>[
  FactoryWord(cluster: 'BR', word: 'BRAVO',   emoji: '🦁', meaning: 'corajoso'),
  FactoryWord(cluster: 'BR', word: 'BRASIL',  emoji: '🇧🇷', meaning: 'nosso país'),
  FactoryWord(cluster: 'BR', word: 'BRINCA',  emoji: '🎮', meaning: 'se diverte'),
  FactoryWord(cluster: 'CL', word: 'CLARO',   emoji: '☀️', meaning: 'luminoso'),
  FactoryWord(cluster: 'CL', word: 'CLUBE',   emoji: '🏟️', meaning: 'grupo'),
  FactoryWord(cluster: 'TR', word: 'TREM',    emoji: '🚂', meaning: 'veículo'),
  FactoryWord(cluster: 'TR', word: 'TRÊS',    emoji: '3️⃣', meaning: 'número'),
  FactoryWord(cluster: 'TR', word: 'TROVÃO',  emoji: '⛈️', meaning: 'barulho'),
  FactoryWord(cluster: 'FL', word: 'FLOR',    emoji: '🌸', meaning: 'planta bonita'),
  FactoryWord(cluster: 'FL', word: 'FLAUTA',  emoji: '🎵', meaning: 'instrumento'),
  FactoryWord(cluster: 'PR', word: 'PRATO',   emoji: '🍽️', meaning: 'para comer'),
  FactoryWord(cluster: 'PR', word: 'PRAIA',   emoji: '🏖️', meaning: 'beira do mar'),
];
