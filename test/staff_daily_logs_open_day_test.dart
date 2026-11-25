import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/daily_logs/domain/entities/daily_note_attachment.dart';
import 'package:comprehensive_hr_and_ops/features/staff/daily_logs/domain/entities/daily_note_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/daily_logs/domain/entities/staff_client_log_entry.dart';
import 'package:comprehensive_hr_and_ops/features/staff/daily_logs/domain/entities/staff_daily_logs_enums.dart';
import 'package:comprehensive_hr_and_ops/features/staff/daily_logs/domain/entities/staff_daily_logs_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/daily_logs/domain/repositories/staff_daily_logs_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/daily_logs/presentation/controllers/staff_daily_logs_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';

class _FakeLogsRepo implements StaffDailyLogsRepository {
  int overviewCalls = 0;

  @override
  Future<Result<StaffDailyLogsOverview>> getOverview({
    required String residenceId,
    required DateTime from,
    required DateTime to,
    String? clientId,
  }) async {
    overviewCalls++;
    return Result.success(StaffDailyLogsOverview.empty);
  }

  @override
  Future<Result<List<({String id, String name})>>> getResidenceOptions() async =>
      Result.success(const [(id: 'res-1', name: 'Mala Box')]);

  @override
  Future<Result<DailyNoteOverview>> getEntryDetail(String entryId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<DailyNoteOverview>> getEmptyDailyNote() async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
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
  }) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<String>> amendEntry({
    required String entryId,
    required String body,
    required String reason,
  }) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<DailyNoteAttachment>> uploadAttachment({
    required String localPath,
    required String fileName,
  }) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<void>> createHandover({
    required String residenceId,
    required String summary,
    String? clientId,
    String? fromShiftId,
    String? toShiftId,
    bool flagForAttention = false,
    bool submit = true,
  }) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<String>> createClient({
    required String name,
    required String residenceId,
    String? room,
  }) async =>
      Result.failure(const ApiError(message: 'unused'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'openDay matches web: selects resident/date and Resident day tab, not Daily Note',
    () async {
      final repo = _FakeLogsRepo();
      final controller = StaffDailyLogsController(
        repository: repo,
        session: UserSession(),
      );
      await Future<void>.delayed(Duration.zero);
      await controller.setResidence('res-1');

      const entry = StaffClientLogEntry(
        id: 'missing-1',
        initials: 'EN',
        shiftLabel: '',
        clientName: 'Encoderit Naeem',
        subtitleLabel: 'Nothing written',
        status: ClientLogStatus.missing,
        dobLabel: '',
        roomLabel: '',
        clientId: 'client-1',
        residenceId: 'res-1',
        logDateIso: '2026-10-28T00:00:00.000Z',
      );

      final before = repo.overviewCalls;
      await controller.openDay(entry);

      expect(controller.selectedClientId.value, 'client-1');
      expect(controller.selectedResidenceId.value, 'res-1');
      expect(controller.selectedTab.value, StaffDailyLogsTab.residentDay);
      expect(controller.toDate.value, DateTime(2026, 10, 28));
      expect(repo.overviewCalls, greaterThan(before));
    },
  );
}
