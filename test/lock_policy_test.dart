import 'package:aprenda_a_ler/features/reading_game/domain/lock_policy.dart';
import 'package:aprenda_a_ler/services/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_prefs.dart';

/// Replica o encadeamento usado nas telas de mapa de fases: percorre as fases
/// em ordem, liberando cada uma conforme a anterior é concluída — exatamente a
/// mesma regra (`isLevelUnlocked`) chamada por vila_das_vogais,
/// parque/bairro_das_familias, castelo_das_palavras e distrito_da_construcao.
List<String> _statesFor(List<bool> completed) {
  final states = <String>[];
  var prevCompleted = true; // a 1ª fase está sempre liberada
  for (final isDone in completed) {
    if (isDone) {
      states.add('completed');
    } else if (isLevelUnlocked(prevCompleted: prevCompleted)) {
      states.add('available');
    } else {
      states.add('locked');
    }
    prevCompleted = isDone;
  }
  return states;
}

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // Predicado de desbloqueio
  // ──────────────────────────────────────────────────────────────────────────
  group('isLevelUnlocked', () {
    test('libera quando a fase anterior foi concluída', () {
      expect(isLevelUnlocked(prevCompleted: true), isTrue);
    });

    test('bloqueia quando a anterior não foi concluída e não há progresso', () {
      expect(isLevelUnlocked(prevCompleted: false), isFalse);
    });

    test('não re-bloqueia uma fase já iniciada (hasProgress)', () {
      expect(isLevelUnlocked(prevCompleted: false, hasProgress: true), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Bloqueio sequencial dentro de um distrito
  // ──────────────────────────────────────────────────────────────────────────
  group('Bloqueio sequencial de fases', () {
    test('com progresso zerado, só a 1ª fase abre', () {
      final states = _statesFor([false, false, false, false, false]);
      expect(states.first, 'available');
      expect(states.sublist(1), everyElement('locked'));
    });

    test('concluir a 1ª fase libera a 2ª e mantém as demais travadas', () {
      final states = _statesFor([true, false, false, false, false]);
      expect(states[0], 'completed');
      expect(states[1], 'available');
      expect(states[2], 'locked');
    });

    test('progressão acumulada destrava em cadeia', () {
      final states = _statesFor([true, true, false, false, false]);
      expect(states[0], 'completed');
      expect(states[1], 'completed');
      expect(states[2], 'available');
      expect(states[3], 'locked');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Conclusão de distritos (mapa principal — Praça Central)
  // ──────────────────────────────────────────────────────────────────────────
  group('DistrictCompletion', () {
    late ProgressService p;

    setUp(() async {
      p = ProgressService(await fakePrefs());
    });

    test('sem progresso, nenhum distrito rastreável está completo', () {
      for (final id in const [
        'vogais',
        'silabas',
        'familias',
        'palavras',
        'construcao',
        'circo',
      ]) {
        expect(DistrictCompletion.isComplete(id, p), isFalse, reason: id);
      }
    });

    test("concluir todas as vogais completa o distrito 'vogais'", () async {
      for (final v in const ['A', 'E', 'I', 'O', 'U']) {
        await p.markAllWordsCompleted('vogal_$v', const ['w1', 'w2', 'w3']);
      }
      expect(DistrictCompletion.isComplete('vogais', p), isTrue);
      // o distrito seguinte continua bloqueado
      expect(DistrictCompletion.isComplete('silabas', p), isFalse);
    });

    test('vogais incompletas (falta o U) não completam o distrito', () async {
      for (final v in const ['A', 'E', 'I', 'O']) {
        await p.markAllWordsCompleted('vogal_$v', const ['w1', 'w2', 'w3']);
      }
      expect(DistrictCompletion.isComplete('vogais', p), isFalse);
    });

    test("concluir B,C,D,F,M completa o distrito 'silabas'", () async {
      for (final c in const ['B', 'C', 'D', 'F', 'M']) {
        await p.markAllWordsCompleted(
            'consonant_$c', const ['w1', 'w2', 'w3', 'w4', 'w5']);
      }
      expect(DistrictCompletion.isComplete('silabas', p), isTrue);
    });

    test('id de distrito desconhecido nunca está completo', () {
      expect(DistrictCompletion.isComplete('inexistente', p), isFalse);
    });
  });
}
