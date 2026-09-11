import 'package:gems_core/gems_core.dart';

import '../entities/report_export_item.dart';
import '../entities/team_reports_page_data.dart';
import '../entities/team_staff_profile.dart';

/// Contract for the HR/Manager "Team & Reports" screen.
abstract class TeamReportsRepository {
  Future<Result<TeamReportsPageData>> getPageData();

  /// `GET /staff/{staffId}` (+ documents)
  Future<Result<TeamStaffProfile>> getStaffProfile(String staffId);

  /// `GET /staff/{staffId}/documents`
  Future<Result<List<TeamStaffDocument>>> getStaffDocuments(String staffId);

  /// `POST /reports/exports`
  Future<Result<ReportExportItem>> createExport({
    required String reportKey,
    String format = 'csv',
  });

  /// `GET /reports/exports/{exportId}`
  Future<Result<ReportExportItem>> getExportStatus(String exportId);

  /// Downloads CSV bytes via `GET /reports/exports/{exportId}/download`
  /// (or a signed/`downloadUrl` from status when present).
  Future<Result<List<int>>> downloadExportFile(String exportId);
}
