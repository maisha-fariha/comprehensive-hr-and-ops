import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_overview.dart';
import '../../domain/repositories/attendance_repository.dart';

/// GetX controller for the "Attendance" screen.
///
/// "Today" / "Late" / "Missed" / "OT" are segmented tabs on a single screen
/// (they share the same header and tab bar in the reference design), so a
/// single controller owns both the fetched [AttendanceOverview] and the
/// currently selected tab.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app.
class AttendanceController extends BaseController<AttendanceOverview> {
  final AttendanceRepository repository;

  final Rx<AttendanceTab> selectedTab = AttendanceTab.today.obs;
  int _loadGeneration = 0;

  AttendanceController({required this.repository}) {
    loadOverview();
  }

  AttendanceOverview? get overview => state.value.data;

  void selectTab(AttendanceTab tab) => selectedTab.value = tab;

  Future<void> loadOverview() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getOverview();
    if (generation != _loadGeneration) return;
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> reviewMissedClockIn(String attendanceId) async {
    final result = await repository.approveAttendance(attendanceId);
    result.when(
      success: (_) => loadOverview(),
      failure: (error) {
        AppSnackbar.show(
          'Could not review',
          error.message,
        );
      },
    );
  }

  @override
  Future<void> refresh() => loadOverview();
}
