import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../errors/app_error_dialog.dart';
import '../errors/app_error_mapper.dart';
import '../errors/app_snackbar.dart';
import '../offline/offline_config.dart';
import '../offline/offline_outbox.dart';
import '../offline/offline_overlay.dart';
import '../offline/outbox_attachments.dart';
import '../offline/outbox_context.dart';
import '../offline/outbox_feature.dart';
import '../offline/outbox_sync_engine.dart';
import '../roles/user_role.dart';
import '../roles/user_session.dart';
import 'connectivity_monitor.dart';
import 'response_cache.dart';
import 'tenant_store.dart';

/// Thin wrapper over [ApiService] that attaches `X-Tenant-Subdomain`,
/// maps failures to readable errors, caches GET bodies for offline reads,
/// queues writes when the device is offline, and refreshes the access
/// token once on HTTP 401 before retrying the original request.
class AppApiClient implements OutboxTransport {
  final ApiService _api;
  final TenantStore _tenant;
  final ResponseCache? _cache;
  final SyncService? _sync;
  final ConnectivityMonitor? _connectivity;

  /// Durable offline outbox. When null the legacy [SyncService] queue is used.
  OfflineOutbox? outbox;

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
    this.outbox,
  })  : _cache = cache,
        _sync = sync,
        _connectivity = connectivity;

  Options _options({
    bool includeTenant = true,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, dynamic>{
      if (!kIsWeb || OfflineConfig.sendClientHeadersOnWeb) ...?extraHeaders,
    };
    final subdomain = _tenant.subdomain;
    if (includeTenant && subdomain != null && subdomain.isNotEmpty) {
      headers['X-Tenant-Subdomain'] = subdomain;
    }
    return Options(headers: headers.isEmpty ? null : headers);
  }

  /// Per-call identity for a write: the same key is reused if the write ends
  /// up queued, so the server can drop a duplicate replay.
  _WriteIdentity? _writeIdentity(String method, String path) {
    if (outbox == null || method == 'GET') return null;
    if (OutboxFeature.isNeverQueued(path) && !_isUploadPath(path)) return null;
    return _WriteIdentity(outbox!.newIdempotencyKey(), DateTime.now());
  }

  bool _isUploadPath(String path) => path == '/uploads';

  /// Avatar uploads feed `/auth/avatar`, which is never queued, so a
  /// placeholder URL could not be used.
  bool _stagesWhenOffline(String path, Map<String, dynamic>? query) =>
      _isUploadPath(path) && query?['category'] != 'avatars';

  /// Swaps temp ids of offline creates that have since reached the server.
  String _resolvePath(String path) => outbox?.resolveTempIds(path) ?? path;

  T _resolveJson<T>(T node) {
    final queue = outbox;
    if (queue == null || queue.engine.resolvedTempIds.isEmpty) return node;
    dynamic walk(dynamic value) {
      if (value is String) return queue.resolveTempIds(value);
      if (value is Map) return value.map((k, v) => MapEntry(k, walk(v)));
      if (value is List) return [for (final v in value) walk(v)];
      return value;
    }

    if (node is Map<String, dynamic>) {
      return Map<String, dynamic>.from(walk(node) as Map) as T;
    }
    if (node is Map || node is List) return walk(node) as T;
    return node;
  }

  /// True when [path], [query] or [data] still points at a record created
  /// offline that the server has not received yet.
  bool _referencesUnsentRecord(
    String path,
    Map<String, dynamic>? query,
    dynamic data,
  ) {
    final queue = outbox;
    if (queue == null) return false;
    final probe = '$path ${query ?? ''} ${data is FormData ? '' : data ?? ''}';
    if (!probe.contains(OfflineOverlay.tempIdPrefix)) return false;
    return queue.unresolvedTempIds.any(probe.contains);
  }

  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) {
    path = _resolvePath(path);
    query = _resolveJson(query);
    if (_referencesUnsentRecord(path, query, null)) {
      return Future.value(Result.success(
        OfflineOverlay.forTempPath(path, outbox!.overlayItems),
      ));
    }
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

  /// File uploads (and any upload inside `OutboxContext.run(stageUploads:
  /// true)`) are kept on the device while offline and answered with a
  /// placeholder URL; a queued write that references it uploads the file
  /// first on replay.
  Future<Result<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) =>
      _post(
        path,
        data: data,
        query: query,
        includeTenant: includeTenant,
        silent: silent,
        allowQueue: allowQueue,
        allowTokenRefresh: allowTokenRefresh,
      );

  /// A [post] whose `Idempotency-Key` is [idempotencyKey], so a form can
  /// reuse one key across its retries and the server keeps a single record
  /// when an earlier attempt did get through.
  Future<Result<dynamic>> postWithKey(
    String path, {
    required String idempotencyKey,
    dynamic data,
    bool silent = false,
  }) =>
      _post(
        path,
        data: data,
        silent: silent,
        allowQueue: false,
        identity: _WriteIdentity(idempotencyKey, DateTime.now()),
      );

  Future<Result<dynamic>> _post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
    _WriteIdentity? identity,
  }) {
    path = _resolvePath(path);
    query = _resolveJson(query);
    data = _resolveJson(data);
    identity ??= _writeIdentity('POST', path);
    final staging = data is FormData &&
            outbox != null &&
            (OutboxContext.stageUploads || _stagesWhenOffline(path, query))
        ? data.clone()
        : null;
    return _send(
      method: 'POST',
      path: path,
      query: query,
      data: data,
      silent: silent,
      allowQueue: allowQueue,
      allowTokenRefresh: allowTokenRefresh,
      identity: identity,
      stagingForm: staging,
      request: () => _api.post<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: _options(
          includeTenant: includeTenant,
          extraHeaders: identity?.headers,
        ),
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
    path = _resolvePath(path);
    query = _resolveJson(query);
    data = _resolveJson(data);
    final identity = _writeIdentity('PUT', path);
    return _send(
      method: 'PUT',
      path: path,
      query: query,
      data: data,
      silent: silent,
      allowQueue: allowQueue,
      allowTokenRefresh: allowTokenRefresh,
      identity: identity,
      request: () => _api.put<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: _options(extraHeaders: identity?.headers),
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
    path = _resolvePath(path);
    query = _resolveJson(query);
    data = _resolveJson(data);
    final identity = _writeIdentity('PATCH', path);
    return _send(
      method: 'PATCH',
      path: path,
      query: query,
      data: data,
      silent: silent,
      allowQueue: allowQueue,
      allowTokenRefresh: allowTokenRefresh,
      identity: identity,
      request: () => _api.patch<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: _options(extraHeaders: identity?.headers),
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
    path = _resolvePath(path);
    query = _resolveJson(query);
    data = _resolveJson(data);
    final identity = _writeIdentity('DELETE', path);
    return _send(
      method: 'DELETE',
      path: path,
      query: query,
      data: data,
      silent: silent,
      allowQueue: allowQueue,
      allowTokenRefresh: allowTokenRefresh,
      identity: identity,
      request: () => _api.delete<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: _options(extraHeaders: identity?.headers),
      ),
    );
  }

  /// Raw replay channel for the outbox: no queueing, no dialogs, one token
  /// refresh on 401, classified outcome.
  @override
  Future<OutboxSendResult> send({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    dynamic data,
    required Map<String, String> headers,
  }) async {
    Future<ApiResponse<dynamic>> attempt(dynamic body) {
      final options = _options(extraHeaders: headers);
      switch (method.toUpperCase()) {
        case 'PUT':
          return _api.put<dynamic>(path,
              data: body, queryParameters: query, options: options);
        case 'PATCH':
          return _api.patch<dynamic>(path,
              data: body, queryParameters: query, options: options);
        case 'DELETE':
          return _api.delete<dynamic>(path,
              data: body, queryParameters: query, options: options);
        default:
          return _api.post<dynamic>(path,
              data: body, queryParameters: query, options: options);
      }
    }

    final retryBody = data is FormData ? data.clone() : data;
    try {
      var response = await attempt(data);
      if (!response.success && response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) response = await attempt(retryBody);
      }
      if (response.success) {
        _connectivity?.reportReachable();
        return OutboxSendResult(
          kind: OutboxSendKind.success,
          statusCode: response.statusCode,
          body: response.data,
        );
      }
      final error = _errorFromResponse(response);
      final kind = OutboxSendResult.classify(response.statusCode);
      if (kind == OutboxSendKind.retryable) {
        _connectivity?.reportUnreachable();
      }
      return OutboxSendResult(
        kind: kind,
        statusCode: response.statusCode,
        message: AppErrorMapper.from(AppErrorMapper.toFriendly(error)).message,
        body: response.errors,
      );
    } catch (error) {
      _connectivity?.reportUnreachable();
      return OutboxSendResult(
        kind: OutboxSendKind.retryable,
        message: 'Could not reach the server.',
      );
    }
  }

  /// Replays writes queued while offline, with tenant + auth headers attached.
  Future<void> flushQueuedWrites() async {
    final durable = outbox;
    if (durable != null) {
      await durable.engine.flush(ignoreBackoff: true);
      return;
    }
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
    _WriteIdentity? identity,
    FormData? stagingForm,
  }) async {
    silent = silent || OutboxContext.silent;
    final online = _isOnline;
    final canCache = _cacheable(method, path);
    // With the durable outbox every eligible write is kept while offline;
    // `allowQueue: false` only applies to the legacy queue.
    final canQueue =
        (allowQueue || outbox != null) && _queueable(method, path);

    if (!online && method == 'GET' && canCache) {
      final cached = await _readCache(method, path, query);
      if (cached != null) return Result.success(cached);
    }

    // A write that references a file kept on this device, or a record
    // created offline, must go through the outbox (which sends those
    // first, in order), even if we are back online.
    if (method != 'GET' &&
        outbox != null &&
        data is! FormData &&
        (StagedUploadStore.referencedIds(data).isNotEmpty ||
            _referencesUnsentRecord(path, query, data))) {
      final queued = canQueue
          ? await _enqueue(method, path, data, query: query, identity: identity)
          : null;
      if (queued != null) {
        if (online) {
          unawaited(outbox!.engine.flush(ignoreBackoff: true));
          await _showQueued(
            'Saved on this device. It will be sent in a moment.',
            silent: silent,
          );
        } else {
          await _showQueued(
            'You are offline. This change is saved on this device and will be sent when you are back online.',
            silent: silent,
          );
        }
        return Result.success(queued.response);
      }
      final error = AppErrorMapper.toFriendly(
        const NetworkError(
          message: 'An attachment saved offline could not be sent.',
          code: 'offline',
        ),
      );
      await _showError(error, silent: silent);
      return Result.failure(error);
    }

    if (!online && stagingForm != null) {
      final staged = await _stage(stagingForm, path, query);
      if (staged != null) return Result.success(staged);
    }

    if (!online && canQueue) {
      final queued =
          await _enqueue(method, path, data, query: query, identity: identity);
      if (queued != null) {
        await _showQueued(
          'You are offline. This change is saved on this device and will be sent when you are back online.',
          silent: silent,
        );
        return Result.success(queued.response);
      }
    }

    if (!online) {
      final error = method == 'GET' && canCache
          ? _uncachedReadError()
          : AppErrorMapper.toFriendly(
              const NetworkError(
                message: 'No connection',
                code: 'offline',
              ),
            );
      await _showError(
        error,
        silent: silent || (outbox != null && _isBackgroundPath(path)),
      );
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
            return await _send(
              method: method,
              path: path,
              request: request,
              query: query,
              data: data,
              silent: silent,
              allowQueue: allowQueue,
              allowTokenRefresh: false,
              alreadyRetriedAfterRefresh: true,
              identity: identity,
              stagingForm: stagingForm,
            );
          }
        }

        var error = AppErrorMapper.toFriendly(rawError);
        if (_isOfflineError(error)) {
          _connectivity?.reportUnreachable();
        } else {
          _connectivity?.reportReachable();
        }
        if (method == 'GET' && canCache && _canServeSavedCopy(error)) {
          final cached = await _readCache(method, path, query);
          if (cached != null) return Result.success(cached);
          if (outbox != null && _isOfflineError(error)) {
            error = _uncachedReadError();
          }
        }
        if (stagingForm != null && _isOfflineError(error)) {
          final staged = await _stage(stagingForm, path, query);
          if (staged != null) return Result.success(staged);
        }
        final queued = canQueue && _isOfflineError(error)
            ? await _enqueue(method, path, data, query: query, identity: identity)
            : null;
        if (queued != null) {
          await _showQueued(
            'The care home could not be reached. This change is saved on this device and will be sent when you are back online.',
            silent: silent,
          );
          return Result.success(queued.response);
        }
        await _showError(
          error,
          silent: silent ||
              (outbox != null &&
                  _isBackgroundPath(path) &&
                  _isOfflineError(error)),
        );
        return Result.failure(error);
      }

      _connectivity?.reportReachable();
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
      var mapped = AppErrorMapper.toFriendly(
        NetworkError.fromException(error, stackTrace),
      );
      if (_isOfflineError(mapped)) _connectivity?.reportUnreachable();
      if (method == 'GET' && canCache && _canServeSavedCopy(mapped)) {
        final cached = await _readCache(method, path, query);
        if (cached != null) return Result.success(cached);
        if (outbox != null && _isOfflineError(mapped)) {
          mapped = _uncachedReadError();
        }
      }
      if (stagingForm != null && _isOfflineError(mapped)) {
        final staged = await _stage(stagingForm, path, query);
        if (staged != null) return Result.success(staged);
      }
      final queued = canQueue && _isOfflineError(mapped)
          ? await _enqueue(method, path, data, query: query, identity: identity)
          : null;
      if (queued != null) {
        await _showQueued(
          'The care home could not be reached. This change is saved on this device and will be sent when you are back online.',
          silent: silent,
        );
        return Result.success(queued.response);
      }
      await _showError(
        mapped,
        silent: silent ||
            (outbox != null &&
                _isBackgroundPath(path) &&
                _isOfflineError(mapped)),
      );
      return Result.failure(mapped);
    }
  }

  Future<dynamic> _readCache(
    String method,
    String path,
    Map<String, dynamic>? query,
  ) async {
    final cache = _cache;
    if (cache == null) return null;
    final cached = await cache.read(method: method, path: path, query: query);
    if (cached == null) return null;
    cache.lastServedSavedAt.value = cached.savedAt;
    final queue = outbox;
    if (queue == null) return cached.body;
    try {
      return OfflineOverlay.apply(
        path: path,
        body: cached.body,
        items: queue.overlayItems,
        skipAppendTags: _tagsWithOwnPendingList,
      );
    } catch (_) {
      return cached.body;
    }
  }

  /// Staff screens that already list pending creates in their own section.
  Set<String> get _tagsWithOwnPendingList {
    if (!Get.isRegistered<UserSession>() ||
        Get.find<UserSession>().role != UserRole.staff) {
      return const {};
    }
    return const {
      OutboxFeature.dailyLogs,
      OutboxFeature.attendance,
      OutboxFeature.incidents,
      OutboxFeature.mar,
      OutboxFeature.medications,
      OutboxFeature.tasks,
      OutboxFeature.recurringChecks,
    };
  }

  AppError _uncachedReadError() {
    if (outbox == null) {
      return AppErrorMapper.toFriendly(
        const NetworkError(message: 'No connection', code: 'offline'),
      );
    }
    return AppErrorMapper.toFriendly(
      const NetworkError(message: 'No connection', code: 'offline_uncached'),
    );
  }

  Future<Map<String, dynamic>?> _stage(
    FormData form,
    String path,
    Map<String, dynamic>? query,
  ) async {
    final queue = outbox;
    if (queue == null) return null;
    return queue.stageUpload(form: form, path: path, query: query);
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
      // Some tenants put validation copy under details.formErrors.
      final details = errors['details'];
      if (details is Map) {
        final formErrors = details['formErrors'];
        if (formErrors is List && formErrors.isNotEmpty) {
          return formErrors.map((e) => e.toString()).join(' ');
        }
      }
    }
    final raw = response.message?.trim() ?? '';
    if (raw.contains('subtype of type') ||
        raw.contains('is not a subtype') ||
        raw.startsWith('type \'')) {
      return 'Request failed. Please try again.';
    }
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

  /// Non-null when the write was stored for a later replay.
  Future<_Queued?> _enqueue(
    String method,
    String path,
    dynamic data, {
    Map<String, dynamic>? query,
    _WriteIdentity? identity,
  }) async {
    final queue = outbox;
    if (queue != null) {
      final item = await queue.enqueue(
        method: method,
        path: path,
        query: query,
        data: data,
        idempotencyKey: identity?.key ?? queue.newIdempotencyKey(),
        occurredAt: identity?.occurredAt,
        tempId: method == 'POST' ? queue.newTempId() : null,
      );
      if (item == null) return null;
      return _Queued({
        ...OfflineOverlay.recordFor(item),
        'offlineQueued': true,
      });
    }
    const legacy = _Queued({'offlineQueued': true});
    final sync = _sync;
    if (sync == null) return legacy;
    try {
      await sync.addToQueue(
        SyncItem(
          id: '${DateTime.now().microsecondsSinceEpoch}-$path',
          method: method,
          endpoint: path,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
      return legacy;
    } catch (_) {
      return null;
    }
  }

  bool _cacheable(String method, String path) {
    if (method != 'GET') return false;
    // SIN and banking numbers must never be written to the device.
    if (path.endsWith('/sensitive')) return false;
    return !_isAuthPath(path);
  }

  bool _queueable(String method, String path) {
    if (method == 'GET') return false;
    if (_isAuthPath(path)) return false;
    if (path.contains('change-password')) return false;
    if (outbox != null && OutboxFeature.isNeverQueued(path)) return false;
    return true;
  }

  /// Background calls (push device registration) stay quiet when offline;
  /// they re-sync after the next sign-in / app start.
  bool _isBackgroundPath(String path) => path.startsWith('/devices');

  bool _isAuthPath(String path) {
    return path.contains('/mobile/auth') ||
        path.contains('/public/tenant') ||
        path.contains('/auth/login') ||
        path.contains('/auth/logout');
  }

  bool get _suppressErrorDialogs {
    try {
      if (Get.isRegistered<UserSession>() &&
          Get.find<UserSession>().isSigningOut) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _showError(AppError error, {required bool silent}) async {
    if (silent || _suppressErrorDialogs) return;
    await AppErrorDialog.showError(error);
  }

  /// Non-blocking notice. Briefly holds other snackbars so a feature's own
  /// "Saved" message does not hide that the change is still on the device.
  Future<void> _showQueued(String message, {required bool silent}) async {
    if (silent || _suppressErrorDialogs) return;
    if (outbox == null) {
      await AppErrorDialog.showQueued(message);
      return;
    }
    AppSnackbar.show('Saved on this device', message, force: true);
    AppSnackbar.holdFor(const Duration(seconds: 3));
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

  /// A screen can keep showing its last saved copy when the care home is
  /// unreachable or answering with a server error.
  bool _canServeSavedCopy(AppError error) {
    if (_isOfflineError(error)) return true;
    final status = error is ApiError
        ? error.statusCode
        : int.tryParse(error.code ?? '');
    return status != null && status >= 500;
  }
}

/// A write kept for later, with the response handed back to the caller.
class _Queued {
  final Map<String, dynamic> response;

  const _Queued(this.response);
}

class _WriteIdentity {
  final String key;
  final DateTime occurredAt;

  const _WriteIdentity(this.key, this.occurredAt);

  Map<String, String> get headers => {
        OfflineConfig.idempotencyHeader: key,
        OfflineConfig.occurredAtHeader: occurredAt.toUtc().toIso8601String(),
      };
}
