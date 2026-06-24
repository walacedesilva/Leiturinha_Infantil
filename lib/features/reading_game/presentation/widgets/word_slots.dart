import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../domain/game_logic.dart';

class WordSlots extends StatelessWidget {
  final GameLogic gameLogic;

  const WordSlots({Key? key, required this.gameLogic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = gameLogic.targetSyllables.length;
        const hPad = 8.0; // padding horizontal por slot
        // Descontar padding horizontal da tela (24 cada lado em game_screen)
        final available = constraints.maxWidth;
        final slotSize =
            ((available - hPad * 2 * n) / n).clamp(58.0, 100.0);
        final fontSize = (slotSize * 0.36).clamp(20.0, 36.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(n, (index) {
            final isPlaced = gameLogic.placedSyllables[index] != null;
            final placedSyllable = gameLogic.placedSyllables[index];

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  gameLogic.onSyllableDropped(details.data, index);
                },
                builder: (context, candidateData, rejectedData) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: slotSize,
                    height: slotSize,
                    decoration: BoxDecoration(
                      color: isPlaced
                          ? AppTheme.successColor
                          : candidateData.isNotEmpty
                              ? AppTheme.primaryColor.withOpacity(0.15)
                              : Colors.white,
                      border: isPlaced
                          ? null
                          : Border.all(
                              color: candidateData.isNotEmpty
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor,
                              width: candidateData.isNotEmpty ? 3 : 4,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isPlaced
                          ? [
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: isPlaced
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              placedSyllable!,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            '_',
                            style: TextStyle(
                              fontSize: fontSize,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                          ),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }
}
