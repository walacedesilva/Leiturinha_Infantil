import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

/// Registro de uma única sessão de jogo.
class GameSession {
  final DateTime date;           // data/hora de início
  final int durationSeconds;     // duração total
  final int wordsValidated;      // palavras corretas
  final int totalAttempts;       // total de tentativas fonéticas
  final double averageAccuracy;  // média da acurácia STT (0–1)
  final List<String> familiesPlayed;
  final Map<String, int> errorsPerSyllable; // sílaba → qtd de erros

  const GameSession({
    required this.date,
    required this.durationSeconds,
    required this.wordsValidated,
    required this.totalAttempts,
    required this.averageAccuracy,
    required this.familiesPlayed,
    this.errorsPerSyllable = const {},
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'durationSeconds': durationSeconds,
        'wordsValidated': wordsValidated,
        'totalAttempts': totalAttempts,
        'averageAccuracy': averageAccuracy,
        'familiesPlayed': familiesPlayed,
        'errorsPerSyllable': errorsPerSyllable,
      };

  factory GameSession.fromJson(Map<String, dynamic> j) => GameSession(
        date: DateTime.parse(j['date'] as String),
        durationSeconds: j['durationSeconds'] as int,
        wordsValidated: j['wordsValidated'] as int,
        totalAttempts: j['totalAttempts'] as int,
        averageAccuracy: (j['averageAccuracy'] as num).toDouble(),
        familiesPlayed: List<String>.from(j['familiesPlayed'] ?? []),
        errorsPerSyllable: Map<String, int>.from(j['errorsPerSyllable'] ?? {}),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVIÇO
// ─────────────────────────────────────────────────────────────────────────────

/// Rastreia sessões de jogo com persistência em SharedPreferences.
/// Máximo de 90 dias de histórico armazenado localmente.
class SessionTrackingService extends ChangeNotifier {
  final SharedPreferences _prefs;

  static const _key = 'session_history';
  static const _maxDays = 90;

  List<GameSession> _sessions = [];
  List<GameSession> get sessions => List.unmodifiable(_sessions);

  // Estado da sessão em andamento
  DateTime? _sessionStart;
  int _sessionWords = 0;
  int _sessionAttempts = 0;
  double _sessionAccuracySum = 0;
  final Set<String> _sessionFamilies = {};
  final Map<String, int> _sessionErrors = {};

  SessionTrackingService(this._prefs) {
    _load();
  }

  // ── Persistência ──────────────────────────────────────────────────────────

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _sessions = list
          .map((e) => GameSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Dados corrompidos/incompatíveis: começa do zero em vez de quebrar.
      debugPrint('SessionTracking: falha ao ler sessões salvas: $e');
      _sessions = [];
    }
  }

  Future<void> _save() async {
    final json = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await _prefs.setString(_key, json);
  }

  // ── Controle de sessão ────────────────────────────────────────────────────

  /// Inicia uma nova sessão de jogo.
  void startSession() {
    _sessionStart = DateTime.now();
    _sessionWords = 0;
    _sessionAttempts = 0;
    _sessionAccuracySum = 0;
    _sessionFamilies.clear();
    _sessionErrors.clear();
  }

  /// Registra um evento de palavra validada.
  void recordWordValidated({
    required double accuracy,
    required int attemptNumber,
    required String familyKey,
  }) {
    _sessionWords++;
    _sessionAttempts += attemptNumber;
    _sessionAccuracySum += accuracy;
    _sessionFamilies.add(familyKey);
  }

  /// Registra erro em uma sílaba específica.
  void recordSyllableError(String syllable) {
    _sessionErrors[syllable] = (_sessionErrors[syllable] ?? 0) + 1;
  }

  /// Finaliza a sessão em andamento e persiste.
  /// Retorna a [GameSession] gerada.
  Future<GameSession?> endSession() async {
    if (_sessionStart == null) return null;
    final duration =
        DateTime.now().difference(_sessionStart!).inSeconds.clamp(0, 7200);

    final session = GameSession(
      date: _sessionStart!,
      durationSeconds: duration,
      wordsValidated: _sessionWords,
      totalAttempts: _sessionAttempts,
      averageAccuracy:
          _sessionWords == 0 ? 0 : _sessionAccuracySum / _sessionWords,
      familiesPlayed: _sessionFamilies.toList(),
      errorsPerSyllable: Map.from(_sessionErrors),
    );

    _sessionStart = null;

    // Adiciona e mantém apenas os últimos _maxDays dias
    _sessions.add(session);
    final cutoff = DateTime.now().subtract(const Duration(days: _maxDays));
    _sessions.removeWhere((s) => s.date.isBefore(cutoff));

    await _save();
    notifyListeners();
    return session;
  }

  bool get sessionInProgress => _sessionStart != null;

  // ── Consultas ─────────────────────────────────────────────────────────────

  /// Sessões dos últimos N dias.
  List<GameSession> sessionsInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _sessions.where((s) => s.date.isAfter(cutoff)).toList();
  }

  /// Sessões de uma semana específica (7 dias a partir de [weekStart]).
  List<GameSession> sessionsInWeek(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7));
    return _sessions
        .where((s) => s.date.isAfter(weekStart) && s.date.isBefore(end))
        .toList();
  }

  /// Acurácia média por dia (últimos 7 dias). Chave = "Seg", "Ter", etc.
  Map<String, double> dailyAccuracyThisWeek() {
    final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final now = DateTime.now();
    // Encontra a segunda-feira desta semana
    final monday = now.subtract(Duration(days: (now.weekday - 1) % 7));

    final result = <String, double>{};
    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final daySessions = _sessions.where((s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day);
      if (daySessions.isEmpty) continue;
      final avg = daySessions.map((s) => s.averageAccuracy).reduce((a, b) => a + b) /
          daySessions.length;
      result[weekdays[i]] = avg;
    }
    return result;
  }

  /// Sílabas com mais erros acumulados (todas as sessões).
  List<MapEntry<String, int>> topErrorSyllables({int limit = 5}) {
    final combined = <String, int>{};
    for (final s in _sessions) {
      s.errorsPerSyllable.forEach((syl, count) {
        combined[syl] = (combined[syl] ??