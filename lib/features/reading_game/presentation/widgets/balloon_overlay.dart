import 'dart:math';
import 'package:flutter/material.dart';

class BalloonOverlay extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const BalloonOverlay({Key? key, required this.onAnimationComplete}) : super(key: key);

  @override
  _BalloonOverlayState createState() => _BalloonOverlayState();
}

class _BalloonOverlayState extends State<BalloonOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Balloon> _balloons = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _controller.addListener(() {
      setState(() {});
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });

    // Initialize balloons
    for (int i = 0; i < 12; i++) {
      _balloons.add(_Balloon(
        xOffset: _random.nextDouble(),
        yOffset: _random.nextDouble(),
        speed: 0.5 + _random.nextDouble() * 0.5,
        color: _getRandomColor(),
        size: 50 + _random.nextDouble() * 50,
      ));
    }

    _controller.forward();
  }

  Color _getRandomColor() {
    List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _balloons.map((balloon) {
          // Calculate current Y position based on animation progress
          // Start from bottom (1.0 + size offset) to top (-0.2)
          double startY = 1.2;
          double endY = -0.2;
          double currentY = startY - ((startY - endY) * _controller.value * balloon.speed);

          return Positioned(
            left: MediaQuery.of(context).size.width * balloon.xOffset,
            top: MediaQuery.of(context).size.height * currentY,
            child: _buildBalloonIcon(balloon.color, balloon.size),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBalloonIcon(Color color, double size) {
    return Container(
      width: size,
      height: size * 1.2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.elliptical(size / 2, size * 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Shine effect
          Positioned(
            top: size * 0.1,
            left: size * 0.1,
            child: Container(
              width: size * 0.3,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.elliptical(size * 0.15, size * 0.25)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Balloon {
  final double xOffset;
  final double yOffset;
  final double speed;
  final Color color;
  final double size;

  _Balloon({
    required this.xOffset,
    required this.yOffset,
    required this.speed,
    required this.color,
    required this.size,
  });
}
