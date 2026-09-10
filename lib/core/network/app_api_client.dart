import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../errors/app_error_dialog.dart';
import '../errors/app_error_mapper.dart';
import 'connectivity_monitor.dart';
import 'response_cache.dart';
import 'tenant_store.dart';

/// Thin wrapper over [ApiService] that attaches `X-Tenant-Subdomain`,
/// maps failures to readable errors, caches GET bodies for offline reads,
/// queues writes when the device is offline, and refreshes the access
/// token once on HTTP 401 before retrying the original request.
class AppApiClient {
  final ApiService _api;
  final TenantStore _tenant;
  final ResponseCache? _cache;
  final SyncService? _sync;
  final ConnectivityMonitor? _connectivity;

  /// Optional hook that exchanges the refresh token for a new access token.
  /// Wired from auth DI after [AuthRepository] is registered.
  Future<bool> Function()? tokenRefresher;

  /// Shared in-flight refresh so concurrent 401s only refresh once.
  Future<bool>? _refreshInFlight;

  AppApiClient(
    this._api,
    this._tenant, {
    ResponseCache? cache,
    SyncService? sync,
    ConnectivityMonitor? connectivity,
  })  : _cache = cache,
        _sync = sync,
        _connectivity = connectivity;

  Options _options({bool includeTenant = true}) {
    final headers = <String, dynamic>{};
    final subdomain = _tenant.subdomain;
    if (includeTenant && subdomain != null && subdomain.isNotEmpty) {
      headers['X-Tenant-Subdomain'] = subdomain;
    }
    return Options(headers: headers.isEmpty ? null : headers);
  }

  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) {
    return _send(
      method: 'GET',
      path: path,
      query: query,
      silent: silent,
      allowTokenRefresh: allowTokenRefresh,
      request: () => _api.get<dynamic>(
        path,
        queryParameters: query,
        options: _options(includeTenant: includeTenant),
      ),
    );
  }

  Future<Result<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      query: query,
      data: data,
      silent: silent,
      allowQueue: allowQueue,
      allowTokenRefresh: allowTokenRefresh,
      request: () => _api.post<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: _options(includeTenant: includeTenant),
      ),
    );
  }

  Future<Result<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) {
    return _send(
      method: 'PUT',
      path: path,
      query: query,
      data: data,
      silent: silent,
      allowQueue: allowQueue,
      allowTokenRefresh: allowTokenRefresh,
      request: () => _api.put<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: _options(),
      ),
    );
  }

  Future<Result<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) {
    return _send(
      method: 'PATCH',
      path: path,
      query: query,
      data: data,
      silent: silent,
      allowQueue: allowQueue,
      allowTokenRefresh: allowTokenRefresh,
      request: () => _api.patch<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: _options(),
      ),
    );
  }

  Future<Result<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      query: query,
      data: data,
      silent: silent,
      allowQueue: allowQueue,
      allowTokenRefresh: allowTokenRefresh,
      request: () => _api.delete<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: _options(),
      ),
    );
  }

  /// Replays writes queued while offline, with tenant + auth headers attached.
  Future<void> flushQueuedWrites() async {
    final sync = _sync;
    if (sync == null) return;
    final queue = await sync.getQueue();
    if (queue.isEmpty) return;

    final failed = <SyncItem>[];
    for (final item in queue) {
      final result = await _replay(item);
      if (result.isFailure) failed.add(item);
    }
    await sync.clearQueue();
    for (final item in failed) {
      await sync.addToQueue(item);
    }
  }

  Future<Result<dynamic>> _replay(SyncItem item) {
    final method = item.method.toUpperCase();
    switch (method) {
      case 'PUT':
        return put(item.endpoint, data: item.data, silent: true, allowQueue: false);
      case 'PATCH':
        return patch(item.endpoint, data: item.data, silent: true, allowQueue: false);
      case 'DELETE':
        return delete(item.endpoint, data: item.data, silent: true, allowQueue: false);
      default:
        return post(item.endpoint, data: item.data, silent: true, allowQueue: false);
    }
  }

  Future<Result<dynamic>> _send({
    required String method,
    required String path,
    required Future<ApiResponse<dynamic>> Function() request,
    Map<String, dynamic>? query,
    dynamic data,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
    bool alreadyRetriedAfterRefresh = false,
  }) async {
    final online = _isOnline;
    final canCache = _cacheable(method, path);
    final canQueue = allowQueue && _queueable(method, path);

    if (!online && method == 'GET' && canCache) {
      final cached = _cache?.get(method: method, path: path, query: query);
      if (cached != null) return Result.success(cached);
    }

    if (!online && canQueue) {
      await _enqueue(method, path, data);
      if (!silent) {
        await AppErrorDialog.showQueued(
          'You are offline. This change is saved on this device and will be sent when you are back online.',
        );
      }
      return Result.success(const {'offlineQueued': true});
    }

    if (!online) {
      final error = AppErrorMapper.toFriendly(
        const NetworkError(
          message: 'No connection',
          code: 'offline',
        ),
      );
      if (!silent) await AppErrorDialog.showError(error);
      return Result.failure(error);
    }

    try {
      final response = await request();
      if (!response.success) {
        final rawError = _errorFromResponse(response);

        // Expired / invalid access token → refresh once, then retry.
        if (allowTokenRefresh &&
            !alreadyRetriedAfterRefresh &&
            _isUnauthorized(rawError, response.statusCode) &&
            !_isAuthPath(path)) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            return _send(
              method: method,
              path: path,
              request: request,
              query: query,
              data: data,
              silent: silent,
              allowQueue: allowQueue,
              allowTokenRefresh: false,
              alreadyRetriedAfterRefresh: true,
            );
          }
        }

        final error = AppErrorMapper.toFriendly(rawError);
        if (method == 'GET' && canCache && _isOfflineError(error)) {
          final cached = _cache?.get(method: method, path: path, query: query);
          if (cached != null) return Result.success(cached);
        }
        if (canQueue && _isOfflineError(error)) {
          await _enqueue(method, path, data);
          if (!silent) {
            await AppErrorDialog.showQueued(
              'The care home could not be reached. This change is saved on this device and will be sent when you are back online.',
            );
          }
          return Result.success(const {'offlineQueued': true});
        }
        if (!silent) await AppErrorDialog.showError(error);
        return Result.failure(error);
      }

      if (canCache) {
        await _cache?.put(
          method: method,
          path: path,
          query: query,
          body: response.data,
        );
      }
      return Result.success(response.data);
    } catch (error, stackTrace) {
      final mapped = AppErrorMapper.toFriendly(
        NetworkError.fromException(error, stackTrace),
      );
      if (method == 'GET' && canCache && _isOfflineError(mapped)) {
        final cached = _cache?.get(method: method, path: path, query: query);
        if (cached != null) return Result.success(cached);
      }
      if (canQueue && _isOfflineError(mapped)) {
        await _enqueue(method, path, data);
        if (!silent) {
          await AppErrorDialog.showQueued(
            'The care home could not be reached. This change is saved on this device and will be sent when you are back online.',
          );
        }
        return Result.success(const {'offlineQueued': true});
      }
      if (!silent) await AppErrorDialog.showError(mapped);
      return Result.failure(mapped);
    }
  }

  Future<bool> _tryRefreshToken() async {
    final refresher = tokenRefresher;
    if (refresher == null) return false;

    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final future = () async {
      try {
        return await refresher();
      } catch (_) {
        return false;
      }
    }();
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  bool _isUnauthorized(AppError error, int? statusCode) {
    if (statusCode == 401) return true;
    if (error is AuthError && error.code == '401') return true;
    if (error is ApiError && error.statusCode == 401) return true;
    return false;
  }

  AppError _errorFromResponse(ApiResponse<dynamic> response) {
    final status = response.statusCode;
    final message = _resolveErrorMessage(response);
    if (status == 401) {
      return AuthError(message: message, code: '401');
    }
    if (status == 403) {
      return PermissionError(message: message, code: '403');
    }
    if (status == 400 || status == 422) {
      return ValidationError(
        message: message,
        fieldErrors: _fieldErrors(response.errors),
      );
    }
    if (status == null || status == 0) {
      return NetworkError(message: message, code: 'offline');
    }
    if (status == 408 || status == 504) {
      return NetworkError(message: message, code: '$status');
    }
    // Prefer ApiError for HTTP statuses (incl. 409 / 5xx) so the UI can show
    // the right copy instead of a generic offline dialog.
    return ApiError(
      message: message,
      statusCode: status,
      responseData: response.errors,
      code: '$status',
    );
  }

  String _resolveErrorMessage(ApiResponse<dynamic> response) {
    final errors = response.errors;
    if (errors != null) {
      final nested = errors['message'] ?? errors['error'];
      if (nested is String && nested.trim().isNotEmpty) return nested.trim();
      if (nested is Map) {
        final msg = nested['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
    }
    final raw = response.message?.trim() ?? '';
    if (raw.isNotEmpty &&
        !raw.contains('validateStatus') &&
        !raw.startsWith('DioException') &&
        !raw.toLowerCase().contains('this exception was thrown because')) {
      return raw;
    }
    return raw.isEmpty ? 'Request failed' : raw;
  }

  Map<String, List<String>>? _fieldErrors(Map<String, dynamic>? errors) {
    if (errors == null || errors.isEmpty) return null;
    final mapped = <String, List<String>>{};
    errors.forEach((key, value) {
      if (value is List) {
        mapped[key] = value.map((item) => item.toString()).toList();
      } else if (value != null) {
        mapped[key] = [value.toString()];
      }
    });
    return mapped.isEmpty ? null : mapped;
  }

  Future<void> _enqueue(String method, String path, dynamic data) async {
    final sync = _sync;
    if (sync == null) return;
    await sync.addToQueue(
      SyncItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-$path',
        method: method,
        endpoint: path,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  bool _cacheable(String method, String path) {
    if (method != 'GET') return false;
    return !_isAuthPath(path);
  }

  bool _queueable(String method, String path) {
    if (method == 'GET') return false;
    if (_isAuthPath(path)) return false;
    if (path.contains('change-password')) return false;
    return true;
  }

  bool _isAuthPath(String path) {
    return path.contains('/mobile/auth') ||
        path.contains('/public/tenant') ||
        path.contains('/auth/login') ||
        path.contains('/auth/logout');
  }

  bool get _isOnline {
    final injected = _connectivity;
    if (injected != null) return injected.online;
    if (Get.isRegistered<ConnectivityMonitor>()) {
      return Get.find<ConnectivityMonitor>().online;
    }
    return true;
  }

  bool _isOfflineError(AppError error) {
    if (error.code == 'offline' || error.code == '0') return true;
    return AppErrorMapper.from(error).isOffline;
  }
}
