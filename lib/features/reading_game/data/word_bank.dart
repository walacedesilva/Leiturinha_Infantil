/// Modelo de uma palavra com suas sílabas
class WordEntry {
  final String word;
  final List<String> syllables;
  const WordEntry({required this.word, required this.syllables});
}

/// Modelo de uma família silábica com metadados visuais
class SyllabicFamily {
  final String key;        // ex: 'CA'
  final String label;      // ex: 'Família CA'
  final int colorValue;    // ex: 0xFF4DB6AC
  final List<WordEntry> words;

  const SyllabicFamily({
    required this.key,
    required this.label,
    required this.colorValue,
    required this.words,
  });

  int get totalWords => words.length;
}

/// Banco de palavras com todas as famílias silábicas do alfabeto.
/// Cada família tem 5 palavras com 2 sílabas simples (CVCV).
/// Áudios em assets/audio/syllables/<sílaba>.mp3 e assets/audio/words/<palavra>.mp3
class WordBank {
  static const List<SyllabicFamily> families = [
    // ── B ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'B', label: 'Família do B', colorValue: 0xFFE57373,
      words: [
        WordEntry(word: 'BALA', syllables: ['BA', 'LA']),
        WordEntry(word: 'BELO', syllables: ['BE', 'LO']),
        WordEntry(word: 'BICO', syllables: ['BI', 'CO']),
        WordEntry(word: 'BOLO', syllables: ['BO', 'LO']),
        WordEntry(word: 'BULE', syllables: ['BU', 'LE']),
      ],
    ),
    // ── C ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'C', label: 'Família do C', colorValue: 0xFFFFB74D,
      words: [
        WordEntry(word: 'CAMA', syllables: ['CA', 'MA']),
        WordEntry(word: 'CEDO', syllables: ['CE', 'DO']),
        WordEntry(word: 'CIMA', syllables: ['CI', 'MA']),
        WordEntry(word: 'COCO', syllables: ['CO', 'CO']),
        WordEntry(word: 'CUBO', syllables: ['CU', 'BO']),
      ],
    ),
    // ── D ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'D', label: 'Família do D', colorValue: 0xFFFFD54F,
      words: [
        WordEntry(word: 'DAMA', syllables: ['DA', 'MA']),
        WordEntry(word: 'DEDO', syllables: ['DE', 'DO']),
        WordEntry(word: 'DINO', syllables: ['DI', 'NO']),
        WordEntry(word: 'DONO', syllables: ['DO', 'NO']),
        WordEntry(word: 'DUNA', syllables: ['DU', 'NA']),
      ],
    ),
    // ── F ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'F', label: 'Família do F', colorValue: 0xFFAED581,
      words: [
        WordEntry(word: 'FADA', syllables: ['FA', 'DA']),
        WordEntry(word: 'FENO', syllables: ['FE', 'NO']),
        WordEntry(word: 'FILA', syllables: ['FI', 'LA']),
        WordEntry(word: 'FOCA', syllables: ['FO', 'CA']),
        WordEntry(word: 'FURO', syllables: ['FU', 'RO']),
      ],
    ),
    // ── G ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'G', label: 'Família do G', colorValue: 0xFF4DB6AC,
      words: [
        WordEntry(word: 'GATO', syllables: ['GA', 'TO']),
        WordEntry(word: 'GELO', syllables: ['GE', 'LO']),
        WordEntry(word: 'GIRA', syllables: ['GI', 'RA']),
        WordEntry(word: 'GOLA', syllables: ['GO', 'LA']),
        WordEntry(word: 'GURI', syllables: ['GU', 'RI']),
      ],
    ),
    // ── J ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'J', label: 'Família do J', colorValue: 0xFF7986CB,
      words: [
        WordEntry(word: 'JACA', syllables: ['JA', 'CA']),
        WordEntry(word: 'JATO', syllables: ['JA', 'TO']),
        WordEntry(word: 'JIPE', syllables: ['JI', 'PE']),
        WordEntry(word: 'JOGO', syllables: ['JO', 'GO']),
        WordEntry(word: 'JUBA', syllables: ['JU', 'BA']),
      ],
    ),
    // ── L ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'L', label: 'Família do L', colorValue: 0xFFBA68C8,
      words: [
        WordEntry(word: 'LAMA', syllables: ['LA', 'MA']),
        WordEntry(word: 'LEVE', syllables: ['LE', 'VE']),
        WordEntry(word: 'LIMA', syllables: ['LI', 'MA']),
        WordEntry(word: 'LONA', syllables: ['LO', 'NA']),
        WordEntry(word: 'LUPA', syllables: ['LU', 'PA']),
      ],
    ),
    // ── M ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'M', label: 'Família do M', colorValue: 0xFFF06292,
      words: [
        WordEntry(word: 'MALA', syllables: ['MA', 'LA']),
        WordEntry(word: 'MESA', syllables: ['ME', 'SA']),
        WordEntry(word: 'MICO', syllables: ['MI', 'CO']),
        WordEntry(word: 'MOLA', syllables: ['MO', 'LA']),
        WordEntry(word: 'MULA', syllables: ['MU', 'LA']),
      ],
    ),
    // ── N ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'N', label: 'Família do N', colorValue: 0xFF64B5F6,
      words: [
        WordEntry(word: 'NABO', syllables: ['NA', 'BO']),
        WordEntry(word: 'NENE', syllables: ['NE', 'NE']),
        WordEntry(word: 'NIDO', syllables: ['NI', 'DO']),
        WordEntry(word: 'NOTA', syllables: ['NO', 'TA']),
        WordEntry(word: 'NUCA', syllables: ['NU', 'CA']),
      ],
    ),
    // ── P ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'P', label: 'Família do P', colorValue: 0xFF4DD0E1,
      words: [
        WordEntry(word: 'PATO', syllables: ['PA', 'TO']),
        WordEntry(word: 'PENA', syllables: ['PE', 'NA']),
        WordEntry(word: 'PICO', syllables: ['PI', 'CO']),
        WordEntry(word: 'POLO', syllables: ['PO', 'LO']),
        WordEntry(word: 'PUMA', syllables: ['PU', 'MA']),
      ],
    ),
    // ── R ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'R', label: 'Família do R', colorValue: 0xFF81C784,
      words: [
        WordEntry(word: 'RABO', syllables: ['RA', 'BO']),
        WordEntry(word: 'REDE', syllables: ['RE', 'DE']),
        WordEntry(word: 'RIMA', syllables: ['RI', 'MA']),
        WordEntry(word: 'RODA', syllables: ['RO', 'DA']),
        WordEntry(word: 'RUGA', syllables: ['RU', 'GA']),
      ],
    ),
    // ── S ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'S', label: 'Família do S', colorValue: 0xFFFF8A65,
      words: [
        WordEntry(word: 'SAPO', syllables: ['SA', 'PO']),
        WordEntry(word: 'SELA', syllables: ['SE', 'LA']),
        WordEntry(word: 'SINO', syllables: ['SI', 'NO']),
        WordEntry(word: 'SOPA', syllables: ['SO', 'PA']),
        WordEntry(word: 'SUCO', syllables: ['SU', 'CO']),
      ],
    ),
    // ── T ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'T', label: 'Família do T', colorValue: 0xFFA1887F,
      words: [
        WordEntry(word: 'TATU', syllables: ['TA', 'TU']),
        WordEntry(word: 'TEMA', syllables: ['TE', 'MA']),
        WordEntry(word: 'TIPO', syllables: ['TI', 'PO']),
        WordEntry(word: 'TOCA', syllables: ['TO', 'CA']),
        WordEntry(word: 'TUBA', syllables: ['TU', 'BA']),
      ],
    ),
    // ── V ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'V', label: 'Família do V', colorValue: 0xFF90A4AE,
      words: [
        WordEntry(word: 'VACA', syllables: ['VA', 'CA']),
        WordEntry(word: 'VALE', syllables: ['VA', 'LE']),
        WordEntry(word: 'VELA', syllables: ['VE', 'LA']),
        WordEntry(word: 'VIDA', syllables: ['VI', 'DA']),
        WordEntry(word: 'VOTO', syllables: ['VO', 'TO']),
      ],
    ),
    // ── X ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'X', label: 'Família do X', colorValue: 0xFFFFEE58,
      words: [
        WordEntry(word: 'XALE', syllables: ['XA', 'LE']),
        WordEntry(word: 'XICA', syllables: ['XI', 'CA']),
        WordEntry(word: 'XIXI', syllables: ['XI', 'XI']),
        WordEntry(word: 'XOTE', syllables: ['XO', 'TE']),
        WordEntry(word: 'XUXU', syllables: ['XU', 'XU']),
      ],
    ),
    // ── Z ─────────────────────────────────────────────────────────────
    SyllabicFamily(
      key: 'Z', label: 'Família do Z', colorValue: 0xFF9575CD,
      words: [
        WordEntry(word: 'ZAGA', syllables: ['ZA', 'GA']),
        WordEntry(word: 'ZAPE', syllables: ['ZA', 'PE']),
        WordEntry(word: 'ZERO', syllables: ['ZE', 'RO']),
        WordEntry(word: 'ZONA', syllables: ['ZO', 'NA']),
        WordEntry(word: 'ZULU', syllables: ['ZU', 'LU']),
      ],
    ),
  ];

  /// Busca família pelo key. Retorna null se não encontrar.
  static SyllabicFamily? getFamily(String key) {
    try {
      return families.firstWhere((f) => f.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Retorna as sílabas de uma palavra (busca em todas as famílias).
  static List<String> getSyllablesForWord(String word) {
    for (final family in families) {
      for (final entry in family.words) {
        if (entry.word == word) return entry.syllables;
      }
    }
    return [];
  }

  /// Lista de todas as palavras (compatibilidade com código legado).
  static List<String> getWordList() {
    return families.expand((f) => f.words.map((w) => w.word)).toList();
  }

  /// Retorna todas as sílabas únicas de uma família (ex: ['BA','BE','BI','BO','BU']).
  static List<String> getSyllablesOfFamily(SyllabicFamily family) {
    final seen = <String>{};
    final result = <String>[];
    for (final entry in family.words) {
      for (final syl in entry.syllables) {
        if (seen.add(syl)) result.add(syl);
      }
    }
    return result;
  }

  /// Filtra palavras de [family] cujas sílabas estão TODAS em [selected].
  /// Retorna lista vazia se nenhuma palavra puder ser formada.
  static List<WordEntry> filterBySyllables(
    SyllabicFamily family,
    List<String> selected,
  ) {
    if (selected.isEmpty) return [];
    final set = selected.toSet();
    return family.words
        .where((e) => e.syllables.every((s) => set.contains(s)))
        .toList();
  }
}
