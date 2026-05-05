class WordBank {
  static const Map<String, List<String>> words = {
    'GATO': ['GA', 'TO'],
    'BOLA': ['BO', 'LA'],
    'CASA': ['CA', 'SA'],
    'PATO': ['PA', 'TO'],
    'DADO': ['DA', 'DO'],
    'MACA': ['MA', 'CA'], // Maçã simplificada
    'FACA': ['FA', 'CA'],
    'LUA': ['LU', 'A'],
    'SAPO': ['SA', 'PO'],
    'FOGO': ['FO', 'GO'],
  };
  
  // Retorna uma lista com todas as palavras para iniciar o jogo
  static List<String> getWordList() {
    return words.keys.toList();
  }

  // Retorna as sílabas corretas para uma dada palavra
  static List<String> getSyllablesForWord(String word) {
    return words[word] ?? [];
  }
}
