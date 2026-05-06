import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

enum ValidationStatus { excellent, almostThere, tryAgain, listenRepeat }

enum ValidationLevel { beginner, intermediate, advanced }

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
  });

  bool get isSuccess =>
      status == ValidationStatus.excellent ||
      status == ValidationStatus.almostThere;
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
          }
        },
        onStatus: (status) {
          debugPrint('[MIC] onStatus: "$status" (_listening=$_listening, deliverOnStatus=${_deliverOnStatus != null})');
          if (status == 'done' || status == 'notListening') {
            _listening = false;
            // STT encerrou sem emitir onResult(finalResult:true) — dispara deliver para desbloquear o jogo
            final fn = _deliverOnStatus;
            _deliverOnStatus = null;
            if (fn != null) {
              debugPrint('[MIC] onStatus "$status": disparando deliverOnStatus (sem resultado final do STT)');
              fn();
            }
          }
        },
        debugLogging: false,
      );
      debugPrint('[MIC] initialize(): _stt.initialize() retornou $_initialized');
      if (_initialized) {
        // Detecta locale disponível: prefere pt_BR, cai para pt, depois padrão
        final locales = await _stt.locales();
        debugPrint('[MIC] locales disponíveis: ${locales.map((l) => l.localeId).toList()}');
        const preferred = ['pt_BR', 'pt-BR', 'pt_PT', 'pt-PT', 'pt'];
        _localeId = null;
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
    Duration timeout = const Duration(seconds: 7),
  }) async {
    debugPrint('[MIC] startListening(): targetWord="$targetWord", _listening=$_listening');
    if (_listening) {
      debugPrint('[MIC] startListening(): já ouvindo — ignorado');
      return;
    }

    // No Android o SpeechRecognizer é de uso único — re-inicializa sempre.
    _initialized = false;
    _deliverOnStatus = null;
    debugPrint('[MIC] startListening(): forçou _initialized=false, chamando initialize()...');
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
    Future.delayed(timeout + const Duration(seconds: 3), () {
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
      debugPrint('[MIC] _stt.listen(): localeId=$_localeId, timeout=$timeout');
      await _stt.listen(
        localeId: _localeId,
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
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

    // Limiar por nível
    final minAccuracy = switch (level) {
      ValidationLevel.beginner => 0.58,
      ValidationLevel.intermediate => 0.73,
      ValidationLevel.advanced => 0.88,
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
      final dist = _levenshtein(sylNorm, heardText.length >= sylNorm.length
          ? heardText.substring(0, sylNorm.length.clamp(0, heardText.length))
          : heardText);
      final acc = (1.0 - dist / sylNorm.length.clamp(1, 99)).clamp(0.0, 1.0);
      final obs = acc >= 0.85
          ? 'pronúncia clara'
          : acc >= 0.60
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
