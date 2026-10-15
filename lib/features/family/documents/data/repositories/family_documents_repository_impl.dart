import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/network/tenant_store.dart';
import '../../../../../core/network/token_store.dart';
import '../../../../../core/offline/offline_file_cache.dart';
import '../../domain/entities/family_document.dart';
import '../../domain/entities/family_document_enums.dart';
import '../../domain/entities/family_documents_overview.dart';
import '../../domain/repositories/family_documents_repository.dart';
import '../mappers/family_documents_mapper.dart';

class FamilyDocumentsRepositoryImpl implements FamilyDocumentsRepository {
  final AppApiClient _api;
  final TokenStore _tokens;
  final TenantStore _tenant;

  FamilyDocumentsRepositoryImpl({
    required AppApiClient api,
    required TokenStore tokens,
    required TenantStore tenant,
  })  : _api = api,
        _tokens = tokens,
        _tenant = tenant;

  @override
  Future<Result<FamilyDocumentsOverview>> getOverview() async {
    final result = await _api.get(ApiEndpoints.familyDocuments);
    return result.when(
      success: (body) async =>
          Result.success(FamilyDocumentsMapper.fromBody(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<FamilyDocumentOpenPayload>> openDocument(
    FamilyDocument document,
  ) async {
    final bytesResult = await OfflineFileCache.remember(
      'family-doc:${document.id}',
      () async {
        final resolved = await _resolveOpenUrl(document);
        if (resolved.isFailure) {
          return Result.failure(
            resolved.error ??
                const ApiError(
                  message: 'This document does not have a file yet.',
                ),
          );
        }
        final target = resolved.value!;
        return _downloadBytes(
          target.url,
          authUnlessSigned: target.needsAuth,
        );
      },
    );
    if (bytesResult.isFailure) {
      return Result.failure(
        bytesResult.error ??
            const ApiError(message: 'Could not download this document.'),
      );
    }

    final fileName = document.openFileName;
    return Result.success(
      FamilyDocumentOpenPayload(
        bytes: bytesResult.value!,
        fileName: fileName,
        mimeType: _mimeFor(document, fileName),
      ),
    );
  }

  @override
  Future<Result<List<FamilyDocumentResident>>> linkedResidents() async {
    final result = await _api.get(ApiEndpoints.familyHome, silent: true);
    return result.when(
      success: (body) async {
        final home = JsonCodec.unwrapMap(body);
        final rows = JsonCodec.unwrapList(home['linkedClients']);
        final people = <FamilyDocumentResident>[];
        for (final raw in rows.whereType<Map>()) {
          final json = JsonCodec.asMap(raw);
          final visibility = JsonCodec.mapAt(json, 'visibility');
          if (visibility != null && visibility['documents'] == false) continue;
          final id = JsonCodec.string(json['id']);
          if (id == null || id.isEmpty) continue;
          final name = JsonCodec.string(json['name']) ??
              [
                JsonCodec.string(json['firstName']),
                JsonCodec.string(json['lastName']),
              ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
          if (name.isEmpty) continue;
          people.add(FamilyDocumentResident(id: id, name: name));
        }
        return Result.success(people);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> sendDocument({
    required String clientId,
    required String name,
    required String category,
    required String localPath,
    required String fileName,
    String? notes,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      final upload = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: const {'category': 'family-uploads'},
        allowQueue: false,
      );
      final uploaded = await upload.when(
        success: (body) async => Result.success(JsonCodec.unwrapMap(body)),
        failure: (error) async => Result<Map<String, dynamic>>.failure(error),
      );
      if (uploaded.isFailure) {
        return Result.failure(
          uploaded.error ?? const ApiError(message: 'Could not upload the file.'),
        );
      }
      final fileUrl = JsonCodec.string(
        uploaded.value?['fileUrl'] ?? uploaded.value?['url'],
      );
      if (fileUrl == null || fileUrl.isEmpty) {
        return Result.failure(
          const ApiError(message: 'Upload succeeded but file URL was missing.'),
        );
      }
      final mime = _mimeForName(fileName);
      final created = await _api.post(
        ApiEndpoints.familyDocuments,
        data: {
          'clientId': clientId,
          'category': category,
          'name': name,
          'fileUrl': fileUrl,
          if (mime != null) 'fileType': mime,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
        allowQueue: false,
      );
      return await created.when(
        success: (_) async => Result.success(null),
        failure: (error) async => Result.failure(error),
      );
    } catch (error) {
      return Result.failure(ApiError(message: 'Could not upload $fileName.'));
    }
  }

  Future<Result<_ResolvedFileTarget>> _resolveOpenUrl(
    FamilyDocument document,
  ) async {
    // Web downloads the stored file path with the session, not a signed /link.
    final raw = (document.fileUrl ?? document.downloadUrl)?.trim();
    final apiPath = _apiFilePath(raw);
    if (apiPath != null) {
      return Result.success(_ResolvedFileTarget(url: apiPath, needsAuth: true));
    }
    if (raw != null &&
        raw.isNotEmpty &&
        (raw.startsWith('http://') || raw.startsWith('https://'))) {
      return Result.success(_ResolvedFileTarget(url: raw, needsAuth: false));
    }

    final filePath = _filesPathFor(document);
    if (filePath != null) {
      final linkPath = ApiEndpoints.fileLinkPath(filePath);
      if (linkPath != null) {
        final linkResult = await _api.get(linkPath, silent: true);
        if (linkResult.isSuccess) {
          final map = JsonCodec.unwrapMap(linkResult.value);
          final signed = JsonCodec.string(map['signedUrl']);
          final plain = JsonCodec.string(map['url'] ?? map['fileUrl']);
          if (signed != null && signed.isNotEmpty) {
            return Result.success(
              _ResolvedFileTarget(url: signed, needsAuth: false),
            );
          }
          if (plain != null && plain.isNotEmpty) {
            return Result.success(
              _ResolvedFileTarget(url: plain, needsAuth: true),
            );
          }
        }
        // Fall through to direct /files/... fetch with auth.
        return Result.success(
          _ResolvedFileTarget(url: filePath, needsAuth: true),
        );
      }
    }

    // 2) Absolute download URL already on the document.
    final direct = document.downloadUrl?.trim();
    if (direct != null && direct.isNotEmpty) {
      final isHttp =
          direct.startsWith('http://') || direct.startsWith('https://');
      return Result.success(
        _ResolvedFileTarget(url: direct, needsAuth: !isHttp),
      );
    }

    // 3) Legacy upload download fallback.
    final uploadId = document.uploadId;
    if (uploadId != null && uploadId.isNotEmpty) {
      final result = await _api.get(ApiEndpoints.uploadDownload(uploadId));
      return result.when(
        success: (body) async {
          if (body is String && body.trim().startsWith('http')) {
            return Result.success(
              _ResolvedFileTarget(url: body.trim(), needsAuth: false),
            );
          }
          final json = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(
            json['signedUrl'] ??
                json['url'] ??
                json['downloadUrl'] ??
                json['href'],
          );
          if (url == null || url.isEmpty) {
            return Result.failure(
              const ApiError(message: 'Download link was missing.'),
            );
          }
          final isHttp =
              url.startsWith('http://') || url.startsWith('https://');
          return Result.success(
            _ResolvedFileTarget(
              url: url,
              needsAuth: !isHttp || !url.contains('token='),
            ),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    }

    return Result.failure(
      const ApiError(message: 'This document does not have a file yet.'),
    );
  }

  String? _apiFilePath(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    const marker = '/api/v1/';
    final at = raw.indexOf(marker);
    final path = at >= 0 ? raw.substring(at + '/api/v1'.length) : raw;
    if (path.startsWith('/files/')) return path;
    return null;
  }

  String? _mimeForName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return null;
  }

  String? _filesPathFor(FamilyDocument document) {
    final raw = (document.fileUrl ?? document.downloadUrl)?.trim();
    if (raw != null && raw.isNotEmpty) {
      final linkable = ApiEndpoints.fileLinkPath(raw);
      if (linkable != null) {
        // Return the object path (without /link) for direct fetch fallback.
        return linkable.endsWith('/link')
            ? linkable.substring(0, linkable.length - '/link'.length)
            : linkable;
      }
    }

    final tenantId = document.tenantId?.trim();
    final category = document.category.trim();
    final fileName = (document.fileName ?? document.openFileName).trim();
    if (tenantId != null &&
        tenantId.isNotEmpty &&
        category.isNotEmpty &&
        fileName.isNotEmpty) {
      return ApiEndpoints.fileObject(
        tenantId: tenantId,
        category: category,
        fileName: fileName,
      );
    }
    return null;
  }

  Future<Result<List<int>>> _downloadBytes(
    String urlOrPath, {
    required bool authUnlessSigned,
  }) async {
    try {
      final headers = <String, dynamic>{'Accept': '*/*'};
      if (authUnlessSigned) {
        final token = _tokens.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        final subdomain = _tenant.subdomain;
        if (subdomain != null && subdomain.isNotEmpty) {
          headers['X-Tenant-Subdomain'] = subdomain;
        }
      }

      final response = await Dio().get<List<int>>(
        _resolveFileUrl(urlOrPath),
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final status = response.statusCode ?? 0;
      final bytes = response.data ?? const <int>[];
      if (status < 200 || status >= 300 || bytes.isEmpty) {
        return Result.failure(
          ApiError(message: _bytesErrorMessage(bytes) ?? 'Could not open file.'),
        );
      }
      return Result.success(bytes);
    } on DioException catch (error) {
      return Result.failure(
        ApiError(message: error.message ?? 'Could not open file.'),
      );
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Could not open file.'),
      );
    }
  }

  static String _resolveFileUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.startsWith('/api/v1/')) {
      final origin = base.replaceAll(RegExp(r'/api/v1/?$'), '');
      return '$origin$trimmed';
    }
    if (trimmed.startsWith('/')) return '$base$trimmed';
    return '$base/$trimmed';
  }

  static String? _bytesErrorMessage(List<int> bytes) {
    try {
      final text = utf8.decode(bytes, allowMalformed: true);
      final decoded = jsonDecode(text);
      final map = JsonCodec.asMap(decoded);
      final nested = map['error'];
      return JsonCodec.string(
        map['message'] ?? (nested is Map ? nested['message'] : null),
      );
    } catch (_) {
      return null;
    }
  }

  static String _mimeFor(FamilyDocument document, String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return document.fileType == FamilyDocumentFileType.jpg
        ? 'image/jpeg'
        : 'application/pdf';
  }
}

class _ResolvedFileTarget {
  final String url;
  final bool needsAuth;

  const _ResolvedFileTarget({required this.url, required this.needsAuth});
}
