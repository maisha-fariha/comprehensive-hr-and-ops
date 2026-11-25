import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/family_care_journal_models.dart';
import '../../domain/entities/family_daily_update_entry.dart';
import '../../domain/entities/family_daily_update_enums.dart';
import '../../domain/repositories/family_daily_updates_repository.dart';

enum CareJournalTab { journal, medical, moments }

/// Care Journal controller — web `/family/updates`.
class FamilyDailyUpdatesController
    extends BaseController<FamilyCareJournalOverview> {
  final FamilyDailyUpdatesRepository repository;

  FamilyDailyUpdatesController({required this.repository}) {
    loadOverview();
  }

  final Rxn<DailyUpdateCategory> selectedCategory = Rxn<DailyUpdateCategory>();
  final Rx<CareJournalTab> selectedTab = CareJournalTab.journal.obs;
  final RxnString selectedClientId = RxnString();

  FamilyCareJournalOverview? get overview => state.value.data;

  List<FamilyDailyUpdateEntry> get visibleEntries {
    final days = overview?.days ?? const [];
    final category = selectedCategory.value;
    final notes = [for (final day in days) ...day.notes];
    if (category == null) return notes;
    return notes.where((entry) => entry.category == category).toList();
  }

  void selectCategory(DailyUpdateCategory? category) =>
      selectedCategory.value = category;

  void selectTab(CareJournalTab tab) => selectedTab.value = tab;

  Future<void> selectClient(String clientId) async {
    if (clientId.isEmpty || clientId == selectedClientId.value) return;
    selectedClientId.value = clientId;
    await loadOverview(clientId: clientId);
  }

  Future<void> loadOverview({String? clientId}) async {
    setLoading(true);
    final result = await repository.getCareJournal(
      clientId: clientId ?? selectedClientId.value,
    );
    result.when(
      success: (data) {
        selectedClientId.value = data.selectedClientId;
        setSuccess(data);
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadOverview(clientId: selectedClientId.value);
}
