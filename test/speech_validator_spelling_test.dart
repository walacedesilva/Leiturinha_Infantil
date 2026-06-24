// ignore_for_file: avoid_print

import 'package:aprenda_a_ler/services/speech_validator.dart';
import 'package:flutter_test/flutter_test.dart';

// Sílabas de teste auxiliares
const _sylBA = ['BA'];
const _sylBOLA = ['BO', 'LA'];
const _sylBELA = ['BE', 'LA'];
const _sylCASA = ['CA', 'SA'];

void main() {
  final validator = SpeechValidator();

  // ────────────────────────────────────────────────────────────────────────
  // _detectSpellingPattern
  // ────────────────────────────────────────────────────────────────────────
  group('detectSpellingPattern — nenhuma soletração', () {
    test('pronúncia normal retorna SpellingType.none', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'bola',
        targetWord: 'BOLA',
        syllables: _sylBOLA,
      );
      expect(type, SpellingType.none);
    });

    test('transcrição vazia retorna SpellingType.none', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: '',
        targetWord: 'BOLA',
        syllables: _sylBOLA,
      );
      expect(type, SpellingType.none);
    });

    test('palavra com vogal não é confundida com vogal de apoio', () {
      // "belo" não tem padrão [consonant][ê/é]
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'belo',
        targetWord: 'BELA',
        syllables: _sylBELA,
      );
      expect(type, SpellingType.none);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('detectSpellingPattern — letterSpelling (nome de letras)', () {
    test('"eme" no transcript → letterSpelling', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'eme a',
        targetWord: 'MA',
        syllables: ['MA'],
      );
      expect(type, SpellingType.letterSpelling);
    });

    test('"erre" no transcript → letterSpelling', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'erre o',
        targetWord: 'RO',
        syllables: ['RO'],
      );
      expect(type, SpellingType.letterSpelling);
    });

    test('"jota" no transcript → letterSpelling', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'jota a',
        targetWord: 'JA',
        syllables: ['JA'],
      );
      expect(type, SpellingType.letterSpelling);
    });

    test('"xis" no transcript → letterSpelling', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'xis i',
        targetWord: 'XI',
        syllables: ['XI'],
      );
      expect(type, SpellingType.letterSpelling);
    });

    test('"agá" no transcript → letterSpelling', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'agá a',
        targetWord: 'HA',
        syllables: ['HA'],
      );
      expect(type, SpellingType.letterSpelling);
    });

    test('"bê" (forma acentuada) no transcript → letterSpelling', () {
      // "bê" + "a" mas "bê" está na lista de nomes de letras
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'bê a',
        targetWord: 'BA',
        syllables: _sylBA,
      );
      expect(type, SpellingType.letterSpelling);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('detectSpellingPattern — separatedLetters (letras isoladas)', () {
    test('"b a" para alvo "BA" → separatedLetters', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'b a',
        targetWord: 'BA',
        syllables: _sylBA,
      );
      expect(type, SpellingType.separatedLetters);
    });

    test('"b o l a" para alvo "BOLA" → separatedLetters', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'b o l a',
        targetWord: 'BOLA',
        syllables: _sylBOLA,
      );
      expect(type, SpellingType.separatedLetters);
    });

    test('"c a s a" para alvo "CASA" → separatedLetters', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'c a s a',
        targetWord: 'CASA',
        syllables: _sylCASA,
      );
      expect(type, SpellingType.separatedLetters);
    });

    test('"b e l a" para alvo "BELA" → separatedLetters', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'b e l a',
        targetWord: 'BELA',
        syllables: _sylBELA,
      );
      expect(type, SpellingType.separatedLetters);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('detectSpellingPattern — supportVowel (vogal de apoio)', () {
    test('"pê" (consoante + ê, nome de letra) no transcript → letterSpelling', () {
      // "pê" está na lista de nomes de letras → letterSpelling
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'pê',
        targetWord: 'PA',
        syllables: ['PA'],
      );
      expect(type, SpellingType.letterSpelling);
    });

    test('"fê" (f + ê) → supportVowel', () {
      // "fê" não é nome de letra na lista, satisfaz [consonant][ê]
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'fê',
        targetWord: 'FA',
        syllables: ['FA'],
      );
      expect(type, SpellingType.supportVowel);
    });

    test('"mé" (m + é) → supportVowel', () {
      final type = validator.detectSpellingPatternForTest(
        rawTranscript: 'mé',
        targetWord: 'MA',
        syllables: ['MA'],
      );
      expect(type, SpellingType.supportVowel);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // _validate (via validateForTest)
  // ────────────────────────────────────────────────────────────────────────
  group('validateForTest — resultado com soletração', () {
    test('transcript normal → spellingType=none, isSuccess possível', () {
      final result = validator.validateForTest(
        transcript: 'bola',
        targetWord: 'BOLA',
        syllables: _sylBOLA,
      );
      expect(result.spellingType, SpellingType.none);
    });

    test('transcrição com "eme" → spellingType=letterSpelling, isSuccess=false',
        () {
      final result = validator.validateForTest(
        transcript: 'eme a',
        targetWord: 'MA',
        syllables: ['MA'],
      );
      expect(result.spellingType, SpellingType.letterSpelling);
      expect(result.isSuccess, isFalse);
    });

    test(
        'transcrição com letras separadas → spellingType=separatedLetters, isSuccess=false',
        () {
      final result = validator.validateForTest(
        transcript: 'b o l a',
        targetWord: 'BOLA',
        syllables: _sylBOLA,
      );
      expect(result.spellingType, SpellingType.separatedLetters);
      expect(result.isSuccess, isFalse);
    });

    test('transcript com vogal de apoio → spellingType=supportVowel, isSuccess=false',
        () {
      final result = validator.validateForTest(
        transcript: 'fê',
        targetWord: 'FA',
        syllables: ['FA'],
      );
      expect(result.spellingType, SpellingType.supportVowel);
      expect(result.isSuccess, isFalse);
    });

    test('spellingExplanation não está vazio quando spellingType != none', () {
      final result = validator.validateForTest(
        transcript: 'b a',
        targetWord: 'BA',
        syllables: _sylBA,
      );
      expect(result.spellingType, isNot(SpellingType.none));
      expect(result.spellingExplanation.isNotEmpty, isTrue);
    });

    test('feedbackMessage não está vazio quando spellingType != none', () {
      final result = validator.validateForTest(
        transcript: 'erre o',
        targetWord: 'RO',
        syllables: ['RO'],
      );
      expect(result.spellingType, isNot(SpellingType.none));
      expect(result.feedbackMessage.isNotEmpty, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // isSuccess invariant
  // ────────────────────────────────────────────────────────────────────────
  group('ValidationResult.isSuccess invariante', () {
    test('isSuccess=false quando spellingType != none, independente do status',
        () {
      const r = ValidationResult(
        status: ValidationStatus.excellent,
        confidence: 1.0,
        transcript: 'bê a',
        targetWord: 'BA',
        syllableResults: [],
        detectedVariations: [],
        variationsAllowed: true,
        feedbackMessage: '',
        feedbackEmoji: '',
        nextAction: 'advance',
        spellingType: SpellingType.letterSpelling,
        spellingExplanation: 'Você está soletrando!',
      );
      expect(r.isSuccess, isFalse);
    });

    test('isSuccess=true quando spellingType=none e status=excellent', () {
      const r = ValidationResult(
        status: ValidationStatus.excellent,
        confidence: 1.0,
        transcript: 'bola',
        targetWord: 'BOLA',
        syllableResults: [],
        detectedVariations: [],
        variationsAllowed: true,
        feedbackMessage: '',
        feedbackEmoji: '',
        nextAction: 'advance',
        spellingType: SpellingType.none,
      );
      expect(r.isSuccess, isTrue);
    });

    test('isSuccess=false quando spellingType=none e status=tryAgain', () {
      const r = ValidationResult(
        status: ValidationStatus.tryAgain,
        confidence: 0.3,
        transcript: 'xyz',
        targetWord: 'BOLA',
        syllableResults: [],
        detectedVariations: [],
        variationsAllowed: false,
        feedbackMessage: '',
        feedbackEmoji: '',
        nextAction: 'retry',
        spellingType: SpellingType.none,
      );
      expect(r.isSuccess, isFalse);
    });
  });
}
