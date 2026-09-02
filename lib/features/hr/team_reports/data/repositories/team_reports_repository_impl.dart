import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/team_reports_page_data.dart';
import '../../domain/repositories/team_reports_repository.dart';
import '../mappers/team_reports_mapper.dart';

class TeamReportsRepositoryImpl implements TeamReportsRepository {
  final AppApiClient _api;
  final UserSession _session;

  TeamReportsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<TeamReportsPageData>> getPageData() async {
    final residenceId = _session.residenceId;
    final staff = await _api.get(
      ApiEndpoints.staffDirectory,
      query: {'residenceId': ?residenceId},
    );
    final staffBody = staff.isSuccess
        ? staff.value
        : (await _api.get(
            ApiEndpoints.staff,
            query: {'residenceId': ?residenceId},
          )).value;

    final extras = await Future.wait([
      _api.get(
        ApiEndpoints.attendance,
        query: {
          'status': 'present',
          'from': IsoDateRange.todayStartIso,
          'to': IsoDateRange.todayEndIso,
          'residenceId': ?residenceId,
        },
      ),
      _api.get(
        ApiEndpoints.shifts,
        query: {
          'status': 'open',
          'from': IsoDateRange.todayStartIso,
          'to': IsoDateRange.todayEndIso,
          'residenceId': ?residenceId,
        },
      ),
      _api.get(ApiEndpoints.reportsSummary),
      _api.get(ApiEndpoints.reportsKpis),
      _api.get(ApiEndpoints.conversations, query: const {'page': 1, 'limit': 20}),
    ]);

    return Result.success(
      TeamReportsMapper.compose(
        staffBody: staffBody,
        onDutyBody: extras[0].value,
        openShiftsBody: extras[1].value,
        summaryBody: extras[2].value,
        kpisBody: extras[3].value,
        conversationsBody: extras[4].value,
      ),
    );
  }
}
