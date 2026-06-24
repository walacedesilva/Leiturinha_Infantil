import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// METRO TRANSITION SCREEN
// Tela de transição "metrô" entre hub e distrito. Dura ~2.5s.
// ─────────────────────────────────────────────────────────────────────────────

class MetroTransitionScreen extends StatefulWidget {
  final String districtName;
  final Widget destination;

  const MetroTransitionScreen({
    super.key,
    required this.districtName,
    required this.destination,
  });

  @override
  State<MetroTransitionScreen> createState() => _MetroTransitionScreenState();
}

class _MetroTransitionScreenState extends State<MetroTransitionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Buildings visible through the train window
  static const _buildings = <({
    double x,
    double bottom,
    double width,
    double height,
    Color color,
  })>[
    (x: 40, bottom: 28, width: 38, height: 75, color: Color(0xFF66BB6A)),
    (x: 100, bottom: 18, width: 55, height: 105, color: Color(0xFFEF6C00)),
    (x: 185, bottom: 30, width: 32, height: 68, color: Color(0xFF8E24AA)),
    (x: 245, bottom: 18, width: 50, height: 120, color: Color(0xFF1565C0)),
    (x: 325, bottom: 26, width: 42, height: 82, color: Color(0xFFE53935)),
    (x: 400, bottom: 14, width: 52, height: 138, color: Color(0xFF00897B)),
    (x: 480, bottom: 22, width: 38, height: 88, color: Color(0xFFD81B60)),
    (x: 545, bottom: 18, width: 60, height: 112, color: Color(0xFF5E35B1)),
    (x: 635, bottom: 32, width: 36, height: 72, color: Color(0xFF66BB6A)),
    (x: 695, bottom: 16, width: 55, height: 130, color: Color(0xFFEF6C00)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _navigate();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => widget.destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: Stack(
        children: [
          // ── Gradient background (train interior) ───────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A237E),
                    Color(0xFF283593),
                    Color(0xFF1565C0),
                  ],
                ),
              ),
            ),
          ),
          // ── Moving window ──────────────────────────────────────────────────
          _TrainWindow(controller: _controller, buildings: _buildings),
          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                _BetoSpeech(districtName: widget.districtName),
                const Spacer(),
                _TrackProgress(controller: _controller),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRAIN WINDOW
// ─────────────────────────────────────────────────────────────────────────────

class _TrainWindow extends StatelessWidget {
  final AnimationController controller;
  final List<({double x, double bottom, double width, double height, Color color})>
      buildings;

  const _TrainWindow({required this.controller, required this.buildings});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Positioned(
      top: 80,
      left: 20,
      right: 20,
      height: 180,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF90CAF9).withOpacity(0.5),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF42A5F5).withOpacity(0.20),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            children: [
              // Sky inside window
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF87CEEB),
                      Color(0xFF5BC8F5),
                      Color(0xFF80CBC4),
                    ],
                  ),
                ),
              ),
              // Moving buildings
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final offset = controller.value * (screenWidth + 400);
                  return Stack(
                    children: buildings
                        .map((b) => Positioned(
                              bottom: b.bottom,
                              left: b.x - offset,
                              child: Container(
                                width: b.width,
                                height: b.height,
                                decoration: BoxDecoration(
                                  color: b.color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              // Glass reflection overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white.withOpacity(0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BETO SPEECH BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _BetoSpeech extends StatelessWidget {
  final String districtName;
  const _BetoSpeech({required this.districtName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Beto mascot
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF8D6E63),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Text('🐻', style: TextStyle(fontSize: 36)),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -6,
                duration: 800.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 12),
          // Bubble
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tchuu tchuu! 🚂',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Estamos indo para\n$districtName!',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF37474F),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .slideX(begin: -0.2, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRACK PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TrackProgress extends StatelessWidget {
  final AnimationController controller;
  const _TrackProgress({required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preparando o distrito...',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedBuilder(
                animation: controller,
                builder: (_, __) => Text(
                  '${(controller.value * 100).toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Track-style progress bar
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(7),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: AnimatedBuilder(
                animation: controller,
                builder: (_, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: controller.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFDD835), Color(0xFFFFB300)],
                      ),
                    ),
                    child: _TrackTies(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Locomotive emoji rides along the bar
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final maxX = screenWidth - 64 - 64; // padding both sides
              return Align(
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(controller.value * maxX, 0),
                  child: const Text('🚂', style: TextStyle(fontSize: 22)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrackTies extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 16).floor().clamp(1, 50);
        return Row(
          children: List.generate(
            count,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
