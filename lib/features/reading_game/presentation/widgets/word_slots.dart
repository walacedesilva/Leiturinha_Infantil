import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../domain/game_logic.dart';

class WordSlots extends StatelessWidget {
  final GameLogic gameLogic;

  const WordSlots({Key? key, required this.gameLogic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        gameLogic.targetSyllables.length,
        (index) {
          final isPlaced = gameLogic.placedSyllables[index] != null;
          final placedSyllable = gameLogic.placedSyllables[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                gameLogic.onSyllableDropped(details.data, index);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isPlaced ? AppTheme.successColor : Colors.white,
                    border: isPlaced ? null : Border.all(color: AppTheme.primaryColor, width: 4),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isPlaced
                        ? [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isPlaced
                      ? Text(
                          placedSyllable!,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '_',
                          style: TextStyle(
                            fontSize: 36,
                            color: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
