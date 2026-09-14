import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_dashboard_overview.dart';
import '../../domain/repositories/staff_dashboard_repository.dart';

/// GetX controller for the Staff Dashboard ("Home") screen.
class StaffDashboardController extends BaseController<StaffDashboardOverview> {
  final StaffDashboardRepository repository;

  /// Account this controller's data belongs to — used to detect stale reuse.
  String? boundUserId;

  final RxBool clockBusy = false.obs;

  StaffDashboardController({required this.repository});

  StaffDashboardOverview? get overview => state.value.data;

  @override
  void onInit() {
    super.onInit();
    loadOverview();
  }

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: (data) {
        try {
          boundUserId = Get.find<UserSession>().userId;
        } catch (_) {
          boundUserId = null;
        }
        setSuccess(data);
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  /// Quick Action: Clock In / Out → POST check-in or check-out, then refresh.
  Future<void> toggleClockInOut() async {
    final shift = overview?.todayShift;
    if (shift == null || clockBusy.value) return;

    clockBusy.value = true;
    final result = shift.onShift
        ? await repository.checkOut(
            shiftId: shift.shiftId,
            residenceId: shift.residenceId,
          )
        : await repository.checkIn(
            shiftId: shift.shiftId,
            residenceId: shift.residenceId,
          );
    clockBusy.value = false;

    result.when(
      success: (_) async {
        AppSnackbar.show(
          shift.onShift ? 'Clocked out' : 'Clocked in',
          shift.onShift
              ? 'Your shift attendance was updated.'
              : 'You are now on shift.',
        );
        await loadOverview();
      },
      failure: (error) {
        AppSnackbar.show(
          'Could not update attendance',
          error.message,
        );
      },
    );
  }

  @override
  Future<void> refresh() => loadOverview();
}
