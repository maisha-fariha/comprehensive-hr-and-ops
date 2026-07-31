import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../domain/entities/team_reports_enums.dart';
import '../../domain/entities/team_reports_page_data.dart';
import '../../domain/repositories/team_reports_repository.dart';

/// GetX controller for the whole "Team & Reports" screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the selected-tab state for
/// the segmented "Team | Reports | Messages" control shared by all three
/// tabs on this single page.
class TeamReportsController extends BaseController<TeamReportsPageData> {
  final TeamReportsRepository repository;

  TeamReportsController({required this.repository}) {
    loadPageData();
  }

  final Rx<TeamReportsTab> selectedTab = TeamReportsTab.team.obs;

  TeamReportsPageData? get pageData => state.value.data;

  void selectTab(TeamReportsTab tab) => selectedTab.value = tab;

  Future<void> loadPageData() async {
    setLoading(true);
    final result = await repository.getPageData();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadPageData();
}
