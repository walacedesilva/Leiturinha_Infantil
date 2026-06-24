import 'package:intl/intl.dart';
import '../features/reading_game/data/word_bank.dart';
import 'gamification_models.dart';
import 'gamification_service.dart';
import 'progress_service.dart';
import 'session_tracking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DO RELATÓRIO
// ─────────────────────────────────────────────────────────────────────────────

/// Status de progresso de uma família silábica no relatório.
enum FamilyStatus { dominada, emProgresso, iniciando, naoPraticada }

class ReportFamilyData {
  final String key;
  final String label;
  final double completion;         // 0–1
  final List<String> masteredSyllables;
  final List<String> pendingSyllables;
  final FamilyStatus status;
  final String? focusRecommendation;

  const ReportFamilyData({
    required this.key,
    required this.label,
    required this.completion,
    required this.masteredSyllables,
    required this.pendingSyllables,
    required this.status,
    this.focusRecommendation,
  });
}

/// Dado de precisão por dia da semana.
class DailyAccuracy {
  final String dayLabel;  // 'Seg', 'Ter' …
  final double accuracy;  // 0–1

  const DailyAccuracy(this.dayLabel, this.accuracy);
}

/// Recomendação contextualizada para pais/educadores.
class ReportRecommendation {
  final String emoji;
  final String text;
  final bool isForAdult;   // true = pais/prof, false = criança

  const ReportRecommendation({
    required this.emoji,
    required this.text,
    required this.isForAdult,
  });
}

/// Relatório semanal completo gerado pelo ReportService.
class WeeklyReport {
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;

  // Resumo
  final int sessionsCount;
  final double avgSessionMinutes;
  final int wordsWorked;
  final double overallAccuracy;
  final double previousWeekAccuracy;   // para mostrar Δ
  final int newSyllablesMastered;

  // Gráfico diário
  final List<DailyAccuracy> dailyChart;

  // Famílias
  final List<ReportFamilyData> families;

  // Erros silábicos (sílabas com mais dificuldades)
  final List<MapEntry<String, int>> topErrors;

  // Gamificação
  final int coins;
  final int xp;
  final int streak;
  final List<String> weekBadgeIds;
  final String levelName;
  final String levelEmoji;

  // Recomendações
  final List<ReportRecommendation> recommendations;

  const WeeklyReport({
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.sessionsCount,
    required this.avgSessionMinutes,
    required this.wordsWorked,
    required this.overallAccuracy,
    required this.previousWeekAccuracy,
    required this.newSyllablesMastered,
    required this.dailyChart,
    required this.families,
    required this.topErrors,
    required this.coins,
    required this.xp,
    required this.streak,
    required this.weekBadgeIds,
    required this.levelName,
    required this.levelEmoji,
    required this.recommendations,
  });

  double get accuracyDelta => overallAccuracy - previousWeekAccuracy;

  String get formattedPeriod {
    final fmt = DateFormat('dd/MM/yyyy');
    return '${fmt.format(periodStart)} - ${fmt.format(periodEnd)}';
  }

  String get formattedGeneratedAt =>
      DateFormat("dd/MM/yyyy 'às' HH:mm").format(generatedAt);
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVIÇO GERADOR DE RELATÓRIO
// ─────────────────────────────────────────────────────────────────────────────

class ReportService {
  final SessionTrackingService sessions;
  final ProgressService progress;
  final GamificationService gamification;

  const ReportService({
    required this.sessions,
    required this.progress,
    required this.gamification,
  });

  /// Gera o relatório da semana atual (segunda a domingo).
  WeeklyReport generateCurrentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: (now.weekday - 1) % 7));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
    return _generate(weekStart, weekEnd);
  }

  /// Gera o relatório para uma semana específica.
  WeeklyReport generateForWeek(DateTime weekStart) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
    return _generate(start, end);
  }

  WeeklyReport _generate(DateTime start, DateTime end) {
    final weekSessions = sessions.sessionsInWeek(start);

    // ── Semana anterior (para Δ) ──────────────────────────────────────────
    final prevStart = start.subtract(const Duration(days: 7));
    final prevSessions = sessions.sessionsInWeek(prevStart);
    final prevAccuracy = prevSessions.isEmpty
        ? 0.0
        : prevSessions.map((s) => s.averageAccuracy).reduce((a, b) => a + b) /
            prevSessions.length;

    // ── Métricas da semana ────────────────────────────────────────────────
    final totalWords =
        weekSessions.fold(0, (sum, s) => sum + s.wordsValidated);
    final totalDuration =
        weekSessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final avgMinutes =
        weekSessions.isEmpty ? 0.0 : (totalDuration / weekSessions.length) / 60;
    final overallAccuracy = weekSessions.isEmpty
        ? 0.0
        : weekSessions.map((s) => s.averageAccuracy).reduce((a, b) => a + b) /
            weekSessions.length;

    // ── Gráfico diário ────────────────────────────────────────────────────
    final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final dailyChart = <DailyAccuracy>[];
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final daySessions = weekSessions.where((s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day);
      if (daySessions.isNotEmpty) {
        final acc =
            daySessions.map((s) => s.averageAccuracy).reduce((a, b) => a + b) /
                daySessions.length;
        dailyChart.add(DailyAccuracy(weekdays[i], acc));
      }
    }

    // ── Famílias ──────────────────────────────────────────────────────────
    // Inclui apenas famílias que foram jogadas ao menos uma vez
    final playedFamilyKeys = weekSessions
        .expand((s) => s.familiesPlayed)
        .toSet();

    // Também inclui famílias com progresso salvo (pode ter sido semanas anteriores)
    final allFamiliesWithProgress = WordBank.families.where((f) {
      final comp = progress.getCompletedWords(f.key);
      return comp.isNotEmpty || playedFamilyKeys.contains(f.key);
    }).toList();

    int newSyllables = 0;
    final familyReports = allFamiliesWithProgress.map((f) {
      final completedWords = progress.getCompletedWords(f.key);
      final completion = f.totalWords == 0
          ? 0.0
          : completedWords.length / f.totalWords;

      // Sílabas dominadas = sílabas que aparecem em palavras concluídas
      final mastered = <String>{};
      for (final word in f.words) {
        if (completedWords.contains(word.word)) {
          for (final syl in word.syllables) {
            if (syl.toUpperCase().startsWith(f.key.toUpperCase())) {
              mastered.add(syl.toUpperCase());
            }
          }
        }
      }

      final allCanonical = f.canonicalSyllables;
      final pending =
          allCanonical.where((s) => !mastered.contains(s)).toList();
      newSyllables += mastered.length;

      FamilyStatus status;
      if (completion >= 1.0) {
        status = FamilyStatus.dominada;
      } else if (completion >= 0.5) {
        status = FamilyStatus.emProgresso;
      } else if (completion > 0) {
        status = FamilyStatus.iniciando;
      } else {
        status = FamilyStatus.naoPraticada;
      }

      String? focus;
      if (pending.isNotEmpty && status != FamilyStatus.dominada) {
        focus = 'Praticar: ${pending.take(3).join(", ")}';
      }

      return ReportFamilyData(
        key: f.key,
        label: f.label,
        completion: completion,
        masteredSyllables: mastered.toList(),
        pendingSyllables: pending,
        status: status,
        focusRecommendation: focus,
      );
    }).toList();

    // ── Top erros silábicos ───────────────────────────────────────────────
    final topErrors = sessions.topErrorSyllables(limit: 5);

    // ── Gamificação ───────────────────────────────────────────────────────
    final gState = gamification.state;
    final level = getLevelForXp(gState.xp);

    // Badges ganhos nesta semana (aproximação: últimos 7 dias de badges)
    // Na ausência de timestamp por badge, listamos todos os badges do estado
    final weekBadgeIds = gState.earnedBadgeIds.toList();

    // ── Recomendações ─────────────────────────────────────────────────────
    final recs = _buildRecommendations(
      familyReports: familyReports,
      topErrors: topErrors,
      overallAccuracy: overallAccuracy,
      streak: gState.currentStreak,
    );

    return WeeklyReport(
      periodStart: start,
      periodEnd: end,
      generatedAt: DateTime.now(),
      sessionsCount: weekSessions.length,
      avgSessionMinutes: avgMinutes,
      wordsWorked: totalWords,
      overallAccuracy: overallAccuracy,
      previousWeekAccuracy: prevAccuracy,
      newSyllablesMastered: newSyllables,
      dailyChart: dailyChart,
      families: familyReports,
      topErrors: topErrors,
      coins: gState.coins,
      xp: gState.xp,
      streak: gState.currentStreak,
      weekBadgeIds: weekBadgeIds,
      levelName: level.name,
      levelEmoji: level.emoji,
      recommendations: recs,
    );
  }

  List<ReportRecommendation> _buildRecommendations({
    required List<ReportFamilyData> familyReports,
    required List<MapEntry<String, int>> topErrors,
    required double overallAccuracy,
    required int streak,
  }) {
    final recs = <ReportRecommendation>[];

    // Próximas sílabas pendentes
    final withPending = familyReports
        .where((f) =>
            f.pendingSyllables.isNotEmpty && f.status != FamilyStatus.dominada)
        .take(2);
    for (final f in withPending) {
      final syls = f.pendingSyllables.take(2).join(' e ');
      recs.add(ReportRecommendation(
        emoji: '🎯',
        text:
            'Na próxima sessão, pratique $syls da ${f.label} em situações do dia a dia.',
        isForAdult: true,
      ));
    }

    // Erros recorrentes
    if (topErrors.isNotEmpty) {
      final syl = topErrors.first.key;
      recs.add(ReportRecommendation(
        emoji: '🔍',
        text:
            'A sílaba "$syl" apareceu com mais erros. Experimente brincadeiras de rima com ela.',
        isForAdult: true,
      ));
    }

    // Boa acurácia
    if (overallAccuracy >= 0.85) {
      recs.add(ReportRecommendation(
        emoji: '⭐',
        text:
            'Ótimo desempenho! Tente apresentar palavras com 3 sílabas para ampliar o desafio.',
        isForAdult: true,
      ));
    }

    // Streak
    if (streak >= 3) {
      recs.add(ReportRecommendation(
        emoji: '🔥',
        text: 'Sequência de $streak dias! Mantenha a rotina — a consistência é o maior acelerador da alfabetização.',
        isForAdult: true,
      ));
    }

    // Para a criança
    for (final f in withPending.take(1)) {
      final next = f.pendingSyllables.take(1).join();
      recs.add(ReportRecommendation(
        emoji: '🎁',
        text: 'Na próxima aventura, vamos descobrir palavras com $next!',
        isForAdult: false,
      ));
    }

    return recs;
  }
}
