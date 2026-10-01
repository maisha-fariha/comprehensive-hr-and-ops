import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/errors/app_snackbar.dart';
import '../../../../core/storage/media_store_download.dart';
import '../domain/entities/hr_document.dart';
import '../domain/entities/hr_document_row.dart';

/// Device file handling for the registry: choosing a file to upload and
/// saving / opening a downloaded one.
abstract final class HrDocumentFiles {
  static Future<HrPickedFile?> pick() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: HrDocumentOptions.allowedExtensions,
    );
    final file = picked?.files.firstOrNull;
    final path = file?.path;
    if (file == null || path == null) return null;
    return HrPickedFile(path: path, name: file.name, size: file.size);
  }

  static String mimeOf(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'csv' => 'text/csv',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      _ => 'application/octet-stream',
    };
  }

  static Future<void> open(HrDocumentFile file) async {
    final bytes = Uint8List.fromList(file.bytes);
    final mime = mimeOf(file.fileName);
    if (mime == 'application/pdf') {
      final saved = await MediaStoreDownload.savePdfAndOpen(
        fileName: file.fileName,
        bytes: bytes,
      );
      if (!saved.success) {
        AppSnackbar.show(saved.error ?? 'The file could not be opened.', '');
      }
      return;
    }
    final saved = await MediaStoreDownload.saveFile(
      fileName: file.fileName,
      bytes: bytes,
      mimeType: mime,
    );
    if (!saved.success) {
      AppSnackbar.show(saved.error ?? 'The file could not be saved.', '');
      return;
    }
    final path = saved.path;
    if (path != null && path.isNotEmpty) {
      await OpenFilex.open(path, type: mime);
    } else {
      AppSnackbar.show('${file.fileName} saved to ${saved.displayLocation}.', '');
    }
  }
}
