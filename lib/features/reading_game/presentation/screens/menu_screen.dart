import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme.dart';
import '../../../../services/progress_service.dart';
import '../../data/word_bank.dart';
import '../../domain/game_logic.dart';
import 'game_screen.dart';

/// Tela de seleção de família silábica com indicador de progresso.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(),
            const SizedBox(height: 8),
            Expanded(
              child: _FamilyGrid(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aprenda a Ler! 📖',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),
          const SizedBox(height: 4),
          Text(
            'Escolha uma família de sílabas',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textColor.withOpacity(0.65),
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        ],
      ),
    );
  }
}

class _FamilyGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final families = WordBank.families;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.05,
        ),
        itemCount: families.length,
        itemBuilder: (context, index) {
          final family = families[index];
          return _FamilyCard(
            family: family,
            animationDelay: Duration(milliseconds: 100 * index),
          );
        },
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final SyllabicFamily family;
  final Duration animationDelay;

  const _FamilyCard({required this.family, required this.animationDelay});

  @override
  Widget build(BuildContext context) {
    // Lê progresso em tempo real via Consumer
    return Consumer<ProgressService>(
      builder: (context, progressService, _) {
        final progress =
            progressService.getFamilyProgress(family.key, family.totalWords);
        final color = Color(family.colorValue);

        return _FamilyCardContent(
          family: family,
          progress: progress,
          color: color,
          animationDelay: animationDelay,
        );
      },
    );
  }
}

class _FamilyCardContent extends StatefulWidget {
  final SyllabicFamily family;
  final FamilyProgress progress;
  final Color color;
  final Duration animationDelay;

  const _FamilyCardContent({
    required this.family,
    required this.progress,
    required this.color,
    required this.animationDelay,
  });

  @override
  State<_FamilyCardContent> createState() => _FamilyCardContentState();
}

class _FamilyCardContentState extends State<_FamilyCardContent> {
  bool _pressed = false;

  void _navigateToGame(BuildContext context) async {
    // Inicializa GameLogic com a família selecionada
    final gameLogic = context.read<GameLogic>();
    gameLogic.initWithFamily(widget.family);

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const GameScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final color = widget.color;
    final isComplete = p.isCompleted;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _navigateToGame(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de completo
              if (isComplete)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🌟 Completo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              // Nome da família
              Text(
                widget.family.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              // Contagem
              Text(
                '${p.completedWords}/${p.totalWords} palavras',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              // Barra de progresso
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: p.percentage,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        )
            .animate(delay: widget.animationDelay)
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.2, duration: 350.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}
