import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme.dart';
import '../../domain/game_logic.dart';
import '../widgets/syllable_pool.dart';
import '../widgets/word_slots.dart';
import '../widgets/balloon_overlay.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<GameLogic>(
          builder: (context, gameLogic, child) {
            if (gameLogic.currentWord.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botão de ouvir a palavra
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 40, color: AppTheme.primaryColor),
                            onPressed: () {
                              gameLogic.playWordAudio();
                            },
                          ),
                          // Placeholder para progresso/estrelas
                          const Icon(Icons.star, size: 40, color: AppTheme.secondaryColor),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Slots da Palavra
                    WordSlots(gameLogic: gameLogic),

                    const Spacer(),

                    // Pool de Sílabas
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SyllablePool(
                        availableSyllables: gameLogic.availableSyllables,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),

                // Comemoração
                if (gameLogic.showCelebration)
                  BalloonOverlay(
                    onAnimationComplete: () {
                      // O game logic avança automaticamente, mas mantemos o callback se precisar de algo na UI
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
