import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/staff_dashboard_overview.dart';
import '../../domain/repositories/staff_dashboard_repository.dart';

/// GetX controller for the Staff Dashboard ("Home") screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app.
class StaffDashboardController extends BaseController<StaffDashboardOverview> {
  final StaffDashboardRepository repository;

  StaffDashboardController({required this.repository}) {
    loadOverview();
  }

  StaffDashboardOverview? get overview => state.value.data;

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
