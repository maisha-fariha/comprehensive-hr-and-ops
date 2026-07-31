import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/dashboard_overview.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// GetX controller for the HR/Manager Dashboard screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app.
class DashboardController extends BaseController<DashboardOverview> {
  final DashboardRepository repository;

  DashboardController({required this.repository}) {
    loadOverview();
  }

  DashboardOverview? get overview => state.value.data;

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
