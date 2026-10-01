import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/referral.dart';
import '../../domain/repositories/admissions_repository.dart';
import '../admissions_endpoints.dart';
import '../mappers/admissions_mapper.dart';

class AdmissionsRepositoryImpl implements AdmissionsRepository {
  final AppApiClient _api;

  AdmissionsRepositoryImpl({required AppApiClient api}) : _api = api;

  /// The web loads every residence in one page of the API maximum.
  static const int _maxPageLimit = 100;

  static Result<void> _done(Result<dynamic> result) => result.when(
        success: (_) => Result.success(null),
        failure: Result.failure,
      );

  Future<Result<void>> _post(String path, Map<String, dynamic> data) async =>
      _done(await _api.post(path, data: data, silent: true, allowQueue: false));

  Future<Result<void>> _patch(String path, Map<String, dynamic> data) async =>
      _done(await _api.patch(path, data: data, silent: true, allowQueue: false));

  Future<Result<void>> _put(String path, Map<String, dynamic> data) async =>
      _done(await _api.put(path, data: data, silent: true, allowQueue: false));

  @override
  Future<Result<ReferralBoard>> board() async {
    final result = await _api.get(AdmissionsEndpoints.board, silent: true);
    return result.when(
      success: (body) => Result.success(AdmissionsMapper.boardFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<ReferralPage>> referrals({
    required int page,
    required int limit,
    String? search,
    String? status,
  }) async {
    final result = await _api.get(
      AdmissionsEndpoints.referrals,
      query: {
        'page': page,
        'limit': limit,
        'search': ?search,
        'status': ?status,
      },
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(AdmissionsMapper.pageFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<Referral>> referral(String id) async {
    final result =
        await _api.get(AdmissionsEndpoints.referral(id), silent: true);
    return result.when(
      success: (body) {
        final referral =
            AdmissionsMapper.referralFrom(JsonCodec.unwrapMap(body));
        return referral == null
            ? Result.failure(
                const ApiError(message: 'Referral could not be read'),
              )
            : Result.success(referral);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> createReferral(Map<String, dynamic> body) =>
      _post(AdmissionsEndpoints.referrals, body);

  @override
  Future<Result<void>> updateReferral(String id, Map<String, dynamic> body) =>
      _patch(AdmissionsEndpoints.referral(id), body);

  @override
  Future<Result<void>> setContacts(
    String id,
    List<Map<String, dynamic>> contacts,
  ) =>
      _put(AdmissionsEndpoints.contacts(id), {'contacts': contacts});

  @override
  Future<Result<void>> setChecklist(String id, List<String> completed) =>
      _put(AdmissionsEndpoints.checklist(id), {'completed': completed});

  @override
  Future<Result<void>> addAssessment(
    String id, {
    required String summary,
    String? outcome,
  }) =>
      _post(AdmissionsEndpoints.assessments(id), {
        'summary': summary,
        'outcome': ?outcome,
      });

  @override
  Future<Result<void>> admit(
    String id, {
    required String residenceId,
    String? roomId,
    String? level,
  }) =>
      _post(AdmissionsEndpoints.admit(id), {
        'residenceId': residenceId,
        'roomId': ?roomId,
        'level': ?level,
      });

  @override
  Future<Result<void>> decline(String id, String reason) =>
      _post(AdmissionsEndpoints.decline(id), {'reason': reason});

  @override
  Future<Result<void>> deleteReferral(String id) async => _done(
        await _api.delete(
          AdmissionsEndpoints.referral(id),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<List<IntakeTemplate>>> templates({
    bool activeOnly = false,
  }) async {
    final result = await _api.get(
      AdmissionsEndpoints.intakeTemplates,
      query: {'activeOnly': activeOnly},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(AdmissionsMapper.templatesFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> createTemplate(Map<String, dynamic> body) =>
      _post(AdmissionsEndpoints.intakeTemplates, body);

  @override
  Future<Result<void>> updateTemplate(String id, Map<String, dynamic> body) =>
      _patch(AdmissionsEndpoints.template(id), body);

  @override
  Future<Result<List<AdmissionOption>>> residences() async {
    final result = await _api.get(
      AdmissionsEndpoints.residences,
      query: const {'page': 1, 'limit': _maxPageLimit},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(AdmissionsMapper.residencesFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<AdmissionRoom>>> rooms(String residenceId) async {
    final result =
        await _api.get(AdmissionsEndpoints.rooms(residenceId), silent: true);
    return result.when(
      success: (body) => Result.success(AdmissionsMapper.roomsFrom(body)),
      failure: Result.failure,
    );
  }
}
