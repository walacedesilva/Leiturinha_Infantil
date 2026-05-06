/// Banco de dados estático de palavras para o app offline.
/// Mantém o mapeamento palavra → sílabas e nível de dificuldade.
class WordData {
  final String word;
  final List<String> syllables;
  final int difficulty; // 1: CV simples, 2: CVC, 3: sílabas complexas

  const WordData({
    required this.word,
    required this.syllables,
    this.difficulty = 1,
  });
}

class WordBank {
  // Lista imutável para garantir performance e segurança offline
  static const List<WordData> _words = [
    WordData(word: 'GATO', syllables: ['GA', 'TO'], difficulty: 1),
    WordData(word: 'BOLA', syllables: ['BO', 'LA'], difficulty: 1),
    WordData(word: 'CASA', syllables: ['CA', 'SA'], difficulty: 1),
    WordData(word: 'SAPO', syllables: ['SA', 'PO'], difficulty: 1),
    WordData(word: 'DEDO', syllables: ['DE', 'DO'], difficulty: 1),
    WordData(word: 'PATO', syllables: ['PA', 'TO'], difficulty: 1),
    WordData(word: 'FOGO', syllables: ['FO', 'GO'], difficulty: 1),
    WordData(word: 'LUVA', syllables: ['LU', 'VA'], difficulty: 1),
    WordData(word: 'MESA', syllables: ['ME', 'SA'], difficulty: 1),
    WordData(word: 'BOLO', syllables: ['BO', 'LO'], difficulty: 1),
  ];

  static List<WordData> get allWords => _words;
  static int get count => _words.length;

  /// Retorna a palavra pelo índice. Retorna null se fora do range.
  static WordData? getWordByIndex(int index) {
    return (index >= 0 && index < _words.length) ? _words[index] : null;
  }

  /// Retorna todas as sílabas únicas usadas no banco (útil para pré-carregamento)
  static List<String> get uniqueSyllables {
    return _words
        .expand((w) => w.syllables)
        .toSet()
        .toList()
      ..sort();
  }
}