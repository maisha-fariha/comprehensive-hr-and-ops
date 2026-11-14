import 'package:gems_core/gems_core.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/app_api_client.dart';
import '../../../../core/network/json_codec.dart';
import '../domain/users_access_models.dart';

/// Users & Access API surface (web `/dashboard/users` parity).
class UsersAccessRepository {
  final AppApiClient _api;

  UsersAccessRepository({AppApiClient? api})
      : _api = api ?? GetIt.instance<AppApiClient>();

  Future<Result<DirectoryPage>> fetchDirectory({
    int page = 1,
    int limit = 50,
    String? search,
    String? userType,
    String? roleCode,
    String? status,
    String? residenceId,
    bool? hasLogin,
    bool includeInactive = false,
  }) async {
    final trimmedSearch = search?.trim();
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (trimmedSearch != null && trimmedSearch.isNotEmpty)
        'search': trimmedSearch,
      if (userType != null && userType.isNotEmpty) 'userType': userType,
      if (roleCode != null && roleCode.isNotEmpty) 'roleCode': roleCode,
      if (status != null && status.isNotEmpty) 'status': status,
      if (residenceId != null && residenceId.isNotEmpty)
        'residenceId': residenceId,
      'hasLogin': ?hasLogin,
      if (includeInactive) 'includeInactive': true,
    };
    final result = await _api.get(
      ApiEndpoints.usersDirectory,
      query: query,
      silent: true,
    );
    return result.when(
      success: (body) {
        final map = body is Map ? JsonCodec.asMap(body) : <String, dynamic>{};
        final meta = JsonCodec.mapAt(map, 'meta') ?? const {};
        // Prefer org-wide `totals` so metric chips / Worth a look stay stable
        // when the list is filtered (page `summary` shrinks with the query).
        final summary = DirectorySummary.fromJson(
          JsonCodec.mapAt(meta, 'totals') ??
              JsonCodec.mapAt(meta, 'summary') ??
              const {},
        );
        final rows = JsonCodec.unwrapList(body).whereType<Map>();
        final people = [
          for (final row in rows)
            DirectoryPerson.fromJson(JsonCodec.asMap(row)),
        ];
        final total = () {
          final raw = meta['total'];
          if (raw is int) return raw;
          if (raw is num) return raw.toInt();
          return people.length;
        }();
        return Result.success(
          DirectoryPage(people: people, summary: summary, total: total),
        );
      },
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<List<StaffCategoryItem>>> fetchStaffCategories({
    bool includeArchived = true,
  }) async {
    final result = await _api.get(ApiEndpoints.staffCategories, silent: true);
    return result.when(
      success: (body) {
        final rows = JsonCodec.unwrapList(body).whereType<Map>();
        final items = [
          for (final row in rows)
            StaffCategoryItem.fromJson(JsonCodec.asMap(row)),
        ];
        if (includeArchived) return Result.success(items);
        return Result.success([for (final i in items) if (i.isActive) i]);
      },
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<StaffCategoryItem>> createStaffCategory({
    required String name,
    String residenceType = 'group_home',
  }) async {
    final result = await _api.post(
      ApiEndpoints.staffCategories,
      data: {
        'name': name.trim(),
        'residenceType': residenceType,
      },
    );
    return result.when(
      success: (body) {
        final map = JsonCodec.unwrapMap(body);
        return Result.success(StaffCategoryItem.fromJson(map));
      },
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> updateStaffCategory({
    required String id,
    required String name,
    String? residenceType,
  }) async {
    final result = await _api.patch(
      ApiEndpoints.staffCategoryById(id),
      data: {
        'name': name.trim(),
        if (residenceType != null && residenceType.isNotEmpty)
          'residenceType': residenceType,
      },
    );
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> archiveStaffCategory(String id) async {
    final result = await _api.post(ApiEndpoints.staffCategoryArchive(id));
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> restoreStaffCategory(String id) async {
    final result = await _api.post(ApiEndpoints.staffCategoryRestore(id));
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> onboardUser(Map<String, dynamic> body) async {
    final result = await _api.post(ApiEndpoints.usersOnboard, data: body);
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> inviteUser({
    required String email,
    required String name,
    List<String>? roleIds,
  }) async {
    final result = await _api.post(
      ApiEndpoints.usersInvite,
      data: {
        'email': email.trim(),
        'name': name.trim(),
        if (roleIds != null && roleIds.isNotEmpty) 'roleIds': roleIds,
      },
    );
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> deactivateUser(String userId) async {
    final result = await _api.post(ApiEndpoints.userDeactivate(userId));
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> reactivateUser(String userId) async {
    final result = await _api.post(ApiEndpoints.userReactivate(userId));
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> sendPasswordReset(String userId) async {
    final result = await _api.post(ApiEndpoints.userSendPasswordReset(userId));
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> replaceUserRoles({
    required String userId,
    required List<String> roleIds,
  }) async {
    final result = await _api.put(
      ApiEndpoints.userRoles(userId),
      data: {'roleIds': roleIds},
    );
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<List<({String id, String name})>>> fetchResidences() async {
    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) {
        final rows = JsonCodec.unwrapList(body).whereType<Map>();
        return Result.success([
          for (final row in rows)
            (
              id: JsonCodec.stringOr(JsonCodec.asMap(row)['id'], ''),
              name: JsonCodec.stringOr(JsonCodec.asMap(row)['name'], ''),
            ),
        ].where((r) => r.id.isNotEmpty).toList());
      },
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<List<({String id, String name, String code})>>> fetchRoles() async {
    final result = await _api.get(ApiEndpoints.roles, silent: true);
    return result.when(
      success: (body) {
        final rows = JsonCodec.unwrapList(body).whereType<Map>();
        return Result.success([
          for (final row in rows)
            (
              id: JsonCodec.stringOr(JsonCodec.asMap(row)['id'], ''),
              name: JsonCodec.stringOr(JsonCodec.asMap(row)['name'], ''),
              code: JsonCodec.stringOr(JsonCodec.asMap(row)['code'], ''),
            ),
        ].where((r) => r.id.isNotEmpty).toList());
      },
      failure: (error) => Result.failure(error),
    );
  }

  String messageOf(ApiError? error) =>
      error?.message ?? 'Something went wrong';
}
