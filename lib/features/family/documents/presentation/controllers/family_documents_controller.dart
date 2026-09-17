import 'dart:typed_data';

import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../domain/entities/family_document.dart';
import '../../domain/entities/family_documents_overview.dart';
import '../../domain/repositories/family_documents_repository.dart';

/// GetX controller for the "Documents" screen.
class FamilyDocumentsController extends BaseController<FamilyDocumentsOverview> {
  final FamilyDocumentsRepository repository;

  FamilyDocumentsController({required this.repository}) {
    loadOverview();
  }

  final RxBool isOpening = false.obs;

  FamilyDocumentsOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadOverview();

  /// Opens a document via `GET /files/.../link` (or fallbacks), then launches
  /// the system viewer.
  Future<void> openDocument(FamilyDocument document) async {
    if (isOpening.value) return;
    isOpening.value = true;
    try {
      final result = await repository.openDocument(document);
      await result.when(
        success: (payload) async {
          final bytes = Uint8List.fromList(payload.bytes);
          final isPdf = payload.mimeType.contains('pdf') ||
              payload.fileName.toLowerCase().endsWith('.pdf');

          if (isPdf) {
            final saveResult = await MediaStoreDownload.savePdfAndOpen(
              fileName: payload.fileName.toLowerCase().endsWith('.pdf')
                  ? payload.fileName
                  : '${payload.fileName}.pdf',
              bytes: bytes,
            );
            if (!saveResult.success) {
              AppErrorDialog.showPageError(
                title: 'Could not open file',
                message: saveResult.error ?? 'Could not save or open the PDF.',
              );
            }
            return;
          }

          final saveResult = await MediaStoreDownload.saveFile(
            fileName: payload.fileName,
            bytes: bytes,
            mimeType: payload.mimeType,
          );
          if (!saveResult.success) {
            AppErrorDialog.showPageError(
              title: 'Could not open file',
              message: saveResult.error ?? 'Could not save the file.',
            );
            return;
          }
          final path = saveResult.path;
          if (path != null && path.isNotEmpty) {
            await OpenFilex.open(path, type: payload.mimeType);
            return;
          }
          Get.snackbar(
            'Downloaded',
            '${payload.fileName} saved to ${saveResult.displayLocation}.',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        failure: (error) async => AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not open document',
        ),
      );
    } finally {
      isOpening.value = false;
    }
  }
}
