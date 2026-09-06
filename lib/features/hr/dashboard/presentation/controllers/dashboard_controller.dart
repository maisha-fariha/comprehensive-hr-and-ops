import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/dashboard_overview.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// GetX controller for the HR/Manager Dashboard screen.
class DashboardController extends BaseController<DashboardOverview> {
  final DashboardRepository repository;

  int _loadGeneration = 0;

  DashboardController({required this.repository}) {
    loadOverview();
  }

  DashboardOverview? get overview => state.value.data;

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

  @override
  Future<void> refresh() => loadOverview();
}
