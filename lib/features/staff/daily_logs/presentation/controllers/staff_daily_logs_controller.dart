import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';

/// GetX controller for the Staff "Daily Logs" screen and its three
/// segmented tabs (My Clients / In Progress / Submitted).
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app; adds a [selectedTab] Rx on top for the segmented
/// tab bar, since all three tabs live on a single screen/data payload.
class StaffDailyLogsController extends BaseController<StaffDailyLogsOverview> {
  final StaffDailyLogsRepository repository;

  final Rx<StaffDailyLogsTab> selectedTab = StaffDailyLogsTab.myClients.obs;

  StaffDailyLogsController({required this.repository}) {
    loadOverview();
  }

  StaffDailyLogsOverview? get overview => state.value.data;

  void selectTab(StaffDailyLogsTab tab) => selectedTab.value = tab;

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
