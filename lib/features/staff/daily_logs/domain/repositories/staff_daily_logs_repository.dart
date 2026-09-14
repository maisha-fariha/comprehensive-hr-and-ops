import 'package:gems_core/gems_core.dart';

import '../entities/daily_note_attachment.dart';
import '../entities/daily_note_overview.dart';
import '../entities/staff_daily_logs_overview.dart';

/// Contract for Staff Daily Logs (My Clients) and Daily Note.
abstract class StaffDailyLogsRepository {
  /// My Clients + In Progress (`entryStatus=draft`) + Submitted
  /// (`entryStatus=submitted`) + open care-flags.
  Future<Result<StaffDailyLogsOverview>> getOverview();

  /// `GET /daily-logs/entries/{entryId}` — details of one entry.
  Future<Result<DailyNoteOverview>> getEntryDetail(String entryId);

  /// Empty form scaffold when there is no existing entry yet.
  Future<Result<DailyNoteOverview>> getEmptyDailyNote();

  /// Save draft / edit draft / submit.
  /// - no [entryId] + draft → `POST /daily-logs/entries` `{status: draft}`
  /// - [entryId] + draft → `PATCH /daily-logs/entries/{id}`
  /// - [entryId] + submit → `PATCH` with `{status: submitted}`
  Future<Result<String>> saveEntry({
    required String clientId,
    required String residenceId,
    required String body,
    String? entryId,
    required bool submit,
    Map<String, String>? observations,
    String? shift,
    bool wellnessCheckCompleted = false,
    bool flagForAttention = false,
    List<DailyNoteAttachment> attachments = const [],
  });

  /// `POST /daily-logs/entries/{entryId}/amendments` — correct a submitted note.
  Future<Result<String>> amendEntry({
    required String entryId,
    required String body,
    required String reason,
  });

  /// `POST /uploads?category=daily-logs` → URL for [attachments].
  Future<Result<DailyNoteAttachment>> uploadAttachment({
    required String localPath,
    required String fileName,
  });

  /// `POST /shift-handovers` — separate from the daily-log entry.
  Future<Result<void>> createHandover({
    required String residenceId,
    required String summary,
    String? clientId,
    String? fromShiftId,
    String? toShiftId,
    bool flagForAttention = false,
    bool submit = true,
  });
}
