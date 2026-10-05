import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/network/tenant_store.dart';
import '../../../../../core/network/token_store.dart';
import '../../domain/entities/hr_document.dart';
import '../../domain/repositories/hr_documents_repository.dart';
import '../hr_documents_endpoints.dart';
import '../mappers/hr_documents_mapper.dart';

class HrDocumentsRepositoryImpl implements HrDocumentsRepository {
  final AppApiClient _api;
  final TokenStore _tokens;
  final TenantStore _tenant;
  final Dio _dio;

  /// The web's `MAX_PAGE_LIMIT` for owner directories.
  static const int directoryLimit = 100;

  HrDocumentsRepositoryImpl({
    required AppApiClient api,
    required TokenStore tokens,
    required TenantStore tenant,
    Dio? dio,
  })  : _api = api,
        _tokens = tokens,
        _tenant = tenant,
        _dio = dio ?? Dio();

  static Result<void> _done(Result<dynamic> result) => result.when(
        success: (_) => Result.success(null),
        failure: Result.failure,
      );

  static Result<HrDocument> _document(Result<dynamic> result) => result.when(
        success: (body) {
          final doc = HrDocumentsMapper.documentFrom(JsonCodec.unwrapMap(body));
          return doc == null
              ? Result.failure(const ApiError(message: 'The document could not be read'))
              : Result.success(doc);
        },
        failure: Result.failure,
      );

  @override
  Future<Result<HrDocumentPage>> list({
    required HrDocumentFilters filters,
    required int page,
    required int limit,
  }) async {
    final result = await _api.get(
      HrDocumentsEndpoints.documents,
      query: {'page': page, 'limit': limit, ...filters.toQuery()},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(HrDocumentsMapper.pageFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<HrDocumentsSummary>> summary(HrDocumentFilters filters) async {
    final result = await _api.get(
      HrDocumentsEndpoints.summary,
      query: filters.toQuery(),
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(HrDocumentsMapper.summaryFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<HrDocumentType>>> types({bool includeArchived = false}) async {
    final result = await _api.get(
      HrDocumentsEndpoints.types,
      query: {'includeArchived': includeArchived},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(HrDocumentsMapper.typesFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<HrDocumentType>> createType({
    required String name,
    required String appliesTo,
  }) async {
    final result = await _api.post(
      HrDocumentsEndpoints.types,
      data: {'name': name, 'appliesTo': appliesTo},
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (body) {
        final type = HrDocumentsMapper.typeFrom(JsonCodec.unwrapMap(body));
        return type == null
            ? Result.failure(const ApiError(message: 'The type could not be read'))
            : Result.success(type);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> archiveType(String id) async => _done(
        await _api.post(
          HrDocumentsEndpoints.archiveType(id),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> restoreType(String id) async => _done(
        await _api.post(
          HrDocumentsEndpoints.restoreType(id),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<String>> uploadFile(HrPickedFile file) async {
    final MultipartFile part;
    try {
      part = await MultipartFile.fromFile(file.path, filename: file.name);
    } catch (_) {
      return Result.failure(ApiError(message: 'Could not read ${file.name}'));
    }
    final result = await _api.post(
      HrDocumentsEndpoints.uploads,
      data: FormData.fromMap({'file': part}),
      query: const {'category': 'documents'},
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (body) {
        final url = JsonCodec.string(JsonCodec.unwrapMap(body)['fileUrl']);
        return url == null
            ? Result.failure(const ApiError(message: 'The upload did not return a file'))
            : Result.success(url);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<HrDocument>> create(Map<String, dynamic> body) async => _document(
        await _api.post(
          HrDocumentsEndpoints.documents,
          data: body,
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<HrDocument>> update(String id, Map<String, dynamic> body) async =>
      _document(
        await _api.patch(
          HrDocumentsEndpoints.document(id),
          data: body,
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> withdraw(String id) async => _done(
        await _api.delete(
          HrDocumentsEndpoints.document(id),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> restore(String id) async => _done(
        await _api.post(
          HrDocumentsEndpoints.restore(id),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> exportReport() async => _done(
        await _api.post(
          HrDocumentsEndpoints.reportExports,
          data: const {'reportKey': 'document_expiry', 'format': 'csv'},
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<HrDocumentFile>> download(String fileUrl, String fallbackName) async {
    final path = HrDocumentsEndpoints.apiFilePath(fileUrl);
    if (path == null) {
      return Result.failure(const ApiError(message: 'This file is no longer available.'));
    }
    final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final token = _tokens.accessToken;
    final subdomain = _tenant.subdomain;
    try {
      final response = await _dio.get<List<int>>(
        '$base$path',
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'Accept': 'application/pdf, application/octet-stream, image/*, */*',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            if (subdomain != null && subdomain.isNotEmpty) 'X-Tenant-Subdomain': subdomain,
          },
        ),
      );
      final status = response.statusCode ?? 0;
      final bytes = response.data ?? const <int>[];
      if (status < 200 || status >= 300 || bytes.isEmpty) {
        return Result.failure(const ApiError(message: 'This file is no longer available.'));
      }
      return Result.success(
        HrDocumentFile(
          bytes: bytes,
          fileName: _fileName(response.headers.value('content-disposition')) ?? fallbackName,
        ),
      );
    } on DioException catch (error) {
      return Result.failure(ApiError(message: error.message ?? 'Cannot reach the server.'));
    }
  }

  static String? _fileName(String? disposition) {
    if (disposition == null) return null;
    final match = RegExp(r"""filename\*?=(?:UTF-8'')?"?([^";]+)"?""", caseSensitive: false)
        .firstMatch(disposition);
    final raw = match?.group(1);
    if (raw == null) return null;
    final name = Uri.decodeComponent(raw).trim();
    return name.isEmpty ? null : name;
  }

  @override
  Future<Result<List<HrDocumentOwner>>> owners(String ownerType) async {
    final path = switch (ownerType) {
      'client' => HrDocumentsEndpoints.clients,
      'staff' => HrDocumentsEndpoints.staff,
      _ => HrDocumentsEndpoints.residences,
    };
    final result = await _api.get(
      path,
      query: const {'page': 1, 'limit': directoryLimit},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(HrDocumentsMapper.ownersFrom(body, ownerType)),
      failure: Result.failure,
    );
  }
}
