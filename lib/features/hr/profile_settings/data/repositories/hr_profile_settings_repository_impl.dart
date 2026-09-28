import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/hr_profile_settings_overview.dart';
import '../../domain/repositories/hr_profile_settings_repository.dart';
import '../mappers/hr_profile_mapper.dart';

class HrProfileSettingsRepositoryImpl implements HrProfileSettingsRepository {
  final AppApiClient _api;
  final UserSession _session;

  HrProfileSettingsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<HrProfileSettingsOverview>> getOverview() async {
    final residences = await _api.get(ApiEndpoints.residences);
    if (residences.isFailure) {
      return Result.failure(
        residences.error ??
            const ApiError(message: 'Could not load managed residences.'),
      );
    }

    final prefs = await _api.get(ApiEndpoints.notificationPreferences);
    final prefsMap = prefs.isSuccess
        ? JsonCodec.unwrapMap(prefs.value)
        : <String, dynamic>{};
    final push = JsonCodec.boolean(
          prefsMap['push'] ??
              prefsMap['pushEnabled'] ??
              prefsMap['pushNotifications'] ??
              prefsMap['pushNotificationsEnabled'],
        ) ??
        true;

    return Result.success(
      HrProfileMapper.compose(
        session: _session,
        residencesBody: residences.value,
        pushNotificationsEnabled: push,
      ),
    );
  }

  @override
  Future<Result<void>> createSupportTicket({
    required String subject,
    required String body,
  }) async {
    final result = await _api.post(
      ApiEndpoints.tickets,
      data: {'subject': subject, 'body': body},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<Map<String, bool>>> getNotificationPreferences() async {
    final result = await _api.get(ApiEndpoints.notificationPreferences);
    return result.when(
      success: (body) async {
        final json = JsonCodec.unwrapMap(body);
        final nested = JsonCodec.mapAt(json, 'preferences') ?? json;
        final values = <String, bool>{};
        nested.forEach((key, value) {
          final parsed = JsonCodec.boolean(value);
          if (parsed != null) values[key] = parsed;
        });
        return Result.success(values);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> updateNotificationPreferences(
    Map<String, bool> values,
  ) async {
    final result = await _api.patch(
      ApiEndpoints.notificationPreferences,
      data: values,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _api.post(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String?>> updateAvatar({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final upload = await _api.post(
        ApiEndpoints.uploads,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: fileName),
        }),
        query: const {'category': 'avatars'},
        allowQueue: false,
        silent: true,
      );

      if (upload.isSuccess) {
        final map = JsonCodec.unwrapMap(upload.value);
        final fileUrl = JsonCodec.string(
          map['fileUrl'] ?? map['url'] ?? map['publicUrl'],
        );
        if (fileUrl == null) {
          return Result.failure(
            const ApiError(message: 'Upload succeeded but the photo URL was missing.'),
          );
        }
        final patched = await _api.patch(
          ApiEndpoints.authAvatar,
          data: {'avatarUrl': fileUrl},
          allowQueue: false,
        );
        return patched.when(
          success: (body) async => Result.success(_avatarUrlFrom(body) ?? fileUrl),
          failure: (error) async => Result.failure(error),
        );
      }

      // Accounts without upload permission: send the file to the avatar
      // endpoint directly.
      final direct = await _api.patch(
        ApiEndpoints.authAvatar,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: fileName),
        }),
        allowQueue: false,
        silent: true,
      );
      return direct.when(
        success: (body) async => Result.success(_avatarUrlFrom(body)),
        failure: (_) async => Result.failure(
          upload.error ?? const ApiError(message: 'Could not upload the photo.'),
        ),
      );
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Could not read the selected photo.'),
      );
    }
  }

  @override
  Future<Result<void>> removeAvatar() async {
    final result = await _api.patch(
      ApiEndpoints.authAvatar,
      data: const {'avatarUrl': null},
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  String? _avatarUrlFrom(dynamic body) {
    final map = JsonCodec.unwrapMap(body);
    return JsonCodec.string(
      map['avatarUrl'] ?? JsonCodec.mapAt(map, 'user')?['avatarUrl'],
    );
  }
}
