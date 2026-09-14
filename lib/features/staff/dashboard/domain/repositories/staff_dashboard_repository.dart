import 'package:gems_core/gems_core.dart';

import '../entities/staff_dashboard_overview.dart';

/// Staff Dashboard (B1 Home) — APIs from the Part B screen map.
abstract class StaffDashboardRepository {
  /// Loads greeting via `GET /mobile/me` and tiles/shift via `GET /mobile/home`.
  Future<Result<StaffDashboardOverview>> getOverview();

  /// Quick Action: Clock In → `POST /attendance/check-in`.
  Future<Result<void>> checkIn({String? shiftId, String? residenceId});

  /// Quick Action: Clock Out → `POST /attendance/check-out`.
  Future<Result<void>> checkOut({String? shiftId, String? residenceId});
}
