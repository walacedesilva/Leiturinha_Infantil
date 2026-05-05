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
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.center,
      children: availableSyllables.map((syllable) {
        return Draggable<String>(
          data: syllable,
          feedback: Material(
            color: Colors.transparent,
            child: _buildSyllableCard(syllable, isDragging: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildSyllableCard(syllable),
          ),
          child: _buildSyllableCard(syllable),
        );
      }).toList(),
    );
  }

  Widget _buildSyllableCard(String syllable, {bool isDragging = false}) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: isDragging ? AppTheme.secondaryColor.withOpacity(0.8) : AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDragging 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        syllable,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          decoration: TextDecoration.none, // Evita underline amarelo do fallback do Material
        ),
      ),
    );
  }
}
