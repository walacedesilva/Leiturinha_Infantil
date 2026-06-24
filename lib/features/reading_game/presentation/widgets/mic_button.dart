import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum MicState { idle, recording, processing }

/// Botão de microfone animado para validação fonética.
/// [state] controla visual: idle → toque para falar; recording → pulsando;
/// processing → girando (analisando).
class MicButton extends StatefulWidget {
  final MicState state;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final String? partialText;

  const MicButton({
    super.key,
    required this.state,
    required this.onTap,
    this.onCancel,
    this.partialText,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label instrucional
        Text(
          switch (widget.state) {
            MicState.idle => 'Toque para falar a palavra!',
            MicState.recording => 'Estou te ouvindo...',
            MicState.processing => 'Analisando...',
          },
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.75),
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 12),

        // Texto capturado: parcial (durante gravação) ou final (pós-validação)
        if (widget.partialText != null && widget.partialText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.state == MicState.recording
                      ? Icons.graphic_eq_rounded
                      : Icons.record_voice_over_rounded,
                  size: 16,
                  color: widget.state == MicState.recording
                      ? Colors.redAccent
                      : cs.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '"${widget.partialText}"',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: widget.state == MicState.recording
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: widget.state == MicState.recording
                          ? Colors.redAccent
                          : cs.primary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ).animate(key: ValueKey(widget.partialText)).fadeIn(duration: 250.ms),
          ),

        // Botão principal
        Stack(
          alignment: Alignment.center,
          children: [
            // Anel pulsante (só enquanto grava)
            if (widget.state == MicState.recording)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  final radius = 40.0 + (_pulseCtrl.value * 18);
                  final opacity = 0.4 - (_pulseCtrl.value * 0.35);
                  return Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withOpacity(opacity.clamp(0.0, 1.0)),
                    ),
                  );
                },
              ),

            GestureDetector(
              onTap: widget.state == MicState.idle ? widget.onTap : null,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: switch (widget.state) {
                    MicState.idle => cs.primary,
                    MicState.recording => Colors.redAccent,
                    MicState.processing => cs.secondary,
                  },
                  boxShadow: [
                    BoxShadow(
                      color: (switch (widget.state) {
                        MicState.idle => cs.primary,
                        MicState.recording => Colors.redAccent,
                        MicState.processing => cs.secondary,
                      }).withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: widget.state == MicState.processing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        widget.state == MicState.recording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
              ),
            ),
          ],
        ),

        // Botão cancelar (só gravando)
        if (widget.state == MicState.recording && widget.onCancel != null) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancelar'),
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback card exibido após validação
// ─────────────────────────────────────────────────────────────────────────────

class ValidationFeedbackCard extends StatelessWidget {
  final ValidationFeedbackData data;
  final VoidCallback onRetry;
  final VoidCallback onAdvance;

  const ValidationFeedbackCard({
    super.key,
    required this.data,
    required this.onRetry,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: data.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.borderColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji + título
          Text(data.emoji, style: const TextStyle(fontSize: 48))
              .animate()
              .scale(begin: const Offset(0.3, 0.3), duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 6),

          Text(
            data.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: data.titleColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            data.message,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Barra de confiança
          _ConfidenceBar(confidence: data.confidence, color: data.titleColor),

          const SizedBox(height: 16),

          // Botões de ação
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (data.showRetry)
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tentar de novo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: data.titleColor,
                    side: BorderSide(color: data.borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: onAdvance,
                icon: Icon(
                  data.nextAction == 'advance'
                      ? Icons.arrow_forward_rounded
                      : Icons.volume_up_rounded,
                  size: 18,
                ),
                label: Text(data.advanceLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: data.titleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.4, duration: 350.ms, curve: Curves.easeOut).fadeIn();
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  final Color color;
  const _ConfidenceBar({required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Precisão', style: TextStyle(fontSize: 12, color: Colors.black54)),
            Text(
              '${(confidence * 100).round()}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// Dados de feedback para o card
class ValidationFeedbackData {
  final String emoji;
  final String title;
  final String message;
  final double confidence;
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final bool showRetry;
  final String nextAction;
  final String advanceLabel;

  const ValidationFeedbackData({
    required this.emoji,
    required this.title,
    required this.message,
    required this.confidence,
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.showRetry,
    required this.nextAction,
    required this.advanceLabel,
  });
}
