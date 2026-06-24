import 'package:flutter/material.dart';

/// Renderiza um conteúdo originalmente desenhado para PAISAGEM dentro de um
/// "palco" de tamanho fixo e o escala com [FittedBox] para caber em qualquer
/// viewport — inclusive RETRATO — sem causar overflow.
///
/// O layout interno do conteúdo permanece idêntico ao da paisagem (mesmas
/// proporções e posições), apenas reduzido proporcionalmente. Útil para as
/// telas de gameplay cujas peças têm largura fixa e estouravam na largura
/// estreita do retrato.
///
/// Uso típico (preservando fundo de tela cheia e overlays):
/// ```dart
/// Stack(children: [
///   Positioned.fill(child: _Background()),         // continua tela cheia
///   SafeArea(child: LandscapeStage(child: Column(...))), // jogo escalado
///   if (showOverlay) _Overlay(),                   // continua tela cheia
/// ])
/// ```
class LandscapeStage extends StatelessWidget {
  /// Conteúdo desenhado para paisagem (geralmente a Column principal da tela).
  final Widget child;

  /// Largura do palco de referência (paisagem). Pode usar [Expanded]/[Spacer]
  /// internamente pois o palco tem altura limitada.
  final double width;

  /// Altura do palco de referência (paisagem).
  final double height;

  /// Alinhamento do palco dentro do espaço disponível.
  final Alignment alignment;

  const LandscapeStage({
    super.key,
    required this.child,
    this.width = 900,
    this.height = 430,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(width: width, height: height, child: child),
      ),
    );
  }
}
