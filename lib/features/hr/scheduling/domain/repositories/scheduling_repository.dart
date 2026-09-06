import 'package:gems_core/gems_core.dart';

import '../entities/scheduling_overview.dart';

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

  /// Manager decision on a pending shift-swap request.
  Future<Result<void>> decideShiftSwap({
    required String swapId,
    required bool approve,
  });
}
