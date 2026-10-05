import 'package:gems_core/gems_core.dart';

import '../entities/daily_note_attachment.dart';
import '../entities/daily_note_overview.dart';
import '../entities/staff_daily_logs_overview.dart';

/// Contract for Staff Daily Logs (web-parity queues + Daily Note).
abstract class StaffDailyLogsRepository {
  /// Loads To review / Missing / Resident day / House activity for filters.
  ///
  /// [residenceId] is required by the API for review/missing queues.
  Future<Result<StaffDailyLogsOverview>> getOverview({
    required String residenceId,
    required DateTime from,
    required DateTime to,
    String? clientId,
  });

  Future<Result<DailyNoteOverview>> getEntryDetail(String entryId);

  Future<Result<DailyNoteOverview>> getEmptyDailyNote();

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

  Future<Result<String>> amendEntry({
    required String entryId,
    required String body,
    required String reason,
  });

  Future<Result<DailyNoteAttachment>> uploadAttachment({
    required String localPath,
    required String fileName,
  });

  Future<Result<void>> createHandover({
    required String residenceId,
    required String summary,
    String? clientId,
    String? fromShiftId,
    String? toShiftId,
    bool flagForAttention = false,
    bool submit = true,
  });

  Future<Result<String>> createClient({
    required String name,
    required String residenceId,
    String? room,
  });

  Future<Result<List<({String id, String name})>>> getResidenceOptions();
}
