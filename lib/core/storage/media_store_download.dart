import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Saves a file into shared device storage.
///
/// On Android 10+ this uses [MediaStore] Downloads (no
/// `MANAGE_EXTERNAL_STORAGE`). On older Android it writes to the public
/// Download folder when storage permission is available. On iOS it saves
/// into the app Documents folder (visible via Files when sharing is enabled).
///
/// PDF save-and-open follows the same structure as OUM_SECURITY_NEW:
/// save bytes → open with system PDF viewer.
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
  }) {
    return saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
    );
  }

  /// Save PDF to Downloads, then open it so the user can view it.
  ///
  /// Android: MediaStore (`Downloads/HROps`) + native `openPdf`, with
  /// [OpenFilex] fallback from a cache copy if the Intent fails.
  /// iOS / desktop: write under Documents, then [OpenFilex.open].
  static Future<MediaStoreSaveResult> savePdfAndOpen({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final safeName = fileName.trim().isEmpty ? 'download.pdf' : fileName.trim();

    if (Platform.isAndroid) {
      String? uri;
      String? filePath;
      var folder = 'Downloads/HROps';

      try {
        final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'savePdfToDownloads',
          {
            'fileName': safeName,
            'bytes': bytes,
          },
        );
        final map = Map<String, dynamic>.from(raw ?? const {});
        uri = map['uri']?.toString();
        filePath = map['filePath']?.toString();
        folder = map['folder']?.toString() ?? folder;
      } on PlatformException catch (e) {
        return MediaStoreSaveResult(
          success: false,
          error: e.message ?? e.code,
        );
      } catch (e) {
        return MediaStoreSaveResult(success: false, error: e.toString());
      }

      final opened = await _openAndroidPdf(
        uri: uri,
        filePath: filePath,
        fileName: safeName,
        bytes: bytes,
      );
      if (!opened) {
        return MediaStoreSaveResult(
          success: false,
          path: filePath,
          uri: uri,
          locationLabel: folder,
          error:
              'PDF was saved to $folder, but no PDF viewer could open it.',
        );
      }

      return MediaStoreSaveResult(
        success: true,
        path: filePath,
        uri: uri,
        locationLabel: folder,
      );
    }

    // iOS and other platforms: save under Documents, then open.
    try {
      final file = await _writeLocalCopy(
        fileName: safeName,
        bytes: bytes,
        subFolder: 'Downloads',
      );
      final openResult = await OpenFilex.open(
        file.path,
        type: 'application/pdf',
      );
      if (openResult.type != ResultType.done) {
        return MediaStoreSaveResult(
          success: false,
          path: file.path,
          error: openResult.message,
        );
      }
      return MediaStoreSaveResult(
        success: true,
        path: file.path,
        locationLabel: Platform.isIOS
            ? 'Files → On My iPhone → Downloads'
            : file.parent.path,
      );
    } catch (e) {
      return MediaStoreSaveResult(success: false, error: e.toString());
    }
  }

  /// Tries native Intent open first, then a cache file via OpenFilex.
  static Future<bool> _openAndroidPdf({
    required String? uri,
    required String? filePath,
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      await _channel.invokeMethod<void>('openPdf', {
        if (uri != null && uri.isNotEmpty) 'uri': uri,
        if (filePath != null && filePath.isNotEmpty) 'filePath': filePath,
      });
      return true;
    } catch (e) {
      debugPrint('openPdf Intent failed, falling back to OpenFilex: $e');
    }

    try {
      final cache = await _writeLocalCopy(
        fileName: fileName,
        bytes: bytes,
        subFolder: 'pdf_preview',
        preferCache: true,
      );
      final openResult = await OpenFilex.open(
        cache.path,
        type: 'application/pdf',
      );
      return openResult.type == ResultType.done;
    } catch (e) {
      debugPrint('OpenFilex fallback failed: $e');
      return false;
    }
  }

  static Future<File> _writeLocalCopy({
    required String fileName,
    required Uint8List bytes,
    required String subFolder,
    bool preferCache = false,
  }) async {
    final base = preferCache
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$subFolder');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Saves [bytes] as [fileName] with the given [mimeType].
  static Future<MediaStoreSaveResult> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final safeName = fileName.trim().isEmpty ? 'download.bin' : fileName.trim();

    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'saveToDownloads',
          {
            'fileName': safeName,
            'bytes': bytes,
            'mimeType': mimeType,
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
            error:
                (result['error'] as String?) ?? 'Could not save via MediaStore.',
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
        final file = await _writeLocalCopy(
          fileName: safeName,
          bytes: bytes,
          subFolder: 'Downloads',
        );
        return MediaStoreSaveResult(success: true, path: file.path);
      } catch (e) {
        return MediaStoreSaveResult(success: false, error: e.toString());
      }
    }

    return const MediaStoreSaveResult(
      success: false,
      error: 'File download is only supported on Android and iOS.',
    );
  }
}

class MediaStoreSaveResult {
  final bool success;
  final String? path;
  final String? uri;
  final String? error;
  final String? locationLabel;

  const MediaStoreSaveResult({
    required this.success,
    this.path,
    this.uri,
    this.error,
    this.locationLabel,
  });

  String get displayLocation {
    if (locationLabel != null && locationLabel!.isNotEmpty) {
      return locationLabel!;
    }
    if (path != null && path!.isNotEmpty) return path!;
    if (uri != null && uri!.isNotEmpty) return uri!;
    return 'Downloads';
  }
}
