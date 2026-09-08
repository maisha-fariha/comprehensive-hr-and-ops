import 'package:gems_core/gems_core.dart';

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
  Future<Result<SchedulingOverview>> getOverview({
    DateTime? weekOf,
    DateTime? selectedDay,
  });

  /// Residences for the Create Shift "Residence" dropdown (`GET /residences`).
  Future<Result<List<ShiftResidenceOption>>> getResidences();

  /// Staff for Create Shift assignment search (`GET /staff?search=`).
  Future<Result<List<ShiftStaffOption>>> searchStaff({
    String? search,
    String? residenceId,
  });

  /// Manager decision on a pending shift-swap request.
  Future<Result<void>> decideShiftSwap({
    required String swapId,
    required bool approve,
  });
}
