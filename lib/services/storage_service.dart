import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _currentIndexKey = 'current_index';
  static const String _scoreKey = 'total_score';
  static const String _completedWordsKey = 'completed_words';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Índice atual da palavra
  int getCurrentIndex() {
    return _prefs.getInt(_currentIndexKey) ?? 0;
  }

  Future<void> saveCurrentIndex(int index) async {
    await _prefs.setInt(_currentIndexKey, index);
  }

  // Pontuação Total
  int getScore() {
    return _prefs.getInt(_scoreKey) ?? 0;
  }

  Future<void> addScore(int points) async {
    int currentScore = getScore();
    await _prefs.setInt(_scoreKey, currentScore + points);
  }

  // Palavras Concluídas
  List<String> getCompletedWords() {
    return _prefs.getStringList(_completedWordsKey) ?? [];
  }

  Future<void> addCompletedWord(String word) async {
    List<String> words = getCompletedWords();
    if (!words.contains(word)) {
      words.add(word);
      await _prefs.setStringList(_completedWordsKey, words);
    }
  }

  // Resetar Progresso (para debug ou recomeço)
  Future<void> resetProgress() async {
    await _prefs.remove(_currentIndexKey);
    await _prefs.remove(_scoreKey);
    await _prefs.remove(_completedWordsKey);
  }
}
