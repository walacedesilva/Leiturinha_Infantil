import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../services/gamification_service.dart';
import '../../data/story_models.dart';
import 'story_player_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// REINO DAS HISTÓRIAS — Hub de Histórias Interativas
// ═════════════════════════════════════════════════════════════════════════════

class ReinoHistoriasScreen extends StatefulWidget {
  const ReinoHistoriasScreen({super.key});

  @override
  State<ReinoHistoriasScreen> createState() => _ReinoHistoriasScreenState();
}

class _ReinoHistoriasScreenState extends State<ReinoHistoriasScreen> {
  List<StoryModel>? _stories;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final stories = await StoryModel.loadAll();
      if (mounted) setState(() { _stories = stories; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: Stack(
        children: [
          // ── Gradient background ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A0A2E),
                    Color(0xFF0D1B4A),
                    Color(0xFF0A1628),
                  ],
                ),
              ),
            ),
          ),
          // ── Stars background ──
          Positioned.fill(child: _StarField()),
          // ── Content ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(coins: gam.state.coins),
                const SizedBox(height: 8),
                _Header(),
                const SizedBox(height: 8),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFBBF24)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar as histórias',
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 16, color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () { setState(() { _loading = true; _error = null; }); _loadStories(); },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    final stories = _stories ?? [];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: stories.length,
      itemBuilder: (context, i) => _StoryCard(
        story: stories[i],
        index: i,
        onTap: () => _openStory(stories[i]),
      ).animate(delay: Duration(milliseconds: 80 * i)).fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
    );
  }

  void _openStory(StoryModel story) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoryPlayerScreen(story: story)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int coins;
  const _TopBar({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDE68A),
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
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reino das Histórias',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Histórias interativas para explorar',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STORY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _StoryCard extends StatelessWidget {
  final StoryModel story;
  final int index;
  final VoidCallback onTap;

  const _StoryCard({
    required this.story,
    required this.index,
    required this.onTap,
  });

  static const _gradients = [
    [Color(0xFFF97316), Color(0xFFD97706)], // safari — laranja/dourado
    [Color(0xFFEC4899), Color(0xFF8B5CF6)], // cozinha — rosa/roxo
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // planetas — azul
    [Color(0xFF14B8A6), Color(0xFF0F766E)], // teatro — ciano/azul-esverdeado
    [Color(0xFF10B981), Color(0xFF047857)], // jardim — verde/esmeralda
    [Color(0xFF8B5CF6), Color(0xFF4F46E5)], // floresta dos sussurros — violeta/indigo
    [Color(0xFF6366F1), Color(0xFFD97706)], // trovão amigo — indigo/âmbar
  ];

  static const _emojis = ['🦁', '👨‍🍳', '🚀', '🎭', '🌸', '🌳', '🌩️'];

  Color get _topColor => _gradients[index % _gradients.length][0];
  Color get _bottomColor => _gradients[index % _gradients.length][1];
  String get _emoji => _emojis[index % _emojis.length];

  @override
  Widget build(BuildContext context) {
    final meta = story.metadata;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _topColor.withOpacity(0.25),
              _bottomColor.withOpacity(0.15),
            ],
          ),
          border: Border.all(
            color: _topColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _topColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: _topColor.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Emoji icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_topColor, _bottomColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _topColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(_emoji,
                            style: const TextStyle(fontSize: 34)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.title,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meta.subtitle,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.65),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Chip(
                                label: meta.difficultyLabel,
                                color: _topColor,
                              ),
                              const SizedBox(width: 6),
                              _Chip(
                                label: meta.durationLabel,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 6),
                              _Chip(
                                label: '${story.acts.length} atos',
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _topColor.withOpacity(0.8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color == Colors.white54 ? Colors.white70 : color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAR FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter());
  }
}

class _StarPainter extends CustomPainter {
  static const _stars = <(double, double, double)>[
    (0.08, 0.05, 2.0), (0.25, 0.10, 1.5), (0.55, 0.03, 2.5),
    (0.75, 0.08, 1.8), (0.90, 0.12, 1.2), (0.15, 0.18, 1.6),
    (0.40, 0.20, 2.2), (0.65, 0.15, 1.4), (0.85, 0.22, 2.0),
    (0.05, 0.30, 1.3), (0.35, 0.35, 1.8), (0.70, 0.32, 2.1),
    (0.95, 0.28, 1.5), (0.20, 0.42, 1.7), (0.50, 0.45, 1.2),
    (0.80, 0.40, 2.3), (0.12, 0.55, 1.9), (0.45, 0.58, 1.4),
    (0.75, 0.52, 1.6), (0.30, 0.65, 2.0), (0.60, 0.68, 1.3),
    (0.88, 0.60, 1.8), (0.05, 0.72, 1.5), (0.42, 0.75, 2.2),
    (0.70, 0.78, 1.7), (0.22, 0.85, 1.4), (0.55, 0.88, 1.9),
    (0.85, 0.82, 1.2), (0.10, 0.92, 2.0), (0.48, 0.95, 1.6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.55);
    for (final (fx, fy, r) in _stars) {
      canvas.drawCircle(Offset(fx * size.width, fy * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}
