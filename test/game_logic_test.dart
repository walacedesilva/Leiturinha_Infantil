import 'package:aprenda_a_ler/features/reading_game/data/word_bank.dart';
import 'package:aprenda_a_ler/features/reading_game/domain/game_logic.dart';
import 'package:aprenda_a_ler/services/audio_manager.dart';
import 'package:aprenda_a_ler/services/gamification_service.dart';
import 'package:aprenda_a_ler/services/progress_service.dart';
import 'package:aprenda_a_ler/services/session_tracking_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/fake_prefs.dart';

// Família de testes com 2 palavras bi-silábicas
const _testFamily = SyllabicFamily(
  key: 'T',
  label: 'Família T (teste)',
  colorValue: 0xFF000000,
  words: [
    WordEntry(word: 'TACO', syllables: ['TA', 'CO']),
    WordEntry(word: 'TELA', syllables: ['TE', 'LA']),
  ],
);

/// Cria um GameLogic com dependências em memória e plugins silenciados.
Future<GameLogic> _makeGameLogic() async {
  final prefs = await fakePrefs();
  final progress = ProgressService(prefs);
  final gam = GamificationService(prefs);
  final tracking = SessionTrackingService(prefs);
  final audio = AudioManager(); // singleton; chamadas são silenciadas pelo binding
  return GameLogic(progress, audio, gam, tracking);
}

void main() {
  // Silencia canais de plataforma (audioplayers, flutter_tts, STT)
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // flutter_tts
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (_) async => null,
    );
    // audioplayers — global scope (init)
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    // audioplayers — per-player channel
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (_) async => null,
    );
    // path_provider (usado internamente pelo audioplayers)
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => '/tmp',
    );
    // speech_to_text
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugin.csdcorp.com/speech_to_text'),
      (_) async => true,
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Inicialização
  // ──────────────────────────────────────────────────────────────────────────
  group('GameLogic — initWithFamily', () {
    test('começa no estado assembling', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      expect(logic.state, GameState.assembling);
    });

    test('currentWord é a primeira palavra da família', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      expect(logic.currentWord, 'TACO');
    });

    test('targetSyllables corresponde às sílabas da palavra', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      expect(logic.targetSyllables, ['TA', 'CO']);
    });

    test('availableSyllables contém as mesmas sílabas (possivelmente embaralhadas)', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      expect(logic.availableSyllables, containsAll(['TA', 'CO']));
      expect(logic.availableSyllables.length, 2);
    });

    test('placedSyllables começa totalmente vazio (nulls)', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      expect(logic.placedSyllables, everyElement(isNull));
      expect(logic.placedSyllables.length, 2);
    });

    test('totalWords reflete o número de palavras pendentes', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      expect(logic.totalWords, 2);
    });

    test('wordIndex começa em 0', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      expect(logic.wordIndex, 0);
    });

    test('família com todas as palavras já concluídas → familyDone', () async {
      final prefs = await fakePrefs();
      final progress = ProgressService(prefs);
      // Marca todas as palavras como concluídas antes
      await progress.markWordCompleted('T', 'TACO');
      await progress.markWordCompleted('T', 'TELA');

      final logic = GameLogic(
        progress, AudioManager(),
        GamificationService(prefs), SessionTrackingService(prefs),
      );
      logic.initWithFamily(_testFamily);
      expect(logic.state, GameState.familyDone);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Modo direto (DesafioPronuncia)
  // ──────────────────────────────────────────────────────────────────────────
  group('GameLogic — initWithFamilyDirect', () {
    test('começa no estado completed (palavra pré-montada)', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      expect(logic.state, GameState.completed);
    });

    test('directMode é true', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      expect(logic.directMode, isTrue);
    });

    test('placedSyllables já estão preenchidos', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      expect(logic.placedSyllables, ['TA', 'CO']);
    });

    test('availableSyllables está vazio no modo direto', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      expect(logic.availableSyllables, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Montagem de sílabas (drag & drop)
  // ──────────────────────────────────────────────────────────────────────────
  group('GameLogic — onSyllableDropped', () {
    test('sílaba correta preenche o slot', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      logic.onSyllableDropped('TA', 0);
      expect(logic.placedSyllables[0], 'TA');
    });

    test('sílaba correta remove da lista disponível', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      logic.onSyllableDropped('TA', 0);
      expect(logic.availableSyllables, isNot(contains('TA')));
    });

    test('sílaba errada não preenche o slot', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      // 'CO' no slot 0 é errado (esperado 'TA')
      logic.onSyllableDropped('CO', 0);
      expect(logic.placedSyllables[0], isNull);
    });

    test('sílaba errada não remove da lista disponível', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      logic.onSyllableDropped('CO', 0);
      expect(logic.availableSyllables, contains('CO'));
    });

    test('ao preencher todos os slots → estado completed', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      // Aguarda a conclusão assíncrona de _checkWordCompletion
      logic.onSyllableDropped('TA', 0);
      logic.onSyllableDropped('CO', 1);
      // Espera um frame para o Future interno completar
      await Future.delayed(Duration.zero);
      expect(logic.state, GameState.completed);
    });

    test('ignorado se estado não é assembling', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily); // already completed
      logic.onSyllableDropped('TA', 0);
      // placedSyllables já estão corretos e não devem ser alterados
      expect(logic.placedSyllables[0], 'TA'); // permanece
    });

    test('notifica listeners ao encaixar sílaba correta', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      var notified = false;
      logic.addListener(() => notified = true);
      logic.onSyllableDropped('TA', 0);
      expect(notified, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // goToNextWord
  // ──────────────────────────────────────────────────────────────────────────
  group('GameLogic — goToNextWord', () {
    test('avança wordIndex de 0 para 1', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      await logic.goToNextWord();
      expect(logic.wordIndex, 1);
    });

    test('currentWord muda para a segunda palavra', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      await logic.goToNextWord();
      expect(logic.currentWord, 'TELA');
    });

    test('após última palavra → estado familyDone', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      await logic.goToNextWord(); // → TELA
      await logic.goToNextWord(); // → fim
      expect(logic.state, GameState.familyDone);
    });

    test('marca palavra como concluída em ProgressService', () async {
      final prefs = await fakePrefs();
      final progress = ProgressService(prefs);
      final logic = GameLogic(
        progress, AudioManager(),
        GamificationService(prefs), SessionTrackingService(prefs),
      );
      logic.initWithFamilyDirect(_testFamily);
      await logic.goToNextWord();
      expect(progress.getCompletedWords('T'), contains('TACO'));
    });

    test('ignorado se estado não é completed/validated', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily); // assembling
      await logic.goToNextWord();
      expect(logic.wordIndex, 0); // não avançou
    });

    test('notifica listeners ao avançar', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      var notified = false;
      logic.addListener(() => notified = true);
      await logic.goToNextWord();
      expect(notified, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Getters de sessão
  // ──────────────────────────────────────────────────────────────────────────
  group('GameLogic — sessionLabel', () {
    test('sessionLabel retorna label da família quando não é dual', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamily(_testFamily);
      expect(logic.sessionLabel, _testFamily.label);
    });
  });

  group('GameLogic — contadores de validação', () {
    test('validationAttempts começa em 0', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      expect(logic.validationAttempts, 0);
    });

    test('canRetryValidation é true quando tentativas < 3', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      expect(logic.canRetryValidation, isTrue);
    });

    test('maxValidationAttempts é 3', () async {
      final logic = await _makeGameLogic();
      logic.initWithFamilyDirect(_testFamily);
      expect(logic.maxValidationAttempts, 3);
    });
  });
}
