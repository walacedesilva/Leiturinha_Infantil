import 'package:aprenda_a_ler/features/reading_game/data/word_bank.dart';
import 'package:aprenda_a_ler/services/gamification_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // WordEntry
  // ──────────────────────────────────────────────────────────────────────────
  group('WordEntry', () {
    const entry = WordEntry(word: 'BALA', syllables: ['BA', 'LA']);

    test('word e syllables corretos', () {
      expect(entry.word, 'BALA');
      expect(entry.syllables, ['BA', 'LA']);
    });

    test('syllables tem 2 itens', () {
      expect(entry.syllables.length, 2);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SyllabicFamily
  // ──────────────────────────────────────────────────────────────────────────
  group('SyllabicFamily', () {
    const family = SyllabicFamily(
      key: 'B',
      label: 'Família do B',
      colorValue: 0xFFE57373,
      words: [
        WordEntry(word: 'BALA', syllables: ['BA', 'LA']),
        WordEntry(word: 'BELO', syllables: ['BE', 'LO']),
        WordEntry(word: 'BICO', syllables: ['BI', 'CO']),
        WordEntry(word: 'BOLO', syllables: ['BO', 'LO']),
        WordEntry(word: 'BULE', syllables: ['BU', 'LE']),
      ],
    );

    test('totalWords retorna 5', () {
      expect(family.totalWords, 5);
    });

    test('canonicalSyllables contém todas as sílabas com B', () {
      final syls = family.canonicalSyllables;
      expect(syls, containsAll(['BA', 'BE', 'BI', 'BO', 'BU']));
    });

    test('canonicalSyllables não contém duplicatas', () {
      final syls = family.canonicalSyllables;
      expect(syls.toSet().length, syls.length);
    });

    test('canonicalSyllables não inclui sílabas de outras famílias', () {
      for (final s in family.canonicalSyllables) {
        expect(s.startsWith('B'), isTrue,
            reason: 'Sílaba $s não começa com B');
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // WordBank — conteúdo básico
  // ──────────────────────────────────────────────────────────────────────────
  group('WordBank', () {
    test('tem pelo menos 10 famílias', () {
      expect(WordBank.families.length, greaterThanOrEqualTo(10));
    });

    test('nenhuma família tem key vazia', () {
      for (final f in WordBank.families) {
        expect(f.key.isNotEmpty, isTrue, reason: 'Família "${f.label}" tem key vazia');
      }
    });

    test('cada família tem pelo menos 1 palavra', () {
      for (final f in WordBank.families) {
        expect(f.words.isNotEmpty, isTrue,
            reason: 'Família ${f.key} não tem palavras');
      }
    });

    test('nenhuma palavra tem sílabas vazias', () {
      for (final f in WordBank.families) {
        for (final w in f.words) {
          for (final s in w.syllables) {
            expect(s.isNotEmpty, isTrue,
                reason: 'Palavra ${w.word} tem sílaba vazia');
          }
        }
      }
    });

    test('keys das famílias são únicas', () {
      final keys = WordBank.families.map((f) => f.key).toList();
      expect(keys.toSet().length, keys.length);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // PlayerLevel / XP
  // ──────────────────────────────────────────────────────────────────────────
  group('PlayerLevel e XP', () {
    test('xp=0 retorna nível 1 (Explorador)', () {
      final lvl = getLevelForXp(0);
      expect(lvl.level, 1);
      expect(lvl.name, 'Explorador');
    });

    test('xp=50 sobe para nível 2 (Aprendiz)', () {
      expect(getLevelForXp(50).level, 2);
    });

    test('xp=600 é nível máximo (Mestre das Palavras)', () {
      final lvl = getLevelForXp(600);
      expect(lvl.level, 5);
      expect(lvl.name, 'Mestre das Palavras');
    });

    test('xp acima do máximo mantém nível 5', () {
      expect(getLevelForXp(9999).level, 5);
    });

    test('getNextLevel retorna null no nível máximo', () {
      expect(getNextLevel(600), isNull);
    });

    test('xpProgressInLevel: xp=0 → 0.0', () {
      expect(xpProgressInLevel(0), 0.0);
    });

    test('xpProgressInLevel: xp=25 (metade do nível 1→2) → 0.5', () {
      // nível 1: 0–50; no xp=25 estamos a 25/50 = 0.5
      expect(xpProgressInLevel(25), closeTo(0.5, 0.01));
    });

    test('xpProgressInLevel: nível máximo → 1.0', () {
      expect(xpProgressInLevel(600), 1.0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // kAllBadges
  // ──────────────────────────────────────────────────────────────────────────
  group('kAllBadges', () {
    test('tem pelo menos 5 badges definidos', () {
      expect(kAllBadges.length, greaterThanOrEqualTo(5));
    });

    test('todos os badges têm id não-vazio', () {
      for (final b in kAllBadges) {
        expect(b.id.isNotEmpty, isTrue, reason: 'Badge "${b.name}" tem id vazio');
      }
    });

    test('ids de badges são únicos', () {
      final ids = kAllBadges.map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
