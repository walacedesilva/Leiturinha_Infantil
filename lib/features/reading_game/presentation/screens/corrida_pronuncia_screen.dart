import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/landscape_stage.dart';
import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import 'encontros_celebracao_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CORRIDA DE PRONÚNCIA — Pista de corrida com sílabas, Beto juiz
// Paleta: Laranja #F97316 | Azul #3B82F6 | Cinza Asfalto #374151
// ═════════════════════════════════════════════════════════════════════════════

const _kOrange     = Color(0xFFF97316);
const _kOrangeDark = Color(0xFFEA580C);
const _kGold       = Color(0xFFFBBF24);
const _kGoldDeep   = Color(0xFFD97706);
const _kBlue       = Color(0xFF3B82F6);
const _kBlueDark   = Color(0xFF1D4ED8);
const _kGreen      = Color(0xFF22C55E);
const _kGreenDark  = Color(0xFF15803D);
const _kRed        = Color(0xFFEF4444);
const _kAsphalt    = Color(0xFF374151);
const _kAsphaltMid = Color(0xFF4B5563);
const _kDark       = Color(0xFF1F2937);
const _kGray       = Color(0xFF9CA3AF);

// ─────────────────────────────────────────────────────────────────────────────
// DATA: Rounds da corrida
// ─────────────────────────────────────────────────────────────────────────────
class _RaceRound {
  final String syllable;   // 'BRA'
  final String word;       // 'BRAVO'
  final String emoji;      // '🦁'
  final String fullPhrase; // 'BRA de BRAVO!'
  final Color carColor;

  const _RaceRound({
    required this.syllable,
    required this.word,
    required this.emoji,
    required this.fullPhrase,
    required this.carColor,
  });
}

const _kRounds = <_RaceRound>[
  _RaceRound(syllable: 'BRA', word: 'BRAVO',  emoji: '🦁', fullPhrase: 'BRA de BRAVO!',  carColor: _kOrange),
  _RaceRound(syllable: 'CLA', word: 'CLARO',  emoji: '☀️', fullPhrase: 'CLA de CLARO!',  carColor: _kBlue),
  _RaceRound(syllable: 'TRE', word: 'TREM',   emoji: '🚂', fullPhrase: 'TRE de TREM!',   carColor: _kGreen),
  _RaceRound(syllable: 'FLO', word: 'FLOR',   emoji: '🌸', fullPhrase: 'FLO de FLOR!',   carColor: Color(0xFFEC4899)),
  _RaceRound(syllable: 'PRA', word: 'PRATO',  emoji: '🍽️', fullPhrase: 'PRA de PRATO!',  carColor: _kGoldDeep),
];

const _kTimePerRound = 15; // segundos por round

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CorridaPronunciaScreen extends StatefulWidget {
  const CorridaPronunciaScreen({super.key});

  @override
  State<CorridaPronunciaScreen> createState() => _CorridaPronunciaScreenState();
}

class _CorridaPronunciaScreenState extends State<CorridaPronunciaScreen>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  int _roundIndex = 0;
  int _secondsLeft = _kTimePerRound;
  int _stars = 0;
  bool _micActive = false;
  bool _showSuccess = false;
  bool _showTimeout = false;

  // ── Animações ─────────────────────────────────────────────────────────────
  late final AnimationController _carCtrl;       // carro lider avança
  late final AnimationController _car2Ctrl;      // carro oponente
  late final AnimationController _timerCtrl;     // timer countdown
  late final AnimationController _micWaveCtrl;   // ondas do mic
  late final AnimationController _gearTrackCtrl; // engrenagens na pista
  late final AnimationController _speedCtrl;     // linhas de velocidade
  late final AnimationController _betoCtrl;      // Beto bounce
  late final AnimationController _successCtrl;

  _RaceRound get _round => _kRounds[_roundIndex];
  int get _total => _kRounds.length;

  @override
  void initState() {
    super.initState();
    AudioManager().playMusic('jogo');

    _carCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _car2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _timerCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _kTimePerRound),
    )..addListener(_onTimerTick)..forward();

    _micWaveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _gearTrackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _speedCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _betoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _playRoundIntro();
  }

  @override
  void dispose() {
    _carCtrl.dispose();
    _car2Ctrl.dispose();
    _timerCtrl.dispose();
    _micWaveCtrl.dispose();
    _gearTrackCtrl.dispose();
    _speedCtrl.dispose();
    _betoCtrl.dispose();
    _successCtrl.dispose();
    AudioManager().playMusic('mapa');
    super.dispose();
  }

  void _onTimerTick() {
    if (!mounted) return;
    final secs = ((_kTimePerRound) * (1 - _timerCtrl.value)).ceil();
    if (secs != _secondsLeft) {
      setState(() => _secondsLeft = secs);
      if (secs == 0 && !_showSuccess) {
        _onTimeout();
      }
    }
  }

  void _playRoundIntro() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      AudioManager().playWord(_round.fullPhrase);
    });
  }

  void _onMicTap() {
    if (_showSuccess || _showTimeout) return;
    setState(() => _micActive = true);
    _micWaveCtrl.repeat();
    AudioManager().playSFX(SFXType.pop);

    // Simula reconhecimento (após 1.8s, considera correto para MVP)
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _micWaveCtrl.stop();
      setState(() => _micActive = false);
      _onCorrect();
    });
  }

  void _onCorrect() {
    if (_showSuccess) return;
    _timerCtrl.stop();

    // Estrelas baseadas no tempo restante
    int stars;
    if (_secondsLeft > 10) {
      stars = 3;
    } else if (_secondsLeft > 5) {
      stars = 2;
    } else {
      stars = 1;
    }

    setState(() {
      _stars = stars;
      _showSuccess = true;
    });
    _successCtrl.forward(from: 0);
    AudioManager().playSFX(SFXType.correct);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) AudioManager().playWord(_round.fullPhrase);
    });

    context.read<GamificationService>().addCoins(stars * 8);
    context.read<GamificationService>().addXp(stars * 12);
  }

  void _onTimeout() {
    if (_showTimeout || _showSuccess) return;
    setState(() => _showTimeout = true);
    AudioManager().playSFX(SFXType.error);
  }

  void _nextRound() {
    if (_roundIndex < _total - 1) {
      setState(() {
        _roundIndex++;
        _secondsLeft = _kTimePerRound;
        _stars = 0;
        _showSuccess = false;
        _showTimeout = false;
      });
      _timerCtrl
        ..reset()
        ..forward();
      _playRoundIntro();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EncontrosCelebracaoScreen()),
      );
    }
  }

  void _skipRound() {
    AudioManager().playSFX(SFXType.pop);
    _timerCtrl.stop();
    _nextRound();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Stack(
        children: [
          // ── Fundo: pista de corrida ──────────────────────────────────────
          Positioned.fill(child: _TrackBg(speedT: _speedCtrl)),
          // ── Conteúdo ────────────────────────────────────────────────────
          SafeArea(
            child: LandscapeStage(child: Column(
              children: [
                // HUD topo
                _RaceHud(
                  round: _round,
                  roundIndex: _roundIndex,
                  total: _total,
                  secondsLeft: _secondsLeft,
                  gearT: _gearTrackCtrl,
                ),
                const SizedBox(height: 8),
                // Pista (carros + Beto)
                Expanded(
                  flex: 3,
                  child: _RaceTrack(
                    round: _round,
                    carT: _carCtrl,
                    car2T: _car2Ctrl,
                    betoT: _betoCtrl,
                    gearT: _gearTrackCtrl,
                    showSuccess: _showSuccess,
                  ),
                ),
                // Sílaba em destaque
                _SyllableDisplay(round: _round, showSuccess: _showSuccess),
                const SizedBox(height: 8),
                // Botão mic + controles
                _RaceControls(
                  round: _round,
                  micActive: _micActive,
                  micWaveT: _micWaveCtrl,
                  onMic: _onMicTap,
                  onListen: _playRoundIntro,
                  onSkip: _skipRound,
                ),
                const SizedBox(height: 8),
              ],
            )),
          ),
          // ── Overlay de sucesso ───────────────────────────────────────────
          if (_showSuccess)
            _RaceSuccessOverlay(
              round: _round,
              stars: _stars,
              isLast: _roundIndex == _total - 1,
              successCtrl: _successCtrl,
              onNext: _nextRound,
            ),
          // ── Overlay de timeout ───────────────────────────────────────────
          if (_showTimeout && !_showSuccess)
            _TimeoutOverlay(
              round: _round,
              onRetry: () {
                setState(() => _showTimeout = false);
                setState(() => _secondsLeft = _kTimePerRound);
                _timerCtrl
                  ..reset()
                  ..forward();
              },
              onSkip: _skipRound,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRACK BACKGROUND (linhas de velocidade)
// ─────────────────────────────────────────────────────────────────────────────
class _TrackBg extends StatelessWidget {
  final AnimationController speedT;
  const _TrackBg({required this.speedT});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: speedT,
      builder: (_, __) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: CustomPaint(
          painter: _SpeedLinePainter(speedT.value),
        ),
      ),
    );
  }
}

class _SpeedLinePainter extends CustomPainter {
  final double t;
  _SpeedLinePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 22; i++) {
      final phase = (t + i / 22.0) % 1.0;
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final len = 20.0 + rng.nextDouble() * 60;
      final opacity = (1 - phase) * 0.4;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawLine(
        Offset(x - len * phase, y),
        Offset(x, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeedLinePainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// RACE HUD (topo)
// ─────────────────────────────────────────────────────────────────────────────
class _RaceHud extends StatelessWidget {
  final _RaceRound round;
  final int roundIndex, total, secondsLeft;
  final AnimationController gearT;

  const _RaceHud({
    required this.round,
    required this.roundIndex,
    required this.total,
    required this.secondsLeft,
    required this.gearT,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Voltar
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          // Sílaba atual
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      round.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Encontros: ${round.syllable}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(
                        Icons.star_rounded,
                        color: i < 3 ? _kGold.withOpacity(0.3) : _kGold,
                        size: 16,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          // Timer (gear shape)
          AnimatedBuilder(
            animation: gearT,
            builder: (_, __) {
              final urgent = secondsLeft <= 5;
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: urgent ? _kRed : _kAsphalt,
                  border: Border.all(
                    color: urgent ? _kRed : _kGold,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (urgent ? _kRed : _kGold).withOpacity(0.5),
                      blurRadius: urgent ? 16 : 8,
                      spreadRadius: urgent ? 4 : 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚙️', style: TextStyle(fontSize: 14)),
                    Text(
                      '${secondsLeft.toString().padLeft(2, '0')}s',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: urgent ? Colors.white : _kGold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RACE TRACK (carros + Beto árbitro)
// ─────────────────────────────────────────────────────────────────────────────
class _RaceTrack extends StatelessWidget {
  final _RaceRound round;
  final AnimationController carT, car2T, betoT, gearT;
  final bool showSuccess;

  const _RaceTrack({
    required this.round,
    required this.carT,
    required this.car2T,
    required this.betoT,
    required this.gearT,
    required this.showSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        // Pista (faixa de asfalto)
        Positioned.fill(
          child: CustomPaint(painter: _TrackPainter()),
        ),
        // Engrenagens na pista (decoração)
        AnimatedBuilder(
          animation: gearT,
          builder: (_, __) => Positioned(
            top: 10,
            left: 8,
            child: Transform.rotate(
              angle: gearT.value * 2 * math.pi,
              child: const Text('⚙️', style: TextStyle(fontSize: 28)),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: gearT,
          builder: (_, __) => Positioned(
            top: 10,
            right: 8,
            child: Transform.rotate(
              angle: -gearT.value * 2 * math.pi,
              child: const Text('⚙️', style: TextStyle(fontSize: 22)),
            ),
          ),
        ),
        // Carro 1 (lider — sílaba atual)
        AnimatedBuilder(
          animation: carT,
          builder: (_, __) {
            final x = 20.0 +
                (showSuccess
                    ? size.width * 0.65
                    : carT.value * size.width * 0.35);
            return Positioned(
              left: x,
              top: 40,
              child: _RaceCar(
                syllable: round.syllable,
                color: round.carColor,
                isLeader: true,
                hasMotionBlur: true,
              ),
            );
          },
        ),
        // Carro 2 (oponente)
        AnimatedBuilder(
          animation: car2T,
          builder: (_, __) {
            final x = car2T.value * size.width * 0.28;
            return Positioned(
              left: x,
              top: 110,
              child: _RaceCar(
                syllable: 'CLA',
                color: const Color(0xFF60A5FA),
                isLeader: false,
                hasMotionBlur: false,
              ),
            );
          },
        ),
        // Beto árbitro (centro)
        AnimatedBuilder(
          animation: betoT,
          builder: (_, __) {
            final dy = math.sin(betoT.value * math.pi * 2) * 5;
            return Positioned(
              right: 16,
              top: 60 + dy,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFED7AA), _kOrange],
                      ),
                      border: Border.all(color: _kGold, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: _kOrange.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🐻', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                  // Bandeira
                  Text(
                    showSuccess ? '🏁' : '🚩',
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            );
          },
        ),
        // Linha de chegada
        Positioned(
          right: 80,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white38, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Asfalto
    final asphalt = Paint()..color = _kAsphalt.withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 28, size.width, 82),
        const Radius.circular(12),
      ),
      asphalt,
    );
    // Faixa central pontilhada
    final dashPaint = Paint()
      ..color = _kGold.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dashWidth = 16.0;
    final dashGap = 10.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height * 0.5),
        Offset(x + dashWidth, size.height * 0.5),
        dashPaint,
      );
      x += dashWidth + dashGap;
    }
    // Bordas da pista (engrenagem esteira)
    final borderPaint = Paint()
      ..color = _kGoldDeep.withOpacity(0.6)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, 28), Offset(size.width, 28), borderPaint);
    canvas.drawLine(Offset(0, 110), Offset(size.width, 110), borderPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RaceCar extends StatelessWidget {
  final String syllable;
  final Color color;
  final bool isLeader, hasMotionBlur;

  const _RaceCar({
    required this.syllable,
    required this.color,
    required this.isLeader,
    required this.hasMotionBlur,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Motion blur (linhas de velocidade)
        if (hasMotionBlur)
          Positioned(
            left: -40,
            top: 8,
            child: Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, color.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        // Corpo do carro
        Container(
          width: isLeader ? 90 : 74,
          height: isLeader ? 44 : 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: isLeader ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isLeader ? 0.6 : 0.3),
                blurRadius: isLeader ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              syllable,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isLeader ? 20 : 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Color(0x66000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Rodas
        Positioned(
          bottom: -5,
          left: 8,
          child: _Wheel(big: isLeader),
        ),
        Positioned(
          bottom: -5,
          right: 8,
          child: _Wheel(big: isLeader),
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  final bool big;
  const _Wheel({required this.big});

  @override
  Widget build(BuildContext context) {
    final d = big ? 14.0 : 11.0;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kAsphalt,
        border: Border.all(color: _kGray, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SYLLABLE DISPLAY (sílaba em grande)
// ─────────────────────────────────────────────────────────────────────────────
class _SyllableDisplay extends StatelessWidget {
  final _RaceRound round;
  final bool showSuccess;

  const _SyllableDisplay({required this.round, required this.showSuccess});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: showSuccess
              ? [_kGreen, _kGreenDark]
              : [_kOrange, _kOrangeDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (showSuccess ? _kGreen : _kOrange).withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(round.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Text(
            round.syllable,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Color(0x55000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (showSuccess)
            const Text('✅', style: TextStyle(fontSize: 28))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  round.word,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Fale rápido! 🏎️',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RACE CONTROLS (mic, ouvir, skip)
// ─────────────────────────────────────────────────────────────────────────────
class _RaceControls extends StatelessWidget {
  final _RaceRound round;
  final bool micActive;
  final AnimationController micWaveT;
  final VoidCallback onMic, onListen, onSkip;

  const _RaceControls({
    required this.round,
    required this.micActive,
    required this.micWaveT,
    required this.onMic,
    required this.onListen,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // "Ouvir Modelo"
          SizedBox(
            width: 52,
            height: 52,
            child: GestureDetector(
              onTap: onListen,
              child: Container(
                decoration: BoxDecoration(
                  color: _kBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Botão mic principal
          Expanded(
            child: GestureDetector(
              onTap: onMic,
              child: AnimatedBuilder(
                animation: micWaveT,
                builder: (_, __) {
                  final scale = micActive
                      ? 1.0 + math.sin(micWaveT.value * math.pi * 2) * 0.04
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: micActive
                              ? [_kGreen, _kGreenDark]
                              : [_kOrange, _kGoldDeep],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: (micActive ? _kGreen : _kOrange)
                                .withOpacity(0.6),
                            blurRadius: micActive ? 24 : 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            micActive
                                ? Icons.graphic_eq_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            micActive ? 'GRAVANDO...' : 'FALAR RÁPIDO',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Skip
          SizedBox(
            width: 52,
            height: 52,
            child: GestureDetector(
              onTap: onSkip,
              child: Container(
                decoration: BoxDecoration(
                  color: _kAsphaltMid,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kGray, width: 1.5),
                ),
                child: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white70,
                  size: 26,
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
class _RaceSuccessOverlay extends StatelessWidget {
  final _RaceRound round;
  final int stars;
  final bool isLast;
  final AnimationController successCtrl;
  final VoidCallback onNext;

  const _RaceSuccessOverlay({
    required this.round,
    required this.stars,
    required this.isLast,
    required this.successCtrl,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _kGold, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withOpacity(0.4),
                  blurRadius: 32,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(round.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  round.syllable,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: _kGold,
                  ),
                ),
                Text(
                  '${round.word} — Perfeito! 🏁',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                // Estrelas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star_rounded,
                        color: i < stars ? _kGold : Colors.white24,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RaceReward(icon: '🪙', text: '+${stars * 8}'),
                    const SizedBox(width: 8),
                    _RaceReward(icon: '⭐', text: '+${stars * 12} XP'),
                  ],
                ),
                const SizedBox(height: 20),
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
                        isLast ? 'FINALIZAR! 🏆' : 'PRÓXIMO ROUND 🚀',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .slideY(begin: 0.3, duration: 400.ms)
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

class _RaceReward extends StatelessWidget {
  final String icon, text;
  const _RaceReward({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kAsphalt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withOpacity(0.5), width: 1.5),
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
              color: _kGold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMEOUT OVERLAY
// ─────────────────────────────────────────────────────────────────────────────
class _TimeoutOverlay extends StatelessWidget {
  final _RaceRound round;
  final VoidCallback onRetry, onSkip;

  const _TimeoutOverlay({
    required this.round,
    required this.onRetry,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kRed, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⏰', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                const Text(
                  'Tempo Esgotado!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kRed,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A sílaba era ${round.syllable} — ${round.fullPhrase}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onRetry,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _kAsphaltMid,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _kGray),
                          ),
                          child: const Center(
                            child: Text(
                              'Tentar de novo',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: onSkip,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kOrange, _kGoldDeep],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Próxima 🏎️',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 350.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 250.ms),
        ),
      ),
    );
  }
}
