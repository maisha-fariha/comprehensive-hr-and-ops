import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/daily_logs_overview.dart';
import '../../domain/repositories/daily_logs_repository.dart';

/// GetX controller for the "Daily Logs" screen and its three segmented tabs
/// (Review / Missing / Handover).
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app; adds a [selectedTab] Rx on top for the segmented
/// tab bar, since all three tabs live on a single screen/data payload.
class DailyLogsController extends BaseController<DailyLogsOverview> {
  final DailyLogsRepository repository;

  final Rx<DailyLogsTab> selectedTab = DailyLogsTab.review.obs;

  DailyLogsController({required this.repository}) {
    loadOverview();
  }

  DailyLogsOverview? get overview => state.value.data;

  void selectTab(DailyLogsTab tab) => selectedTab.value = tab;

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
