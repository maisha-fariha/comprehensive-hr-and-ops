import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Saves a file into shared device storage.
///
/// On Android 10+ this uses [MediaStore] Downloads (no
/// `MANAGE_EXTERNAL_STORAGE`). On older Android it writes to the public
/// Download folder when storage permission is available. On iOS it saves
/// into the app Documents folder (visible via Files when sharing is enabled).
class MediaStoreDownload {
  MediaStoreDownload._();

  static const MethodChannel _channel = MethodChannel(
    'com.comprehensive_hr_and_ops/media_store',
  );

  /// Saves [bytes] as [fileName] (e.g. `CIR-abc12345.pdf`).
  ///
  /// Returns a display path / content URI string on success.
  static Future<MediaStoreSaveResult> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final safeName = fileName.trim().isEmpty ? 'download.pdf' : fileName.trim();

    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'saveToDownloads',
          {
            'fileName': safeName,
            'bytes': bytes,
            'mimeType': 'application/pdf',
          },
        );
        if (result == null) {
          return const MediaStoreSaveResult(
            success: false,
            error: 'MediaStore returned no result.',
          );
        }
        final success = result['success'] == true;
        if (!success) {
          return MediaStoreSaveResult(
            success: false,
            error: (result['error'] as String?) ?? 'Could not save via MediaStore.',
          );
        }
        return MediaStoreSaveResult(
          success: true,
          path: result['path'] as String?,
          uri: result['uri'] as String?,
        );
      } on PlatformException catch (e) {
        return MediaStoreSaveResult(
          success: false,
          error: e.message ?? e.code,
        );
      } catch (e) {
        return MediaStoreSaveResult(success: false, error: e.toString());
      }
    }

    if (Platform.isIOS) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final downloads = Directory('${dir.path}/Downloads');
        if (!downloads.existsSync()) {
          downloads.createSync(recursive: true);
        }
        final file = File('${downloads.path}/$safeName');
        await file.writeAsBytes(bytes, flush: true);
        return MediaStoreSaveResult(success: true, path: file.path);
      } catch (e) {
        return MediaStoreSaveResult(success: false, error: e.toString());
      }
    }

    return const MediaStoreSaveResult(
      success: false,
      error: 'PDF download is only supported on Android and iOS.',
    );
  }
}

class MediaStoreSaveResult {
  final bool success;
  final String? path;
  final String? uri;
  final String? error;

  const MediaStoreSaveResult({
    required this.success,
    this.path,
    this.uri,
    this.error,
  });

  String get displayLocation {
    if (path != null && path!.isNotEmpty) return path!;
    if (uri != null && uri!.isNotEmpty) return uri!;
    return 'Downloads';
  }
}
