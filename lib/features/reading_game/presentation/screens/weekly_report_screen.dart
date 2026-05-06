import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../services/gamification_models.dart';
import '../../../../services/gamification_service.dart';
import '../../../../services/progress_service.dart';
import '../../../../services/report_service.dart';
import '../../../../services/session_tracking_service.dart';
import 'pdf_export_service.dart';

/// Tela de relatório semanal para pais e educadores.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  late WeeklyReport _report;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _report = _buildReport(context);
  }

  WeeklyReport _buildReport(BuildContext context) {
    return ReportService(
      sessions: context.read<SessionTrackingService>(),
      progress: context.read<ProgressService>(),
      gamification: context.read<GamificationService>(),
    ).generateCurrentWeek();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EXPORT PDF + SHARE
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final file = await PdfExportService.generate(_report);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Relatório de Progresso - Leiturinha',
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

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
        title: const Text(
          'Relatório Semanal',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          _exporting
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Exportar PDF',
                  onPressed: _exportPdf,
                ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _report = _buildReport(context));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(report: _report),
              const SizedBox(height: 16),
              _SummaryCard(report: _report),
              const SizedBox(height: 16),
              _AccuracyChart(report: _report),
              const SizedBox(height: 16),
              _FamiliesCard(report: _report),
              const SizedBox(height: 16),
              _ErrorsCard(report: _report),
              const SizedBox(height: 16),
              _EngagementCard(report: _report),
              const SizedBox(height: 16),
              _RecommendationsCard(report: _report),
              const SizedBox(height: 24),
              _ExportButton(
                loading: _exporting,
                onExport: _exportPdf,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARDS INTERNOS
// ─────────────────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Widget child;
  final Color? headerColor;
  final Widget? header;

  const _ReportCard({required this.child, this.headerColor, this.header});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: headerColor ?? const Color(0xFF2979FF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: header!,
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Cabeçalho ────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final WeeklyReport report;
  const _HeaderCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      headerColor: const Color(0xFF2979FF),
      header: const Text(
        '📊 RELATÓRIO DE PROGRESSO - ALFABETIZAÇÃO FONÉTICA',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('📅 Período:', report.formattedPeriod),
          const SizedBox(height: 4),
          _infoRow('🕐 Gerado em:', report.formattedGeneratedAt),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Colors.black87),
            children: [
              TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value),
            ],
          ),
        ),
      );
}

// ── Resumo ────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final WeeklyReport report;
  const _SummaryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final delta = report.accuracyDelta;
    final deltaStr = delta >= 0
        ? '+${(delta * 100).toStringAsFixed(0)}%'
        : '${(delta * 100).toStringAsFixed(0)}%';

    return _ReportCard(
      header: const Text(
        '🌟 RESUMO DA SEMANA',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: '✅',
            text:
                'Sessões realizadas: ${report.sessionsCount} de 7 dias',
          ),
          _SummaryRow(
            icon: '✅',
            text:
                'Tempo médio por sessão: ${report.avgSessionMinutes.toStringAsFixed(0)} min',
          ),
          _SummaryRow(
            icon: '✅',
            text: 'Palavras trabalhadas: ${report.wordsWorked}',
          ),
          _SummaryRow(
            icon: '✅',
            text:
                'Taxa de acerto geral: ${(report.overallAccuracy * 100).toStringAsFixed(0)}% $deltaStr',
            highlight: delta >= 0,
          ),
          _SummaryRow(
            icon: '✅',
            text:
                'Sílabas dominadas: ${report.newSyllablesMastered}',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String icon;
  final String text;
  final bool highlight;

  const _SummaryRow({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: highlight ? const Color(0xFF2E7D32) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gráfico de acurácia diária ────────────────────────────────────────────────

class _AccuracyChart extends StatelessWidget {
  final WeeklyReport report;
  const _AccuracyChart({required this.report});

  @override
  Widget build(BuildContext context) {
    final chart = report.dailyChart;
    if (chart.isEmpty) {
      return _ReportCard(
        header: const Text(
          '📈 EVOLUÇÃO FONÉTICA',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Ainda sem sessões esta semana.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return _ReportCard(
      header: const Text(
        '📈 EVOLUÇÃO FONÉTICA',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      child: Column(
        children: chart.map((d) {
          final pct = d.accuracy.clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    d.dayLabel,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF42A5F5),
                                pct >= 0.85
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF29B6F6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Famílias silábicas ────────────────────────────────────────────────────────

class _FamiliesCard extends StatelessWidget {
  final WeeklyReport report;
  const _FamiliesCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      header: const Text(
        '🔤 FAMÍLIAS SILÁBICAS TRABALHADAS',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      child: Column(
        children: report.families.map((f) => _FamilyRow(data: f)).toList(),
      ),
    );
  }
}

class _FamilyRow extends StatelessWidget {
  final ReportFamilyData data;
  const _FamilyRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = data.completion.clamp(0.0, 1.0);
    final statusLabel = switch (data.status) {
      FamilyStatus.dominada     => 'DOMINADA ✅',
      FamilyStatus.emProgresso  => 'EM PROGRESSO 🔄',
      FamilyStatus.iniciando    => 'INICIANDO 🌱',
      FamilyStatus.naoPraticada => 'NÃO PRATICADA ⬜',
    };
    final statusColor = switch (data.status) {
      FamilyStatus.dominada     => const Color(0xFF2E7D32),
      FamilyStatus.emProgresso  => const Color(0xFF1565C0),
      FamilyStatus.iniciando    => const Color(0xFFF57F17),
      FamilyStatus.naoPraticada => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 4),
          // Sílabas dominadas
          if (data.masteredSyllables.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              children: [
                ...data.masteredSyllables.map(
                  (s) => _SylChip(label: s, done: true),
                ),
                ...data.pendingSyllables.map(
                  (s) => _SylChip(label: s, done: false),
                ),
              ],
            ),
          ],
          // Foco recomendado
          if (data.focusRecommendation != null) ...[
            const SizedBox(height: 4),
            Text(
              '💡 ${data.focusRecommendation}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SylChip extends StatelessWidget {
  final String label;
  final bool done;
  const _SylChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFFE8F5E9)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done ? const Color(0xFF81C784) : Colors.grey.shade300,
        ),
      ),
      child: Text(
        '${done ? "✓" : "▢"} $label',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: done ? const Color(0xFF2E7D32) : Colors.grey.shade600,
        ),
      ),
    );
  }
}

// ── Erros mais frequentes ────────────────────────────────────────────────────

class _ErrorsCard extends StatelessWidget {
  final WeeklyReport report;
  const _ErrorsCard({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report.topErrors.isEmpty) return const SizedBox.shrink();
    return _ReportCard(
      header: const Text(
        '🗣️ SÍLABAS COM MAIS DESAFIOS',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sílabas que geraram mais tentativas (oportunidades de aprendizado!):',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          ...report.topErrors.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      e.key,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (e.value /
                                (report.topErrors.first.value + 1))
                            .clamp(0.1, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.orange.shade50,
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFFFFA726)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${e.value}×',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

// ── Engajamento/Gamificação ───────────────────────────────────────────────────

class _EngagementCard extends StatelessWidget {
  final WeeklyReport report;
  const _EngagementCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final badges = report.weekBadgeIds
        .map((id) => getBadgeById(id))
        .whereType<GameBadge>()
        .toList();

    return _ReportCard(
      headerColor: const Color(0xFF7B1FA2),
      header: const Text(
        '🎮 ENGAJAMENTO E MOTIVAÇÃO',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                report.levelEmoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.levelName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${report.xp} XP  •  🪙 ${report.coins} moedas  •  🔥 ${report.streak} dias',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Conquistas desbloqueadas:',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges
                  .take(6)
                  .map((b) => _BadgeChip(badge: b))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final GameBadge badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            badge.name,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recomendações ─────────────────────────────────────────────────────────────

class _RecommendationsCard extends StatelessWidget {
  final WeeklyReport report;
  const _RecommendationsCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final forAdults = report.recommendations.where((r) => r.isForAdult).toList();
    final forKids = report.recommendations.where((r) => !r.isForAdult).toList();

    return _ReportCard(
      headerColor: const Color(0xFF00897B),
      header: const Text(
        '💡 RECOMENDAÇÕES PERSONALIZADAS',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (forAdults.isNotEmpty) ...[
            const Text(
              'Para pais e educadores:',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 8),
            ...forAdults.map((r) => _RecRow(rec: r)),
          ],
          if (forKids.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Para a criança:',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 8),
            ...forKids.map((r) => _RecRow(rec: r)),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '🔒 Dados protegidos conforme LGPD. O áudio bruto é descartado após o processamento. Apenas métricas pedagógicas são armazenadas localmente no dispositivo.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                color: Color(0xFF004D40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecRow extends StatelessWidget {
  final ReportRecommendation rec;
  const _RecRow({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rec.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rec.text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botão exportar ────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onExport;
  const _ExportButton({required this.loading, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onExport,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2979FF),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(
        loading ? 'Gerando PDF…' : 'Exportar / Compartilhar PDF',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
