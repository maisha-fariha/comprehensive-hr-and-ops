import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/family_daily_update_entry.dart';
import '../../domain/entities/family_daily_update_enums.dart';
import '../../domain/entities/family_daily_updates_overview.dart';
import '../../domain/repositories/family_daily_updates_repository.dart';

/// GetX controller for the Family "Daily Updates" screen.
class FamilyDailyUpdatesController
    extends BaseController<FamilyDailyUpdatesOverview> {
  final FamilyDailyUpdatesRepository repository;

  FamilyDailyUpdatesController({required this.repository}) {
    loadOverview();
  }

  final Rxn<DailyUpdateCategory> selectedCategory = Rxn<DailyUpdateCategory>();

  FamilyDailyUpdatesOverview? get overview => state.value.data;

  List<FamilyDailyUpdateEntry> get visibleEntries {
    final entries = overview?.entries ?? const [];
    final category = selectedCategory.value;
    if (category == null) return entries;
    return entries.where((entry) => entry.category == category).toList();
  }

  void selectCategory(DailyUpdateCategory? category) =>
      selectedCategory.value = category;

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
