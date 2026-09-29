import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../../core/network/api_endpoints.dart';
import '../../../../../../core/network/app_api_client.dart';
import '../../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_document.dart';
import '../../domain/repositories/staff_documents_repository.dart';
import '../mappers/staff_documents_mapper.dart';

class StaffDocumentsRepositoryImpl implements StaffDocumentsRepository {
  final AppApiClient _api;

  Map<String, String> _typeNames = const {};
  Map<String, String> _ownerNames = const {};

  StaffDocumentsRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<StaffDocumentsSummary>> getSummary() async {
    final result = await _api.get(ApiEndpoints.documentsSummary, silent: true);
    return result.when(
      success: (body) async =>
          Result.success(StaffDocumentsMapper.summaryFromJson(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffDocumentsPageResult>> listDocuments({
    int page = 1,
    int limit = 20,
    String? search,
    String? ownerType,
    String? documentTypeId,
    String? status,
    String? visibility,
    bool includeDeleted = false,
  }) async {
    await _ensureLookups();
    final result = await _api.get(
      ApiEndpoints.documents,
      query: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (ownerType != null && ownerType.isNotEmpty) 'ownerType': ownerType,
        if (documentTypeId != null && documentTypeId.isNotEmpty)
          'documentTypeId': documentTypeId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (visibility != null && visibility.isNotEmpty) 'visibility': visibility,
        if (includeDeleted) 'includeDeleted': true,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body).whereType<Map>().map((raw) {
          return StaffDocumentsMapper.documentFromJson(
            JsonCodec.asMap(raw),
            typeNames: _typeNames,
            ownerNames: _ownerNames,
          );
        }).toList();
        final meta = JsonCodec.metaOf(body) ?? const {};
        return Result.success(
          StaffDocumentsPageResult(
            items: items,
            page: JsonCodec.integerOr(meta['page'], page),
            limit: JsonCodec.integerOr(meta['limit'], limit),
            total: JsonCodec.integerOr(meta['total'], items.length),
            totalPages: JsonCodec.integerOr(meta['totalPages'], 1),
          ),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffDocumentType>>> listTypes({
    bool includeArchived = false,
  }) async {
    final result = await _api.get(
      ApiEndpoints.documentTypes,
      query: {if (includeArchived) 'includeArchived': true},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final types = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map((raw) => StaffDocumentsMapper.typeFromJson(JsonCodec.asMap(raw)))
            .toList();
        _typeNames = {
          for (final t in types.where((t) => t.id.isNotEmpty)) t.id: t.name,
        };
        return Result.success(types);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffDocumentType>> createType({
    required String name,
    required String appliesTo,
  }) async {
    final result = await _api.post(
      ApiEndpoints.documentTypes,
      data: {
        'name': name.trim(),
        'appliesTo': appliesTo,
        'isMandatory': false,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final type = StaffDocumentsMapper.typeFromJson(
          JsonCodec.unwrapMap(body),
        );
        _typeNames = {..._typeNames, type.id: type.name};
        return Result.success(type);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> archiveType(String id) async {
    final result = await _api.post(
      ApiEndpoints.documentTypeArchive(id),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> restoreType(String id) async {
    final result = await _api.post(
      ApiEndpoints.documentTypeRestore(id),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String>> uploadFile({
    required String localPath,
    required String fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: const {'category': 'documents'},
        allowQueue: false,
      );
      return await result.when(
        success: (body) async {
          final map = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(
            map['fileUrl'] ?? map['url'] ?? map['publicUrl'],
          );
          if (url == null || url.isEmpty) {
            return Result.failure(
              const ApiError(
                message: 'Upload succeeded but file URL was missing.',
              ),
            );
          }
          return Result.success(url);
        },
        failure: (error) async => Result.failure(error),
      );
    } catch (error) {
      return Result.failure(
        ApiError(message: 'Could not upload $fileName: $error'),
      );
    }
  }

  @override
  Future<Result<StaffDocument>> createDocument(
    StaffCreateDocumentInput input,
  ) async {
    final data = <String, dynamic>{
      'name': input.name.trim(),
      'ownerType': input.ownerType,
      if (input.ownerId != null && input.ownerId!.isNotEmpty)
        'ownerId': input.ownerId,
      if (input.documentTypeId != null && input.documentTypeId!.isNotEmpty)
        'documentTypeId': input.documentTypeId,
      'fileUrl': input.fileUrl,
      'visibility': input.visibility,
      if (input.expiresAt != null)
        'expiresAt': input.expiresAt!.toUtc().toIso8601String(),
      if (input.notes != null && input.notes!.trim().isNotEmpty)
        'notes': input.notes!.trim(),
    };
    final result = await _api.post(
      ApiEndpoints.documents,
      data: data,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        await _ensureLookups();
        return Result.success(
          StaffDocumentsMapper.documentFromJson(
            JsonCodec.unwrapMap(body),
            typeNames: _typeNames,
            ownerNames: _ownerNames,
          ),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> withdrawDocument(String id) async {
    final result = await _api.delete(
      ApiEndpoints.documentById(id),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> restoreDocument(String id) async {
    final result = await _api.post(
      ApiEndpoints.documentRestore(id),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffDocumentOwnerOption>>> listClients() async {
    final result = await _api.get(
      ApiEndpoints.clients,
      query: const {'page': 1, 'limit': 200},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map((raw) => StaffDocumentsMapper.ownerFromPerson(JsonCodec.asMap(raw)))
            .where((o) => o.id.isNotEmpty)
            .toList();
        _mergeOwners('client', items);
        return Result.success(items);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffDocumentOwnerOption>>> listStaff() async {
    final result = await _api.get(
      ApiEndpoints.staff,
      query: const {'page': 1, 'limit': 200},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map((raw) => StaffDocumentsMapper.ownerFromPerson(JsonCodec.asMap(raw)))
            .where((o) => o.id.isNotEmpty)
            .toList();
        _mergeOwners('staff', items);
        return Result.success(items);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffDocumentOwnerOption>>> listResidences() async {
    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 200},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map(
              (raw) =>
                  StaffDocumentsMapper.ownerFromResidence(JsonCodec.asMap(raw)),
            )
            .where((o) => o.id.isNotEmpty)
            .toList();
        _mergeOwners('residence', items);
        return Result.success(items);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<void> _ensureLookups() async {
    if (_typeNames.isEmpty) {
      await listTypes(includeArchived: true);
    }
    if (_ownerNames.isEmpty) {
      await Future.wait([listClients(), listStaff(), listResidences()]);
    }
  }

  void _mergeOwners(String type, List<StaffDocumentOwnerOption> items) {
    final next = Map<String, String>.from(_ownerNames);
    for (final item in items) {
      next[item.id] = item.label;
      next['$type:${item.id}'] = item.label;
    }
    _ownerNames = next;
  }
}
