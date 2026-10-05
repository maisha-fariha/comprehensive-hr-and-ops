import 'package:dio/dio.dart';
import '../utils/api_config.dart';
import '../utils/api_response.dart';

/// REST API Service for CRUD operations
class ApiService {
  late Dio _dio;
  final ApiConfig config;
  String? _authToken;

  ApiService(this.config) {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...config.defaultHeaders,
        },
        connectTimeout: config.timeout,
        receiveTimeout: config.timeout,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          if (config.enableLogging) {
            print('REQUEST[${options.method}] => PATH: ${options.path}');
            print('Headers: ${options.headers}');
            if (options.data != null) {
              print('Data: ${options.data}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (config.enableLogging) {
            print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
            print('Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (config.enableLogging) {
            print('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
            print('Message: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Handle successful response
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      try {
        final data = fromJson != null ? fromJson(response.data) : response.data as T;
        return ApiResponse.success(
          data,
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse.error(
          'Failed to parse response: $e',
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.error(
      _bodyMessage(response.data) ?? 'Request failed',
      statusCode: response.statusCode,
      errors: _bodyErrors(response.data),
    );
  }

  /// Top-level `message`, or the `{ error: { message } }` envelope.
  String? _bodyMessage(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    final error = data['error'];
    if (error is Map) {
      final nested = error['message'];
      if (nested is String && nested.trim().isNotEmpty) return nested;
    }
    if (error is String && error.trim().isNotEmpty) return error;
    return null;
  }

  /// Top-level `errors`, or `{ error: { details: { fieldErrors } } }`.
  Map<String, dynamic>? _bodyErrors(dynamic data) {
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is Map<String, dynamic>) return errors;
    final error = data['error'];
    if (error is Map) {
      final details = error['details'];
      if (details is Map) {
        final fieldErrors = details['fieldErrors'];
        if (fieldErrors is Map && fieldErrors.isNotEmpty) {
          return Map<String, dynamic>.from(fieldErrors);
        }
      }
    }
    return null;
  }

  /// Handle error response
  ApiResponse<T> _handleError<T>(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      
      // Handle different error types
      String message;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        message = 'Connection timeout. Please check your internet connection.';
      } else if (error.type == DioExceptionType.connectionError) {
        message = 'Connection error. Unable to reach the server.';
      } else if (error.type == DioExceptionType.badResponse) {
        message = _bodyMessage(error.response?.data) ??
            error.message ??
            'Server error occurred';
      } else {
        message = error.message ?? 'Network error occurred';
      }

      return ApiResponse.error(
        message,
        statusCode: statusCode ?? 500,
        errors: _bodyErrors(error.response?.data),
      );
    }

    return ApiResponse.error(
      error.toString(),
      statusCode: 500,
    );
  }
}

