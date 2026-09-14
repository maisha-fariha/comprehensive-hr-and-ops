import 'package:gems_core/gems_core.dart';

import '../entities/staff_schedule_overview.dart';
import '../entities/staff_shift.dart';

abstract class StaffScheduleRepository {
  /// Loads mine + open shifts, my swaps, and (when permitted) appointments.
  Future<Result<StaffScheduleOverview>> getOverview({
    DateTime? weekStart,
    DateTime? selectedDate,
  });

  /// `GET /shifts/{shiftId}` — staffing counts + colleague avatars.
  Future<Result<StaffShift>> getShiftDetail(String shiftId);

  /// `POST /shifts/{shiftId}/bids`
  Future<Result<void>> bidOnShift(String shiftId, {String? note});

  /// `POST /shifts/{fromShiftId}/swap-requests`
  Future<Result<void>> requestSwap({
    required String fromShiftId,
    String? note,
    String? targetStaffId,
    String? toShiftId,
  });

  /// `POST /shift-swaps/{swapId}/respond` — `{ response: accepted|declined }`
  Future<Result<void>> respondToSwap({
    required String swapId,
    required bool accepted,
    String? note,
  });

  /// `POST /shift-swaps/{swapId}/cancel`
  Future<Result<void>> cancelSwap(String swapId);
}
