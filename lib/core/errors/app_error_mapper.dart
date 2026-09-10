import 'package:gems_core/gems_core.dart';

/// User-facing copy for a failure, derived from [AppError] / HTTP status.
class AppErrorInfo {
  final String title;
  final String message;
  final bool isOffline;
  final bool isAuth;
  final bool canRetry;

  const AppErrorInfo({
    required this.title,
    required this.message,
    this.isOffline = false,
    this.isAuth = false,
    this.canRetry = true,
  });
}

abstract final class AppErrorMapper {
  static AppErrorInfo from(AppError? error, {String? fallbackTitle}) {
    if (error == null) {
      return AppErrorInfo(
        title: fallbackTitle ?? 'Something went wrong',
        message: 'Please try again in a moment.',
      );
    }

    if (error.code == 'offline_queued') {
      return AppErrorInfo(
        title: 'Saved on this device',
        message: error.message,
        isOffline: true,
        canRetry: false,
      );
    }

    if (error is AuthError || error is PermissionError) {
      return AppErrorInfo(
        title: error is PermissionError ? 'Access denied' : 'Sign-in needed',
        message: _clean(error.message),
        isAuth: true,
        canRetry: error is! PermissionError,
      );
    }

    if (error is ValidationError) {
      return AppErrorInfo(
        title: 'Check your details',
        message: _validationMessage(error),
        canRetry: false,
      );
    }

    if (error is ApiError) {
      return _fromStatus(
        statusCode: error.statusCode,
        raw: error.message,
        fallbackTitle: fallbackTitle,
      );
    }

    // NetworkError may carry an HTTP status in [code] (e.g. "500", "409")
    // when AppApiClient maps server failures that way.
    if (error is NetworkError) {
      final status = int.tryParse(error.code ?? '');
      if (status != null && status > 0) {
        return _fromStatus(
          statusCode: status,
          raw: error.message,
          fallbackTitle: fallbackTitle,
        );
      }
      if (error.code == 'offline' ||
          error.code == '0' ||
          (_isTrueOfflineMessage(error.message))) {
        return const AppErrorInfo(
          title: 'No connection',
          message:
              'We could not reach the care home. Check Wi-Fi or mobile data, then try again. Anything you already opened can still be viewed from the last saved copy.',
          isOffline: true,
        );
      }
      return AppErrorInfo(
        title: fallbackTitle ?? 'Something went wrong',
        message: _clean(error.message),
      );
    }

    if (_isTrueOfflineMessage(error.message)) {
      return const AppErrorInfo(
        title: 'No connection',
        message:
            'We could not reach the care home. Check Wi-Fi or mobile data, then try again. Anything you already opened can still be viewed from the last saved copy.',
        isOffline: true,
      );
    }

    return AppErrorInfo(
      title: fallbackTitle ?? 'Something went wrong',
      message: _clean(error.message),
    );
  }

  static AppErrorInfo _fromStatus({
    required int? statusCode,
    required String raw,
    String? fallbackTitle,
  }) {
    switch (statusCode) {
      case 400:
      case 422:
        return AppErrorInfo(
          title: 'Check your details',
          message: _clean(
            raw,
            fallback: 'Some of the information entered is not valid.',
          ),
          canRetry: false,
        );
      case 401:
        return AppErrorInfo(
          title: 'Sign-in needed',
          message: _clean(
            raw,
            fallback:
                'Your session has expired or the email and password do not match. Sign in again to continue.',
          ),
          isAuth: true,
        );
      case 403:
        return AppErrorInfo(
          title: 'Access denied',
          message: _clean(
            raw,
            fallback: 'This action is not allowed for your role.',
          ),
          isAuth: true,
          canRetry: false,
        );
      case 404:
        return AppErrorInfo(
          title: 'Not found',
          message: _clean(
            raw,
            fallback: 'That record is no longer available.',
          ),
          canRetry: false,
        );
      case 409:
        return AppErrorInfo(
          title: 'Not ready yet',
          message: _clean(
            raw,
            fallback:
                'This request cannot be decided yet. The colleague asked may still need to respond.',
          ),
          canRetry: false,
        );
      case 408:
      case 504:
        return const AppErrorInfo(
          title: 'Request timed out',
          message:
              'The care home server took too long to respond. Try again on a stronger connection.',
          isOffline: true,
        );
      case 429:
        return const AppErrorInfo(
          title: 'Too many attempts',
          message: 'Please wait a moment and try again.',
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return const AppErrorInfo(
            title: 'Care home is unavailable',
            message:
                'The server is having trouble right now. Your last saved information is still on this device. Please try again shortly.',
          );
        }
        if (_isTrueOfflineMessage(raw)) {
          return const AppErrorInfo(
            title: 'No connection',
            message:
                'We could not reach the care home. Check your internet and try again.',
            isOffline: true,
          );
        }
        return AppErrorInfo(
          title: fallbackTitle ?? 'Something went wrong',
          message: _clean(raw),
        );
    }
  }

  /// Real transport failures — not Dio HTTP boilerplate that happens to
  /// mention "connection" after sanitizing.
  static bool _isTrueOfflineMessage(String message) {
    if (_looksLikeHttpBoilerplate(message)) return false;
    final lower = message.toLowerCase();
    return lower.contains('socket') ||
        lower.contains('connection timeout') ||
        lower.contains('connection error') ||
        lower.contains('connection refused') ||
        lower.contains('failed host') ||
        lower.contains('host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('offline') ||
        lower.contains('unable to reach') ||
        lower.contains('no address associated') ||
        (lower.contains('timed out') && !lower.contains('status code'));
  }

  static bool _looksLikeHttpBoilerplate(String message) {
    final lower = message.toLowerCase();
    return message.startsWith('DioException') ||
        lower.contains('validatestatus') ||
        lower.contains('this exception was thrown because') ||
        lower.contains('status code of');
  }

  static String _validationMessage(ValidationError error) {
    final fields = error.fieldErrors;
    if (fields != null && fields.isNotEmpty) {
      return fields.values.expand((list) => list).join('\n');
    }
    return _clean(error.message);
  }

  static String _clean(String message, {String? fallback}) {
    final text = message.trim();
    if (text.isEmpty) return fallback ?? 'Please try again in a moment.';
    if (_looksLikeHttpBoilerplate(text) ||
        text.startsWith('Exception:') ||
        text.contains('SocketException') ||
        text.contains('HttpException')) {
      return fallback ?? 'Please try again in a moment.';
    }
    // Nested API envelope: { error: { message: "..." } } may already be
    // flattened by the client; keep readable server copy as-is.
    return text;
  }

  static AppError toFriendly(AppError error) {
    final info = from(error);
    if (error is ApiError) {
      return ApiError(
        message: info.message,
        statusCode: error.statusCode,
        responseData: error.responseData,
        code: error.code ??
            (info.isOffline
                ? 'offline'
                : info.isAuth
                    ? 'auth'
                    : error.statusCode?.toString()),
        originalError: error.originalError,
        stackTrace: error.stackTrace,
      );
    }
    if (error is NetworkError) {
      return NetworkError(
        message: info.message,
        code: error.code ?? (info.isOffline ? 'offline' : null),
        originalError: error.originalError,
        stackTrace: error.stackTrace,
      );
    }
    if (error is AuthError) {
      return AuthError(
        message: info.message,
        code: error.code ?? 'auth',
        originalError: error.originalError,
        stackTrace: error.stackTrace,
      );
    }
    if (error is PermissionError) {
      return PermissionError(
        message: info.message,
        code: error.code ?? 'permission',
        originalError: error.originalError,
        stackTrace: error.stackTrace,
      );
    }
    if (error is ValidationError) {
      return ValidationError(
        message: info.message,
        fieldErrors: error.fieldErrors,
        code: error.code,
        originalError: error.originalError,
        stackTrace: error.stackTrace,
      );
    }
    return error;
  }

  const AppErrorMapper._();
}
