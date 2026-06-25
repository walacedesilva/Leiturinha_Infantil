import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gamification_models.dart';
import 'audio_manager.dart';

/// Serviço de gamificação: XP, moedas, badges, streak, adaptação dinâmica.
/// Persiste tudo em SharedPreferences. Notifica listeners ao mudar estado.
class GamificationService extends ChangeNotifier {
  final SharedPreferences _prefs;

  static const _keyCoins    = 'gam_coins';
  static const _keyXp       = 'gam_xp';
  static const _keyBadges   = 'gam_badges';
  static const _keyStreak   = 'gam_streak';
  static const _keyLastPlay = 'gam_last_play';
  static const _keyTotalWords = 'gam_total_words';
  static const _keyConsecFirst = 'gam_consec_first';
  static const _keyFamilies   = 'gam_families';

  late PlayerState _state;
  PlayerState get state => _state;

  GamificationService(this._prefs) {
    _state = _load();
    _updateStreak();
  }

  // ────────────────────────────────────────────────────────────────────────
  // CARGA / SALVAMENTO
  // ────────────────────────────────────────────────────────────────────────

  PlayerState _load() {
    final lastPlayStr = _prefs.getString(_keyLastPlay);
    return PlayerState(
      coins:                _prefs.getInt(_keyCoins) ?? 0,
      xp:                   _prefs.getInt(_keyXp) ?? 0,
      earnedBadgeIds:       Set<String>.from(
          jsonDecode(_prefs.getString(_keyBadges) ?? '[]') as List),
      currentStreak:        _prefs.getInt(_keyStreak) ?? 0,
      lastPlayDate:         lastPlayStr != null
          ? DateTime.tryParse(lastPlayStr)
          : null,
      totalWordsValidated:  _prefs.getInt(_keyTotalWords) ?? 0,
      consecutiveFirstTry:  _prefs.getInt(_keyConsecFirst) ?? 0,
      familiesPlayed:       Set<String>.from(
          jsonDecode(_prefs.getString(_keyFamilies) ?? '[]') as List),
    );
  }

  Future<void> _save() async {
    await Future.wait([
      _prefs.setInt(_keyCoins, _state.coins),
      _prefs.setInt(_keyXp, _state.xp),
      _prefs.setString(_keyBadges, jsonEncode(_state.earnedBadgeIds.toList())),
      _prefs.setInt(_keyStreak, _state.currentStreak),
      if (_state.lastPlayDate != null)
        _prefs.setString(_keyLastPlay, _state.lastPlayDate!.toIso8601String()),
      _prefs.setInt(_keyTotalWords, _state.totalWordsValidated),
      _prefs.setInt(_keyConsecFirst, _state.consecutiveFirstTry),
      _prefs.setString(_keyFamilies, jsonEncode(_state.familiesPlayed.toList())),
    ]);
  }

  // ────────────────────────────────────────────────────────────────────────
  // STREAK DIÁRIO
  // ────────────────────────────────────────────────────────────────────────

  void _updateStreak() {
    final now = DateTime.now();
    final last = _state.lastPlayDate;
    if (last == null) return;
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;
    if (diff > 1) {
      // Quebrou o streak
      _state = _state.copyWith(currentStreak: 0);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // EVENTO PRINCIPAL: palavra validada
  // ────────────────────────────────────────────────────────────────────────

  /// Chame ao validar uma palavra com sucesso (acurácia > limiar).
  /// [attemptNumber]: 1 = primeira tentativa, 2 ou 3 = tentativas seguintes.
  /// [isDualFamily]: se veio de sessão de 2 famílias.
  /// [familyKey]: chave da família (ex: 'B').
  /// Retorna [RewardEvent] com moedas, XP e badges ganhos neste evento.
  Future<RewardEvent> onWordValidated({
    required double accuracy,
    required int attemptNumber,
    required bool isDualFamily,
    required String familyKey,
    bool wordWasNew = true,
  }) async {
    int coins = 0;
    int xp = 0;
    final newBadges = <String>[];
    String label = '';

    // ── Moedas por acerto ────────────────────────────────────────────────
    if (attemptNumber == 1) {
      coins += 5;
      label = '+5 moedas (1ª tentativa)';
    } else {
      coins += 3;
      label = '+3 moedas';
    }
    if (wordWasNew) coins += 2; // bônus palavra nova

    // ── XP: fórmula pedagógica ────────────────────────────────────────────
    xp += (accuracy * 10).round();                // até +10 por acurácia
    if (attemptNumber == 1) xp += 5;             // bônus 1ª tentativa
    if (wordWasNew) xp += 3;                      // bônus palavra nova

    // ── Streak do dia ─────────────────────────────────────────────────────
    final now = DateTime.now();
    final last = _state.lastPlayDate;
    int newStreak = _state.currentStreak;
    if (last == null) {
      newStreak = 1;
    } else {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;
      if (diff == 0) {
        // Mesmo dia — mantém streak
      } else if (diff == 1) {
        newStreak++;
        if (newStreak == 7) coins += 5; // bônus 7 dias seguidos
      } else {
        newStreak = 1;
      }
    }

    // ── Tentativas consecutivas na 1ª ────────────────────────────────────
    int newConsec = attemptNumber == 1
        ? _state.consecutiveFirstTry + 1
        : 0;

    // ── Famílias jogadas ─────────────────────────────────────────────────
    final newFamilies = Set<String>.from(_state.familiesPlayed)..add(familyKey);

    // ── Atualiza contadores ──────────────────────────────────────────────
    final prevBadges = Set<String>.from(_state.earnedBadgeIds);
    final newTotal = _state.totalWordsValidated + 1;

    // ── Verifica badges ──────────────────────────────────────────────────
    void tryBadge(String id) {
      if (!prevBadges.contains(id)) {
        prevBadges.add(id);
        newBadges.add(id);
      }
    }

    if (newTotal == 1) tryBadge('primeira_palavra');
    if (attemptNumber >= 3) tryBadge('persistente');
    if (newStreak >= 7) tryBadge('leitor_semanal');
    if (isDualFamily) tryBadge('combinador');
    if (newConsec >= 5) tryBadge('velocista');
    if (newFamilies.length >= 5) tryBadge('explorador_familias');
    if (prevBadges.length >= 5) tryBadge('colecionador');

    // Badges por família completa (verificados externamente via onFamilyCompleted)

    // ── Salva novo estado ────────────────────────────────────────────────
    _state = _state.copyWith(
      coins: _state.coins + coins,
      xp: _state.xp + xp,
      earnedBadgeIds: prevBadges,
      currentStreak: newStreak,
      lastPlayDate: now,
      totalWordsValidated: newTotal,
      consecutiveFirstTry: newConsec,
      familiesPlayed: newFamilies,
    );
    await _save();
    notifyListeners();

    return RewardEvent(
      coins: coins,
      xp: xp,
      label: label,
      newBadgeIds: newBadges,
    );
  }

  /// Chame quando uma família inteira for concluída.
  Future<RewardEvent> onFamilyCompleted(String familyKey) async {
    int coins = 10;
    int xp = 15;
    final newBadges = <String>[];
    final prevBadges = Set<String>.from(_state.earnedBadgeIds);

    void tryBadge(String id) {
      if (!prevBadges.contains(id)) {
        prevBadges.add(id);
        newBadges.add(id);
      }
    }

    // Badge específico por família
    final familyBadge = 'mestre_${familyKey.toLowerCase()}';
    if (getBadgeById(familyBadge) != null) tryBadge(familyBadge);
    if (prevBadges.length >= 5) tryBadge('colecionador');

    _state = _state.copyWith(
      coins: _state.coins + coins,
      xp: _state.xp + xp,
      earnedBadgeIds: prevBadges,
    );
    await _save();
    notifyListeners();

    return RewardEvent(
      coins: coins,
      xp: xp,
      label: '+10 moedas por completar família!',
      newBadgeIds: newBadges,
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // LOJA — gastar moedas
  // ────────────────────────────────────────────────────────────────────────

  /// Tenta gastar [amount] moedas. Retorna `true` se havia saldo suficiente.
  Future<bool> spendCoins(int amount) async {
    if (_state.coins < amount) return false;
    _state = _state.copyWith(coins: _state.coins - amount);
    await _save();
    notifyListeners();
    return true;
  }

  // ────────────────────────────────────────────────────────────────────────
  // ADAPTAÇÃO DINÂMICA
  // ────────────────────────────────────────────────────────────────────────

  /// Sugestão baseada no desempenho atual.
  DifficultyHint getDifficultyHint(int recentAttempts, int recentErrors) {
    if (_state.consecutiveFirstTry >= 5) {
      return DifficultyHint.increaseChallenge;
    }
    if (recentErrors >= 3) {
      return DifficultyHint.offerHelp;
    }
    return DifficultyHint.normal;
  }

  // ────────────────────────────────────────────────────────────────────────
  // RESET (debug)
  // ────────────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    _state = PlayerState.empty();
    await _save();
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────────────
  // HELPERS: recompensas diretas (usadas por mini-atividades externas)
  // ────────────────────────────────────────────────────────────────────────

  /// Adiciona XP diretamente. [source] é apenas informativo para logs.
  Future<void> addXp(int amount, {String source = ''}) async {
    if (amount <= 0) return;
    _state = _state.copyWith(xp: _state.xp + amount);
    await _save();
    notifyListeners();
  }

  /// Adiciona moedas diretamente.
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _state = _state.copyWith(coins: _state.coins + amount);
    AudioManager().playSFX(SFXType.coin); // tilintar de moeda ao creditar
    await _save();
    notifyListeners();
  }
}

enum DifficultyHint { normal, increaseChallenge, offerHelp }
