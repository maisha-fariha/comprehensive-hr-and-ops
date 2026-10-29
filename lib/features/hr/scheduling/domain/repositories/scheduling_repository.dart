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
    ScheduleSpan span = ScheduleSpan.week,
    DateTime? monthOf,
  });

  /// `POST /shifts/{id}/open`.
  Future<Result<void>> openShift(String shiftId);

  /// `POST /shifts/{id}/cancel`.
  Future<Result<void>> cancelShift(String shiftId);

  /// `DELETE /shifts/{id}`. The shift is kept and can be restored.
  Future<Result<void>> deleteShift(String shiftId);

  /// `POST /shifts/{shiftId}/swap-requests`. An empty colleague means cover.
  Future<Result<void>> requestSwap({
    required String shiftId,
    String? note,
  });

  /// Residences for the Create Shift "Residence" dropdown (`GET /residences`).
  Future<Result<List<ShiftResidenceOption>>> getResidences();

  /// `GET /settings/scheduling` — e.g. `defaultBreakMinutes` (web create-shift default).
  Future<Result<int>> getDefaultBreakMinutes();

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
