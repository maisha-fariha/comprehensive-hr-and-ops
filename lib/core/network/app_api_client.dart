import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import 'tenant_store.dart';

/// Thin wrapper over [ApiService] that attaches `X-Tenant-Subdomain` and
/// converts [ApiResponse] into [Result].
class AppApiClient {
  final ApiService _api;
  final TenantStore _tenant;

  AppApiClient(this._api, this._tenant);

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
  }) {
    return _send(
      () => _api.get<dynamic>(
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
  }) {
    return _send(
      () => _api.post<dynamic>(
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
  }) {
    return _send(
      () => _api.put<dynamic>(
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
  }) {
    return _send(
      () => _api.patch<dynamic>(
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
  }) {
    return _send(
      () => _api.delete<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: _options(),
      ),
    );
  }

  Future<Result<dynamic>> _send(
    Future<ApiResponse<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      if (!response.success) {
        return Result.failure(
          ApiError(
            message: response.message ?? 'Request failed',
            statusCode: response.statusCode,
            responseData: response.errors,
          ),
        );
      }
      return Result.success(response.data);
    } catch (error, stackTrace) {
      return Result.failure(NetworkError.fromException(error, stackTrace));
    }
  }
}
