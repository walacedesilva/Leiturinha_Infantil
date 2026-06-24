import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═════════════════════════════════════════════════════════════════════════════
// NAV BACK BUTTON
// Botão de voltar padronizado: círculo branco com seta, sombra suave.
// Posição: canto superior esquerdo respeitando a safe area.
// Uso: coloque dentro de um Stack no topo da tela.
//
//   Stack(children: [
//     ... conteúdo ...,
//     const NavBackButton(),
//   ])
// ═════════════════════════════════════════════════════════════════════════════

class NavBackButton extends StatelessWidget {
  /// Callback opcional. Se nulo, usa Navigator.of(context).pop().
  final VoidCallback? onBack;

  /// Cor do ícone de seta. Padrão: roxo #7C3AED.
  final Color iconColor;

  const NavBackButton({
    super.key,
    this.onBack,
    this.iconColor = const Color(0xFF7C3AED),
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPad + 12,
      left: 16,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
