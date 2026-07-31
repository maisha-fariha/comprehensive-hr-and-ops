import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/staff_schedule_overview.dart';
import '../../domain/repositories/staff_schedule_repository.dart';

/// GetX controller for the "My Schedule" screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app.
class StaffScheduleController extends BaseController<StaffScheduleOverview> {
  final StaffScheduleRepository repository;

  StaffScheduleController({required this.repository}) {
    loadOverview();
  }

  StaffScheduleOverview? get overview => state.value.data;

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
