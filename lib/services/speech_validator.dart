import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

enum ValidationStatus { excellent, almostThere, tryAgain, listenRepeat }

enum ValidationLevel { beginner, intermediate, advanced }

/// Tipo de padrão de soletração detectado no transcript STT.
/// [none] = pronúncia normal (sem soletração detectada).
enum SpellingType {
  none,             // Pronúncia normal — sem soletração
  letterSpelling,   // Nomeia as letras: "bê-a" ao invés de "ba"
  separatedLetters, // Letras isoladas: "b... a"
  supportVowel,     // Vogal de apoio: consoante+"ê" → "bêa" ao invés de "ba"
}

class SyllableResult {
  final String syllable;
  final double accuracy;
  final String observation;
  const SyllableResult({
    required this.syllable,
    required this.accuracy,
    required this.observation,
  });
}

class ValidationResult {
  final ValidationStatus status;
  final double confidence;
  final String transcript;
  final String targetWord;
  final List<SyllableResult> syllableResults;
  final List<String> detectedVariations;
  final bool variationsAllowed;

  // Feedback
  final String feedbackMessage;
  final String feedbackEmoji;
  final String nextAction; // 'advance' | 'retry' | 'reinforce'

  // Soletração detectada
  final SpellingType spellingType;
  final String spellingExplanation;

  const ValidationResult({
    required this.status,
    required this.confidence,
    required this.transcript,
    required this.targetWord,
    required this.syllableResults,
    required this.detectedVariations,
    required this.variationsAllowed,
    required this.feedbackMessage,
    required this.feedbackEmoji,
    required this.nextAction,
    this.spellingType = SpellingType.none,
    this.spellingExplanation = '',
  });

  /// Sucesso apenas quando não há soletração detectada E o status é positivo.
  bool get isSuccess =>
      spellingType == SpellingType.none &&
      (status == ValidationStatus.excellent ||
          status == ValidationStatus.almostThere);
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVIÇO
// ─────────────────────────────────────────────────────────────────────────────

/// Serviço singleton de validação fonética usando STT on-device (pt-BR).
/// Funciona com reconhecimento offline nativo do Android ≥ 10.
class SpeechValidator {
  static final SpeechValidator _instance = SpeechValidator._internal();
  factory SpeechValidator() => _instance;
  SpeechValidator._internal();

  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;
  bool _listening = false;

  // Estado de escuta
  String _lastTranscript = '';
  bool get isListening => _listening;

  // Bridge: permite que onStatus dispare deliver() quando STT encerra sem onResult final
  void Function()? _deliverOnStatus;

  // Grace timer: aguarda resultado tardio antes de entregar silêncio
  // (Android dispara onEndOfSpeech ANTES do primeiro partial em MIUI)
  Timer? _graceTimer;

  // ────────────────────────────────────────────────
  // INICIALIZAÇÃO
  // ────────────────────────────────────────────────

  // Locale a usar (detectado uma vez)
  String? _localeId;

  Future<bool> initialize() async {
    debugPrint('[MIC] initialize(): _initialized=$_initialized, isAvailable=${_stt.isAvailable}');
    if (_initialized && _stt.isAvailable) {
      debugPrint('[MIC] initialize(): já disponível, pulando');
      return true;
    }
    try {
      _initialized = await _stt.initialize(
        onError: (e) {
          debugPrint('[MIC] onError: "${e.errorMsg}" (permanent: ${e.permanent})');
          if (e.permanent) {
            _initialized = false;
            debugPrint('[MIC] onError permanente → _initialized=false');
            // Erro permanente: entrega com o que foi ouvido até agora (parcial ou vazio)
            final fn = _deliverOnStatus;
            _deliverOnStatus = null;
            if (fn != null) {
              debugPrint('[MIC] onError permanente: disparando bridge (transcript="$_lastTranscript")');
              fn();
            }
          }
        },
        onStatus: (status) {
          debugPrint('[MIC] onStatus: "$status" (transcript="$_lastTranscript", listening=$_listening, bridge=${_deliverOnStatus != null})');
          if (status == 'done' || status == 'notListening') {
            _listening = false;
            // ⚠️  ATENÇÃO: 'done' chega de 'doneNoResult' que é enviado pelo plugin Android
            // em onEndOfSpeech() — ANTES de onResults(). Se dispararmos a bridge aqui com
            // transcrição parcial, perdemos o resultado real que vem em onResult(finalResult=true).
            //
            // Regra: só disparar bridge se NÃO há transcrição parcial (sem fala detectada).
            // Se há transcrição, confiamos em onResult(finalResult:true) para entregar.
            if (_lastTranscript.isEmpty) {
              // Condição de corrida: Android pode disparar onEndOfSpeech antes do
              // primeiro partial result chegar. Aguarda 2s (grace period) antes de
              // entregar silêncio, dando tempo para resultados tardios chegarem.
              _graceTimer?.cancel();
              _graceTimer = Timer(const Duration(milliseconds: 2000), () {
                _graceTimer = null;
                if (_lastTranscript.isEmpty) {
                  final fn = _deliverOnStatus;
                  _deliverOnStatus = null;
                  if (fn != null) {
                    debugPrint('[MIC] onStatus "$status" + grace: sem transcrição → bridge (silêncio)');
                    fn();
                  }
                } else {
                  debugPrint('[MIC] grace: transcrição chegou durante espera="$_lastTranscript" → aguardando onResult(final)');
                }
              });
              debugPrint('[MIC] onStatus "$status": transcript vazio → grace timer 2s iniciado');
            } else {
              _graceTimer?.cancel();
              _graceTimer = null;
              debugPrint('[MIC] onStatus "$status": transcrição="$_lastTranscript" → aguardando onResult(final)');
            }
          }
        },
        debugLogging: false,
      );
      debugPrint('[MIC] initialize(): _stt.initialize() retornou $_initialized');
      if (_initialized && _localeId == null) {
        // Detecta locale apenas uma vez — preservado entre sessões
        final locales = await _stt.locales();
        debugPrint('[MIC] locales disponíveis: ${locales.map((l) => l.localeId).toList()}');
        const preferred = ['pt_BR', 'pt-BR', 'pt_PT', 'pt-PT', 'pt'];
        for (final pref in preferred) {
          if (locales.any((l) => l.localeId == pref)) {
            _localeId = pref;
            break;
          }
        }
        _localeId ??= locales.isNotEmpty ? locales.first.localeId : null;
        debugPrint('[MIC] locale selecionado: $_localeId');
      }
      return _initialized;
    } catch (e) {
      debugPrint('[MIC] initialize() EXCEÇÃO: $e');
      return false;
    }
  }

  // ────────────────────────────────────────────────
  // ESCUTA
  // ────────────────────────────────────────────────

  /// Inicia captura de voz. Chama [onResult] a cada resultado parcial/final.
  /// Inclui timer de segurança para nunca travar o estado em "validating".
  Future<void> startListening({
    required ValueChanged<String> onPartial,
    required void Function(ValidationResult) onValidated,
    required String targetWord,
    required List<String> syllables,
    ValidationLevel level = ValidationLevel.beginner,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final actualTimeout = timeout.inSeconds < 20 ? const Duration(seconds: 20) : timeout;
    debugPrint('[MIC] startListening(): targetWord="$targetWord", _listening=$_listening, requestedTimeout=$timeout, actualTimeout=$actualTimeout');
    if (_listening) {
      debugPrint('[MIC] startListening(): já ouvindo — ignorado');
      return;
    }

    // O plugin Kotlin gerencia o ciclo de vida do SpeechRecognizer internamente.
    // Só inicializa na primeira vez ou após erro permanente (_initialized=false).
    _deliverOnStatus = null;
    debugPrint('[MIC] startListening(): inicializando STT (se necessário)...');
    final ok = await initialize();
    debugPrint('[MIC] startListening(): initialize() = $ok');
    if (!ok) {
      debugPrint('[MIC] startListening(): STT indisponível → listenRepeat imediato');
      onValidated(_buildResult(
        status: ValidationStatus.listenRepeat,
        confidence: 0.0,
        transcript: '',
        targetWord: targetWord,
        syllables: syllables,
        level: level,
        variations: ['stt_indisponivel'],
      ));
      return;
    }

    _lastTranscript = '';
    _listening = true;
    var delivered = false;

    // Entrega resultado UMA única vez — evita duplicatas
    void deliver(ValidationResult r) {
      debugPrint('[MIC] deliver(): status=${r.status}, confidence=${r.confidence.toStringAsFixed(2)}, transcript="${r.transcript}", já_entregue=$delivered');
      if (delivered) return;
      delivered = true;
      _deliverOnStatus = null;
      _graceTimer?.cancel();
      _graceTimer = null;
      _listening = false;
      onValidated(r);
    }

    // Bridge para onStatus — STT pode fechar sem emitir onResult final
    _deliverOnStatus = () {
      debugPrint('[MIC] _deliverOnStatus chamado: transcript="$_lastTranscript"');
      if (!delivered) {
        deliver(_validate(
          transcript: _lastTranscript,
          targetWord: targetWord,
          syllables: syllables,
          level: level,
        ));
      }
    };

    // ── Timer de segurança ──────────────────────────────────────────────
    Future.delayed(actualTimeout + const Duration(seconds: 3), () {
      debugPrint('[MIC] safety timer disparado: delivered=$delivered, transcript="$_lastTranscript"');
      if (!delivered) {
        debugPrint('[MIC] safety timer: deliver forçado por timeout');
        _stt.cancel().catchError((_) {});
        deliver(_validate(
          transcript: _lastTranscript,
          targetWord: targetWord,
          syllables: syllables,
          level: level,
        ));
      }
    });

    // ── Inicia escuta ───────────────────────────────────────────────────
    // NOTA: speech_to_text 7.x retorna void (não bool) em listen() —
    // não capturamos o retorno para evitar TypeError de cast null→bool.
    // Usamos _stt.isListening para verificar se realmente iniciou.
    try {
      debugPrint('[MIC] _stt.listen(): localeId=$_localeId, timeout=$actualTimeout');
      await _stt.listen(
        localeId: _localeId,
        listenFor: actualTimeout,
        pauseFor: const Duration(seconds: 10),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          // confirmation: melhor para uma palavra isolada (vs dictation para frases)
          // dictation: mantém o reconhecedor ativo por mais tempo,
          // melhor para criança que pode pausar entre sílabas.
          listenMode: ListenMode.dictation,
        ),
        onResult: (result) {
          debugPrint('[MIC] onResult: "${result.recognizedWords}" | final=${result.finalResult}');
          _lastTranscript = result.recognizedWords;
          onPartial(_lastTranscript);
          if (result.finalResult) {
            deliver(_validate(
              transcript: _lastTranscript,
              targetWord: targetWord,
              syllables: syllables,
              level: level,
            ));
          }
        },
      );
      debugPrint('[MIC] _stt.listen() retornou sem exceção | isListening=${_stt.isListening}');
    } catch (e) {
      // Em speech_to_text 7.x, listen() pode lançar TypeError de cast ao retornar null.
      // Se onStatus("listening") já disparou, o STT abriu normalmente — não entregar erro.
      final isActuallyListening = _stt.isListening;
      debugPrint('[MIC] _stt.listen() EXCEÇÃO: $e | isListening=$isActuallyListening');
      if (!isActuallyListening && !delivered) {
        debugPrint('[MIC] STT não iniciou de fato → listenRepeat imediato');
        deliver(_buildResult(
          status: ValidationStatus.listenRepeat,
          confidence: 0.0,
          transcript: '',
          targetWord: targetWord,
          syllables: syllables,
          level: level,
          variations: ['stt_nao_iniciou'],
        ));
      } else {
        debugPrint('[MIC] exceção era apenas de cast — STT está ativo, aguardando fala...');
      }
    }
  }

  Future<void> stopListening() async {
    debugPrint('[MIC] stopListening()');
    _deliverOnStatus = null;
    _listening = false;
    await _stt.stop();
  }

  Future<void> cancelListening() async {
    debugPrint('[MIC] cancelListening()');
    _deliverOnStatus = null;
    _listening = false;
    await _stt.cancel();
  }

  // ────────────────────────────────────────────────
  // HOOKS DE TESTE (não usar em produção)
  // ────────────────────────────────────────────────

  /// Exposto apenas para testes unitários.
  @visibleForTesting
  SpellingType detectSpellingPatternForTest({
    required String rawTranscript,
    required String targetWord,
    required List<String> syllables,
  }) =>
      _detectSpellingPattern(
        rawTranscript: rawTranscript,
        targetWord: targetWord,
        syllables: syllables,
      );

  /// Exposto apenas para testes unitários.
  @visibleForTesting
  ValidationResult validateForTest({
    required String transcript,
    required String targetWord,
    required List<String> syllables,
    ValidationLevel level = ValidationLevel.beginner,
  }) =>
      _validate(
        transcript: transcript,
        targetWord: targetWord,
        syllables: syllables,
        level: level,
      );

  // ────────────────────────────────────────────────
  // VALIDAÇÃO FONÉTICA
  // ────────────────────────────────────────────────

  ValidationResult _validate({
    required String transcript,
    required String targetWord,
    required List<String> syllables,
    required ValidationLevel level,
  }) {
    final target = _normalize(targetWord);
    final heard = _normalize(transcript.isEmpty ? '' : transcript);

    if (heard.isEmpty) {
      return _buildResult(
        status: ValidationStatus.listenRepeat,
        confidence: 0.0,
        transcript: '',
        targetWord: targetWord,
        syllables: syllables,
        level: level,
        variations: ['silencio'],
      );
    }

    // ── Detecção de soletração (sobre transcript bruto, antes de normalizar) ──
    final spellingType = _detectSpellingPattern(
      rawTranscript: transcript,
      targetWord: targetWord,
      syllables: syllables,
    );
    if (spellingType != SpellingType.none) {
      return _buildSpellingResult(
        spellingType: spellingType,
        transcript: transcript,
        targetWord: targetWord,
        syllables: syllables,
        level: level,
      );
    }

    // ── Atalho: alvo de vogal única (A/E/I/O/U) ─────────────────────────────
    // O STT pt-BR raramente retorna a letra isolada — devolve palavras curtas
    // como "eu", "oi", "há", "ei", "um", "ah", etc.
    if (target.length == 1 && 'aeiou'.contains(target)) {
      // Caso 1: heard contém a vogal-alvo (ex: "ah"→'a', "ai"→'a', "eu"→'e')
      if (heard.contains(target)) {
        return _buildResult(
          status: ValidationStatus.excellent,
          confidence: 1.0,
          transcript: transcript,
          targetWord: targetWord,
          syllables: syllables,
          level: level,
          variations: [],
        );
      }
      // Caso 2: 'h' inicial mudo — "há"→"ha", remove h e testa início
      final withoutLeadingH = heard.replaceFirst(RegExp(r'^h+'), '');
      if (withoutLeadingH.startsWith(target)) {
        return _buildResult(
          status: ValidationStatus.excellent,
          confidence: 1.0,
          transcript: transcript,
          targetWord: targetWord,
          syllables: syllables,
          level: level,
          variations: [],
        );
      }
      // Caso 3 (beginner): heard curto (≤ 4 chars) composto quase só de vogais —
      // STT confundiu o fonema vocálico (ex: "a" transcrito como "ei", "e", "oi").
      // Criança claramente tentou emitir um som vocálico.
      if (level == ValidationLevel.beginner &&
          heard.isNotEmpty &&
          heard.length <= 4 &&
          heard.replaceAll(RegExp(r'[aeiouhy]'), '').length <= 1) {
        return _buildResult(
          status: ValidationStatus.excellent,
          confidence: 1.0,
          transcript: transcript,
          targetWord: targetWord,
          syllables: syllables,
          level: level,
          variations: [],
        );
      }
    }

    // Normaliza variações fonéticas comuns
    final heardAdjusted = _applyPhoneticNormalization(heard);
    final targetAdjusted = _applyPhoneticNormalization(target);

    // Distância de Levenshtein entre os dois
    final distance = _levenshtein(heardAdjusted, targetAdjusted);
    final maxLen = (target.length > heard.length ? target.length : heard.length)
        .clamp(1, 999);
    double rawConfidence = 1.0 - (distance / maxLen);
    rawConfidence = rawConfidence.clamp(0.0, 1.0);

    // Detecta variações aplicadas
    final variations = _detectVariations(heard, target, level);
    final variationsAllowed =
        _areVariationsAllowed(variations, level);

    // Aplica bônus por variações aceitáveis
    double adjustedConfidence = rawConfidence;
    if (variationsAllowed && adjustedConfidence < 0.95) {
      adjustedConfidence = (adjustedConfidence + 0.10).clamp(0.0, 1.0);
    }

    // Limiar por nível (calibrado para pronúncia infantil)
    final minAccuracy = switch (level) {
      ValidationLevel.beginner => 0.45,
      ValidationLevel.intermediate => 0.65,
      ValidationLevel.advanced => 0.82,
    };

    final ValidationStatus status;
    if (adjustedConfidence >= 0.90) {
      status = ValidationStatus.excellent;
    } else if (adjustedConfidence >= minAccuracy) {
      status = ValidationStatus.almostThere;
    } else if (adjustedConfidence >= 0.35) {
      status = ValidationStatus.tryAgain;
    } else {
      status = ValidationStatus.listenRepeat;
    }

    return _buildResult(
      status: status,
      confidence: adjustedConfidence,
      transcript: transcript,
      targetWord: targetWord,
      syllables: syllables,
      level: level,
      variations: variations,
    );
  }

  ValidationResult _buildResult({
    required ValidationStatus status,
    required double confidence,
    required String transcript,
    required String targetWord,
    required List<String> syllables,
    required ValidationLevel level,
    required List<String> variations,
  }) {
    // Avalia sílaba por sílaba
    final heardNorm = _applyPhoneticNormalization(_normalize(transcript));
    final syllableResults = _scoreSyllables(
      syllables: syllables,
      heardText: heardNorm,
      level: level,
    );

    final bool variationsAllowed = _areVariationsAllowed(variations, level);

    final (String msg, String emoji, String action) = switch (status) {
      ValidationStatus.excellent => (
          'Muito bem! Você falou ${_formatSyllables(syllables)} perfeitamente!',
          '🌟',
          'advance',
        ),
      ValidationStatus.almostThere => (
          'Quase perfeito! Tente falar assim: ${_formatSyllables(syllables)}',
          '👍',
          'advance',
        ),
      ValidationStatus.tryAgain => (
          'Vamos tentar de novo? Ouça: ${_formatSyllables(syllables)}',
          '🔄',
          'retry',
        ),
      ValidationStatus.listenRepeat => (
          'Ouça e repita comigo: ${_formatSyllables(syllables)}',
          '🎧',
          'reinforce',
        ),
    };

    return ValidationResult(
      status: status,
      confidence: confidence,
      transcript: transcript,
      targetWord: targetWord,
      syllableResults: syllableResults,
      detectedVariations: variations,
      variationsAllowed: variationsAllowed,
      feedbackMessage: msg,
      feedbackEmoji: emoji,
      nextAction: action,
    );
  }

  // ────────────────────────────────────────────────
  // UTILIDADES FONÉTICAS
  // ────────────────────────────────────────────────

  /// Detecta se o transcript bruto (pré-normalização) indica soletração.
  /// Opera sobre o texto cru para preservar acentos diagnósticos (ê, é).
  SpellingType _detectSpellingPattern({
    required String rawTranscript,
    required String targetWord,
    required List<String> syllables,
  }) {
    if (rawTranscript.trim().isEmpty) return SpellingType.none;
    final lower = rawTranscript.toLowerCase().trim();
    final tokens = lower.split(RegExp(r'\s+'));

    // ── 1. Nomes de letras reconhecíveis (sem ambiguidade no contexto) ─
    // Verificado ANTES do regex de vogal de apoio porque "bê", "pê", etc.
    // correspondem a ambos os critérios — aqui a intenção é sempre letra nomeada.
    const letterNames = {
      'eme', 'ene', 'erre', 'jota', 'efe', 'xis',
      'agá', 'aga', 'dábliu', 'dabliu', 'ípsilon', 'ipsilon',
      'bê', 'pê', 'tê', 'cê', 'gê', 'zê', 'quê', 'ká', 'ka',
    };
    for (final token in tokens) {
      if (letterNames.contains(token)) {
        return SpellingType.letterSpelling;
      }
    }

    // ── 2. Vogal de apoio: token = [consoante][ê/é] ──────────────────
    // Ex: criança diz "fê" ao invés de "fa", "mé" ao invés de "ma"
    // (letras nomeadas como "bê"/"pê" já foram capturadas acima)
    final supportVowelToken = RegExp(r'^[bcdfghjklmnpqrstvwxyz][êé]$');
    for (final token in tokens) {
      if (supportVowelToken.hasMatch(token)) {
        return SpellingType.supportVowel;
      }
    }

    // ── 3. Letras separadas formando a palavra-alvo ──────────────────
    // Ex: "b a" para "BA" ou "b o l a" para "BOLA"
    if (tokens.length >= 2) {
      final singleAlphaRe = RegExp(r'^[a-záéíóúâêîôûãõç]$');
      final allSingleAlpha = tokens.every((t) => singleAlphaRe.hasMatch(t));
      if (allSingleAlpha) {
        final joined = tokens.join('');
        final targetNorm = _normalize(targetWord);
        if (_levenshtein(joined, targetNorm) <= 1) {
          return SpellingType.separatedLetters;
        }
      }
    }

    return SpellingType.none;
  }

  /// Constrói [ValidationResult] específico para soletração detectada.
  ValidationResult _buildSpellingResult({
    required SpellingType spellingType,
    required String transcript,
    required String targetWord,
    required List<String> syllables,
    required ValidationLevel level,
  }) {
    final heardNorm = _applyPhoneticNormalization(_normalize(transcript));
    final syllableResults = _scoreSyllables(
      syllables: syllables,
      heardText: heardNorm,
      level: level,
    );

    final sylFormatted = _formatSyllables(syllables);
    final wordUpper = syllables.map((s) => s.toUpperCase()).join('');

    final (String msg, String explanation, String emoji) = switch (spellingType) {
      SpellingType.letterSpelling => (
        'Fale a palavra toda: $sylFormatted',
        'Você está soletrando as letrinhas! Em vez de dizer cada letra, fale a palavra inteira: $wordUpper!',
        '🔤',
      ),
      SpellingType.separatedLetters => (
        'Junte as letrinhas! Fale: $sylFormatted',
        'As letras precisam ficar juntinhas! Fale assim: $wordUpper (tudo junto!)',
        '🔗',
      ),
      SpellingType.supportVowel => (
        'Tire o "Ê" do meio! Fala: $sylFormatted',
        'Não precisa do "ê"! Fale direto: ${syllables.first.toUpperCase()} (tudo junto!)',
        '👄',
      ),
      SpellingType.none => ('', '', ''), // inalcançável
    };

    return ValidationResult(
      status: ValidationStatus.tryAgain,
      confidence: 0.0,
      transcript: transcript,
      targetWord: targetWord,
      syllableResults: syllableResults,
      detectedVariations: const [],
      variationsAllowed: true,
      feedbackMessage: msg,
      feedbackEmoji: emoji,
      nextAction: 'retry',
      spellingType: spellingType,
      spellingExplanation: explanation,
    );
  }

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ê', 'e')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 's')
        .replaceAll(RegExp(r'[^a-z]'), '');
  }

  /// Colapsa pares sonoros para comparação neutra.
  String _applyPhoneticNormalization(String s) {
    return s
        .replaceAll('p', 'b')   // voicing b↔p
        .replaceAll('t', 'd')   // voicing t↔d
        .replaceAll('k', 'g')   // voicing k↔g
        .replaceAll('c', 'g')
        .replaceAll('v', 'f')   // voicing v↔f
        .replaceAll('z', 's')   // voicing z↔s
        .replaceAll('r', 'l');  // líquidas l↔r
  }

  List<String> _detectVariations(
      String heard, String target, ValidationLevel level) {
    final variations = <String>[];

    if (heard.isEmpty) return ['silencio'];

    // Nasalização
    if ((heard.contains('n') || heard.contains('m')) &&
        !target.contains('n') && !target.contains('m')) {
      variations.add('nasalizacao');
    }

    // Omissão de sílaba final
    if (heard.length < target.length * 0.65) {
      variations.add('omissao_final');
    }

    // Troca de sonoridade
    final bp = (heard.contains('p') && target.contains('b')) ||
        (heard.contains('b') && target.contains('p'));
    final td = (heard.contains('t') && target.contains('d')) ||
        (heard.contains('d') && target.contains('t'));
    final kg = (heard.contains('c') || heard.contains('k')) &&
        target.contains('g');
    if (bp || td || kg) variations.add('troca_sonoridade');

    // Troca l/r
    if ((heard.contains('l') && target.contains('r')) ||
        (heard.contains('r') && target.contains('l'))) {
      variations.add('troca_l_r');
    }

    return variations;
  }

  bool _areVariationsAllowed(List<String> variations, ValidationLevel level) {
    if (variations.isEmpty) return true;
    return switch (level) {
      ValidationLevel.beginner => true, // tudo permitido
      ValidationLevel.intermediate =>
        !variations.contains('omissao_final') &&
            !variations.contains('troca_sonoridade'),
      ValidationLevel.advanced => false,
    };
  }

  List<SyllableResult> _scoreSyllables({
    required List<String> syllables,
    required String heardText,
    required ValidationLevel level,
  }) {
    return syllables.map((syl) {
      final sylNorm = _applyPhoneticNormalization(_normalize(syl));
      // Compara cada sílaba contra o texto ouvido completo (não apenas prefixo)
      // e verifica se a sílaba está contida no texto ouvido
      double acc;
      if (heardText.contains(sylNorm)) {
        acc = 1.0;
      } else {
        final maxLen = (sylNorm.length > heardText.length ? sylNorm.length : heardText.length).clamp(1, 999);
        final dist = _levenshtein(sylNorm, heardText);
        acc = (1.0 - dist / maxLen).clamp(0.0, 1.0);
      }
      final obs = acc >= 0.85
          ? 'pronúncia clara'
          : acc >= 0.55
              ? 'variação aceitável'
              : 'precisa de reforço';
      return SyllableResult(syllable: syl, accuracy: acc, observation: obs);
    }).toList();
  }

  String _formatSyllables(List<String> syllables) =>
      syllables.join(' - ');

  // Levenshtein iterativo
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      prev.setAll(0, curr);
    }
    return prev[b.length];
  }
}
