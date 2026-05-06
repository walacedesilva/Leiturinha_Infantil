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

  /// Sílabas canônicas da família: apenas as que começam com [key].
  /// Ex: família B → [BA, BE, BI, BO, BU].
  List<String> get canonicalSyllables {
    final keyUpper = key.toUpperCase();
    final result = <String>[];
    final seen = <String>{};
    for (final entry in words) {
      for (final syl in entry.syllables) {
        final s = syl.toUpperCase();
        if (s.startsWith(keyUpper) && seen.add(s)) result.add(s);
      }
    }
    if (result.isEmpty) {
      for (final v in ['A', 'E', 'I', 'O', 'U']) result.add('$keyUpper$v');
    }
    return result;
  }
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

  /// Retorna apenas as sílabas canônicas de uma família (ex: ['BA','BE','BI','BO','BU']).
  /// Sílabas secundárias das palavras (ex: LA de BALA) não são exibidas no seletor.
  static List<String> getSyllablesOfFamily(SyllabicFamily family) {
    return family.canonicalSyllables;
  }

  /// Filtra palavras de [family] cuja sílaba canônica (começa com a chave da família)
  /// está presente em [selected]. Sílabas secundárias não são exigidas.
  static List<WordEntry> filterBySyllables(
    SyllabicFamily family,
    List<String> selected,
  ) {
    if (selected.isEmpty) return [];
    final set = selected.toSet();
    final keyUpper = family.key.toUpperCase();
    return family.words
        .where((e) => e.syllables.any(
              (s) => s.toUpperCase().startsWith(keyUpper) && set.contains(s),
            ))
        .toList();
  }

  // ── Palavras exclusivamente cross-family (não presentes em nenhuma família) ──

  static const Map<String, List<WordEntry>> _crossWords = {
    // B + C
    'B_C': [
      WordEntry(word: 'BOCA',   syllables: ['BO', 'CA']),
      WordEntry(word: 'CABO',   syllables: ['CA', 'BO']),
      WordEntry(word: 'BECO',   syllables: ['BE', 'CO']),
      WordEntry(word: 'CUBA',   syllables: ['CU', 'BA']),
      WordEntry(word: 'CABE',   syllables: ['CA', 'BE']),
      WordEntry(word: 'BOBOCA', syllables: ['BO', 'BO', 'CA']),
      WordEntry(word: 'BICOCA', syllables: ['BI', 'CO', 'CA']),
    ],
    // D + T
    'D_T': [
      WordEntry(word: 'TUDO',   syllables: ['TU', 'DO']),
      WordEntry(word: 'DATA',   syllables: ['DA', 'TA']),
      WordEntry(word: 'DITO',   syllables: ['DI', 'TO']),
      WordEntry(word: 'TODO',   syllables: ['TO', 'DO']),
      WordEntry(word: 'TODA',   syllables: ['TO', 'DA']),
      WordEntry(word: 'DOTE',   syllables: ['DO', 'TE']),
      WordEntry(word: 'DITADO', syllables: ['DI', 'TA', 'DO']),
    ],
    // F + V
    'F_V': [
      WordEntry(word: 'FAVO', syllables: ['FA', 'VO']),
      WordEntry(word: 'FAVA', syllables: ['FA', 'VA']),
    ],
    // L + R
    'L_R': [
      WordEntry(word: 'ROLA', syllables: ['RO', 'LA']),
      WordEntry(word: 'LIRA', syllables: ['LI', 'RA']),
      WordEntry(word: 'ROLO', syllables: ['RO', 'LO']),
      WordEntry(word: 'RELA', syllables: ['RE', 'LA']),
      WordEntry(word: 'RELE', syllables: ['RE', 'LE']),
      WordEntry(word: 'LERO', syllables: ['LE', 'RO']),
      WordEntry(word: 'LORO', syllables: ['LO', 'RO']),
    ],
    // M + P
    'M_P': [
      WordEntry(word: 'MAPA', syllables: ['MA', 'PA']),
      WordEntry(word: 'PUMA', syllables: ['PU', 'MA']),
    ],
    // C + S  (CASA é palavra-âncora essencial)
    'C_S': [
      WordEntry(word: 'CASA', syllables: ['CA', 'SA']),
      WordEntry(word: 'SACO', syllables: ['SA', 'CO']),
      WordEntry(word: 'SOCA', syllables: ['SO', 'CA']),
      WordEntry(word: 'SOCO', syllables: ['SO', 'CO']),
    ],
    // B + S
    'B_S': [
      WordEntry(word: 'SABE', syllables: ['SA', 'BE']),
      WordEntry(word: 'SOBE', syllables: ['SO', 'BE']),
    ],
    // M + S
    'M_S': [
      WordEntry(word: 'SOMA', syllables: ['SO', 'MA']),
      WordEntry(word: 'SUMO', syllables: ['SU', 'MO']),
    ],
  };

  /// Filtra palavras de TODAS as famílias cujas sílabas estão em
  /// [activePrimary] ∪ [activeSecondary], incluindo palavras cross-family.
  /// Garante sem duplicatas via set interno.
  static List<WordEntry> filterByDualFamilies(
    SyllabicFamily primary,
    List<String> activePrimary,
    SyllabicFamily? secondary,
    List<String> activeSecondary,
  ) {
    final allActive = {...activePrimary, ...activeSecondary};
    if (allActive.isEmpty) return [];

    final result = <WordEntry>[];
    final seen = <String>{};

    // Em modo combinação, uma palavra só é elegível se TODAS as suas sílabas
    // pertencerem à família primária OU à secundária (sem sílabas estrangeiras),
    // além de estarem presentes no conjunto ativo selecionado.
    bool isEligible(WordEntry entry) {
      if (secondary != null) {
        final pk = primary.key.toUpperCase();
        final sk = secondary.key.toUpperCase();
        if (!entry.syllables.every(
          (s) =>
              s.toUpperCase().startsWith(pk) ||
              s.toUpperCase().startsWith(sk),
        )) return false;
      }
      return entry.syllables.every((s) => allActive.contains(s));
    }

    // Palavras da família primária
    for (final entry in primary.words) {
      if (!seen.contains(entry.word) && isEligible(entry)) {
        seen.add(entry.word);
        result.add(entry);
      }
    }

    // Palavras da família secundária (modo dual)
    if (secondary != null) {
      for (final entry in secondary.words) {
        if (!seen.contains(entry.word) && isEligible(entry)) {
          seen.add(entry.word);
          result.add(entry);
        }
      }

      // Palavras cross-family específicas do par
      final keys = [primary.key, secondary.key]..sort();
      final pairKey = keys.join('_');
      for (final entry in _crossWords[pairKey] ?? const <WordEntry>[]) {
        if (!seen.contains(entry.word) && isEligible(entry)) {
          seen.add(entry.word);
          result.add(entry);
        }
      }
    }

    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Configuração de sessão com uma ou duas famílias silábicas
// ─────────────────────────────────────────────────────────────────────────────

class DualFamilyConfig {
  final SyllabicFamily primary;
  final List<String> activePrimary;
  final SyllabicFamily? secondary;
  final List<String> activeSecondary;

  const DualFamilyConfig({
    required this.primary,
    required this.activePrimary,
    this.secondary,
    this.activeSecondary = const [],
  });

  bool get isDual => secondary != null && activeSecondary.isNotEmpty;

  /// União de todas as sílabas ativas (primária + secundária).
  List<String> get allActiveSyllables => [...activePrimary, ...activeSecondary];

  /// Chave canônica da sessão (ex: 'B' ou 'B_C').
  String get sessionKey {
    if (!isDual) return primary.key;
    final keys = [primary.key, secondary!.key]..sort();
    return keys.join('_');
  }

  /// Rótulo de exibição (ex: 'Família B + C').
  String get displayLabel {
    if (!isDual) return primary.label;
    return 'Família ${primary.key} + ${secondary!.key}';
  }
}
