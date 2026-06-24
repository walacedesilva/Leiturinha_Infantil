import 'package:aprenda_a_ler/services/session_tracking_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/fake_prefs.dart';

void main() {
  group('SessionTrackingService', () {
    late SessionTrackingService svc;

    setUp(() async {
      final prefs = await fakePrefs();
      svc = SessionTrackingService(prefs);
    });

    test('histórico começa vazio', () {
      expect(svc.sessions, isEmpty);
    });

    test('startSession não lança exceção', () {
      expect(() => svc.startSession(), returnsNormally);
    });

    test('recordWordValidated não lança exceção', () {
      svc.startSession();
      expect(
        () => svc.recordWordValidated(
          accuracy: 0.9,
          attemptNumber: 1,
          familyKey: 'B',
        ),
        returnsNormally,
      );
    });

    test('finishSession salva uma sessão no histórico', () async {
      svc.startSession();
      svc.recordWordValidated(accuracy: 0.9, attemptNumber: 1, familyKey: 'B');
      await svc.endSession();
      expect(svc.sessions.length, 1);
    });

    test('sessão salva contém o número correto de palavras', () async {
      svc.startSession();
      svc.recordWordValidated(accuracy: 1.0, attemptNumber: 1, familyKey: 'B');
      svc.recordWordValidated(accuracy: 0.8, attemptNumber: 2, familyKey: 'B');
      await svc.endSession();
      expect(svc.sessions.last.wordsValidated, 2);
    });

    test('sessão salva tem familiesPlayed correto', () async {
      svc.startSession();
      svc.recordWordValidated(accuracy: 1.0, attemptNumber: 1, familyKey: 'B');
      svc.recordWordValidated(accuracy: 1.0, attemptNumber: 1, familyKey: 'C');
      await svc.endSession();
      expect(svc.sessions.last.familiesPlayed, containsAll(['B', 'C']));
    });

    test('acurácia média é calculada corretamente', () async {
      svc.startSession();
      svc.recordWordValidated(accuracy: 1.0, attemptNumber: 1, familyKey: 'B');
      svc.recordWordValidated(accuracy: 0.5, attemptNumber: 1, familyKey: 'B');
      await svc.endSession();
      // média de 1.0 e 0.5 = 0.75
      expect(svc.sessions.last.averageAccuracy, closeTo(0.75, 0.01));
    });

    test('múltiplas sessões acumulam no histórico', () async {
      for (int i = 0; i < 3; i++) {
        svc.startSession();
        svc.recordWordValidated(accuracy: 1.0, attemptNumber: 1, familyKey: 'B');
        await svc.endSession();
      }
      expect(svc.sessions.length, 3);
    });

    test('notifica listeners após endSession', () async {
      var called = false;
      svc.addListener(() => called = true);
      svc.startSession();
      await svc.endSession();
      expect(called, isTrue);
    });

    test('persiste sessões entre instâncias', () async {
      final prefs = await fakePrefs();
      final svc1 = SessionTrackingService(prefs);
      svc1.startSession();
      svc1.recordWordValidated(accuracy: 1.0, attemptNumber: 1, familyKey: 'B');
      await svc1.endSession();

      final svc2 = SessionTrackingService(prefs);
      expect(svc2.sessions.length, 1);
    });
  });
}
