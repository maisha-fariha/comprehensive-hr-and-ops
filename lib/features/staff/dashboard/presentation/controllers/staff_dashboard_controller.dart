import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_dashboard_overview.dart';
import '../../domain/repositories/staff_dashboard_repository.dart';

/// GetX controller for the Staff Dashboard ("Home") screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app.
class StaffDashboardController extends BaseController<StaffDashboardOverview> {
  final StaffDashboardRepository repository;

  /// Account this controller's data belongs to — used to detect stale reuse.
  String? boundUserId;

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

  @override
  Future<void> refresh() => loadOverview();
}
