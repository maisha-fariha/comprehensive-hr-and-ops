import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/staff_incident.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import '../../domain/repositories/staff_incidents_repository.dart';

/// GetX controller for the Staff Incidents list screen (both tabs).
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the selected-tab and
/// search-query state backing the "My Incidents / All Incidents" segmented
/// control and search bar.
class StaffIncidentsController extends BaseController<List<StaffIncident>> {
  final StaffIncidentsRepository repository;

  StaffIncidentsController({required this.repository}) {
    loadIncidents();
  }

  final Rx<StaffIncidentsTab> selectedTab = StaffIncidentsTab.myIncidents.obs;
  final RxString searchQuery = ''.obs;

  List<StaffIncident> get incidents => state.value.data ?? const [];

  /// Incidents for the currently selected tab, filtered by [searchQuery].
  /// Both tabs share the same underlying list in the source screenshots -
  /// only each card's rendering differs per tab (handled by the widgets).
  List<StaffIncident> get visibleIncidents {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return incidents;
    return incidents.where((incident) => incident.title.toLowerCase().contains(query)).toList();
  }

  void selectTab(StaffIncidentsTab tab) => selectedTab.value = tab;

  void updateSearchQuery(String query) => searchQuery.value = query;

  Future<void> loadIncidents() async {
    setLoading(true);
    final result = await repository.getIncidents();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadIncidents();
}
