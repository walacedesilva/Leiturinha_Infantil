import 'package:aprenda_a_ler/services/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/fake_prefs.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // ProgressService
  // ──────────────────────────────────────────────────────────────────────────
  group('ProgressService', () {
    late ProgressService service;

    setUp(() async {
      final prefs = await fakePrefs();
      service = ProgressService(prefs);
    });

    test('getCompletedWords retorna lista vazia para família nova', () {
      expect(service.getCompletedWords('B'), isEmpty);
    });

    test('markWordCompleted adiciona a palavra', () async {
      await service.markWordCompleted('B', 'BALA');
      expect(service.getCompletedWords('B'), contains('BALA'));
    });

    test('markWordCompleted não duplica a mesma palavra', () async {
      await service.markWordCompleted('B', 'BALA');
      await service.markWordCompleted('B', 'BALA');
      final completed = service.getCompletedWords('B');
      expect(completed.where((w) => w == 'BALA').length, 1);
    });

    test('múltiplas palavras são salvas separadamente', () async {
      await service.markWordCompleted('B', 'BALA');
      await service.markWordCompleted('B', 'BELO');
      final completed = service.getCompletedWords('B');
      expect(completed, containsAll(['BALA', 'BELO']));
      expect(completed.length, 2);
    });

    test('progresso de famílias diferentes são independentes', () async {
      await service.markWordCompleted('B', 'BALA');
      await service.markWordCompleted('C', 'CAMA');
      expect(service.getCompletedWords('B'), contains('BALA'));
      expect(service.getCompletedWords('B'), isNot(contains('CAMA')));
      expect(service.getCompletedWords('C'), contains('CAMA'));
    });

    test('getFamilyProgress.percentage=0 quando nenhuma palavra concluída', () {
      final progress = service.getFamilyProgress('B', 5);
      expect(progress.percentage, 0.0);
      expect(progress.isCompleted, isFalse);
    });

    test('getFamilyProgress.percentage=0.4 após 2/5 palavras', () async {
      await service.markWordCompleted('B', 'BALA');
      await service.markWordCompleted('B', 'BELO');
      final progress = service.getFamilyProgress('B', 5);
      expect(progress.percentage, closeTo(0.4, 0.001));
    });

    test('getFamilyProgress.isCompleted=true quando todas concluídas', () async {
      for (final w in ['BALA', 'BELO', 'BICO', 'BOLO', 'BULE']) {
        await service.markWordCompleted('B', w);
      }
      final progress = service.getFamilyProgress('B', 5);
      expect(progress.isCompleted, isTrue);
      expect(progress.percentage, 1.0);
    });

    test('resetFamily limpa todas as palavras da família', () async {
      await service.markWordCompleted('B', 'BALA');
      await service.markWordCompleted('B', 'BELO');
      await service.resetFamily('B');
      expect(service.getCompletedWords('B'), isEmpty);
    });

    test('resetFamily não afeta outras famílias', () async {
      await service.markWordCompleted('B', 'BALA');
      await service.markWordCompleted('C', 'CAMA');
      await service.resetFamily('B');
      expect(service.getCompletedWords('C'), contains('CAMA'));
    });

    test('notifica listeners ao marcar palavra', () async {
      var notified = false;
      service.addListener(() => notified = true);
      await service.markWordCompleted('B', 'BALA');
      expect(notified, isTrue);
    });

    test('notifica listeners ao resetar família', () async {
      var notified = false;
      service.addListener(() => notified = true);
      await service.resetFamily('B');
      expect(notified, isTrue);
    });

    test('persiste entre instâncias com mesmos prefs', () async {
      final prefs = await fakePrefs();
      final svc1 = ProgressService(prefs);
      await svc1.markWordCompleted('B', 'BALA');

      final svc2 = ProgressService(prefs);
      expect(svc2.getCompletedWords('B'), contains('BALA'));
    });
  });
}
