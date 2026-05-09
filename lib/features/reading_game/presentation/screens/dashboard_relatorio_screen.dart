import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../../services/report_service.dart';
import '../../../../services/session_tracking_service.dart';
import '../../data/word_bank.dart';
import 'pdf_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────────────────────────────────────────

// spec colors
const _kBg = Color(0xFFEFF6FF);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF3B82F6);
const _kGreen = Color(0xFF22C55E);
const _kText = Color(0xFF1E2A38);
const _kSubtext = Color(0xFF6B7280);

// ─────────────────────────────────────────────────────────────────────────────
// VIEW MODE
// ─────────────────────────────────────────────────────────────────────────────

enum _ViewMode { pais, professor }

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DashboardRelatorioScreen extends StatefulWidget {
  /// Nome da criança exibido no cabeçalho.
  final String childName;

  const DashboardRelatorioScreen({
    super.key,
    this.childName = 'do Aluno',
  });

  @override
  State<DashboardRelatorioScreen> createState() =>
      _DashboardRelatorioScreenState();
}

class _DashboardRelatorioScreenState extends State<DashboardRelatorioScreen> {
  _ViewMode _mode = _ViewMode.pais;
  late DateTime _weekStart;
  WeeklyReport? _report;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: (now.weekday - 1) % 7));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshReport();
  }

  void _refreshReport() {
    final report = ReportService(
      sessions: context.read<SessionTrackingService>(),
      progress: context.read<ProgressService>(),
      gamification: context.read<GamificationService>(),
    ).generateForWeek(_weekStart);
    setState(() => _report = report);
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    _refreshReport();
  }

  void _nextWeek() {
    final next = _weekStart.add(const Duration(days: 7));
    if (next.isBefore(DateTime.now())) {
      setState(() => _weekStart = next);
      _refreshReport();
    }
  }

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: (now.weekday - 1) % 7));
    final cur = DateTime(monday.year, monday.month, monday.day);
    return _weekStart == cur;
  }

  // ── Export ─────────────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    final r = _report;
    if (r == null) return;
    setState(() => _exporting = true);
    try {
      final file = await PdfExportService.generate(r);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Relatório de Progresso — Leiturinha',
        text: 'Relatório semanal de alfabetização fonética 📊',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _shareWhatsapp() async {
    final r = _report;
    if (r == null) return;
    final lines = [
      '📊 *Relatório Leiturinha — ${r.formattedPeriod}*',
      '',
      '• ${r.sessionsCount} sessões realizadas',
      '• ${(r.overallAccuracy * 100).toStringAsFixed(0)}% de acerto',
      '• ${r.wordsWorked} palavras praticadas',
      '• ${r.newSyllablesMastered} sílabas trabalhadas',
      '',
      if (r.recommendations.isNotEmpty) '💡 ${r.recommendations.first.text}',
    ];
    await Share.share(lines.join('\n'));
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_outlined,
                color: _kBlue, size: 22),
            SizedBox(width: 8),
            Text(
              'Configurar Alertas',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Em breve você poderá configurar lembretes diários e notificações '
          'de progresso para acompanhar a evolução da criança.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Entendido',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: _kBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = _report;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            _TopBar(
              childName: widget.childName,
              weekStart: _weekStart,
              mode: _mode,
              isCurrentWeek: _isCurrentWeek,
              onPrev: _prevWeek,
              onNext: _isCurrentWeek ? null : _nextWeek,
              onModeChanged: (m) => setState(() => _mode = m),
              onBack: () => Navigator.of(context).pop(),
            ),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: r == null
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async => _refreshReport(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Metric tiles ─────────────────────────────
                            _MetricGrid(report: r)
                                .animate()
                                .fadeIn(duration: 350.ms)
                                .slideY(begin: -0.1, duration: 350.ms),

                            const SizedBox(height: 14),

                            // ── Line chart ────────────────────────────────
                            _WeeklyLineChartCard(report: r)
                                .animate(delay: 80.ms)
                                .fadeIn(duration: 350.ms)
                                .slideY(begin: 0.1, duration: 350.ms),

                            const SizedBox(height: 14),

                            // ── Famílias silábicas ────────────────────────
                            _FamilyBarsCard(report: r)
                                .animate(delay: 160.ms)
                                .fadeIn(duration: 350.ms)
                                .slideY(begin: 0.1, duration: 350.ms),

                            // ── Professor extras ──────────────────────────
                            if (_mode == _ViewMode.professor) ...[
                              const SizedBox(height: 14),
                              _ProfessorExtrasCard(report: r)
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.2, duration: 400.ms),
                            ],

                            const SizedBox(height: 14),

                            // ── Tip + action buttons ──────────────────────
                            _TipAndActionsCard(
                              report: r,
                              exporting: _exporting,
                              onPdf: _exportPdf,
                              onWhatsapp: _shareWhatsapp,
                              onAlerts: _showAlertsDialog,
                            )
                                .animate(delay: 240.ms)
                                .fadeIn(duration: 350.ms),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String childName;
  final DateTime weekStart;
  final _ViewMode mode;
  final bool isCurrentWeek;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final ValueChanged<_ViewMode> onModeChanged;
  final VoidCallback onBack;

  const _TopBar({
    required this.childName,
    required this.weekStart,
    required this.mode,
    required this.isCurrentWeek,
    required this.onPrev,
    required this.onNext,
    required this.onModeChanged,
    required this.onBack,
  });

  String _fmtDate(DateTime d) => DateFormat('dd/MMM', 'pt_BR').format(d);

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateLabel = '${_fmtDate(weekStart)} – ${_fmtDate(weekEnd)}';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: back + title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: _kText),
                onPressed: onBack,
              ),
              const Text(
                '📊',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Progresso $childName',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: _kText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Row 2: week nav + toggle
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 0),
            child: Row(
              children: [
                // ← week arrow
                _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: onPrev,
                ),

                // Date label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: _kBlue),
                      const SizedBox(width: 4),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                // → week arrow
                _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: isCurrentWeek ? null : onNext,
                  disabled: isCurrentWeek,
                ),

                const Spacer(),

                // Toggle Pais / Professor
                _ModeToggle(
                  mode: mode,
                  onChanged: onModeChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _NavArrow({
    required this.icon,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          icon,
          size: 24,
          color: disabled ? Colors.grey.shade300 : _kBlue,
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'Pais',
            icon: Icons.family_restroom_rounded,
            active: mode == _ViewMode.pais,
            onTap: () => onChanged(_ViewMode.pais),
          ),
          _ToggleChip(
            label: 'Professor',
            icon: Icons.school_rounded,
            active: mode == _ViewMode.professor,
            onTap: () => onChanged(_ViewMode.professor),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? Colors.white : _kSubtext),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : _kSubtext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED CARD SHELL
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METRIC TILES  (2 × 2 grid)
// ─────────────────────────────────────────────────────────────────────────────

class _MetricGrid extends StatelessWidget {
  final WeeklyReport report;
  const _MetricGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    final pct = report.overallAccuracy;
    final delta = report.accuracyDelta;

    final tiles = [
      _MetricData(
        value: '${report.sessionsCount}',
        label: 'sessões',
        icon: Icons.play_circle_outline_rounded,
      ),
      _MetricData(
        value: '${(pct * 100).toStringAsFixed(0)}%',
        label: 'acerto',
        sub: delta == 0
            ? null
            : delta > 0
                ? '▲ ${(delta * 100).toStringAsFixed(0)}%'
                : '▼ ${(delta.abs() * 100).toStringAsFixed(0)}%',
        subColor: delta >= 0 ? _kGreen : Colors.redAccent,
        icon: Icons.track_changes_rounded,
      ),
      _MetricData(
        value: '${report.newSyllablesMastered}',
        label: 'sílabas novas',
        icon: Icons.text_fields_rounded,
      ),
      _MetricData(
        value: '${report.wordsWorked}',
        label: 'palavras',
        icon: Icons.auto_stories_rounded,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: tiles
          .asMap()
          .entries
          .map((e) => _MetricTile(data: e.value, delay: e.key * 60))
          .toList(),
    );
  }
}

class _MetricData {
  final String value;
  final String label;
  final String? sub;
  final Color? subColor;
  final IconData icon;

  const _MetricData({
    required this.value,
    required this.label,
    required this.icon,
    this.sub,
    this.subColor,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricData data;
  final int delay;
  const _MetricTile({required this.data, required this.delay});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
      // Green check circle — spec: #DCFCE7 bg, #22C55E icon 32px
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF22C55E), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: _kText,
                        height: 1.1,
                      ),
                    ),
                    if (data.sub != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        data.sub!,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: data.subColor ?? _kGreen,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  data.label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: _kSubtext,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY LINE CHART
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyLineChartCard extends StatelessWidget {
  final WeeklyReport report;
  const _WeeklyLineChartCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final chart = report.dailyChart;

    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evolução da semana',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: _kText,
            ),
          ),
          const SizedBox(height: 12),
          if (chart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Sem sessões registradas nesta semana.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: _kSubtext,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: _LineChartPainterWidget(data: chart),
            ),
        ],
      ),
    );
  }
}

class _LineChartPainterWidget extends StatelessWidget {
  final List<DailyAccuracy> data;
  const _LineChartPainterWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(data: data),
      size: const Size(double.infinity, 160),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<DailyAccuracy> data;
  static const _kDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  const _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 22.0;
    const dotR = 5.5;
    const padLeft = 32.0;
    const padRight = 10.0;

    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - labelH - 10;
    final topY = 10.0;

    // Grid lines at 25%, 50%, 75%, 100%
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    final gridLabelStyle = const TextStyle(
      fontFamily: 'Nunito',
      fontSize: 10,
      color: _kSubtext,
    );

    for (final pct in [0.25, 0.5, 0.75, 1.0]) {
      final y = topY + chartH * (1 - pct);
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(padLeft + chartW, y),
        gridPaint,
      );
      // Y label
      final tp = TextPainter(
        text: TextSpan(
          text: '${(pct * 100).toInt()}%',
          style: gridLabelStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Map dayLabel → x position (evenly spaced across full width including
    // days with no data, so that the axis is consistent)
    final slotCount = _kDays.length; // 7 slots
    double xForSlot(int i) =>
        padLeft + (i / (slotCount - 1)) * chartW;

    // Build ordered point list (may have gaps for missing days)
    final points = <Offset?>[];
    for (final day in _kDays) {
      final match = data.where((d) => d.dayLabel == day);
      if (match.isEmpty) {
        points.add(null);
      } else {
        final acc = match.first.accuracy.clamp(0.0, 1.0);
        final x = xForSlot(_kDays.indexOf(day));
        final y = topY + chartH * (1 - acc);
        points.add(Offset(x, y));
      }
    }

    // Collect non-null runs and draw each as a separate smooth path
    final linePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _kBlue.withOpacity(0.18),
          _kBlue.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(
          padLeft, topY, chartW, chartH));

    // Split into continuous runs
    final runs = <List<Offset>>[];
    List<Offset>? current;
    for (final p in points) {
      if (p != null) {
        current ??= [];
        current.add(p);
      } else if (current != null) {
        runs.add(current);
        current = null;
      }
    }
    if (current != null) runs.add(current);

    for (final run in runs) {
      if (run.isEmpty) continue;
      if (run.length == 1) {
        // Single dot — draw separately
        canvas.drawCircle(run[0], dotR, Paint()..color = _kBlue);
        continue;
      }

      // Build catmull-rom smooth path
      final path = _catmullRomPath(run);

      // Fill
      final fillPath = Path.from(path)
        ..lineTo(run.last.dx, topY + chartH)
        ..lineTo(run.first.dx, topY + chartH)
        ..close();
      canvas.drawPath(fillPath, fillPaint);

      // Line
      canvas.drawPath(path, linePaint);

      // Dots + accuracy labels
      final dotPaint = Paint()
        ..color = _kBlue
        ..style = PaintingStyle.fill;
      final dotOutline = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      for (final p in run) {
        canvas.drawCircle(p, dotR + 1.5, dotOutline);
        canvas.drawCircle(p, dotR, dotPaint);

        // Accuracy label above dot
        final idx = points.indexOf(p);
        if (idx >= 0 && idx < data.length) {
          final acc = data
              .where((d) => d.dayLabel == _kDays[idx])
              .map((d) => d.accuracy)
              .firstOrNull;
          if (acc != null) {
            final tp = TextPainter(
              text: TextSpan(
                text: '${(acc * 100).toInt()}%',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _kBlue,
                ),
              ),
              textDirection: ui.TextDirection.ltr,
            )..layout();
            tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - dotR - tp.height - 2));
          }
        }
      }
    }

    // X-axis labels — spec: SemiBold 14px #6B7280
    final labelPaint = const TextStyle(
      fontFamily: 'Nunito',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF6B7280),
    );
    for (var i = 0; i < _kDays.length; i++) {
      final hasData = points[i] != null;
      final style = hasData
          ? const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            )
          : labelPaint;
      final tp = TextPainter(
        text: TextSpan(text: _kDays[i], style: style),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(xForSlot(i) - tp.width / 2, topY + chartH + 6),
      );
    }
  }

  /// Catmull-Rom spline converted to cubic bezier segments.
  Path _catmullRomPath(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    if (pts.length < 2) return path;

    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[0];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : pts[pts.length - 1];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6.0,
        p1.dy + (p2.dy - p0.dy) / 6.0,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6.0,
        p2.dy - (p3.dy - p1.dy) / 6.0,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.data != data;
}

// ─────────────────────────────────────────────────────────────────────────────
// FAMILY PROGRESS BARS
// ─────────────────────────────────────────────────────────────────────────────

class _FamilyBarsCard extends StatelessWidget {
  final WeeklyReport report;
  const _FamilyBarsCard({required this.report});

  Color _familyColor(String key) {
    try {
      return Color(
          WordBank.families.firstWhere((f) => f.key == key).colorValue);
    } catch (_) {
      return _kBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final families = report.families;

    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Famílias Silábicas',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: _kText,
            ),
          ),
          const SizedBox(height: 14),
          if (families.isEmpty)
            const Text(
              'Nenhuma família praticada ainda.',
              style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 13, color: _kSubtext),
            )
          else
            ...families.asMap().entries.map((e) {
              final f = e.value;
              final color = _familyColor(f.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FamilyBar(
                  label: f.label,
                  value: f.completion,
                  color: color,
                  delay: e.key * 80,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _FamilyBar extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final Color color;
  final int delay;

  const _FamilyBar({
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: Duration(milliseconds: 700 + delay),
              curve: Curves.easeOut,
              builder: (_, val, __) {
                return LinearProgressIndicator(
                  value: val,
                  minHeight: 24,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 38,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _kText,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFESSOR EXTRAS (error syllables + engagement)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfessorExtrasCard extends StatelessWidget {
  final WeeklyReport report;
  const _ProfessorExtrasCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          const Row(
            children: [
              Icon(Icons.school_rounded, size: 18, color: _kBlue),
              SizedBox(width: 6),
              Text(
                'Análise Pedagógica',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Engagement metrics ─────────────────────────────────────
          Row(
            children: [
              _EngMetric(
                icon: '🔥',
                label: 'Sequência',
                value: '${report.streak} dia${report.streak == 1 ? "" : "s"}',
              ),
              const SizedBox(width: 12),
              _EngMetric(
                icon: '⏱️',
                label: 'Média sessão',
                value:
                    '${report.avgSessionMinutes.toStringAsFixed(1)} min',
              ),
              const SizedBox(width: 12),
              _EngMetric(
                icon: '🏅',
                label: 'Nível',
                value: '${report.levelEmoji} ${report.levelName}',
              ),
            ],
          ),

          // ── Top error syllables ────────────────────────────────────
          if (report.topErrors.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Sílabas com mais dificuldades',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _kSubtext,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: report.topErrors.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${e.value}×)',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: _kSubtext,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // ── All recommendations ────────────────────────────────────
          if (report.recommendations.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Recomendações',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _kSubtext,
              ),
            ),
            const SizedBox(height: 8),
            ...report.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.emoji,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec.text,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: _kText,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _EngMetric extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _EngMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: _kSubtext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIP + ACTION BUTTONS
// ─────────────────────────────────────────────────────────────────────────────

class _TipAndActionsCard extends StatelessWidget {
  final WeeklyReport report;
  final bool exporting;
  final VoidCallback onPdf;
  final VoidCallback onWhatsapp;
  final VoidCallback onAlerts;

  const _TipAndActionsCard({
    required this.report,
    required this.exporting,
    required this.onPdf,
    required this.onWhatsapp,
    required this.onAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final tip = report.recommendations
        .where((r) => r.isForAdult)
        .map((r) => r.text)
        .firstOrNull;

    return Column(
      children: [
        // ── Dica do dia ─────────────────────────────────────────────────
        if (tip != null)
          // spec: #FEF3C7 bg, #FBBF24 border 2px, lamp #F59E0B, text #92400E
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: const Color(0xFFFBBF24), width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded,
                    size: 20, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: Color(0xFF92400E),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Dica: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: tip),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Action buttons ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Exportar PDF',
                color: const Color(0xFF3B82F6),
                loading: exporting,
                onTap: onPdf,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                icon: Icons.chat_outlined,
                label: 'WhatsApp',
                color: const Color(0xFF22C55E),
                onTap: onWhatsapp,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                icon: Icons.tune_rounded,
                label: 'Alertas',
                color: const Color(0xFF6B7280),
                onTap: onAlerts,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
