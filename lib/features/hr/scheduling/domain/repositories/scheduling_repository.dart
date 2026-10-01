import 'package:gems_core/gems_core.dart';

import '../entities/create_shift_draft.dart';
import '../entities/scheduling_enums.dart';
import '../entities/scheduling_overview.dart';
import '../entities/shift_residence_option.dart';
import '../entities/shift_staff_option.dart';

/// Contract for fetching the HR/Manager Scheduling screen's data (its
/// Calendar, Board and Requests tabs).
abstract class SchedulingRepository {
  /// Loads schedule data for the week containing [weekOf].
  ///
  /// [selectedDay] controls which day is marked selected on the calendar
  /// week strip (and which day's shifts feed the calendar timeline).
  ///
  /// [residenceId] scopes every query to one home (defaults to the session
  /// residence). [status] narrows calendar/board shifts to one lifecycle
  /// state. [mine] limits the week and open shifts to the signed-in user's
  /// own shifts (`mine=true`, the web "My shifts" toggle).
  Future<Result<SchedulingOverview>> getOverview({
    DateTime? weekOf,
    DateTime? selectedDay,
    String? residenceId,
    ShiftStatusFilter? status,
    bool mine = false,
  });

  /// Residences for the Create Shift "Residence" dropdown (`GET /residences`).
  Future<Result<List<ShiftResidenceOption>>> getResidences();

  /// Tenant staff for the Create Shift "Assigned Staff" picker
  /// (`GET /staff?page=1&limit=100`, searched client-side like the web).
  Future<Result<List<ShiftStaffOption>>> getStaffOptions();

  /// Creates a shift (or a recurring series) via `POST /shifts`.
  /// Returns how many shifts were created.
  Future<Result<int>> createShift(Map<String, dynamic> payload);

  /// Loads one shift (`GET /shifts/{id}`) as an Edit Shift form.
  Future<Result<CreateShiftDraft>> getShiftDraft(String shiftId);

  /// Saves an edited shift like the web: `PATCH /shifts/{id}` with
  /// [payload], then `PUT /shifts/{id}/assignments` with [staffIds].
  Future<Result<void>> updateShift({
    required String shiftId,
    required Map<String, dynamic> payload,
    required List<String> staffIds,
  });

  /// Manager decision on a pending shift-swap request.
  Future<Result<void>> decideShiftSwap({
    required String swapId,
    required bool approve,
  });
}
