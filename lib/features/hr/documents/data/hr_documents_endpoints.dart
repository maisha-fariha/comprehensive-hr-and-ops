import '../../../../core/network/api_endpoints.dart';

/// Paths used by the manager Documents registry (web `/dashboard/documents`).
abstract final class HrDocumentsEndpoints {
  static const String documents = ApiEndpoints.documents;
  static const String summary = ApiEndpoints.documentsSummary;
  static const String types = ApiEndpoints.documentTypes;
  static const String uploads = '/uploads';
  static const String reportExports = '/reports/exports';
  static const String clients = '/clients';
  static const String staff = '/staff';
  static const String residences = '/residences';

  static String document(String id) => '$documents/$id';
  static String restore(String id) => '$documents/$id/restore';
  static String archiveType(String id) => '$types/$id/archive';
  static String restoreType(String id) => '$types/$id/restore';

  /// The web `toApiFilePath`: the part of a stored `fileUrl` after `/api/v1`,
  /// or null when the file is not served by the API.
  static String? apiFilePath(String? fileUrl) {
    if (fileUrl == null || fileUrl.isEmpty) return null;
    final at = fileUrl.indexOf('/api/v1/');
    if (at == -1) return null;
    return fileUrl.substring(at + '/api/v1'.length);
  }
}
