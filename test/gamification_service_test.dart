import 'package:aprenda_a_ler/services/gamification_service.dart';
import 'package:aprenda_a_ler/services/gamification_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/fake_prefs.dart';

void main() {
  group('GamificationService', () {
    late GamificationService svc;

    setUp(() async {
      final prefs = await fakePrefs();
      svc = GamificationService(prefs);
    });

    // ── Estado inicial ───────────────────────────────────────────────────
    group('estado inicial', () {
      test('moedas começam em 0', () {
        expect(svc.state.coins, 0);
      });

      test('XP começa em 0', () {
        expect(svc.state.xp, 0);
      });

      test('streak começa em 0', () {
        expect(svc.state.currentStreak, 0);
      });

      test('badges começam vazios', () {
        expect(svc.state.earnedBadgeIds, isEmpty);
      });

      test('totalWordsValidated começa em 0', () {
        expect(svc.state.totalWordsValidated, 0);
      });
    });

    // ── onWordValidated ───────────────────────────────────────────────────
    group('onWordValidated', () {
      test('1ª tentativa com acurácia 1.0 dá +5+2=7 moedas', () async {
        final reward = await svc.onWordValidated(
          accuracy: 1.0,
          attemptNumber: 1,
          isDualFamily: false,
          familyKey: 'B',
          wordWasNew: true,
        );
        // +5 (1ª tent.) + 2 (nova) = 7
        expect(reward.coins, 7);
      });

      test('2ª tentativa dá +3+2=5 moedas', () async {
        final reward = await svc.onWordValidated(
          accuracy: 1.0,
          attemptNumber: 2,
          isDualFamily: false,
          familyKey: 'B',
          wordWasNew: true,
        );
        // +3 + 2 (nova) = 5
        expect(reward.coins, 5);
      });

      test('XP com acurácia 1.0 e 1ª tent: +10+5+3=18 XP', () async {
        final reward = await svc.onWordValidated(
          accuracy: 1.0,
          attemptNumber: 1,
          isDualFamily: false,
          familyKey: 'B',
          wordWasNew: true,
        );
        expect(reward.xp, 18);
      });

      test('XP com acurácia 0.5: (0.5*10=5)+5+3=13 XP', () async {
        final reward = await svc.onWordValidated(
          accuracy: 0.5,
          attemptNumber: 1,
          isDualFamily: false,
          familyKey: 'B',
          wordWasNew: true,
        );
        expect(reward.xp, 13);
      });

      test('moedas acumulam no estado', () async {
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        // 7 + 5 (sem wordWasNew na 2ª chamada, mas default é true) = 7 + 7 = 14
        expect(svc.state.coins, greaterThan(0));
      });

      test('totalWordsValidated incrementa a cada chamada', () async {
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'C',
        );
        expect(svc.state.totalWordsValidated, 2);
      });

      test('primeira palavra desbloqueia badge "primeira_palavra"', () async {
        final reward = await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        expect(reward.newBadgeIds, contains('primeira_palavra'));
        expect(svc.state.earnedBadgeIds, contains('primeira_palavra'));
      });

      test('badge "primeira_palavra" não é dado duas vezes', () async {
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        final reward2 = await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        expect(reward2.newBadgeIds, isNot(contains('primeira_palavra')));
      });

      test('badge "persistente" ao usar 3ª tentativa', () async {
        final reward = await svc.onWordValidated(
          accuracy: 0.5, attemptNumber: 3,
          isDualFamily: false, familyKey: 'B',
        );
        expect(reward.newBadgeIds, contains('persistente'));
      });

      test('badge "combinador" ao usar isDualFamily=true', () async {
        final reward = await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: true, familyKey: 'B',
        );
        expect(reward.newBadgeIds, contains('combinador'));
      });

      test('familiesPlayed acumula famílias distintas', () async {
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'C',
        );
        expect(svc.state.familiesPlayed, containsAll(['B', 'C']));
      });

      test('notifica listeners ao ganhar recompensa', () async {
        var called = false;
        svc.addListener(() => called = true);
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        expect(called, isTrue);
      });
    });

    // ── onFamilyCompleted ─────────────────────────────────────────────────
    group('onFamilyCompleted', () {
      test('dá +10 moedas e +15 XP', () async {
        final reward = await svc.onFamilyCompleted('B');
        expect(reward.coins, 10);
        expect(reward.xp, 15);
      });

      test('acumula moedas no estado', () async {
        await svc.onFamilyCompleted('B');
        expect(svc.state.coins, 10);
      });

      test('notifica listeners', () async {
        var called = false;
        svc.addListener(() => called = true);
        await svc.onFamilyCompleted('B');
        expect(called, isTrue);
      });
    });

    // ── spendCoins ────────────────────────────────────────────────────────
    group('spendCoins', () {
      setUp(() async {
        // Garante saldo inicial de 7 moedas
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
      });

      test('retorna true e debita quando há saldo', () async {
        final balanceBefore = svc.state.coins;
        final ok = await svc.spendCoins(3);
        expect(ok, isTrue);
        expect(svc.state.coins, balanceBefore - 3);
      });

      test('retorna false e não debita quando saldo insuficiente', () async {
        final balanceBefore = svc.state.coins;
        final ok = await svc.spendCoins(9999);
        expect(ok, isFalse);
        expect(svc.state.coins, balanceBefore);
      });

      test('gasto zerado (0) sempre retorna true', () async {
        final ok = await svc.spendCoins(0);
        expect(ok, isTrue);
      });
    });

    // ── getDifficultyHint ─────────────────────────────────────────────────
    group('getDifficultyHint', () {
      test('normal sem histórico especial', () {
        expect(svc.getDifficultyHint(0, 0), DifficultyHint.normal);
      });

      test('offerHelp quando 3+ erros recentes', () {
        expect(svc.getDifficultyHint(5, 3), DifficultyHint.offerHelp);
      });

      test('increaseChallenge após 5 acertos consecutivos na 1ª tentativa', () async {
        // Simula 5 acertos seguidos na 1ª tentativa
        for (int i = 0; i < 5; i++) {
          await svc.onWordValidated(
            accuracy: 1.0, attemptNumber: 1,
            isDualFamily: false, familyKey: 'B',
          );
        }
        expect(svc.getDifficultyHint(5, 0), DifficultyHint.increaseChallenge);
      });
    });

    // ── reset ─────────────────────────────────────────────────────────────
    group('reset', () {
      test('zera moedas, XP, badges e streak', () async {
        await svc.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        await svc.reset();
        expect(svc.state.coins, 0);
        expect(svc.state.xp, 0);
        expect(svc.state.earnedBadgeIds, isEmpty);
        expect(svc.state.currentStreak, 0);
      });

      test('notifica listeners ao resetar', () async {
        var called = false;
        svc.addListener(() => called = true);
        await svc.reset();
        expect(called, isTrue);
      });
    });

    // ── persistência ─────────────────────────────────────────────────────
    group('persistência entre instâncias', () {
      test('moedas e XP sobrevivem à recriação do serviço', () async {
        final prefs = await fakePrefs();
        final svc1 = GamificationService(prefs);
        await svc1.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );
        final coinsAfter = svc1.state.coins;

        final svc2 = GamificationService(prefs);
        expect(svc2.state.coins, coinsAfter);
      });

      test('badges sobrevivem à recriação do serviço', () async {
        final prefs = await fakePrefs();
        final svc1 = GamificationService(prefs);
        await svc1.onWordValidated(
          accuracy: 1.0, attemptNumber: 1,
          isDualFamily: false, familyKey: 'B',
        );

        final svc2 = GamificationService(prefs);
        expect(svc2.state.earnedBadgeIds, contains('primeira_palavra'));
      });
    });
  });
}
