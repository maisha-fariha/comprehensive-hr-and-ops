import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/family_daily_updates_overview.dart';
import '../../domain/repositories/family_daily_updates_repository.dart';

/// GetX controller for the Family "Daily Updates" screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app.
class FamilyDailyUpdatesController extends BaseController<FamilyDailyUpdatesOverview> {
  final FamilyDailyUpdatesRepository repository;

  FamilyDailyUpdatesController({required this.repository}) {
    loadOverview();
  }

  FamilyDailyUpdatesOverview? get overview => state.value.data;

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
