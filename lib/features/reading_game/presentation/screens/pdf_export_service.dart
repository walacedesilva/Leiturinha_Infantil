import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../services/gamification_models.dart';
import '../../../../services/report_service.dart';

/// Gera um PDF do relatório semanal e salva no diretório temporário.
class PdfExportService {
  static Future<File> generate(WeeklyReport report) async {
    final pdf = pw.Document();

    // Carrega fonte Nunito como fallback (usa a padrão se não disponível)
    pw.Font? font;
    try {
      final fontData =
          await rootBundle.load('assets/fonts/Nunito-Regular.ttf');
      font = pw.Font.ttf(fontData);
    } catch (e) {
      debugPrint('PDF: falha ao carregar Nunito-Regular, usando fonte padrão: $e');
    }

    pw.Font? fontBold;
    try {
      final fontData = await rootBundle.load('assets/fonts/Nunito-Bold.ttf');
      fontBold = pw.Font.ttf(fontData);
    } catch (e) {
      debugPrint('PDF: falha ao carregar Nunito-Bold, usando fonte padrão: $e');
    }

    final baseStyle = pw.TextStyle(font: font, fontSize: 11);
    final boldStyle =
        pw.TextStyle(font: fontBold ?? font, fontWeight: pw.FontWeight.bold);

    pw.Widget _section(String title, List<pw.Widget> children) =>
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              color: PdfColors.blue800,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: pw.Text(
                title,
                style: boldStyle.copyWith(
                    color: PdfColors.white, fontSize: 12),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColors.blue800, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: children,
              ),
            ),
            pw.SizedBox(height: 12),
          ],
        );

    pw.Widget _row(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            children: [
              pw.Text(label, style: boldStyle.copyWith(fontSize: 11)),
              pw.SizedBox(width: 4),
              pw.Text(value, style: baseStyle),
            ],
          ),
        );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // ── Cabeçalho ────────────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            color: PdfColors.blue800,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'RELATÓRIO DE PROGRESSO - ALFABETIZAÇÃO FONÉTICA',
                  style: boldStyle.copyWith(
                      color: PdfColors.white, fontSize: 13),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Período: ${report.formattedPeriod}  |  Gerado em: ${report.formattedGeneratedAt}',
                  style:
                      baseStyle.copyWith(color: PdfColors.white, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Resumo ────────────────────────────────────────────────────────
          _section('RESUMO DA SEMANA', [
            _row('Sessões realizadas:', '${report.sessionsCount} de 7 dias'),
            _row('Tempo médio por sessão:',
                '${report.avgSessionMinutes.toStringAsFixed(0)} minutos'),
            _row('Palavras trabalhadas:', '${report.wordsWorked}'),
            _row(
              'Taxa de acerto geral:',
              '${(report.overallAccuracy * 100).toStringAsFixed(0)}%'
              '  (${report.accuracyDelta >= 0 ? "+" : ""}${(report.accuracyDelta * 100).toStringAsFixed(0)}% vs. semana anterior)',
            ),
            _row('Sílabas dominadas:', '${report.newSyllablesMastered}'),
          ]),

          // ── Gráfico diário ─────────────────────────────────────────────────
          if (report.dailyChart.isNotEmpty)
            _section('EVOLUÇÃO FONÉTICA (ACURÁCIA POR DIA)', [
              ...report.dailyChart.map((d) {
                final pct = d.accuracy.clamp(0.0, 1.0);
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 36,
                        child: pw.Text(d.dayLabel, style: boldStyle.copyWith(fontSize: 10)),
                      ),
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: (pct * 100).clamp(1.0, 100.0).round(),
                              child: pw.Container(
                                height: 14,
                                color: pct >= 0.85
                                    ? PdfColors.green700
                                    : PdfColors.blue400,
                              ),
                            ),
                            if (((1 - pct) * 100).round() > 0)
                              pw.Expanded(
                                flex: ((1 - pct) * 100).clamp(0.0, 99.0).round(),
                                child: pw.Container(
                                  height: 14,
                                  color: PdfColors.grey200,
                                ),
                              ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: boldStyle.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }),
            ]),

          // ── Famílias ────────────────────────────────────────────────────────
          _section('FAMÍLIAS SILÁBICAS TRABALHADAS', [
            ...report.families.map((f) {
              final statusLabel = switch (f.status) {
                FamilyStatus.dominada     => 'DOMINADA',
                FamilyStatus.emProgresso  => 'EM PROGRESSO',
                FamilyStatus.iniciando    => 'INICIANDO',
                FamilyStatus.naoPraticada => 'NÃO PRATICADA',
              };
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(f.label,
                            style: boldStyle.copyWith(fontSize: 11)),
                        pw.Text(
                          '${(f.completion * 100).toStringAsFixed(0)}% $statusLabel',
                          style: boldStyle.copyWith(
                            fontSize: 10,
                            color: f.status == FamilyStatus.dominada
                                ? PdfColors.green700
                                : PdfColors.blue700,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: (f.completion * 100).clamp(1.0, 100.0).round(),
                          child: pw.Container(
                            height: 8,
                            color: f.status == FamilyStatus.dominada
                                ? PdfColors.green600
                                : PdfColors.blue500,
                          ),
                        ),
                        if (((1 - f.completion) * 100).round() > 0)
                          pw.Expanded(
                            flex: ((1 - f.completion) * 100)
                                .clamp(0.0, 99.0)
                                .round(),
                            child: pw.Container(
                              height: 8,
                              color: PdfColors.grey200,
                            ),
                          ),
                      ],
                    ),
                    if (f.masteredSyllables.isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Dominadas: ${f.masteredSyllables.join(", ")}',
                        style: baseStyle.copyWith(
                            fontSize: 9, color: PdfColors.green800),
                      ),
                    ],
                    if (f.pendingSyllables.isNotEmpty) ...[
                      pw.Text(
                        'Pendentes: ${f.pendingSyllables.join(", ")}',
                        style: baseStyle.copyWith(
                            fontSize: 9, color: PdfColors.orange700),
                      ),
                    ],
                    if (f.focusRecommendation != null)
                      pw.Text(
                        'Foco: ${f.focusRecommendation}',
                        style: baseStyle.copyWith(
                            fontSize: 9, color: PdfColors.orange900),
                      ),
                  ],
                ),
              );
            }),
          ]),

          // ── Engajamento ─────────────────────────────────────────────────────
          _section('ENGAJAMENTO E GAMIFICAÇÃO', [
            _row('Nível:', '${report.levelEmoji} ${report.levelName}'),
            _row('XP:', '${report.xp}'),
            _row('Moedas:', '${report.coins}'),
            _row('Sequência:', '${report.streak} dias consecutivos'),
            if (report.weekBadgeIds.isNotEmpty)
              _row('Conquistas:',
                  report.weekBadgeIds.map((id) {
                    final b = getBadgeById(id);
                    return b != null ? '${b.emoji} ${b.name}' : id;
                  }).join('  |  ')),
          ]),

          // ── Recomendações ────────────────────────────────────────────────────
          _section('RECOMENDAÇÕES', [
            ...report.recommendations.map(
              (r) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  '${r.emoji}  ${r.isForAdult ? "[Pais/Educador]" : "[Para a criança]"}  ${r.text}',
                  style: baseStyle.copyWith(fontSize: 10),
                ),
              ),
            ),
          ]),

          // ── Rodapé LGPD ─────────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColors.teal50,
            child: pw.Text(
              'Dados protegidos conforme LGPD. O áudio bruto é descartado após o processamento fonético. '
              'Apenas métricas pedagógicas são armazenadas localmente no dispositivo do responsável.',
              style: baseStyle.copyWith(
                  fontSize: 8.5, color: PdfColors.teal900),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/relatorio_semanal.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
