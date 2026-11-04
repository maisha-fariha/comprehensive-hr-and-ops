import 'package:gems_core/gems_core.dart';

import '../entities/ai_assist.dart';

/// Cross-feature AI drafting helpers used by MAR, Goals, Rota, Training and
/// Inventory (web `/ai/*` parity).
abstract class AiAssistRepository {
  Future<Result<bool>> isDraftingEnabled();

  Future<Result<AiMarReview>> reviewMar({
    required String clientId,
    required int days,
  });

  Future<Result<AiGoalsSuggestResult>> suggestGoals({
    required String clientId,
    String? notes,
    int count = 4,
  });

  /// Web "Summarise progress" (`POST /ai/daily-logs/summarize`).
  Future<Result<AiDraftResult>> summarizeDailyLogs({
    required String clientId,
    required int days,
  });

  /// Web AI Day Assistant (`POST /ai/daily-logs/ask-day`).
  Future<Result<AiAskDayAnswer>> askDay({
    required String clientId,
    required String logDate,
    required String query,
    required String preset,
  });

  /// Web "Tidy my note" (`POST /ai/daily-logs/draft-entry`).
  Future<Result<AiDailyLogDraftEntry>> draftDailyLogEntry({
    required String clientId,
    required String notes,
    String? logType,
    String? mood,
    String? sleep,
    String? hygiene,
  });

  /// Web "Draft handover note" (`POST /ai/handovers/draft`).
  Future<Result<AiHandoverDraft>> draftHandover({
    required String residenceId,
    String? since,
    String? until,
  });

  /// Web "Draft outcome review" (`POST /ai/client-goals/:id/review`).
  Future<Result<AiDraftResult>> reviewGoals({
    required String clientId,
    required int days,
  });

  Future<Result<AiRotaFindings>> reviewRota({
    required String residenceId,
    required String from,
    required int days,
  });

  Future<Result<AiTrainingGaps>> trainingGaps();

  Future<Result<AiStockReorder>> reviewStock({
    required String residenceId,
    required int days,
  });
}
