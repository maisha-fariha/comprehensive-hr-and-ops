import 'package:gems_core/gems_core.dart';

import '../entities/team_reports_page_data.dart';

/// Contract for fetching the HR/Manager "Team & Reports" screen (the Team,
/// Reports and Messages segmented tabs). The presentation layer only ever
/// depends on this interface, so swapping the mocked
/// [TeamReportsRepositoryImpl] for a real API-backed implementation later
/// requires no changes above the data layer.
abstract class TeamReportsRepository {
  Future<Result<TeamReportsPageData>> getPageData();
}
