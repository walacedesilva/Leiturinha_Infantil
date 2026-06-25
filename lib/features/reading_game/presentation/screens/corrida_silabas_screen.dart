import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../services/audio_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _Checkpoint {
  final String emoji;
  final String label;
  final bool unlocked;

  const _Checkpoint({
    required this.emoji,
    required this.label,
    required this.unlocked,
  });
}

class _RankEntry {
  final String avatar;
  final String name;
  final int words;
  final bool isPlayer;

  const _RankEntry({
    required this.avatar,
    required this.name,
    required this.words,
    required this.isPlayer,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

// spec colors — cream/warm palette
const Color _kOrange   = Color(0xFFF97316);
const Color _kYellow   = Color(0xFFFBBF24);
const Color _kBg       = Color(0xFFFFFBF0); // cream bg
const Color _kCard     = Colors.white;
const Color _kGreen    = Color(0xFF22C55E);
const Color _kPurple   = Color(0xFFA855F7);
const Color _kTextDark = Color(0xFF1E2A38);
const Color _kSubtext  = Color(0xFF6B7280);

const Duration _kEventDuration = Duration(minutes: 3);

const List<_Checkpoint> _kCheckpoints = [
  _Checkpoint(emoji: '🚩', label: 'Início',   unlocked: true),
  _Checkpoint(emoji: '⭐', label: '1 palavra', unlocked: true),
  _Checkpoint(emoji: '🔥', label: '2 palavras', unlocked: true),
  _Checkpoint(emoji: '🏅', label: '3 palavras', unlocked: false),
  _Checkpoint(emoji: '🏆', label: '5 palavras', unlocked: false),
];

const List<_RankEntry> _kRanking = [
  _RankEntry(avatar: '🦊', name: 'Raposa',  words: 4, isPlayer: false),
  _RankEntry(avatar: '👦', name: 'Você',    words: 2, isPlayer: true),
  _RankEntry(avatar: '🐸', name: 'Sapinho', words: 2, isPlayer: false),
  _RankEntry(avatar: '🐢', name: 'Tartaruga', words: 1, isPlayer: false),
];

const List<Map<String, String>> _kExclusiveRewards = [
  {'emoji': '🏆', 'label': 'Troféu da Corrida', 'qty': '×1'},
  {'emoji': '⚡', 'label': '+50 XP Bônus',       'qty': ''},
  {'emoji': '🎖️', 'label': 'Badge Especial',    'qty': '×1'},
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// Tela 6 — Evento Especial "Corrida das Sílabas"
///
/// Exibe um banner festivo com timer de urgência, faixa de progresso com
/// checkpoints temáticos, missão mensurável, recompensas exclusivas e
/// ranking amigável.
class CorridaSilabasScreen extends StatefulWidget {
  const CorridaSilabasScreen({super.key});

  @override
  State<CorridaSilabasScreen> createState() => _CorridaSilabasScreenState();
}

class _CorridaSilabasScreenState extends State<CorridaSilabasScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flagCtrl;
  late final AnimationController _pulseCtrl;

  // Timer countdown — starts at 3 min (demo)
  late Duration _remaining;
  Timer? _ticker;

  // Player progress in the mission (out of 5 words target)
  int _wordsCompleted = 2;
  static const int _wordsTarget = 5;

  @override
  void initState() {
    super.initState();
    AudioManager().playMusic('jogo');

    _remaining = _kEventDuration;

    _flagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _flagCtrl.dispose();
    _pulseCtrl.dispose();
    _ticker?.cancel();
    AudioManager().playMusic('mapa');
    super.dispose();
  }

  String get _timerLabel {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isUrgent => _remaining.inSeconds <= 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            _TopBar(onBack: () => Navigator.of(context).maybePop()),
            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    // Festival banner + timer
                    _FestivalBanner(
                      timerLabel: _timerLabel,
                      isUrgent: _isUrgent,
                      pulseCtrl: _pulseCtrl,
                    ),
                    const SizedBox(height: 16),
                    // Progress track with checkpoints
                    _ProgressTrack(
                      completed: _wordsCompleted,
                      target: _wordsTarget,
                      checkpoints: _kCheckpoints,
                      flagCtrl: _flagCtrl,
                    ),
                    const SizedBox(height: 16),
                    // Mission card
                    _MissionCard(
                      completed: _wordsCompleted,
                      target: _wordsTarget,
                      timerLabel: _timerLabel,
                      isUrgent: _isUrgent,
                    ),
                    const SizedBox(height: 16),
                    // Exclusive rewards
                    _ExclusiveRewardsCard(rewards: _kExclusiveRewards),
                    const SizedBox(height: 16),
                    // Ranking
                    _RankingCard(entries: _kRanking),
                    const SizedBox(height: 20),
                    // CTA
                    _CtaButton(onTap: _onPlayTap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPlayTap() {
    // In production: push the pronunciation challenge pre-configured for
    // event mode (shorter words, higher XP multiplier).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🏁 Vamos lá! Boa corrida!'),
        backgroundColor: _kGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF374151), size: 22),
          ),
          const Expanded(
            child: Text(
              'Corrida das Sílabas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ),
          // Spacer to balance back button
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FESTIVAL BANNER + TIMER
// ─────────────────────────────────────────────────────────────────────────────

class _FestivalBanner extends StatelessWidget {
  final String timerLabel;
  final bool isUrgent;
  final AnimationController pulseCtrl;

  const _FestivalBanner({
    required this.timerLabel,
    required this.isUrgent,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6D00), Color(0xFFFFAB40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withOpacity(0.55),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // ── Firework row ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('🎉', style: TextStyle(fontSize: 28)),
              SizedBox(width: 6),
              Text(
                'EVENTO ESPECIAL',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(width: 6),
              Text('🎉', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          // ── Event name ────────────────────────────────────────────────
          const Text(
            '🏁 Corrida das Sílabas',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // ── Timer chip ────────────────────────────────────────────────
          _TimerChip(
            label: timerLabel,
            isUrgent: isUrgent,
            pulseCtrl: pulseCtrl,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.12, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _TimerChip extends StatelessWidget {
  final String label;
  final bool isUrgent;
  final AnimationController pulseCtrl;

  const _TimerChip({
    required this.label,
    required this.isUrgent,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    // spec: circular 96×96, bg #FEF3C7, border 4px #F59E0B, clock icon 32px
    final bg = isUrgent ? const Color(0xFFEF4444) : const Color(0xFFFEF3C7);
    final borderColor =
        isUrgent ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
    final textColor =
        isUrgent ? Colors.white : const Color(0xFF92400E);

    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) {
        final scale = isUrgent ? 1.0 + pulseCtrl.value * 0.06 : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 4),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.40),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_rounded,
                size: 32, color: borderColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS TRACK WITH CHECKPOINTS
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressTrack extends StatelessWidget {
  final int completed;
  final int target;
  final List<_Checkpoint> checkpoints;
  final AnimationController flagCtrl;

  const _ProgressTrack({
    required this.completed,
    required this.target,
    required this.checkpoints,
    required this.flagCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sua Corrida',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: 0, end: completed / target.clamp(1, 9999)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 14,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation(_kYellow),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Checkpoints
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: checkpoints.asMap().entries.map((e) {
              final idx = e.key;
              final cp  = e.value;
              final isLast = idx == checkpoints.length - 1;
              return _CheckpointDot(
                checkpoint: cp,
                flagCtrl: flagCtrl,
                isFinish: isLast,
              );
            }).toList(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _CheckpointDot extends StatelessWidget {
  final _Checkpoint checkpoint;
  final AnimationController flagCtrl;
  final bool isFinish;

  const _CheckpointDot({
    required this.checkpoint,
    required this.flagCtrl,
    required this.isFinish,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = checkpoint.unlocked;
    final dotColor = unlocked ? _kGreen : const Color(0xFFE5E7EB);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: unlocked ? _kGreen : const Color(0xFFD1D5DB),
                  width: 2.5,
                ),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: _kGreen.withOpacity(0.4),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            ),
            Text(
              checkpoint.emoji,
              style: TextStyle(
                fontSize: 20,
                color: unlocked ? _kTextDark : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 58,
          child: Text(
            checkpoint.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: unlocked ? _kTextDark : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MISSION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final int completed;
  final int target;
  final String timerLabel;
  final bool isUrgent;

  const _MissionCard({
    required this.completed,
    required this.target,
    required this.timerLabel,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (target - completed).clamp(0, target);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Text('🎯', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text(
                'Missão do Evento',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Objective row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Word counter bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completed / $target',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B3F00),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'palavras lidas',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        remaining > 0
                            ? 'Faltam $remaining palavra${remaining > 1 ? "s" : ""}!'
                            : '✅ Missão completa!',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: remaining == 0
                              ? _kGreen
                              : _kSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Timer row
          Row(
            children: [
              const Text('⏱️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Tempo restante: $timerLabel',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isUrgent
                      ? const Color(0xFFEF4444)
                      : _kSubtext,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXCLUSIVE REWARDS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ExclusiveRewardsCard extends StatelessWidget {
  final List<Map<String, String>> rewards;

  const _ExclusiveRewardsCard({required this.rewards});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🎁', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text(
                'Recompensas Exclusivas',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Só disponíveis durante o evento!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: _kSubtext,
            ),
          ),
          const SizedBox(height: 12),
          ...rewards.asMap().entries.map((e) {
            final idx = e.key;
            final r   = e.value;
            return _RewardRow(reward: r, delay: Duration(milliseconds: 80 * idx));
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _RewardRow extends StatelessWidget {
  final Map<String, String> reward;
  final Duration delay;

  const _RewardRow({required this.reward, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                reward['emoji']!,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reward['label']!,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _kTextDark,
              ),
            ),
          ),
          if (reward['qty']!.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kYellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                reward['qty']!,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B3F00),
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay + 300.ms, duration: 350.ms)
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          duration: 350.ms,
          curve: Curves.elasticOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RANKING CARD
// ─────────────────────────────────────────────────────────────────────────────

class _RankingCard extends StatelessWidget {
  final List<_RankEntry> entries;

  const _RankingCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final sorted = List<_RankEntry>.from(entries)
      ..sort((a, b) => b.words.compareTo(a.words));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🤝', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text(
                'Amigos na Corrida',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Divirta-se junto, cada um no seu ritmo! 😊',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: _kSubtext,
            ),
          ),
          const SizedBox(height: 14),
          ...sorted.asMap().entries.map((e) {
            return _RankRow(
              rank: e.key + 1,
              entry: e.value,
              maxWords: sorted.first.words,
              delay: Duration(milliseconds: 60 * e.key),
            );
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final _RankEntry entry;
  final int maxWords;
  final Duration delay;

  const _RankRow({
    required this.rank,
    required this.entry,
    required this.maxWords,
    required this.delay,
  });

  Color get _rankColor {
    if (rank == 1) return _kYellow;
    if (rank == 2) return const Color(0xFFB0BEC5);
    if (rank == 3) return const Color(0xFFFF8A65);
    return const Color(0xFF9CA3AF);
  }

  String get _rankEmoji {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    final isPlayer = entry.isPlayer;
    final barFrac = maxWords == 0 ? 0.0 : entry.words / maxWords;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isPlayer
            ? const Color(0xFFF5F3FF) // light purple tint
            : const Color(0xFFF9FAFB), // near white
        borderRadius: BorderRadius.circular(14),
        border: isPlayer
            ? Border.all(color: _kPurple, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 28,
            child: Text(
              _rankEmoji,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: rank <= 3 ? 20 : 14,
                fontWeight: FontWeight.bold,
                color: _rankColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar bubble
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(entry.avatar,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          // Name + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: isPlayer
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _kTextDark,
                      ),
                    ),
                    if (isPlayer) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _kPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Você',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: barFrac),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation(
                          isPlayer ? _kPurple : _kYellow),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Word count chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.words} pal.',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay + 400.ms, duration: 350.ms)
        .slideX(
          begin: 0.08,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CtaButton({required this.onTap});

  @override
  Widget build(BuildContext context) => _ActionBtn(onTap: onTap);
}

class _ActionBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ActionBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x66F59E0B),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('☀️', style: TextStyle(fontSize: 36)),
              SizedBox(height: 4),
              Text(
                'INICIAR\nDESAFIO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF92400E),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.06,
            duration: 900.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;

  const _Card({required this.child, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? _kCard : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
