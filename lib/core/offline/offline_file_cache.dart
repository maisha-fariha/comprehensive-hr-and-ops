import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../errors/app_error_mapper.dart';
import '../network/connectivity_monitor.dart';
import 'offline_outbox.dart';
import 'outbox_attachments.dart';

/// Files opened with a connection (documents, attachments, PDFs, photos)
/// kept in the app's private storage so they open again offline.
///
/// Scoped by tenant + user, capped by size (oldest removed first). Exports
/// built from live data should not use this.
abstract final class OfflineFileCache {
  static const int maxBytes = 150 * 1024 * 1024;

  /// Turned on by the offline bootstrap once device storage is available.
  static bool enabled = false;

  /// `tenant|user` of the signed-in person. Wired by the offline bootstrap.
  static String Function() scope = () => '';

  @visibleForTesting
  static Future<Directory> Function()? rootOverride;

  @visibleForTesting
  static bool Function()? offlineOverride;

  static Future<Directory>? _root;

  static bool get _offline {
    final override = offlineOverride;
    if (override != null) return override();
    return Get.isRegistered<ConnectivityMonitor>() &&
        !Get.find<ConnectivityMonitor>().online;
  }

  /// Offline: the saved copy (or an "open it once online" error). Online:
  /// [download], saving the bytes on success. With [serveCopyOnFailure] a
  /// failed download still falls back to the saved copy. A [source] that is
  /// a file picked offline and not sent yet is read from the device.
  static Future<Result<List<int>>> remember(
    String key,
    Future<Result<List<int>>> Function() download, {
    bool serveCopyOnFailure = false,
    String? source,
  }) async {
    if (kIsWeb || !enabled) return download();
    final unsent = await _unsentUpload(source);
    if (unsent != null) return Result.success(unsent);
    if (_offline) {
      final copy = await read(key);
      if (copy != null) return Result.success(copy);
      return Result.failure(uncachedError);
    }
    final result = await download();
    final bytes = result.value;
    if (result.isSuccess && bytes != null && bytes.isNotEmpty) {
      unawaited(write(key, bytes));
      return result;
    }
    if (serveCopyOnFailure || _offline) {
      final copy = await read(key);
      if (copy != null) return Result.success(copy);
    }
    return result;
  }

  static Future<List<int>?> _unsentUpload(String? source) async {
    if (source == null || !StagedUploadStore.isToken(source.trim())) {
      return null;
    }
    final path = OfflineOutbox.maybe?.localPathForUpload(source.trim());
    if (path == null) return null;
    try {
      final file = File(path);
      return await file.exists() ? await file.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  static AppError get uncachedError => AppErrorMapper.toFriendly(
        const NetworkError(message: 'No connection', code: 'offline_uncached'),
      );

  static Future<List<int>?> read(String key) async {
    if (kIsWeb || !enabled) return null;
    try {
      final file = await _fileFor(key);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      unawaited(file.setLastModified(DateTime.now()).catchError((_) {}));
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, List<int> bytes) async {
    if (kIsWeb || !enabled || bytes.isEmpty) return;
    try {
      final file = await _fileFor(key);
      await file.writeAsBytes(bytes, flush: true);
      await _evict(file.parent);
    } catch (_) {}
  }

  static Future<void> clear() async {
    if (kIsWeb) return;
    try {
      final dir = await _dir();
      if (await dir.exists()) await dir.delete(recursive: true);
      _root = null;
    } catch (_) {}
  }

  static Future<File> _fileFor(String key) async {
    final dir = await _dir();
    return File('${dir.path}/${_hash('${scope()}|$key')}');
  }

  static Future<Directory> _dir() {
    return _root ??= () async {
      final base = await (rootOverride ?? getApplicationSupportDirectory)();
      final dir = Directory('${base.path}/offline_files');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }();
  }

  static Future<void> _evict(Directory dir) async {
    final files = <File>[];
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        files.add(entity);
        total += await entity.length();
      }
    }
    if (total <= maxBytes) return;
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    for (final file in files) {
      if (total <= (maxBytes * 0.9).floor()) break;
      total -= await file.length();
      await file.delete();
    }
  }

  static String _hash(String input) {
    var h1 = 0x811c9dc5;
    var h2 = 0x811c9dc5;
    final units = input.codeUnits;
    for (var i = 0; i < units.length; i++) {
      h1 = ((h1 ^ units[i]) * 0x01000193) & 0xffffffff;
      h2 = ((h2 ^ units[units.length - 1 - i]) * 0x01000193) & 0xffffffff;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}'
        '${h2.toRadixString(16).padLeft(8, '0')}';
  }

  @visibleForTesting
  static void resetForTests() => _root = null;
}
