import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../domain/lock_policy.dart';
import 'vowel_practice_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS & DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum _CardState { completed, active, locked }

class _VowelLevel {
  final String vowel;
  final String emoji;
  final String label;
  final Color primary;
  final Color light;
  final Color dark;
  final List<String> exampleWords;
  final _CardState state;
  final int progress;
  final int total;
  final String soundPhrase;
  final List<String> objectEmojis;

  const _VowelLevel({
    required this.vowel,
    required this.emoji,
    required this.label,
    required this.primary,
    required this.light,
    required this.dark,
    required this.exampleWords,
    required this.state,
    required this.progress,
    required this.total,
    required this.soundPhrase,
    required this.objectEmojis,
  });
}

const _kLevels = <_VowelLevel>[
  _VowelLevel(
    vowel: 'A',
    emoji: '🍎',
    label: 'Aventura do A',
    primary: Color(0xFFEF4444),
    light: Color(0xFFFEE2E2),
    dark: Color(0xFF991B1B),
    exampleWords: ['ABELHA', 'AMOR', 'ARCO', 'AVIÃO'],
    state: _CardState.completed,
    progress: 3,
    total: 3,
    soundPhrase: 'Aaaa de ABACAXI, A de AVIÃO!',
    objectEmojis: ['🍎', '✈️', '🎨'],
  ),
  _VowelLevel(
    vowel: 'E',
    emoji: '⭐',
    label: 'Estrela do E',
    primary: Color(0xFF3B82F6),
    light: Color(0xFFDBEAFE),
    dark: Color(0xFF1D4ED8),
    exampleWords: ['ELEFANTE', 'ESCOLA', 'ESTRELA', 'ESPADA'],
    state: _CardState.active,
    progress: 1,
    total: 3,
    soundPhrase: 'Eeee de ESTRELA, E de ELEFANTE!',
    objectEmojis: ['⭐', '🐘', '🏫'],
  ),
  _VowelLevel(
    vowel: 'I',
    emoji: '🏝️',
    label: 'Ilha do I',
    primary: Color(0xFFF59E0B),
    light: Color(0xFFFEF3C7),
    dark: Color(0xFFB45309),
    exampleWords: ['ILHA', 'INSETO', 'ÍNDIO', 'IMAGEM'],
    state: _CardState.locked,
    progress: 0,
    total: 3,
    soundPhrase: 'Iiii de ILHA, I de ÍMÃ!',
    objectEmojis: ['🏝️', '🧲', '⛪'],
  ),
  _VowelLevel(
    vowel: 'O',
    emoji: '👁️',
    label: 'Olho do O',
    primary: Color(0xFF22C55E),
    light: Color(0xFFDCFCE7),
    dark: Color(0xFF166534),
    exampleWords: ['OVO', 'OURIÇO', 'OSSO', 'OURO'],
    state: _CardState.locked,
    progress: 0,
    total: 3,
    soundPhrase: 'Oooo de OLHO, O de ÔNIBUS!',
    objectEmojis: ['👁️', '🚌', '🥚'],
  ),
  _VowelLevel(
    vowel: 'U',
    emoji: '🍇',
    label: 'Uva do U',
    primary: Color(0xFFA855F7),
    light: Color(0xFFF3E8FF),
    dark: Color(0xFF6B21A8),
    exampleWords: ['UVA', 'URSO', 'UNIFORME', 'ÚTIL'],
    state: _CardState.locked,
    progress: 0,
    total: 3,
    soundPhrase: 'Uuuu de UVA, U de URSO!',
    objectEmojis: ['🍇', '🐻', '👶'],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// Computes real card state and progress for each vowel from ProgressService.
List<_VowelLevel> _computeLevels(ProgressService progress) {
  final computed = <_VowelLevel>[];
  var prevCompleted = true; // a primeira vogal está sempre liberada
  for (final base in _kLevels) {
    final key = 'vogal_${base.vowel}';
    final fp = progress.getFamilyProgress(key, base.total);
    final _CardState state;
    // Bloqueio sequencial: uma vogal só abre quando a anterior é concluída.
    if (fp.isCompleted) {
      state = _CardState.completed;
    } else if (isLevelUnlocked(
        prevCompleted: prevCompleted, hasProgress: fp.completedWords > 0)) {
      state = _CardState.active;
    } else {
      state = _CardState.locked;
    }
    prevCompleted = fp.isCompleted;
    computed.add(_VowelLevel(
      vowel: base.vowel,
      emoji: base.emoji,
      label: base.label,
      primary: base.primary,
      light: base.light,
      dark: base.dark,
      exampleWords: base.exampleWords,
      state: state,
      progress: fp.completedWords,
      total: base.total,
      soundPhrase: base.soundPhrase,
      objectEmojis: base.objectEmojis,
    ));
  }
  return computed;
}

class VilaDasVogaisScreen extends StatelessWidget {
  const VilaDasVogaisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();
    final progress = context.watch<ProgressService>();
    final computedLevels = _computeLevels(progress);
    final firstActive = computedLevels.firstWhere(
      (l) => l.state == _CardState.active,
      orElse: () => computedLevels.first,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF1E40AF),
      body: SafeArea(
        child: Column(
          children: [
            _Header(coins: gam.state.coins),
            const _MapTitle(),
            const Expanded(child: _LevelList()),
            _PlayButton(
              onTap: () => _navigateToInterior(context, firstActive),
            ),
          ],
        ),
      ),
    );
  }

  static void _navigateToInterior(BuildContext context, _VowelLevel level) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => _VowelInteriorScreen(level: level),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int coins;
  const _Header({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🧒', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Olá! 👋',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1,
                  ),
                ),
                Text(
                  'Explorador',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFF59E0B),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 5),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAP TITLE
// ─────────────────────────────────────────────────────────────────────────────

class _MapTitle extends StatelessWidget {
  const _MapTitle();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();
    final completed = _kLevels.where((l) =>
      progress.getFamilyProgress('vogal_${l.vowel}', l.total).isCompleted
    ).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            'VILA DAS VOGAIS',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🌟  $completed de ${_kLevels.length} concluído',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: -0.15, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEVEL LIST
// ─────────────────────────────────────────────────────────────────────────────

class _LevelList extends StatelessWidget {
  const _LevelList();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();
    final levels = _computeLevels(progress);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: levels.length,
      itemBuilder: (context, idx) {
        return _LevelCard(
          level: levels[idx],
          index: idx,
        )
            .animate(delay: Duration(milliseconds: 80 * idx))
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEVEL CARD
// ─────────────────────────────────────────────────────────────────────────────

class _LevelCard extends StatefulWidget {
  final _VowelLevel level;
  final int index;
  const _LevelCard({required this.level, required this.index});

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final Animation<double> _scaleAnim;
  bool _showStars = false;

  int _tapCount = 0;
  DateTime _firstTapTime = DateTime(0);
  bool _spamBlocked = false;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    if (widget.level.state == _CardState.locked) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Complete as vogais anteriores primeiro!',
              style: TextStyle(fontFamily: 'Nunito')),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    if (now.difference(_firstTapTime) > const Duration(seconds: 2)) {
      _tapCount = 0;
      _firstTapTime = now;
    }
    _tapCount++;
    if (_tapCount > 5) {
      if (!_spamBlocked) {
        setState(() => _spamBlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🐢 Calma, devagarinho!',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 15)),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) setState(() => _spamBlocked = false);
        });
      }
      return;
    }

    HapticFeedback.lightImpact();
    _tapCtrl.forward(from: 0);
    setState(() => _showStars = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showStars = false);
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      VilaDasVogaisScreen._navigateToInterior(context, widget.level);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.level.state == _CardState.locked;
    final isCompleted = widget.level.state == _CardState.completed;
    final isActive = widget.level.state == _CardState.active;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: isLocked
                ? []
                : [
                    BoxShadow(
                      color: widget.level.primary.withOpacity(isActive ? 0.45 : 0.25),
                      blurRadius: isActive ? 22 : 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isLocked
                        ? const LinearGradient(
                            colors: [Color(0xFF374151), Color(0xFF1F2937)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [widget.level.light, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  ),
                  child: Row(
                    children: [
                      _ProgressRing(level: widget.level),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.level.label,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isLocked
                                    ? const Color(0xFF9CA3AF)
                                    : widget.level.dark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _StateLabel(level: widget.level),
                            if (!isLocked) ...[
                              const SizedBox(height: 8),
                              _ProgressBar(level: widget.level),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _RightIcon(level: widget.level),
                    ],
                  ),
                ),
                if (isActive)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: widget.level.primary.withOpacity(0.70),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isCompleted)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.level.primary, widget.level.light, widget.level.primary],
                        ),
                      ),
                    ),
                  ),
                if (_showStars && !isLocked)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _StarParticleOverlay(color: widget.level.primary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      )
          .animate(
            target: isActive ? 1 : 0,
            onPlay: (c) => isActive ? c.repeat(reverse: true) : null,
          )
          .scaleXY(begin: 1.0, end: 1.015, duration: 1200.ms, curve: Curves.easeInOut),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAR PARTICLE OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

class _StarParticleOverlay extends StatefulWidget {
  final Color color;
  const _StarParticleOverlay({required this.color});

  @override
  State<_StarParticleOverlay> createState() => _StarParticleOverlayState();
}

class _StarParticleOverlayState extends State<_StarParticleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = math.Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(5, (_) => _Particle(_rng));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(_particles, _ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  final double x;
  final double startY;
  final double size;
  final double speed;

  _Particle(math.Random rng)
      : x = rng.nextDouble(),
        startY = 0.3 + rng.nextDouble() * 0.5,
        size = 8 + rng.nextDouble() * 10,
        speed = 0.6 + rng.nextDouble() * 0.4;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final Color color;

  const _ParticlePainter(this.particles, this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final progress = (t * p.speed).clamp(0.0, 1.0);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final y = p.startY - progress * 0.6;
      paint.color = color.withOpacity(opacity * 0.85);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size * (1 - progress * 0.5),
        paint,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: '⭐',
          style: TextStyle(fontSize: p.size, color: Colors.white.withOpacity(opacity)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(p.x * size.width - p.size / 2, y * size.height - p.size / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// VOWEL INTERIOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _VowelInteriorScreen extends StatefulWidget {
  final _VowelLevel level;
  const _VowelInteriorScreen({super.key, required this.level});

  @override
  State<_VowelInteriorScreen> createState() => _VowelInteriorScreenState();
}

class _VowelInteriorScreenState extends State<_VowelInteriorScreen>
    with TickerProviderStateMixin {
  late final AnimationController _vowelBounceCtrl;
  late final Animation<double> _vowelBounce;
  bool _vowelGlowing = false;
  String? _activeWord;

  int _interiorTapCount = 0;
  DateTime _interiorFirstTap = DateTime(0);

  @override
  void initState() {
    super.initState();
    _vowelBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _vowelBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _vowelBounceCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _vowelBounceCtrl.dispose();
    super.dispose();
  }

  bool _checkSpam() {
    final now = DateTime.now();
    if (now.difference(_interiorFirstTap) > const Duration(seconds: 2)) {
      _interiorTapCount = 0;
      _interiorFirstTap = now;
    }
    _interiorTapCount++;
    if (_interiorTapCount > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🐢 Calma, devagarinho!',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 15)),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    }
    return false;
  }

  void _onTapVowel() {
    if (_checkSpam()) return;
    HapticFeedback.mediumImpact();
    _vowelBounceCtrl.forward(from: 0);
    setState(() => _vowelGlowing = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _vowelGlowing = false);
    });
    AudioManager().playWord(widget.level.vowel);
  }

  void _onLongPressVowel() {
    HapticFeedback.vibrate();
    AudioManager().playWord(widget.level.soundPhrase);
  }

  void _onTapWord(String word) {
    if (_checkSpam()) return;
    HapticFeedback.lightImpact();
    setState(() => _activeWord = word);
    AudioManager().playWord(word);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _activeWord = null);
    });
  }

  void _onDoubleTapWord(String word) {
    HapticFeedback.lightImpact();
    AudioManager().playWordSlow(word);
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    return Scaffold(
      backgroundColor: level.dark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      level.label,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(level.emoji, style: const TextStyle(fontSize: 28)),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _onTapVowel,
              onLongPress: _onLongPressVowel,
              child: AnimatedBuilder(
                animation: _vowelBounce,
                builder: (_, child) => Transform.scale(
                  scale: _vowelBounce.value,
                  child: child,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: level.primary,
                    boxShadow: [
                      BoxShadow(
                        color: level.primary.withOpacity(_vowelGlowing ? 0.9 : 0.4),
                        blurRadius: _vowelGlowing ? 40 : 20,
                        spreadRadius: _vowelGlowing ? 8 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      level.vowel,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).scaleXY(begin: 0.7, end: 1.0),
            const SizedBox(height: 8),
            Text(
              '👆 Toque na vogal para ouvir!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: level.objectEmojis
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(e.value, style: const TextStyle(fontSize: 40)),
                    )
                        .animate(delay: Duration(milliseconds: 200 + e.key * 100))
                        .fadeIn(duration: 300.ms)
                        .scaleXY(begin: 0.5, end: 1.0),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Palavras com "${level.vowel}":',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: level.exampleWords
                        .asMap()
                        .entries
                        .map((e) => _WordChip(
                              word: e.value,
                              level: level,
                              isActive: _activeWord == e.value,
                              onTap: () => _onTapWord(e.value),
                              onDoubleTap: () => _onDoubleTapWord(e.value),
                            )
                                .animate(delay: Duration(milliseconds: 100 * e.key))
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: 0.2, end: 0))
                        .toList(),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => AudioManager().playWord(level.soundPhrase),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.volume_up_rounded, color: level.light, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          level.soundPhrase,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            color: level.light,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, animation, __) => VowelPracticeScreen(
                          vowel: level.vowel,
                          primary: level.primary,
                          light: level.light,
                          dark: level.dark,
                          examplePhrase: '${level.vowel} de ${level.exampleWords[0]}!',
                          objectEmoji: level.objectEmojis.first,
                        ),
                        transitionsBuilder: (_, animation, __, child) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          return FadeTransition(
                            opacity: curved,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
                              child: child,
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 380),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: level.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.mic_rounded, size: 24),
                  label: const Text(
                    'Praticar Agora',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _WordChip extends StatelessWidget {
  final String word;
  final _VowelLevel level;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _WordChip({
    required this.word,
    required this.level,
    required this.isActive,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? level.primary : level.light.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? level.primary : level.primary.withOpacity(0.40),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: level.primary.withOpacity(0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          word,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : level.light,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS RING
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  final _VowelLevel level;
  const _ProgressRing({required this.level});

  @override
  Widget build(BuildContext context) {
    final isLocked = level.state == _CardState.locked;
    final isCompleted = level.state == _CardState.completed;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _RingPainter(
              progress: level.progress / level.total,
              color: isLocked ? const Color(0xFF4B5563) : level.primary,
              trackColor: isLocked
                  ? const Color(0xFF374151)
                  : level.primary.withOpacity(0.15),
              strokeWidth: 5,
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked
                  ? const Color(0xFF1F2937)
                  : isCompleted
                      ? level.primary
                      : Colors.white,
              boxShadow: isLocked
                  ? []
                  : [
                      BoxShadow(
                        color: level.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: isLocked
                  ? const Icon(Icons.lock_rounded, color: Color(0xFF9CA3AF), size: 22)
                  : isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                      : Text(
                          level.vowel,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: level.primary,
                            height: 1,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _StateLabel extends StatelessWidget {
  final _VowelLevel level;
  const _StateLabel({required this.level});

  @override
  Widget build(BuildContext context) {
    switch (level.state) {
      case _CardState.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 15, color: level.primary),
            const SizedBox(width: 4),
            Text(
              'Concluído!  ${level.progress}/${level.total}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: level.primary,
              ),
            ),
          ],
        );
      case _CardState.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: level.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '▶  Em Andamento',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      case _CardState.locked:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF6B7280)),
            SizedBox(width: 4),
            Text(
              'Bloqueado',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final _VowelLevel level;
  const _ProgressBar({required this.level});

  @override
  Widget build(BuildContext context) {
    final pct = level.progress / level.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: level.primary.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(level.primary),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${level.progress} de ${level.total} lições',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: level.dark.withOpacity(0.60),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT ICON
// ─────────────────────────────────────────────────────────────────────────────

class _RightIcon extends StatelessWidget {
  final _VowelLevel level;
  const _RightIcon({required this.level});

  @override
  Widget build(BuildContext context) {
    final isActive = level.state == _CardState.active;
    final isLocked = level.state == _CardState.locked;

    if (isLocked) {
      return const SizedBox(width: 32);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(level.emoji, style: const TextStyle(fontSize: 32)),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: level.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: level.primary.withOpacity(0.40),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              '▶ JOGAR',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAY BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            gradient: const LinearGradient(
              colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFF97316),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'JOGAR AGORA',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(
                      color: Color(0x55000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.025, duration: 1400.ms, curve: Curves.easeInOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Início', active: true),
          _NavItem(icon: Icons.flash_on_rounded, label: 'Desafios'),
          _NavItem(icon: Icons.emoji_events_rounded, label: 'Troféus'),
          _NavItem(icon: Icons.person_rounded, label: 'Perfil'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: active
              ? BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Icon(
            icon,
            color: active ? Colors.white : Colors.white38,
            size: 24,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }
}
