import 'package:gems_core/gems_core.dart';

import '../entities/recurring_check.dart';

/// Web `/dashboard/recurring-checks` reads and writes.
abstract class RecurringChecksRepository {
  Future<Result<CheckSchedulePage>> schedules({required int page, required int limit});

  /// A resident's schedules for "Record Progress" (`clientId`, limit 50).
  Future<Result<List<CheckSchedule>>> clientSchedules(String clientId);

  Future<Result<void>> createSchedule(Map<String, dynamic> body);

  Future<Result<void>> updateSchedule(String id, Map<String, dynamic> body);

  Future<Result<void>> deleteSchedule(String id);

  /// Occurrences on [day] (`YYYY-MM-DD`), first 100.
  Future<Result<List<CheckInstance>>> instances({
    required String day,
    String? residenceId,
    String? status,
    bool mine = false,
  });

  /// Checks recorded on [day]; the web sends the Status filter as `outcome`.
  Future<Result<List<CheckEntry>>> entries({
    required String day,
    String? residenceId,
    String? outcome,
    bool mine = false,
  });

  Future<Result<void>> updateInstance(String id, Map<String, dynamic> body);

  Future<Result<List<CheckAvailableStaff>>> availableStaff(String instanceId);

  Future<Result<void>> recordEntry(Map<String, dynamic> body);

  Future<Result<List<CheckOption>>> residences();

  Future<Result<List<CheckOption>>> staff();

  Future<Result<List<CheckOption>>> clients({String? residenceId});

  /// `GET /staff/directory` for a residence ("Who usually does this").
  Future<Result<List<CheckOption>>> colleagues(String? residenceId);

  /// Residence of the caller's open attendance, or null when not clocked in.
  Future<Result<String?>> openAttendanceResidenceId();
}
