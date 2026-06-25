import 'package:flutter/material.dart';

/// Mascote "Léo" (urso) — cabeça desenhada com [CustomPainter] a partir da
/// receita do handoff de design. Todas as proporções são relativas ao tamanho
/// do widget ([size]), de forma que 1 unidade-receita ≈ `size` (equivalente ao
/// `1em` do protótipo HTML).
///
/// Cores (handoff):
///   orelha externa  #9A6A41 · orelha interna #C99B6E · rosto #B07D52
///   bochecha #F0A0A0 · focinho #F0DDC4 · olhos/nariz/boca #3A2A1E
class LeoBear extends StatelessWidget {
  /// Lado do quadrado em que o urso é desenhado (em px lógicos).
  final double size;

  const LeoBear({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LeoBearPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _LeoBearPainter extends CustomPainter {
  // Paleta do handoff
  static const _earOuter = Color(0xFF9A6A41);
  static const _earInner = Color(0xFFC99B6E);
  static const _face = Color(0xFFB07D52);
  static const _cheek = Color(0xFFF0A0A0);
  static const _muzzle = Color(0xFFF0DDC4);
  static const _ink = Color(0xFF3A2A1E);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width; // base (1em do protótipo)
    final cx = size.width / 2;
    final paint = Paint()..isAntiAlias = true;

    // ── Orelhas (ø .55em), a .05em da borda no topo ─────────────────────────
    final earR = 0.275 * s; // raio = .55/2
    final earY = 0.05 * s + earR;
    final earOuterL = Offset(0.05 * s + earR, earY);
    final earOuterR = Offset(size.width - 0.05 * s - earR, earY);

    paint.color = _earOuter;
    canvas.drawCircle(earOuterL, earR, paint);
    canvas.drawCircle(earOuterR, earR, paint);

    // Orelha interna (ø .3em), concêntrica
    final earInnerR = 0.15 * s;
    paint.color = _earInner;
    canvas.drawCircle(earOuterL, earInnerR, paint);
    canvas.drawCircle(earOuterR, earInnerR, paint);

    // ── Rosto: .2em do topo, 1.3em × 1.2em, radius ~47% ─────────────────────
    final faceW = 1.3 * s;
    final faceH = 1.2 * s;
    final faceRect = Rect.fromLTWH(
      cx - faceW / 2,
      0.2 * s,
      faceW,
      faceH,
    );
    paint.color = _face;
    canvas.drawRRect(
      RRect.fromRectXY(faceRect, faceW * 0.47, faceH * 0.47),
      paint,
    );

    // Centro vertical do rosto (referência p/ feições)
    final faceCx = cx;
    final faceCy = faceRect.center.dy;

    // ── Bochechas rosadas (.3em × .22em, opacity .8) ────────────────────────
    paint.color = _cheek.withOpacity(0.8);
    final cheekW = 0.3 * s, cheekH = 0.22 * s;
    final cheekY = faceCy + 0.12 * s;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(faceCx - 0.42 * s, cheekY),
        width: cheekW,
        height: cheekH,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(faceCx + 0.42 * s, cheekY),
        width: cheekW,
        height: cheekH,
      ),
      paint,
    );

    // ── Focinho (.6em × .5em), centro-baixo ─────────────────────────────────
    paint.color = _muzzle;
    final muzzleCenter = Offset(faceCx, faceCy + 0.2 * s);
    canvas.drawOval(
      Rect.fromCenter(
        center: muzzleCenter,
        width: 0.6 * s,
        height: 0.5 * s,
      ),
      paint,
    );

    // ── Olhos (.14em × .18em) ───────────────────────────────────────────────
    paint.color = _ink;
    final eyeY = faceCy - 0.08 * s;
    final eyeW = 0.14 * s, eyeH = 0.18 * s;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(faceCx - 0.26 * s, eyeY), width: eyeW, height: eyeH),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(faceCx + 0.26 * s, eyeY), width: eyeW, height: eyeH),
      paint,
    );

    // ── Nariz (.18em × .13em), no topo do focinho ───────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(faceCx, muzzleCenter.dy - 0.12 * s),
        width: 0.18 * s,
        height: 0.13 * s,
      ),
      paint,
    );

    // ── Sorriso: arco (borda inferior) .045em ───────────────────────────────
    final smile = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.045 * s
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    final smileRect = Rect.fromCenter(
      center: Offset(faceCx, muzzleCenter.dy + 0.02 * s),
      width: 0.34 * s,
      height: 0.26 * s,
    );
    // Meia-volta inferior (0 → π)
    canvas.drawArc(smileRect, 0, 3.14159, false, smile);
  }

  @override
  bool shouldRepaint(covariant _LeoBearPainter oldDelegate) => false;
}
