import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/staff_attendance_overview.dart';
import '../../domain/repositories/staff_attendance_repository.dart';

/// GetX controller for the "Attendance" screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app.
class StaffAttendanceController extends BaseController<StaffAttendanceOverview> {
  final StaffAttendanceRepository repository;

  StaffAttendanceController({required this.repository}) {
    loadOverview();
  }

  StaffAttendanceOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadOverview();
}
