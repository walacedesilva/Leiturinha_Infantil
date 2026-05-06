import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class SyllablePool extends StatelessWidget {
  final List<String> availableSyllables;

  const SyllablePool({
    Key? key,
    required this.availableSyllables,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Card ocupa ~22% da tela, entre 68 e 90px
    final cardSize = (screenWidth * 0.22).clamp(68.0, 90.0);
    final fontSize = (cardSize * 0.36).clamp(22.0, 32.0);

    return Wrap(
      spacing: 14.0,
      runSpacing: 14.0,
      alignment: WrapAlignment.center,
      children: availableSyllables.map((syllable) {
        return Draggable<String>(
          data: syllable,
          feedback: Material(
            color: Colors.transparent,
            child: _buildCard(syllable, cardSize, fontSize, isDragging: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildCard(syllable, cardSize, fontSize),
          ),
          child: _buildCard(syllable, cardSize, fontSize),
        );
      }).toList(),
    );
  }

  Widget _buildCard(String syllable, double size, double fontSize,
      {bool isDragging = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDragging
            ? AppTheme.secondaryColor.withOpacity(0.8)
            : AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDragging
            ? null
            : [
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          syllable,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
