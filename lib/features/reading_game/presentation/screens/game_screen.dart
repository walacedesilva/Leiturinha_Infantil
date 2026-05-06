import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme.dart';
import '../../domain/game_logic.dart';
import '../../../../services/speech_validator.dart';
import '../widgets/gamification_widgets.dart';
import '../widgets/syllable_pool.dart';
import '../widgets/word_slots.dart';
import '../widgets/balloon_overlay.dart';
import '../widgets/mic_button.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Controla o delay de 500ms no botão "Próxima Palavra" para evitar toque acidental
  bool _nextButtonEnabled = false;
  bool _rewardShown = false; // impede toast duplicado por rebuild

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<GameLogic>(
          builder: (context, gameLogic, _) {
            // Dispara toast de recompensa uma vez ao entrar no estado 'validated' com sucesso
            if (gameLogic.isValidated &&
                gameLogic.lastReward != null &&
                (gameLogic.lastReward!.hasReward || gameLogic.lastReward!.hasBadge) &&
                !_rewardShown) {
              _rewardShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) showRewardToast(context, gameLogic.lastReward!);
              });
            }
            if (!gameLogic.isValidated) _rewardShown = false;

            // ── Família completa ──────────────────────────────────
            if (gameLogic.isFamilyDone) {
              return _FamilyDoneView(familyLabel: gameLogic.sessionLabel);
            }

            // ── Carregando ────────────────────────────────────────
            if (gameLogic.currentWord.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Ativa o botão de próxima após 500ms quando palavra completa ou validada
            final isPostAssembly = gameLogic.isCompleted ||
                gameLogic.isValidating ||
                gameLogic.isValidated;

            if (isPostAssembly && !_nextButtonEnabled) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => _nextButtonEnabled = true);
              });
            }
            if (!isPostAssembly && _nextButtonEnabled) {
              _nextButtonEnabled = false;
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // ── Top bar ─────────────────────────────────────
                    _TopBar(familyLabel: gameLogic.sessionLabel),

                    // ── Contador de palavras ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LinearProgressIndicator(
                        value: gameLogic.totalWords == 0
                            ? 0
                            : gameLogic.wordIndex / gameLogic.totalWords,
                        backgroundColor: Colors.grey.shade200,
                        color: AppTheme.primaryColor,
                        minHeight: 6,
                      ),
                    ),

                    // ── Área principal rolável ───────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            const SizedBox(height: 28),

                            // ── Slots da palavra ──────────────────────
                            WordSlots(gameLogic: gameLogic),

                            const SizedBox(height: 20),

                            // ── Botão de áudio 🔊 (pós-acerto) ────────
                            AnimatedOpacity(
                              opacity: isPostAssembly ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 400),
                              child: isPostAssembly
                                  ? _AudioButton(
                                      onPressed: gameLogic.playFormedWord)
                                  : const SizedBox(height: 80),
                            ),

                            const SizedBox(height: 16),

                            // ── Botão de microfone (sempre visível pós-acerto) ──
                            if (isPostAssembly)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: MicButton(
                                  state: gameLogic.isValidating
                                      ? MicState.recording
                                      : MicState.idle,
                                  partialText: gameLogic.isValidating
                                      ? gameLogic.partialTranscript
                                      : null,
                                  onTap: gameLogic.isValidating
                                      ? () {}
                                      : () => gameLogic.startSpeechValidation(),
                                  onCancel: gameLogic.isValidating
                                      ? gameLogic.cancelSpeechValidation
                                      : null,
                                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.25),
                              ),

                            // ── Card de feedback (aparece após validação) ──
                            if (gameLogic.isValidated &&
                                gameLogic.lastValidation != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                child: ValidationFeedbackCard(
                                  key: const ValueKey('feedback_card'),
                                  data: _buildFeedbackData(
                                    gameLogic.lastValidation!,
                                    gameLogic.canRetryValidation,
                                  ),
                                  onRetry: () =>
                                      gameLogic.startSpeechValidation(),
                                  onAdvance: () async {
                                    setState(
                                        () => _nextButtonEnabled = false);
                                    await gameLogic.goToNextWord();
                                  },
                                ),
                              ),

                            const SizedBox(height: 16),

                            // ── Pool de sílabas (travado pós-acerto) ───
                            if (!gameLogic.isValidated)
                              AnimatedOpacity(
                                opacity: isPostAssembly ? 0.35 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: IgnorePointer(
                                  ignoring: isPostAssembly,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: SyllablePool(
                                      availableSyllables:
                                          gameLogic.availableSyllables,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // ── Botão "Próxima Palavra" (fixo no rodapé) ────
                    AnimatedOpacity(
                      opacity: isPostAssembly && !gameLogic.isValidating
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: _NextButton(
                          enabled: (gameLogic.isCompleted ||
                                  gameLogic.isValidated) &&
                              _nextButtonEnabled,
                          onPressed: () async {
                            setState(() => _nextButtonEnabled = false);
                            await gameLogic.goToNextWord();
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Balões de celebração ──────────────────────────
                if (isPostAssembly)
                  const IgnorePointer(child: BalloonOverlay()),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS INTERNOS
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String familyLabel;
  const _TopBar({required this.familyLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 32),
            color: AppTheme.textColor,
            tooltip: 'Voltar ao menu',
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              familyLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Ícone de áudio pulsante — aparece somente após a palavra ser formada.
class _AudioButton extends StatelessWidget {
  final Future<void> Function() onPressed;
  const _AudioButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.of(context).size.width * 0.20).clamp(60.0, 80.0);
    final iconSize = size * 0.55;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.volume_up_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 700.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1, 1),
            duration: 700.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}

/// Botão "Próxima Palavra" com delay de ativação.
class _NextButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _NextButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.arrow_forward_rounded, size: 28),
        label: const Text(
          'Próxima Palavra',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    )
        .animate(target: enabled ? 1 : 0)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 250.ms);
  }
}

/// Converte [ValidationResult] em dados visuais para o card de feedback.
ValidationFeedbackData _buildFeedbackData(
    ValidationResult r, bool canRetry) {
  return switch (r.status) {
    ValidationStatus.excellent => ValidationFeedbackData(
        emoji: '🌟',
        title: 'Excelente!',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFE8F8E8),
        borderColor: Colors.green,
        titleColor: Colors.green,
        showRetry: false,
        nextAction: 'advance',
        advanceLabel: 'Próxima Palavra!',
      ),
    ValidationStatus.almostThere => ValidationFeedbackData(
        emoji: '👍',
        title: 'Quase Lá!',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFFFF9E6),
        borderColor: Colors.amber,
        titleColor: Colors.orange,
        showRetry: canRetry,
        nextAction: 'advance',
        advanceLabel: 'Continuar',
      ),
    ValidationStatus.tryAgain => ValidationFeedbackData(
        emoji: '🔄',
        title: 'Tente Mais Uma Vez',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFFFF3F3),
        borderColor: Colors.deepOrange,
        titleColor: Colors.deepOrange,
        showRetry: canRetry,
        nextAction: 'retry',
        advanceLabel: 'Pular',
      ),
    ValidationStatus.listenRepeat => ValidationFeedbackData(
        emoji: '🎧',
        title: 'Vamos Ouvir Juntos',
        message: r.feedbackMessage,
        confidence: r.confidence,
        backgroundColor: const Color(0xFFEFF5FF),
        borderColor: Colors.blueAccent,
        titleColor: Colors.blueAccent,
        showRetry: canRetry,
        nextAction: 'reinforce',
        advanceLabel: 'Próxima Palavra',
      ),
  };
}

class _FamilyDoneView extends StatelessWidget {
  final String familyLabel;
  const _FamilyDoneView({required this.familyLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80))
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Família Completa!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Text(
              familyLabel,
              style: const TextStyle(
                fontSize: 20,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home_rounded, size: 28),
              label: const Text(
                'Voltar ao Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(double.infinity, 64),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                final gameLogic = context.read<GameLogic>();
                gameLogic.restartFamily();
              },
              child: const Text(
                'Repetir família',
                style: TextStyle(
                  fontSize: 17,
                  color: AppTheme.textColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}

