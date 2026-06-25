import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../reading_game/data/digrafos_content.dart';

// ═════════════════════════════════════════════════════════════════════════════
// JARDIM DE PALAVRAS — Plantar palavras com dígrafos
// Paleta: Verde #22C55E, Roxo #8B5CF6, Dourado #FBBF24
// ═════════════════════════════════════════════════════════════════════════════

const _kGreen      = Color(0xFF22C55E);
const _kGreenDark  = Color(0xFF16A34A);
const _kGreenLight = Color(0xFFF0FDF4);
const _kPurple     = Color(0xFF8B5CF6);
const _kPurpleDark = Color(0xFF6D28D9);
const _kLavender   = Color(0xFFA78BFA);
const _kGold       = Color(0xFFFBBF24);
const _kGoldDeep   = Color(0xFFD97706);
const _kSkyTop     = Color(0xFFDDD6FE);
const _kSkyBottom  = Color(0xFFBAE6FD);

class WordGardenScreen extends StatefulWidget {
  const WordGardenScreen({super.key});

  @override
  State<WordGardenScreen> createState() => _WordGardenScreenState();
}

class _WordGardenScreenState extends State<WordGardenScreen>
    with TickerProviderStateMixin {
  // words shown in the 3 garden beds (one per digraph group, cycling)
  final List<GardenWord?> _planted = [null, null, null];
  late final List<GardenWord> _queue;
  int _queueIdx = 0;
  int _seedCount = 4;

  // Animations
  late final AnimationController _butterflyCtrl;
  late final AnimationController _growCtrl;
  late final AnimationController _mascotCtrl;
  late final AnimationController _pollenCtrl;

  GardenWord? _flyingWord; // word being carried by butterfly
  int? _targetBed;
  bool _showSuccess = false;

  final List<String> _herbarium = [];

  @override
  void initState() {
    super.initState();
    AudioManager().playMusic('jogo');
    _queue = List.of(kGardenWords)..shuffle(math.Random(12));

    _butterflyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pollenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _butterflyCtrl.dispose();
    _growCtrl.dispose();
    _mascotCtrl.dispose();
    _pollenCtrl.dispose();
    AudioManager().playMusic('mapa');
    super.dispose();
  }

  GardenWord? get _nextWord =>
      _queueIdx < _queue.length ? _queue[_queueIdx] : null;

  Future<void> _plant(int bedIndex) async {
    final word = _nextWord;
    if (word == null || _seedCount <= 0 || _planted[bedIndex] != null) return;

    setState(() {
      _flyingWord = word;
      _targetBed  = bedIndex;
      _seedCount--;
    });

    // Butterfly animation: fly to bed
    await _butterflyCtrl.forward(from: 0);

    setState(() {
      _planted[bedIndex] = word;
      _flyingWord = null;
      _targetBed  = null;
    });

    await _growCtrl.forward(from: 0);
    AudioManager().playSFX(SFXType.correct);
    AudioManager().playWord(word.word);

    setState(() => _showSuccess = true);

    // Gamification
    if (mounted) {
      final gam = context.read<GamificationService>();
      final progress = context.read<ProgressService>();
      await gam.addXp(15);
      await gam.addCoins(5);
      progress.markWordCompleted('garden_${word.word}', word.word);
    }

    _herbarium.add('${word.emoji} ${word.word}');

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _showSuccess = false;
        _queueIdx++;
      });
    }
  }

  void _harvest(int bedIndex) {
    if (_planted[bedIndex] == null) return;
    AudioManager().playSFX(SFXType.pop);
    setState(() {
      _planted[bedIndex] = null;
      _seedCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final next = _nextWord;

    return Scaffold(
      body: Stack(
        children: [
          // ── Sky background ──────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kSkyTop, _kSkyBottom, Color(0xFFBBF7D0)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // ── Pollen / sparkle particles ─────────────────────────────────
          AnimatedBuilder(
            animation: _pollenCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _PollenPainter(_pollenCtrl.value),
              ),
            ),
          ),
          // ── Butterflies (decorative) ────────────────────────────────────
          AnimatedBuilder(
            animation: _pollenCtrl,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _ButterflyPainter(_pollenCtrl.value),
              ),
            ),
          ),
          // ── Flying word butterfly ───────────────────────────────────────
          if (_flyingWord != null)
            AnimatedBuilder(
              animation: _butterflyCtrl,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(_butterflyCtrl.value);
                final startX = size.width * 0.15;
                final startY = size.height * 0.62;
                final endX   = size.width * (0.18 + (_targetBed ?? 1) * 0.28);
                final endY   = size.height * 0.55;
                final x = startX + (endX - startX) * t;
                final y = startY + (endY - startY) * t - math.sin(t * math.pi) * 60;
                return Positioned(
                  left: x - 30,
                  top: y - 30,
                  child: _FlyingWordBubble(word: _flyingWord!),
                );
              },
            ),
          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  seedCount: _seedCount,
                  collected: _herbarium.length,
                ),
                const SizedBox(height: 8),
                // Beto mascot
                AnimatedBuilder(
                  animation: _mascotCtrl,
                  builder: (_, __) => _BetoMascot(
                    instruction: next != null
                        ? 'Plante ${next.digraph} com ${next.complement}! 🌱'
                        : 'Jardim completo! 🎉',
                    bounce: _mascotCtrl.value,
                  ),
                ),
                const SizedBox(height: 16),
                // Garden beds
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: List.generate(3, (i) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                if (_planted[i] != null) {
                                  _harvest(i);
                                } else {
                                  _plant(i);
                                }
                              },
                              child: _GardenBed(
                                index: i,
                                planted: _planted[i],
                                isTarget: _targetBed == i,
                                growAnim: _growCtrl,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                // Success overlay
                if (_showSuccess && _planted.any((p) => p != null))
                  _SuccessBanner(word: _planted.lastWhere((p) => p != null)!),
                const SizedBox(height: 12),
                // Herbarium panel
                _HerbariumPanel(collected: _herbarium),
                const SizedBox(height: 8),
                // Bottom action bar
                _ActionBar(
                  next: next,
                  canPlant: next != null && _seedCount > 0,
                  onPlant: () => _plant(_planted.indexWhere((p) => p == null)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int seedCount, collected;
  const _TopBar({required this.seedCount, required this.collected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _kGreenDark, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jardim de Palavras 🌿',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14532D),
                  ),
                ),
                Text(
                  'Herbário: $collected palavras',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: _kGreenDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kGreen.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              children: [
                const Text('🌱', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$seedCount sementes',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _kGreenDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BETO MASCOT
// ─────────────────────────────────────────────────────────────────────────────
class _BetoMascot extends StatelessWidget {
  final String instruction;
  final double bounce;
  const _BetoMascot({required this.instruction, required this.bounce});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Transform.translate(
            offset: Offset(0, -bounce * 5),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF92400E).withOpacity(0.3),
                    boxShadow: [
                      BoxShadow(color: _kGreen.withOpacity(0.4), blurRadius: 10),
                    ],
                  ),
                ),
                const Text('🐻', style: TextStyle(fontSize: 32)),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: Text('🪣', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: _kGreen.withOpacity(0.4), width: 1.5),
              ),
              child: Text(
                instruction,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14532D),
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
// GARDEN BED
// ─────────────────────────────────────────────────────────────────────────────
class _GardenBed extends StatelessWidget {
  final int index;
  final GardenWord? planted;
  final bool isTarget;
  final AnimationController growAnim;

  const _GardenBed({
    required this.index,
    required this.planted,
    required this.isTarget,
    required this.growAnim,
  });

  // Which digraph to show as signpost in empty beds
  static const _signs = ['CH', 'LH', 'NH'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: planted != null
              ? [const Color(0xFF86EFAC), const Color(0xFF4ADE80)]
              : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTarget ? _kGold : _kGreen.withOpacity(0.4),
          width: isTarget ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isTarget ? _kGold : _kGreen).withOpacity(0.3),
            blurRadius: isTarget ? 16 : 8,
            spreadRadius: isTarget ? 4 : 0,
          ),
        ],
      ),
      child: planted != null
          ? _PlantedView(word: planted!, anim: growAnim)
          : _EmptyBedView(sign: _signs[index % _signs.length]),
    );
  }
}

class _EmptyBedView extends StatelessWidget {
  final String sign;
  const _EmptyBedView({required this.sign});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kPurple.withOpacity(0.4), width: 1.5),
          ),
          child: Text(
            sign,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _kPurpleDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('🌱', style: TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          'Toque para\nplantar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _kGreenDark.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _PlantedView extends StatelessWidget {
  final GardenWord word;
  final AnimationController anim;
  const _PlantedView({required this.word, required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final scale = anim.status == AnimationStatus.forward
            ? 0.6 + anim.value * 0.4
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(word.emoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kGold, _kGoldDeep]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _kGold.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  word.word,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1C1917),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Colher 🌾',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9,
                  color: _kGreenDark.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLYING WORD BUBBLE (borboleta carregando sílaba)
// ─────────────────────────────────────────────────────────────────────────────
class _FlyingWordBubble extends StatelessWidget {
  final GardenWord word;
  const _FlyingWordBubble({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: _kGold.withOpacity(0.5), blurRadius: 12),
        ],
        border: Border.all(color: _kGold, width: 2.5),
      ),
      child: Text(
        word.complement,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: _kPurpleDark,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessBanner extends StatelessWidget {
  final GardenWord word;
  const _SuccessBanner({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGold, _kGoldDeep],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _kGold.withOpacity(0.5), blurRadius: 16, spreadRadius: 3),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(word.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            '${word.word} cresceu! 🌟',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1917),
            ),
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERBARIUM PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _HerbariumPanel extends StatelessWidget {
  final List<String> collected;
  const _HerbariumPanel({required this.collected});

  @override
  Widget build(BuildContext context) {
    if (collected.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreen.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        children: [
          const Text(
            '📚 Herbário:',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _kGreenDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: collected.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => Center(
                child: Text(
                  collected[i],
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kPurpleDark,
                  ),
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
// ACTION BAR (bottom)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final GardenWord? next;
  final bool canPlant;
  final VoidCallback onPlant;

  const _ActionBar({
    required this.next,
    required this.canPlant,
    required this.onPlant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                if (next == null) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🔊 ${next!.word}!',
                        style: const TextStyle(fontFamily: 'Nunito')),
                    backgroundColor: _kPurple,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text(
                'Ouvir palavra',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPurple,
                side: const BorderSide(color: _kPurple, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canPlant ? onPlant : null,
              icon: const Text('🌿', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Colher planta',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: _kGreen.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────
class _PollenPainter extends CustomPainter {
  final double t;
  _PollenPainter(this.t);

  static final _rng = math.Random(55);
  static final _dots = List.generate(20, (_) => (
    x: _rng.nextDouble(),
    y: _rng.nextDouble() * 0.7,
    speed: 0.3 + _rng.nextDouble() * 0.5,
    size: 2.5 + _rng.nextDouble() * 4,
    color: [
      const Color(0xFFFBBF24),
      const Color(0xFFA78BFA),
      const Color(0xFF4ADE80),
    ][_rng.nextInt(3)],
  ));

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dots) {
      final phase = (t * d.speed + d.x) % 1.0;
      final opacity = math.sin(phase * math.pi) * 0.6;
      canvas.drawCircle(
        Offset(
          d.x * size.width + math.sin(phase * math.pi * 3) * 12,
          d.y * size.height - phase * 80,
        ),
        d.size,
        Paint()..color = d.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_PollenPainter o) => o.t != t;
}

class _ButterflyPainter extends CustomPainter {
  final double t;
  _ButterflyPainter(this.t);

  static final _rng = math.Random(77);
  static final _butterflies = List.generate(5, (i) => (
    baseX: _rng.nextDouble(),
    baseY: _rng.nextDouble() * 0.45,
    speed: 0.15 + _rng.nextDouble() * 0.2,
    phase: _rng.nextDouble(),
  ));

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _butterflies) {
      final phase = (t * b.speed + b.phase) % 1.0;
      final x = b.baseX * size.width + math.sin(phase * math.pi * 2) * 40;
      final y = b.baseY * size.height + math.cos(phase * math.pi * 3) * 20;

      // Simplified butterfly shape
      final wingFlap = math.sin(phase * math.pi * 8) * 8;
      final wingPaint = Paint()
        ..color = _kLavender.withOpacity(0.45);

      // Left wings
      final leftPath = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x - 14 - wingFlap, y - 8, x - 18, y + 2)
        ..quadraticBezierTo(x - 12, y + 10, x, y);
      canvas.drawPath(leftPath, wingPaint);

      // Right wings
      final rightPath = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + 14 + wingFlap, y - 8, x + 18, y + 2)
        ..quadraticBezierTo(x + 12, y + 10, x, y);
      canvas.drawPath(rightPath, wingPaint);
    }
  }

  @override
  bool shouldRepaint(_ButterflyPainter o) => o.t != t;
}
