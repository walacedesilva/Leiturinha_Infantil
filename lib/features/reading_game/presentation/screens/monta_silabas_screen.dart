import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/landscape_stage.dart';
import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../reading_game/data/encontros_content.dart';
import 'encontros_celebracao_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// MONTA-SÍLABAS — Atividade principal do Distrito dos Encontros
// Interface: Esteira industrial, blocos de madeira, braço robótico
// Paleta: Laranja #F97316 | Dourado #FBBF24 | Azul #3B82F6
// ═════════════════════════════════════════════════════════════════════════════

const _kOrange     = Color(0xFFF97316);
const _kOrangeDark = Color(0xFFEA580C);
const _kOrangeGlow = Color(0xFFFED7AA);
const _kGold       = Color(0xFFFBBF24);
const _kGoldDeep   = Color(0xFFD97706);
const _kBlue       = Color(0xFF3B82F6);
const _kBlueDark   = Color(0xFF1D4ED8);
const _kBlueLight  = Color(0xFFEFF6FF);
const _kGreen      = Color(0xFF22C55E);
const _kGreenDark  = Color(0xFF15803D);
const _kRed        = Color(0xFFEF4444);
const _kGray       = Color(0xFF9CA3AF);
const _kDark       = Color(0xFF1F2937);
const _kBg         = Color(0xFFF8FAFC);
const _kSteelLight = Color(0xFFF1F5F9);
const _kSteelMid   = Color(0xFFE2E8F0);

// ─────────────────────────────────────────────────────────────────────────────
// DATA: Puzzles de Monta-Sílabas
// Cada puzzle: cluster + vogal → sílaba + palavra-exemplo + emoji
// ─────────────────────────────────────────────────────────────────────────────
class _SilabaPuzzle {
  final String letter1;   // 'B'
  final String letter2;   // 'R'
  final String vowel;     // 'A'
  final String syllable;  // 'BRA'
  final String word;      // 'BRAÇO'
  final String emoji;     // '💪'
  final String meaning;   // 'parte do corpo'
  final List<String> distractors; // letras falsas

  const _SilabaPuzzle({
    required this.letter1,
    required this.letter2,
    required this.vowel,
    required this.syllable,
    required this.word,
    required this.emoji,
    required this.meaning,
    required this.distractors,
  });
}

const _kPuzzles = <_SilabaPuzzle>[
  _SilabaPuzzle(
    letter1: 'B', letter2: 'R', vowel: 'A',
    syllable: 'BRA', word: 'BRAÇO', emoji: '💪', meaning: 'parte do corpo',
    distractors: ['S', 'T', 'M', 'P'],
  ),
  _SilabaPuzzle(
    letter1: 'C', letter2: 'L', vowel: 'A',
    syllable: 'CLA', word: 'CLARO', emoji: '☀️', meaning: 'luminoso',
    distractors: ['R', 'S', 'T', 'V'],
  ),
  _SilabaPuzzle(
    letter1: 'T', letter2: 'R', vowel: 'E',
    syllable: 'TRE', word: 'TREM', emoji: '🚂', meaning: 'veículo',
    distractors: ['S', 'M', 'P', 'B'],
  ),
  _SilabaPuzzle(
    letter1: 'F', letter2: 'L', vowel: 'O',
    syllable: 'FLO', word: 'FLOR', emoji: '🌸', meaning: 'planta bonita',
    distractors: ['R', 'T', 'S', 'M'],
  ),
  _SilabaPuzzle(
    letter1: 'P', letter2: 'R', vowel: 'A',
    syllable: 'PRA', word: 'PRATO', emoji: '🍽️', meaning: 'para comer',
    distractors: ['S', 'T', 'V', 'M'],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MontaSilabasScreen extends StatefulWidget {
  const MontaSilabasScreen({super.key});

  @override
  State<MontaSilabasScreen> createState() => _MontaSilabasScreenState();
}

class _MontaSilabasScreenState extends State<MontaSilabasScreen>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  int _puzzleIndex = 0;
  bool _slot1Filled = false; // letter1 colocada
  bool _slot2Filled = false; // letter2 colocada
  bool _slot3Filled = false; // vogal colocada
  bool _showSuccess  = false;
  bool _showError    = false;
  bool _advancing    = false;
  String _errorLetter = '';

  // ── Animações ─────────────────────────────────────────────────────────────
  late final AnimationController _beltCtrl;
  late final AnimationController _gearCtrl;
  late final AnimationController _armCtrl;
  late final AnimationController _successCtrl;
  late final AnimationController _errorCtrl;
  late final AnimationController _mascotCtrl;
  late final AnimationController _sparkCtrl;
  late final AnimationController _magnetCtrl;

  _SilabaPuzzle get _puzzle => _kPuzzles[_puzzleIndex];
  int get _total => _kPuzzles.length;

  bool get _slot12Done => _slot1Filled && _slot2Filled;
  bool get _allDone    => _slot1Filled && _slot2Filled && _slot3Filled;

  @override
  void initState() {
    super.initState();
    AudioManager().playMusic('jogo');

    _beltCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _gearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _armCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _errorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _magnetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _playInstruction();
  }

  @override
  void dispose() {
    _beltCtrl.dispose();
    _gearCtrl.dispose();
    _armCtrl.dispose();
    _successCtrl.dispose();
    _errorCtrl.dispose();
    _mascotCtrl.dispose();
    _sparkCtrl.dispose();
    _magnetCtrl.dispose();
    AudioManager().playMusic('mapa');
    super.dispose();
  }

  void _playInstruction() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      AudioManager().playWord(_puzzle.syllable);
    });
  }

  void _onLetterTapped(String letter) {
    if (_showSuccess || _advancing) return;

    // Slot 1: letter1
    if (!_slot1Filled) {
      if (letter == _puzzle.letter1) {
        HapticFeedback.lightImpact();
        AudioManager().playSFX(SFXType.pop);
        AudioManager().playWord(letter);
        setState(() => _slot1Filled = true);
        if (_slot2Filled) _checkMagnet();
      } else {
        _wrongLetter(letter);
      }
      return;
    }

    // Slot 2: letter2
    if (!_slot2Filled) {
      if (letter == _puzzle.letter2) {
        HapticFeedback.lightImpact();
        AudioManager().playSFX(SFXType.pop);
        AudioManager().playWord(letter);
        setState(() => _slot2Filled = true);
        _checkMagnet();
      } else {
        _wrongLetter(letter);
      }
      return;
    }

    // Slot 3: vowel
    if (!_slot3Filled) {
      if (letter == _puzzle.vowel) {
        HapticFeedback.mediumImpact();
        AudioManager().playSFX(SFXType.correct);
        setState(() => _slot3Filled = true);
        Future.delayed(const Duration(milliseconds: 300), _onComplete);
      } else {
        _wrongLetter(letter);
      }
    }
  }

  void _checkMagnet() {
    // Toca efeito magnético quando os 2 primeiros slots são preenchidos
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) AudioManager().playWord(_puzzle.letter1 + _puzzle.letter2);
    });
  }

  void _wrongLetter(String letter) {
    HapticFeedback.vibrate();
    AudioManager().playSFX(SFXType.error);
    setState(() {
      _showError = true;
      _errorLetter = letter;
    });
    _errorCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showError = false);
    });
  }

  void _onComplete() {
    if (_advancing) return;
    setState(() => _showSuccess = true);
    _successCtrl.forward(from: 0);
    _gearCtrl.duration = const Duration(milliseconds: 800); // acelera engrenagem!
    AudioManager().playSFX(SFXType.balloons);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) AudioManager().playWord('${_puzzle.syllable}! ${_puzzle.word}!');
    });
    context.read<GamificationService>().addCoins(10);
    context.read<GamificationService>().addXp(15);
  }

  void _advanceNext() {
    if (_advancing) return;
    setState(() => _advancing = true);

    if (_puzzleIndex < _total - 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _puzzleIndex++;
          _slot1Filled = false;
          _slot2Filled = false;
          _slot3Filled = false;
          _showSuccess  = false;
          _advancing    = false;
        });
        _gearCtrl.duration = const Duration(milliseconds: 2400);
        _playInstruction();
      });
    } else {
      // Último puzzle — vai para celebração
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const EncontrosCelebracaoScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Fundo: interior fábrica desfocado ─────────────────────────────
          Positioned.fill(child: _FactoryBg()),
          // ── Conteúdo principal ────────────────────────────────────────────
          SafeArea(
            child: LandscapeStage(child: Column(
              children: [
                _TopBar(
                  puzzleIndex: _puzzleIndex,
                  total: _total,
                  puzzle: _puzzle,
                ),
                const SizedBox(height: 8),
                // Braço robótico + dica visual
                _RobotArm(armT: _armCtrl, magnetT: _magnetCtrl,
                    slot12Done: _slot12Done, puzzle: _puzzle),
                const SizedBox(height: 8),
                // Esteira + slots
                _AssemblyLine(
                  puzzle: _puzzle,
                  slot1: _slot1Filled,
                  slot2: _slot2Filled,
                  slot3: _slot3Filled,
                  beltT: _beltCtrl,
                  gearT: _gearCtrl,
                  sparkT: _sparkCtrl,
                  magnetT: _magnetCtrl,
                ),
                const SizedBox(height: 12),
                // Mascote
                _MascotRow(
                  mascotT: _mascotCtrl,
                  slot12Done: _slot12Done,
                  allDone: _allDone,
                  puzzle: _puzzle,
                ),
                const SizedBox(height: 12),
                // Blocos de letras (teclado)
                Expanded(
                  child: _LetterKeyboard(
                    puzzle: _puzzle,
                    slot1: _slot1Filled,
                    slot2: _slot2Filled,
                    slot3: _slot3Filled,
                    onTap: _onLetterTapped,
                    showError: _showError,
                    errorLetter: _errorLetter,
                  ),
                ),
                // Botões de áudio
                _AudioBar(
                  puzzle: _puzzle,
                  onListen: _playInstruction,
                ),
                const SizedBox(height: 8),
              ],
            )),
          ),
          // ── Overlay de sucesso ───────────────────────────────────────────
          if (_showSuccess)
            _SuccessOverlay(
              puzzle: _puzzle,
              successCtrl: _successCtrl,
              isLast: _puzzleIndex == _total - 1,
              onNext: _advanceNext,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FACTORY BG (desfocado)
// ─────────────────────────────────────────────────────────────────────────────
class _FactoryBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC), Color(0xFFFFF7ED)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Opacity(
        opacity: 0.07,
        child: CustomPaint(
          painter: _BgGearsPainter(),
        ),
      ),
    );
  }
}

class _BgGearsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kOrange;
    _drawGearCircle(canvas, Offset(size.width * 0.88, size.height * 0.15), 60, paint);
    _drawGearCircle(canvas, Offset(size.width * 0.05, size.height * 0.70), 48, paint);
    _drawGearCircle(canvas, Offset(size.width * 0.50, size.height * 0.88), 36, paint);
  }

  void _drawGearCircle(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawCircle(c, r, p);
    canvas.drawCircle(c, r * 0.45, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int puzzleIndex, total;
  final _SilabaPuzzle puzzle;
  const _TopBar({required this.puzzleIndex, required this.total, required this.puzzle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Botão voltar
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kDark),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 6),
          // Título + progresso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monta-Sílabas ⚙️',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kDark,
                  ),
                ),
                Text(
                  'Bloco ${puzzleIndex + 1} de $total  •  ${puzzle.syllable} → ${puzzle.word}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: _kGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Progresso circular
          _ProgressBadge(current: puzzleIndex + 1, total: total),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _ProgressBadge extends StatelessWidget {
  final int current, total;
  const _ProgressBadge({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: _kSteelMid,
            color: _kOrange,
            strokeWidth: 4,
          ),
          Text(
            '$current/$total',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROBOT ARM (topo direito, segurando bloco magnético)
// ─────────────────────────────────────────────────────────────────────────────
class _RobotArm extends StatelessWidget {
  final AnimationController armT;
  final AnimationController magnetT;
  final bool slot12Done;
  final _SilabaPuzzle puzzle;

  const _RobotArm({
    required this.armT,
    required this.magnetT,
    required this.slot12Done,
    required this.puzzle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 16),
          // Instrução textual
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: slot12Done ? _kOrangeGlow : _kBlueLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: slot12Done ? _kOrange : _kBlue.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Text(
                slot12Done
                    ? '🧲 ${puzzle.letter1}${puzzle.letter2} unidos! Adicione ${puzzle.vowel} para fazer ${puzzle.syllable}!'
                    : '⚙️ Toque em ${puzzle.letter1} e depois em ${puzzle.letter2} para montar!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: slot12Done ? _kOrangeDark : _kBlueDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Braço robótico animado
          AnimatedBuilder(
            animation: armT,
            builder: (_, __) {
              final dy = math.sin(armT.value * math.pi * 2) * 8;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Braço
                    Container(
                      width: 8,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kGray, Color(0xFF6B7280)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                    ),
                    // Pinca/Magneto
                    AnimatedBuilder(
                      animation: magnetT,
                      builder: (_, __) {
                        final glow = slot12Done
                            ? 0.6 + magnetT.value * 0.4
                            : 0.2;
                        return Container(
                          width: 32,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6B7280), Color(0xFF374151)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              if (slot12Done)
                                BoxShadow(
                                  color: _kOrange.withOpacity(glow),
                                  blurRadius: 12,
                                  spreadRadius: 4,
                                ),
                            ],
                            border: Border.all(
                              color: slot12Done
                                  ? _kOrange
                                  : Colors.white24,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              slot12Done ? '🧲' : '🤖',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ASSEMBLY LINE — esteira + slots [B]+[R]+[A]=[BRA]
// ─────────────────────────────────────────────────────────────────────────────
class _AssemblyLine extends StatelessWidget {
  final _SilabaPuzzle puzzle;
  final bool slot1, slot2, slot3;
  final AnimationController beltT, gearT, sparkT, magnetT;

  const _AssemblyLine({
    required this.puzzle,
    required this.slot1,
    required this.slot2,
    required this.slot3,
    required this.beltT,
    required this.gearT,
    required this.sparkT,
    required this.magnetT,
  });

  @override
  Widget build(BuildContext context) {
    final bothFirst = slot1 && slot2;
    final allFilled = slot1 && slot2 && slot3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Slots de montagem
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Slot 1
              _AssemblySlot(
                label: slot1 ? puzzle.letter1 : puzzle.letter1,
                filled: slot1,
                active: !slot1,
                glowing: bothFirst && !allFilled,
                gearT: gearT,
                magnetT: magnetT,
              ),
              // Operador +
              const _PlusSign(),
              // Slot 2
              _AssemblySlot(
                label: slot2 ? puzzle.letter2 : puzzle.letter2,
                filled: slot2,
                active: slot1 && !slot2,
                glowing: bothFirst && !allFilled,
                gearT: gearT,
                magnetT: magnetT,
              ),
              // Operador +
              const _PlusSign(),
              // Slot 3 (vogal)
              _AssemblySlot(
                label: puzzle.vowel,
                filled: slot3,
                active: bothFirst && !slot3,
                glowing: false,
                gearT: gearT,
                magnetT: magnetT,
                isVowel: true,
              ),
              // = resultado
              const _EqualSign(),
              // Resultado
              _ResultSlot(
                syllable: puzzle.syllable,
                ready: allFilled,
                sparkT: sparkT,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Esteira animada
          _BeltTrack(beltT: beltT, gearT: gearT, accelerated: allFilled),
          // Faíscas magnéticas entre slot1+slot2
          if (bothFirst && !allFilled)
            AnimatedBuilder(
              animation: magnetT,
              builder: (_, __) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      '✨ Efeito magnético! ✨',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kOrange
                            .withOpacity(0.6 + magnetT.value * 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssemblySlot extends StatelessWidget {
  final String label;
  final bool filled, active, glowing, isVowel;
  final AnimationController gearT, magnetT;

  const _AssemblySlot({
    required this.label,
    required this.filled,
    required this.active,
    required this.glowing,
    required this.gearT,
    required this.magnetT,
    this.isVowel = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: magnetT,
      builder: (_, __) {
        final glowOpacity = glowing ? (0.5 + magnetT.value * 0.5) : 0.0;
        return Container(
          width: 58,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (glowing)
                BoxShadow(
                  color: _kOrange.withOpacity(glowOpacity),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              if (active && !glowing)
                BoxShadow(
                  color: _kBlue.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: _WoodBlock(
            letter: filled ? label : '?',
            filled: filled,
            active: active,
            glowing: glowing,
            isVowel: isVowel,
          ),
        );
      },
    );
  }
}

class _WoodBlock extends StatelessWidget {
  final String letter;
  final bool filled, active, glowing, isVowel;

  const _WoodBlock({
    required this.letter,
    required this.filled,
    required this.active,
    required this.glowing,
    this.isVowel = false,
  });

  @override
  Widget build(BuildContext context) {
    Color topColor, bottomColor, borderColor;
    if (glowing) {
      topColor = const Color(0xFFFFF7ED);
      bottomColor = const Color(0xFFFED7AA);
      borderColor = _kOrange;
    } else if (filled && isVowel) {
      topColor = const Color(0xFFEFF6FF);
      bottomColor = const Color(0xFFDBEAFE);
      borderColor = _kBlue;
    } else if (filled) {
      topColor = const Color(0xFFFEF9C3);
      bottomColor = const Color(0xFFFEF08A);
      borderColor = _kGoldDeep;
    } else if (active) {
      topColor = _kBlueLight;
      bottomColor = const Color(0xFFDBEAFE);
      borderColor = _kBlue;
    } else {
      topColor = _kSteelLight;
      bottomColor = _kSteelMid;
      borderColor = _kGray.withOpacity(0.5);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topColor, bottomColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: filled ? _kDark : _kGray,
          ),
        ),
      ),
    );
  }
}

class _PlusSign extends StatelessWidget {
  const _PlusSign();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '+',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: _kGray.withOpacity(0.7),
        ),
      ),
    );
  }
}

class _EqualSign extends StatelessWidget {
  const _EqualSign();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '=',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: _kGray.withOpacity(0.7),
        ),
      ),
    );
  }
}

class _ResultSlot extends StatelessWidget {
  final String syllable;
  final bool ready;
  final AnimationController sparkT;

  const _ResultSlot({
    required this.syllable,
    required this.ready,
    required this.sparkT,
  });

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return Container(
        width: 72,
        height: 62,
        decoration: BoxDecoration(
          color: _kSteelLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _kGray.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Text(
            '???',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kGray.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: sparkT,
      builder: (_, __) {
        final glow = 0.5 + sparkT.value * 0.5;
        return Container(
          width: 72,
          height: 62,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kOrange, _kGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGoldDeep, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: _kOrange.withOpacity(glow * 0.8),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              syllable,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Color(0x88000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 400.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 300.ms);
      },
    );
  }
}

class _BeltTrack extends StatelessWidget {
  final AnimationController beltT, gearT;
  final bool accelerated;

  const _BeltTrack({
    required this.beltT,
    required this.gearT,
    required this.accelerated,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: beltT,
      builder: (_, __) {
        return Container(
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF78350F), Color(0xFF92400E), Color(0xFF78350F)],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CustomPaint(
              painter: _BeltAnimPainter(beltT.value, accelerated),
            ),
          ),
        );
      },
    );
  }
}

class _BeltAnimPainter extends CustomPainter {
  final double t;
  final bool fast;
  _BeltAnimPainter(this.t, this.fast);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final spacing = 18.0;
    final speed = fast ? 3.0 : 1.0;
    final offset = (t * spacing * speed) % spacing;
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height * 0.2),
        Offset(x + 10, size.height * 0.9),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BeltAnimPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// MASCOTE (robozinho com feedback)
// ─────────────────────────────────────────────────────────────────────────────
class _MascotRow extends StatelessWidget {
  final AnimationController mascotT;
  final bool slot12Done, allDone;
  final _SilabaPuzzle puzzle;

  const _MascotRow({
    required this.mascotT,
    required this.slot12Done,
    required this.allDone,
    required this.puzzle,
  });

  @override
  Widget build(BuildContext context) {
    String face, msg;
    if (allDone) {
      face = '🤖';
      msg = '${puzzle.syllable}! Som forte! ${puzzle.emoji}';
    } else if (slot12Done) {
      face = '🦾';
      msg = 'Agora adicione ${puzzle.vowel}!';
    } else {
      face = '👷';
      msg = puzzle.word.substring(0, 1) == puzzle.letter1
          ? 'Comece com ${puzzle.letter1}!'
          : 'Toque nas letras certas!';
    }

    return AnimatedBuilder(
      animation: mascotT,
      builder: (_, __) {
        final dy = math.sin(mascotT.value * math.pi * 2) * 4;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFED7AA), _kOrange],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kGold, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(face, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: allDone ? _kGreen : _kOrange.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      msg,
                      key: ValueKey(msg),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: allDone ? _kGreenDark : _kDark,
                      ),
                    ),
                  ),
                ),
              ),
              // Ilustração da palavra quando completo
              if (allDone) ...[
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text(
                      puzzle.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    Text(
                      puzzle.word,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _kOrangeDark,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TECLADO DE LETRAS (blocos de madeira tappáveis)
// ─────────────────────────────────────────────────────────────────────────────
class _LetterKeyboard extends StatelessWidget {
  final _SilabaPuzzle puzzle;
  final bool slot1, slot2, slot3;
  final ValueChanged<String> onTap;
  final bool showError;
  final String errorLetter;

  const _LetterKeyboard({
    required this.puzzle,
    required this.slot1,
    required this.slot2,
    required this.slot3,
    required this.onTap,
    required this.showError,
    required this.errorLetter,
  });

  List<String> get _allLetters {
    final base = [puzzle.letter1, puzzle.letter2, puzzle.vowel];
    final dist = puzzle.distractors.take(4).toList();
    final all = [...base, ...dist];
    all.shuffle(math.Random(puzzle.letter1.codeUnitAt(0)));
    return all;
  }

  bool _isUsed(String letter) {
    if (letter == puzzle.letter1 && slot1) return true;
    if (letter == puzzle.letter2 && slot2) return true;
    if (letter == puzzle.vowel && slot3) return true;
    return false;
  }

  bool _isActive(String letter) {
    if (!slot1 && letter == puzzle.letter1) return true;
    if (slot1 && !slot2 && letter == puzzle.letter2) return true;
    if (slot1 && slot2 && !slot3 && letter == puzzle.vowel) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final letters = _allLetters;
    final rows = <List<String>>[];
    for (int i = 0; i < letters.length; i += 4) {
      rows.add(letters.sublist(i, math.min(i + 4, letters.length)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: rows.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((letter) {
              final used = _isUsed(letter);
              final active = _isActive(letter);
              final isError = showError && errorLetter == letter;

              return _LetterBlock(
                letter: letter,
                used: used,
                active: active,
                isError: isError,
                onTap: () => onTap(letter),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _LetterBlock extends StatelessWidget {
  final String letter;
  final bool used, active, isError;
  final VoidCallback onTap;

  const _LetterBlock({
    required this.letter,
    required this.used,
    required this.active,
    required this.isError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color topC, botC, borderC;
    if (isError) {
      topC = const Color(0xFFFEE2E2);
      botC = const Color(0xFFFECACA);
      borderC = _kRed;
    } else if (used) {
      topC = _kSteelLight;
      botC = _kSteelMid;
      borderC = _kGray.withOpacity(0.3);
    } else if (active) {
      topC = const Color(0xFFFFF7ED);
      botC = const Color(0xFFFED7AA);
      borderC = _kOrange;
    } else {
      topC = const Color(0xFFFEFCE8);
      botC = const Color(0xFFFEF9C3);
      borderC = const Color(0xFFFCD34D);
    }

    return GestureDetector(
      onTap: used ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [topC, botC],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderC, width: 3),
          boxShadow: [
            BoxShadow(
              color: used
                  ? Colors.transparent
                  : isError
                      ? _kRed.withOpacity(0.4)
                      : active
                          ? _kOrange.withOpacity(0.5)
                          : Colors.black.withOpacity(0.12),
              blurRadius: active || isError ? 12 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: used
                      ? _kGray.withOpacity(0.4)
                      : isError
                          ? _kRed
                          : _kDark,
                ),
              ),
            ),
            // Textura de madeira (linhas sutis)
            if (!used)
              Positioned.fill(
                child: CustomPaint(painter: _WoodTexturePainter()),
              ),
            // Indicador ativo (pulsing border)
            if (active && !used)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _kOrange.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      )
          .animate(target: isError ? 1 : 0)
          .shake(duration: 400.ms, hz: 4, offset: const Offset(6, 0)),
    );
  }
}

class _WoodTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double y = 8; y < size.height; y += 12) {
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y + 2), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO BAR
// ─────────────────────────────────────────────────────────────────────────────
class _AudioBar extends StatelessWidget {
  final _SilabaPuzzle puzzle;
  final VoidCallback onListen;

  const _AudioBar({required this.puzzle, required this.onListen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          // "Ouvir Modelo"
          Expanded(
            child: GestureDetector(
              onTap: onListen,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Ouvir Modelo',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // "FALAR" (mic — decorativo, TTS faz o trabalho)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                AudioManager().playSFX(SFXType.pop);
                AudioManager().playWord(puzzle.syllable);
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kOrange, _kGold],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'FALAR',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS OVERLAY
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessOverlay extends StatelessWidget {
  final _SilabaPuzzle puzzle;
  final AnimationController successCtrl;
  final bool isLast;
  final VoidCallback onNext;

  const _SuccessOverlay({
    required this.puzzle,
    required this.successCtrl,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _kOrange, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withOpacity(0.5),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Faíscas e engrenagem
                AnimatedBuilder(
                  animation: successCtrl,
                  builder: (_, __) {
                    return SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(80, 80),
                            painter: _SuccessGearPainter(successCtrl.value),
                          ),
                          Text(
                            puzzle.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  '${puzzle.syllable}!',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: _kOrangeDark,
                  ),
                ),
                Text(
                  'Som forte! 🔊',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kGoldDeep,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${puzzle.emoji} ${puzzle.word} — ${puzzle.meaning}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Recompensas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _RewardChip(icon: '🪙', text: '+10'),
                    SizedBox(width: 8),
                    _RewardChip(icon: '⭐', text: '+15 XP'),
                  ],
                ),
                const SizedBox(height: 20),
                // Botão próximo
                GestureDetector(
                  onTap: onNext,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kOrange, _kGold],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: _kOrange.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isLast ? 'FINALIZAR! 🏆' : 'PRÓXIMO BLOCO ⚙️',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut)
                    .fadeIn(duration: 350.ms),
              ],
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 300.ms),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String icon, text;
  const _RewardChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kGoldDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessGearPainter extends CustomPainter {
  final double t;
  _SuccessGearPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;
    final angle = t * 2 * math.pi;

    final paint = Paint()
      ..color = _kOrange.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Outer ring rotating
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Spark lines
    final sparkPaint = Paint()
      ..color = _kGold
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final a = angle + i * math.pi / 4;
      final opacity = math.sin(t * math.pi * 2 + i) * 0.5 + 0.5;
      sparkPaint.color = _kGold.withOpacity(opacity);
      canvas.drawLine(
        Offset(cx + (r * 0.55) * math.cos(a), cy + (r * 0.55) * math.sin(a)),
        Offset(cx + r * math.cos(a), cy + r * math.sin(a)),
        sparkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SuccessGearPainter o) => o.t != t;
}
