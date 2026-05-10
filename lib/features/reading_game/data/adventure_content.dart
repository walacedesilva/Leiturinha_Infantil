// ignore_for_file: constant_identifier_names
/// ═══════════════════════════════════════════════════════════════════════════
/// DISTRITO DA AVENTURA — Banco de Conteúdo
/// Público-alvo : 6–7 anos (leitores emergentes)
/// Progressão   : palavras isoladas → frases simples → textos curtos
/// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// §1  FRASES PROGRESSIVAS (15+)
// ─────────────────────────────────────────────────────────────────────────────

/// Nível de complexidade de uma frase ou atividade.
enum AdventureLevel {
  /// Palavras de 1–2 sílabas, estrutura CV pura (ex: "O GATO MIA")
  beginner,
  /// Frases com 3–5 palavras, vogal nasal ou dígrafo simples
  easy,
  /// Frases com 6–8 palavras, artigos, preposições
  medium,
  /// Frases com 9–12 palavras, advérbios, adjetivos compostos
  hard,
  /// Frases longas, estrutura subordinada, conjunções
  advanced,
}

class ReadingPhrase {
  final String id;
  final String text;
  final AdventureLevel level;
  /// Tradução/explicação curta para exibir depois da leitura
  final String hint;
  /// Emoji representando a cena
  final String emoji;
  /// Palavras-chave para destaque visual
  final List<String> keywords;

  const ReadingPhrase({
    required this.id,
    required this.text,
    required this.level,
    required this.hint,
    required this.emoji,
    required this.keywords,
  });
}

const List<ReadingPhrase> kReadingPhrases = [
  // ── Nível 1: Iniciante ────────────────────────────────────────────────────
  ReadingPhrase(
    id: 'p01',
    text: 'O GATO MIA.',
    level: AdventureLevel.beginner,
    hint: 'O gato faz o som "miau"!',
    emoji: '🐱',
    keywords: ['GATO', 'MIA'],
  ),
  ReadingPhrase(
    id: 'p02',
    text: 'A BOLA ROLA.',
    level: AdventureLevel.beginner,
    hint: 'A bola se move rodando!',
    emoji: '⚽',
    keywords: ['BOLA', 'ROLA'],
  ),
  ReadingPhrase(
    id: 'p03',
    text: 'TODOS SÃO AMIGOS.',
    level: AdventureLevel.beginner,
    hint: 'Amigos brincam juntos!',
    emoji: '🤝',
    keywords: ['TODOS', 'AMIGOS'],
  ),
  ReadingPhrase(
    id: 'p04',
    text: 'O CÃO LATE FORTE.',
    level: AdventureLevel.beginner,
    hint: 'O cachorro ladra bem alto!',
    emoji: '🐶',
    keywords: ['CÃO', 'LATE'],
  ),
  ReadingPhrase(
    id: 'p05',
    text: 'O PATO NADA NO RIO.',
    level: AdventureLevel.easy,
    hint: 'O pato adora a água!',
    emoji: '🦆',
    keywords: ['PATO', 'NADA', 'RIO'],
  ),
  // ── Nível 2: Fácil ───────────────────────────────────────────────────────
  ReadingPhrase(
    id: 'p06',
    text: 'A MENINA LAVA A MÃO.',
    level: AdventureLevel.easy,
    hint: 'Lavar as mãos é muito importante!',
    emoji: '🙌',
    keywords: ['MENINA', 'LAVA', 'MÃO'],
  ),
  ReadingPhrase(
    id: 'p07',
    text: 'O MENINO COME PÃO.',
    level: AdventureLevel.easy,
    hint: 'O pão é um alimento gostoso!',
    emoji: '🍞',
    keywords: ['MENINO', 'COME', 'PÃO'],
  ),
  ReadingPhrase(
    id: 'p08',
    text: 'O SOL BRILHA NO CÉU AZUL.',
    level: AdventureLevel.easy,
    hint: 'O sol nos aquece e ilumina!',
    emoji: '☀️',
    keywords: ['SOL', 'BRILHA', 'CÉU'],
  ),
  ReadingPhrase(
    id: 'p09',
    text: 'A BORBOLETA VOA SOBRE A FLOR.',
    level: AdventureLevel.medium,
    hint: 'A borboleta visita as flores!',
    emoji: '🦋',
    keywords: ['BORBOLETA', 'VOA', 'FLOR'],
  ),
  // ── Nível 3: Médio ───────────────────────────────────────────────────────
  ReadingPhrase(
    id: 'p10',
    text: 'O GATO BRINCOU COM O FIO VERMELHO.',
    level: AdventureLevel.medium,
    hint: 'Gatinhos adoram brincar com fios!',
    emoji: '🧶',
    keywords: ['GATO', 'BRINCOU', 'FIO', 'VERMELHO'],
  ),
  ReadingPhrase(
    id: 'p11',
    text: 'A FADA VIVE NA FLORESTA ENCANTADA.',
    level: AdventureLevel.medium,
    hint: 'A floresta encantada é cheia de magia!',
    emoji: '🧚',
    keywords: ['FADA', 'VIVE', 'FLORESTA'],
  ),
  ReadingPhrase(
    id: 'p12',
    text: 'O COELHO PULA SOBRE A PEDRA GRANDE.',
    level: AdventureLevel.medium,
    hint: 'O coelho é muito ágil!',
    emoji: '🐰',
    keywords: ['COELHO', 'PULA', 'PEDRA'],
  ),
  ReadingPhrase(
    id: 'p13',
    text: 'A JOANINHA TEM BOLINHAS VERMELHAS E PRETAS.',
    level: AdventureLevel.hard,
    hint: 'As bolinhas são a marca da joaninha!',
    emoji: '🐞',
    keywords: ['JOANINHA', 'BOLINHAS', 'VERMELHAS'],
  ),
  // ── Nível 4: Difícil ─────────────────────────────────────────────────────
  ReadingPhrase(
    id: 'p14',
    text: 'O MACACO COMEU A BANANA MADURA E DOCE.',
    level: AdventureLevel.hard,
    hint: 'Macacos amam bananas maduras!',
    emoji: '🐒',
    keywords: ['MACACO', 'BANANA', 'MADURA'],
  ),
  ReadingPhrase(
    id: 'p15',
    text: 'O URSO DORMIU SOB A ÁRVORE GRANDE E FRONDOSA.',
    level: AdventureLevel.hard,
    hint: 'A sombra da árvore é ótima para dormir!',
    emoji: '🐻',
    keywords: ['URSO', 'DORMIU', 'ÁRVORE'],
  ),
  // ── Nível 5: Avançado ────────────────────────────────────────────────────
  ReadingPhrase(
    id: 'p16',
    text: 'O LEÃO E O RATO SE TORNARAM GRANDES AMIGOS.',
    level: AdventureLevel.advanced,
    hint: 'Amizades surgem nos momentos mais inesperados!',
    emoji: '🦁',
    keywords: ['LEÃO', 'RATO', 'AMIGOS'],
  ),
  ReadingPhrase(
    id: 'p17',
    text: 'A TARTARUGA E A LEBRE CORRERAM PELA FLORESTA VERDE.',
    level: AdventureLevel.advanced,
    hint: 'A história da tartaruga e da lebre é famosa!',
    emoji: '🐢',
    keywords: ['TARTARUGA', 'LEBRE', 'CORRERAM'],
  ),
  ReadingPhrase(
    id: 'p18',
    text: 'O PEIXINHO DOURADO MORAVA NO FUNDO DO MAR AZUL.',
    level: AdventureLevel.advanced,
    hint: 'O fundo do mar é cheio de maravilhas!',
    emoji: '🐠',
    keywords: ['PEIXINHO', 'DOURADO', 'MORAVA', 'MAR'],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// §2  MICROCONTOS INTERATIVOS (5+)
// ─────────────────────────────────────────────────────────────────────────────

/// Uma lacuna dentro de um microconto para a criança preencher.
class StoryGap {
  final int position; // índice do segmento onde a lacuna aparece
  final List<String> options; // opções para escolher
  final int correctIndex; // índice correto em [options]
  final String hint; // dica amigável se errar

  const StoryGap({
    required this.position,
    required this.options,
    required this.correctIndex,
    required this.hint,
  });
}

/// Um microconto com lacunas para escolha narrativa.
class MicroStory {
  final String id;
  final String title;
  final String emoji;
  final AdventureLevel level;
  /// Segmentos de texto. Lacunas são marcadas com '' (vazio).
  final List<String> segments;
  final List<StoryGap> gaps;
  /// Moral ou mensagem final após completar
  final String moral;
  /// Cores do tema da história
  final int primaryColorValue;
  final int lightColorValue;

  const MicroStory({
    required this.id,
    required this.title,
    required this.emoji,
    required this.level,
    required this.segments,
    required this.gaps,
    required this.moral,
    required this.primaryColorValue,
    required this.lightColorValue,
  });
}

const List<MicroStory> kMicroStories = [
  // ── Conto 1: O Gato Aventureiro ──────────────────────────────────────────
  MicroStory(
    id: 's01',
    title: 'O Gato Aventureiro',
    emoji: '🐱',
    level: AdventureLevel.beginner,
    segments: [
      'Era uma vez um gato chamado ',
      '.\n\nEle adorava ',
      ' pelo jardim.\n\nUm dia, ele encontrou uma ',
      ' muito bonita.\n\nFeliz, o gato voltou para casa com ela!',
    ],
    gaps: [
      StoryGap(
        position: 0,
        options: ['Miau', 'Bola', 'Sol'],
        correctIndex: 0,
        hint: 'Esse é um nome de som de gato!',
      ),
      StoryGap(
        position: 1,
        options: ['pular', 'dormir', 'voar'],
        correctIndex: 0,
        hint: 'Gatos adoram pular de um lado para o outro!',
      ),
      StoryGap(
        position: 2,
        options: ['flor', 'pedra', 'chuva'],
        correctIndex: 0,
        hint: 'O que pode ser bonita e colorida no jardim?',
      ),
    ],
    moral: '🌟 Toda aventura traz uma surpresa maravilhosa!',
    primaryColorValue: 0xFF06B6D4,
    lightColorValue: 0xFFE0F7FA,
  ),
  // ── Conto 2: A Borboleta e a Flor ────────────────────────────────────────
  MicroStory(
    id: 's02',
    title: 'A Borboleta e a Flor',
    emoji: '🦋',
    level: AdventureLevel.easy,
    segments: [
      'Uma borboleta ',
      ' voou pelo prado.\n\nEla viu uma flor ',
      '.\n\nA flor tinha pétalas ',
      '.\n\nJuntas, elas fizeram o prado mais ',
      '!',
    ],
    gaps: [
      StoryGap(
        position: 0,
        options: ['colorida', 'triste', 'fria'],
        correctIndex: 0,
        hint: 'Borboletas são lindas e cheias de cor!',
      ),
      StoryGap(
        position: 1,
        options: ['sorridente', 'dormindo', 'chorando'],
        correctIndex: 0,
        hint: 'Flores felizes ficam com a cabeça erguida!',
      ),
      StoryGap(
        position: 2,
        options: ['rosas', 'azuis', 'cinzas'],
        correctIndex: 0,
        hint: 'Rosas são vermelhas... mas pétalas rosas são mais comuns!',
      ),
      StoryGap(
        position: 3,
        options: ['bonito', 'escuro', 'pesado'],
        correctIndex: 0,
        hint: 'A beleza deixa tudo mais bonito!',
      ),
    ],
    moral: '🌸 A amizade torna o mundo mais belo!',
    primaryColorValue: 0xFFEC4899,
    lightColorValue: 0xFFFCE7F3,
  ),
  // ── Conto 3: O Urso Dorminhoco ───────────────────────────────────────────
  MicroStory(
    id: 's03',
    title: 'O Urso Dorminhoco',
    emoji: '🐻',
    level: AdventureLevel.medium,
    segments: [
      'O urso Tobias era muito ',
      '.\n\nEle sempre ',
      ' embaixo da grande árvore.\n\nUm dia, a chuva o ',
      '.\n\nEle abriu os olhos e viu um ',
      ' colorido no céu!',
    ],
    gaps: [
      StoryGap(
        position: 0,
        options: ['dorminhoco', 'rápido', 'barulhento'],
        correctIndex: 0,
        hint: 'O nome da história diz tudo!',
      ),
      StoryGap(
        position: 1,
        options: ['dormia', 'corria', 'nadava'],
        correctIndex: 0,
        hint: 'O que um dorminhoco faz?',
      ),
      StoryGap(
        position: 2,
        options: ['acordou', 'abraçou', 'pintou'],
        correctIndex: 0,
        hint: 'A chuva fez ele parar de dormir!',
      ),
      StoryGap(
        position: 3,
        options: ['arco-íris', 'nuvem preta', 'sol quente'],
        correctIndex: 0,
        hint: 'Depois da chuva, sempre aparece algo colorido!',
      ),
    ],
    moral: '🌈 Depois da chuva, sempre vem o arco-íris!',
    primaryColorValue: 0xFF8B5CF6,
    lightColorValue: 0xFFF3E8FF,
  ),
  // ── Conto 4: A Festa da Selva ────────────────────────────────────────────
  MicroStory(
    id: 's04',
    title: 'A Festa da Selva',
    emoji: '🦁',
    level: AdventureLevel.hard,
    segments: [
      'Na selva, o leão resolveu fazer uma ',
      ' para todos os animais.\n\nO elefante trouxe ',
      '.\n\nO macaco trouxe ',
      '.\n\nA cobra trouxe ',
      '.\n\nFoi a festa mais ',
      ' que a selva já viu!',
    ],
    gaps: [
      StoryGap(
        position: 0,
        options: ['festa', 'guerra', 'corrida'],
        correctIndex: 0,
        hint: 'O leão queria celebrar com todos!',
      ),
      StoryGap(
        position: 1,
        options: ['frutas', 'pedras', 'água fria'],
        correctIndex: 0,
        hint: 'Elefantes carregam alimentos para compartilhar!',
      ),
      StoryGap(
        position: 2,
        options: ['bananas', 'livros', 'folhas'],
        correctIndex: 0,
        hint: 'Macacos adoram essa fruta amarela!',
      ),
      StoryGap(
        position: 3,
        options: ['música', 'barulho', 'silêncio'],
        correctIndex: 0,
        hint: 'Cobras se movem com ritmo!',
      ),
      StoryGap(
        position: 4,
        options: ['divertida', 'triste', 'barulhenta'],
        correctIndex: 0,
        hint: 'Uma festa com amigos é sempre...!',
      ),
    ],
    moral: '🎉 Juntos, somos mais felizes!',
    primaryColorValue: 0xFFF59E0B,
    lightColorValue: 0xFFFEF3C7,
  ),
  // ── Conto 5: O Dragão Amigável ───────────────────────────────────────────
  MicroStory(
    id: 's05',
    title: 'O Dragão Amigável',
    emoji: '🐉',
    level: AdventureLevel.advanced,
    segments: [
      'Havia um dragão chamado ',
      ' que morava numa montanha ',
      '.\n\nApesar de ',
      ', ele era muito gentil.\n\nUm dia, uma criança perdida ',
      ' no caminho.\n\nO dragão usou seu fogo para ',
      ' o caminho de volta!',
    ],
    gaps: [
      StoryGap(
        position: 0,
        options: ['Brasi', 'Fogo', 'Nuvem'],
        correctIndex: 0,
        hint: 'Um nome legal para um dragão brasileiro!',
      ),
      StoryGap(
        position: 1,
        options: ['encantada', 'triste', 'escura'],
        correctIndex: 0,
        hint: 'Montanhas de dragões são sempre...!',
      ),
      StoryGap(
        position: 2,
        options: ['ser grande', 'ter asas', 'soprar fogo'],
        correctIndex: 2,
        hint: 'O que é típico e impressionante num dragão?',
      ),
      StoryGap(
        position: 3,
        options: ['se perdeu', 'correu', 'dormiu'],
        correctIndex: 0,
        hint: 'A criança precisava de ajuda!',
      ),
      StoryGap(
        position: 4,
        options: ['iluminar', 'queimar', 'apagar'],
        correctIndex: 0,
        hint: 'O fogo do dragão ajudou a criança a enxergar!',
      ),
    ],
    moral: '💙 Um coração gentil faz grandes amigos!',
    primaryColorValue: 0xFF22C55E,
    lightColorValue: 0xFFF0FDF4,
  ),
  // ── Conto 6: A Estrela Cadente ───────────────────────────────────────────
  MicroStory(
    id: 's06',
    title: 'A Estrela Cadente',
    emoji: '⭐',
    level: AdventureLevel.advanced,
    segments: [
      'Numa noite ',
      ', uma estrela cadente cruzou o céu.\n\nUma menina chamada ',
      ' a viu pela janela.\n\nEla fez um ',
      ' especial.\n\nNa manhã seguinte, encontrou um cachorrinho ',
      ' no jardim!\n\nSeu desejo tinha se ',
      '!',
    ],
    gaps: [
      StoryGap(
        position: 0,
        options: ['estrelada', 'chuvosa', 'nublada'],
        correctIndex: 0,
        hint: 'Para ver estrelas, o céu precisa estar...!',
      ),
      StoryGap(
        position: 1,
        options: ['Luna', 'Chuva', 'Nuvem'],
        correctIndex: 0,
        hint: 'Um nome que lembra a lua e as estrelas!',
      ),
      StoryGap(
        position: 2,
        options: ['desejo', 'desenho', 'barulho'],
        correctIndex: 0,
        hint: 'Ao ver uma estrela cadente, fazemos um...!',
      ),
      StoryGap(
        position: 3,
        options: ['fofo', 'assustador', 'triste'],
        correctIndex: 0,
        hint: 'Cachorrinhos são sempre carinhosos e...!',
      ),
      StoryGap(
        position: 4,
        options: ['realizado', 'esquecido', 'perdido'],
        correctIndex: 0,
        hint: 'O desejo aconteceu de verdade!',
      ),
    ],
    moral: '✨ Acredite nos seus sonhos!',
    primaryColorValue: 0xFF6366F1,
    lightColorValue: 0xFFEEF2FF,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// §3  BANCO DE VOCABULÁRIO
// ─────────────────────────────────────────────────────────────────────────────

class VocabEntry {
  final String word;
  final String definition;
  final String emoji;
  final String exampleSentence;

  const VocabEntry({
    required this.word,
    required this.definition,
    required this.emoji,
    required this.exampleSentence,
  });
}

const List<VocabEntry> kVocabBank = [
  VocabEntry(
    word: 'MIA',
    definition: 'Som que o gato faz.',
    emoji: '🐱',
    exampleSentence: 'O gato mia quando está com fome.',
  ),
  VocabEntry(
    word: 'ROLA',
    definition: 'Quando alguma coisa gira e se move.',
    emoji: '⚽',
    exampleSentence: 'A bola rola pelo chão.',
  ),
  VocabEntry(
    word: 'AMIGOS',
    definition: 'Pessoas ou animais que se gostam.',
    emoji: '🤝',
    exampleSentence: 'Todos são amigos na escola.',
  ),
  VocabEntry(
    word: 'FLORESTA',
    definition: 'Lugar com muitas árvores e animais.',
    emoji: '🌳',
    exampleSentence: 'A fada vive na floresta encantada.',
  ),
  VocabEntry(
    word: 'BORBOLETA',
    definition: 'Inseto lindo com asas coloridas.',
    emoji: '🦋',
    exampleSentence: 'A borboleta voa sobre as flores.',
  ),
  VocabEntry(
    word: 'AVENTURA',
    definition: 'Uma viagem ou história cheia de surpresas.',
    emoji: '🚀',
    exampleSentence: 'Vamos começar nossa grande aventura!',
  ),
  VocabEntry(
    word: 'ENCANTADA',
    definition: 'Algo especial com magia.',
    emoji: '✨',
    exampleSentence: 'A floresta encantada tem muita magia.',
  ),
  VocabEntry(
    word: 'COELHO',
    definition: 'Animal pequeno com orelhas grandes.',
    emoji: '🐰',
    exampleSentence: 'O coelho pula sobre a pedra.',
  ),
  VocabEntry(
    word: 'TARTARUGA',
    definition: 'Animal com casco duro nas costas.',
    emoji: '🐢',
    exampleSentence: 'A tartaruga anda devagar, mas chega lá!',
  ),
  VocabEntry(
    word: 'SELVA',
    definition: 'Floresta tropical com muitos animais.',
    emoji: '🌿',
    exampleSentence: 'Na selva, o leão é o rei.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// §4  PROGRESSO DAS AVENTURAS
// ─────────────────────────────────────────────────────────────────────────────

/// Chaves de progresso para o Distrito da Aventura no ProgressService.
abstract class AdventureProgressKeys {
  static const String phrasePrefix = 'adventure_phrase_';
  static const String storyPrefix = 'adventure_story_';
  static const String totalPhrases = 'adventure_total_phrases';

  static String phraseKey(String phraseId) => '$phrasePrefix$phraseId';
  static String storyKey(String storyId) => '$storyPrefix$storyId';

  static int get phrasesCount => kReadingPhrases.length;
  static int get storiesCount => kMicroStories.length;
}
