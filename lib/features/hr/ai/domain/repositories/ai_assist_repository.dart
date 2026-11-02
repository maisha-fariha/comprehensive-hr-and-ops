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
