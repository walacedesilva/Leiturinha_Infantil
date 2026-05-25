import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/gamification_models.dart';
import '../../../../services/progress_service.dart';
import 'portal_estelar_game_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MISSÃO DECODIFICAÇÃO GALÁCTICA — GAMEPLAY SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class MissaoDecodificacaoGalacticaScreen extends StatefulWidget {
  const MissaoDecodificacaoGalacticaScreen({super.key});

  @override
  State<MissaoDecodificacaoGalacticaScreen> createState() =>
      _MissaoDecodificacaoGalacticaScreenState();
}

class _MissaoDecodificacaoGalacticaScreenState
    extends State<MissaoDecodificacaoGalacticaScreen>
    with TickerProviderStateMixin {
  late final AnimationController _portalCtrl;
  late final AnimationController _particleCtrl;
  
  // Game state
  late final String _targetWord;
  late final List<String> _displayLetters;
  late final List<String> _options;
  late final String _correctLetter;
  bool _isSolved = false;
  int _failedAttempts = 0;
  bool _showLore = true;

  @override
  void initState() {
    super.initState();
    _portalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _setupRandomChallenge();
  }

  void _setupRandomChallenge() {
    _targetWord = "ESTRELA";
    final rand = math.Random();
    
    // Choose a random index from 0 to 6 to be the hidden blank space
    final blankIndex = rand.nextInt(_targetWord.length);
    _correctLetter = _targetWord[blankIndex];

    // Generate display characters with the blank slot
    _displayLetters = List.generate(_targetWord.length, (i) {
      return i == blankIndex ? "_" : _targetWord[i];
    });

    // Distractor alphabet pool (excluding the correct letter)
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    final distractors = alphabet.split("").where((letter) => letter != _correctLetter).toList();
    distractors.shuffle(rand);

    // Pick 5 distractors and include the correct option
    final chosenOptions = distractors.take(5).toList();
    chosenOptions.add(_correctLetter);
    chosenOptions.shuffle(rand); // Shuffle all options
    _options = chosenOptions;
  }

  @override
  void dispose() {
    _portalCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _onLetterSelect(String letter) {
    if (_isSolved) return;
    
    if (letter == _correctLetter) {
      // Correct!
      AudioManager().playSFX(SFXType.correct);
      setState(() {
        final blankIdx = _displayLetters.indexOf("_");
        if (blankIdx != -1) {
          _displayLetters[blankIdx] = _correctLetter;
        }
        _isSolved = true;
      });
      // Award points
      final gam = Provider.of<GamificationService>(context, listen: false);
      gam.addXp(50);
      gam.addCoins(20);
    } else {
      // Wrong!
      AudioManager().playSFX(SFXType.error);
      setState(() {
        _failedAttempts++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Ops! Tente outra letra espacial para abrir o portal!',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFD946EF),
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Cosmic Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF02010A),
                  Color(0xFF0B0626),
                  Color(0xFF160F38),
                ],
              ),
            ),
          ),

          // 2. Cosmic Floating Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GalacticParticlesPainter(progress: _particleCtrl.value),
                );
              },
            ),
          ),

          // 3. Game Layout
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar
                _buildHeader(context),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Portal Title
                        const Text(
                          'DECODIFICAÇÃO GALÁCTICA',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFBBF24),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Abra o Portal Estelar!',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Complete a palavra secreta para estabilizar o portal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLoreBriefing(),
                        const SizedBox(height: 25),

                        // Glowing Interactive Portal Visual
                        _buildPortalVisual(size),
                        const SizedBox(height: 40),

                        // Current Word Slots Display
                        _buildWordDisplay(),
                        const SizedBox(height: 50),

                        // Orbital Options Bubbles
                        if (!_isSolved)
                          _buildOptionsRow()
                        else
                          _buildMissionCompleteBox(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Missão Estelar',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          // Fuel badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🚀', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  '100%',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalVisual(Size size) {
    return SizedBox(
      height: 180,
      width: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer spinning halo 1
          AnimatedBuilder(
            animation: _portalCtrl,
            builder: (context, _) {
              return Transform.rotate(
                angle: _portalCtrl.value * 2 * math.pi,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFF00F2FE).withOpacity(0.0),
                        const Color(0xFFD946EF).withOpacity(0.4),
                        const Color(0xFF00F2FE).withOpacity(0.8),
                        const Color(0xFF00F2FE).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Outer spinning halo 2 (counter-rotating)
          AnimatedBuilder(
            animation: _portalCtrl,
            builder: (context, _) {
              return Transform.rotate(
                angle: -_portalCtrl.value * 2 * math.pi * 1.5,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFFFFF176).withOpacity(0.0),
                        const Color(0xFFFFF176).withOpacity(0.7),
                        const Color(0xFFD946EF).withOpacity(0.4),
                        const Color(0xFFFFF176).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Center core
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A0520),
              border: Border.all(
                color: _isSolved ? const Color(0xFFFBBF24) : const Color(0xFF00F2FE),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isSolved ? const Color(0xFFFBBF24) : const Color(0xFF00F2FE)).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Center(
              child: _isSolved
                  ? const Text(
                      '🌟',
                      style: TextStyle(fontSize: 48),
                    )
                      .animate()
                      .scaleXY(begin: 0.5, end: 1.2, duration: 1000.ms, curve: Curves.elasticOut)
                      .shake(duration: 1000.ms)
                  : const Text(
                      '🔮',
                      style: TextStyle(fontSize: 42),
                    )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 0.9, end: 1.1, duration: 1500.ms),
            ),
          ),
          // Success laser beams
          if (_isSolved) ...[
            Positioned.fill(
              child: CustomPaint(
                painter: _LaserFlarePainter(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWordDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_displayLetters.length, (index) {
        final char = _displayLetters[index];
        final isBlank = char == "_";

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 42,
          height: 52,
          decoration: BoxDecoration(
            color: isBlank
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFF00F2FE).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBlank
                  ? const Color(0xFFD946EF).withOpacity(0.4)
                  : const Color(0xFF00F2FE),
              width: isBlank ? 1.5 : 2.0,
            ),
            boxShadow: !isBlank
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withOpacity(0.3),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              isBlank ? "?" : char,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isBlank ? const Color(0xFFD946EF) : Colors.white,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOptionsRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_options.length, (index) {
        final opt = _options[index];

        return GestureDetector(
          onTap: () => _onLetterSelect(opt),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1B6B), Color(0xFF1E1045)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                opt,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.04,
                duration: 1200.ms + Duration(milliseconds: index * 150),
              )
              .moveY(
                begin: 0,
                end: -3.0,
                duration: 1200.ms + Duration(milliseconds: index * 150),
              ),
        );
      }),
    );
  }

  Widget _buildMissionCompleteBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.15),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🌟 MISSÃO CUMPRIDA! 🌟',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFBBF24),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Você estabilizou o portal estelar de Vênus com a letra correta!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          
          // Points row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRewardPill('⭐ +50 XP', const Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              _buildRewardPill('🪙 +20 Moedas', const Color(0xFFFBBF24)),
            ],
          ),
          const SizedBox(height: 24),

          // Continue CTA Button
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PortalEstelarGameScreen()),
              );
            },
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.35),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Center(
                child: Text(
                  'INICIAR EXPLORAÇÃO ESTELAR 🚀',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOutBack);
  }

  Widget _buildRewardPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoreBriefing() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showLore
                ? const Color(0xFF00F2FE).withOpacity(0.4)
                : Colors.white.withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: _showLore
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header toggle button
            InkWell(
              onTap: () {
                setState(() {
                  _showLore = !_showLore;
                });
                AudioManager().playSFX(SFXType.pop);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      color: Color(0xFFFBBF24),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'MISSÃO: BIBLIOTECA CÓSMICA',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _showLore
                            ? const Color(0xFF00F2FE).withOpacity(0.15)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _showLore ? 'FECHAR' : 'VER HISTÓRIA',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: _showLore ? const Color(0xFF00F2FE) : Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _showLore ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_showLore) ...[
              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white70,
                        ),
                        children: [
                          TextSpan(text: 'Você é um '),
                          TextSpan(
                            text: 'Explorador Lexical',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: ' que viaja pelo Sistema Solar para restaurar a '),
                          TextSpan(
                            text: 'Biblioteca Cósmica',
                            style: TextStyle(
                              color: Color(0xFF00F2FE),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: ', danificada por uma '),
                          TextSpan(
                            text: '"tempestade de interferência"',
                            style: TextStyle(
                              color: Color(0xFFD946EF),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: '.\n\nEm cada planeta, você encontra uma civilização alienígena que precisa de ajuda para compreender e se comunicar usando a língua portuguesa.\n\nCada atividade de leitura gera '),
                          TextSpan(
                            text: 'Fragmentos de Sabedoria',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: ' que reconstroem a biblioteca e desbloqueiam novas rotas estelares! 🚀'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _GalacticParticlesPainter extends CustomPainter {
  final double progress;
  final List<_GalacticStar> stars;

  _GalacticParticlesPainter({required this.progress})
      : stars = _generateStars();

  static List<_GalacticStar>? _cachedStars;

  static List<_GalacticStar> _generateStars() {
    if (_cachedStars != null) return _cachedStars!;
    final random = math.Random(54321);
    final list = <_GalacticStar>[];
    for (int i = 0; i < 30; i++) {
      list.add(_GalacticStar(
        xPct: random.nextDouble(),
        yPct: random.nextDouble(),
        speed: 0.05 + random.nextDouble() * 0.1,
        size: 1.5 + random.nextDouble() * 3.5,
        opacity: 0.1 + random.nextDouble() * 0.5,
      ));
    }
    _cachedStars = list;
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      double y = size.height - ((s.yPct * size.height + progress * s.speed * size.height) % size.height);
      double x = s.xPct * size.width;

      final double pulse = 0.4 + 0.6 * math.sin(progress * 2 * math.pi + s.xPct * 10);
      final paint = Paint()
        ..color = Colors.white.withOpacity(s.opacity * pulse)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), s.size * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GalacticParticlesPainter oldDelegate) => true;
}

class _GalacticStar {
  final double xPct;
  final double yPct;
  final double speed;
  final double size;
  final double opacity;

  _GalacticStar({
    required this.xPct,
    required this.yPct,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _LaserFlarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw solar rays
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(cx + math.cos(angle - 0.1) * 200, cy + math.sin(angle - 0.1) * 200)
        ..lineTo(cx + math.cos(angle + 0.1) * 200, cy + math.sin(angle + 0.1) * 200)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LaserFlarePainter oldDelegate) => false;
}
