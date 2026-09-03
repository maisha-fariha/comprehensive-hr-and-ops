import 'package:flutter/services.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../domain/entities/family_document.dart';
import '../../domain/entities/family_documents_overview.dart';
import '../../domain/repositories/family_documents_repository.dart';

/// GetX controller for the "Documents" screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app. The screen is fully static/list-style, so no
/// additional selection/filter state is needed beyond the loaded overview.
class FamilyDocumentsController extends BaseController<FamilyDocumentsOverview> {
  final FamilyDocumentsRepository repository;

  FamilyDocumentsController({required this.repository}) {
    loadOverview();
  }

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

  Future<void> download(FamilyDocument document) async {
    final result = await repository.resolveDownloadUrl(document);
    result.when(
      success: (url) async {
        if (url == null || url.isEmpty) {
          AppErrorDialog.showPageError(
            title: 'Download unavailable',
            message: 'This document does not have a download link yet.',
          );
          return;
        }
        await Clipboard.setData(ClipboardData(text: url));
        Get.snackbar(
          'Download link copied',
          'Paste it in a browser to open the file.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not download',
      ),
    );
  }
}
