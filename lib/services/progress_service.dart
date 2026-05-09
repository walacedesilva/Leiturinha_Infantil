import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estrutura de progresso por família silábica
class FamilyProgress {
  final String familyKey;
  final int completedWords;
  final int totalWords;
  final List<String> completedWordsList;

  const FamilyProgress({
    required this.familyKey,
    required this.completedWords,
    required this.totalWords,
    required this.completedWordsList,
  });

  double get percentage =>
      totalWords == 0 ? 0.0 : completedWords / totalWords;

  bool get isCompleted => completedWords >= totalWords;
}

/// Serviço de persistência de progresso por família silábica.
/// Usa SharedPreferences com serialização JSON simples.
/// Chave: "progress_<familyKey>" → JSON {"completed": ["GATO", ...]}
class ProgressService extends ChangeNotifier {
  final SharedPreferences _prefs;

  static const String _progressPrefix = 'progress_';
  static const String _lastFamilyKey = 'last_played_family';

  ProgressService(this._prefs);

  // ────────────────────────────────────────────────
  // LEITURA
  // ────────────────────────────────────────────────

  /// Retorna lista de palavras concluídas numa família.
  List<String> getCompletedWords(String familyKey) {
    final raw = _prefs.getString('$_progressPrefix$familyKey');
    if (raw == null) return [];
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return List<String>.from(map['completed'] ?? []);
    } catch (_) {
      return [];
    }
  }

  /// Retorna objeto FamilyProgress com dados calculados.
  FamilyProgress getFamilyProgress(String familyKey, int totalWords) {
    final completed = getCompletedWords(familyKey);
    return FamilyProgress(
      familyKey: familyKey,
      completedWords: completed.length,
      totalWords: totalWords,
      completedWordsList: completed,
    );
  }

  // ────────────────────────────────────────────────
  // ESCRITA
  // ────────────────────────────────────────────────

  /// Marca uma palavra como concluída numa família. Notifica listeners.
  Future<void> markWordCompleted(String familyKey, String word) async {
    final completed = getCompletedWords(familyKey);
    if (!completed.contains(word)) {
      completed.add(word);
      await _save(familyKey, completed);
      notifyListeners();
    }
  }

  /// Reseta o progresso de uma família específica.
  Future<void> resetFamily(String familyKey) async {
    await _prefs.remove('$_progressPrefix$familyKey');
    notifyListeners();
  }

  /// Reseta todo o progresso salvo.
  Future<void> resetAll(List<String> familyKeys) async {
    for (final key in familyKeys) {
      await _prefs.remove('$_progressPrefix$key');
    }
    notifyListeners();
  }

  // ────────────────────────────────────────────────
  // ÚLTIMA FAMÍLIA JOGADA
  // ────────────────────────────────────────────────

  /// Retorna a chave da última família jogada, ou null se nunca jogou.
  String? getLastPlayedFamilyKey() => _prefs.getString(_lastFamilyKey);

  /// Salva a última família jogada.
  Future<void> saveLastPlayedFamily(String familyKey) async {
    await _prefs.setString(_lastFamilyKey, familyKey);
  }

  // ────────────────────────────────────────────────
  // INTERNO
  // ────────────────────────────────────────────────

  Future<void> _save(String familyKey, List<String> completed) async {
    final encoded = json.encode({'completed': completed});
    await _prefs.setString('$_progressPrefix$familyKey', encoded);
  }
}
