import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/repositories/incidents_repository.dart';

/// GetX controller for the Incidents list screen (all 3 tabs).
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the selected-tab state
/// backing the "Open / Under Review / Closed" segmented control.
class IncidentsController extends BaseController<IncidentsBoard> {
  final IncidentsRepository repository;

  IncidentsController({required this.repository}) {
    loadBoard();
  }

  final Rx<IncidentsTab> selectedTab = IncidentsTab.open.obs;

  IncidentsBoard? get board => state.value.data;

  void selectTab(IncidentsTab tab) => selectedTab.value = tab;

  Future<void> loadBoard() async {
    setLoading(true);
    final result = await repository.getBoard();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadBoard();
}
