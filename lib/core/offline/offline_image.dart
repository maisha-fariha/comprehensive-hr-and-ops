import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gems_core/gems_core.dart';

import '../network/authorized_file.dart';
import 'offline_file_cache.dart';
import 'offline_outbox.dart';
import 'outbox_attachments.dart';

/// Image source for stored photos (avatars, client photos, selfies,
/// attachments) that keeps working offline:
/// - a photo picked offline (placeholder URL) is shown from the device,
/// - other photos keep a copy on the device after they first load.
abstract final class OfflineImage {
  /// [withAuth] sends the login + tenant headers (stored `/files/...`
  /// paths); leave it off for public or pre-signed links.
  static ImageProvider provider(String url, {bool withAuth = false}) {
    final trimmed = url.trim();
    if (StagedUploadStore.isToken(trimmed)) {
      final local = OfflineOutbox.maybe?.localPathForUpload(trimmed);
      if (local != null && !kIsWeb) return FileImage(File(local));
    }
    if (kIsWeb) {
      return NetworkImage(
        AuthorizedFile.resolveUrl(trimmed),
        headers: withAuth ? AuthorizedFile.headers() : null,
      );
    }
    return SavedNetworkImage(trimmed, withAuth: withAuth);
  }
}

/// Network image that saves its bytes with [OfflineFileCache] and falls back
/// to the saved copy when it cannot be downloaded.
@immutable
class SavedNetworkImage extends ImageProvider<SavedNetworkImage> {
  final String url;
  final bool withAuth;
  final double scale;

  const SavedNetworkImage(this.url, {this.withAuth = false, this.scale = 1.0});

  @override
  Future<SavedNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<SavedNetworkImage>(this);

  @override
  ImageStreamCompleter loadImage(
    SavedNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: scale,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final result = await OfflineFileCache.remember(
      'img:$url',
      _download,
      serveCopyOnFailure: true,
    );
    final bytes = result.value;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Image unavailable: $url');
    }
    final buffer =
        await ui.ImmutableBuffer.fromUint8List(Uint8List.fromList(bytes));
    return decode(buffer);
  }

  Future<Result<List<int>>> _download() async {
    try {
      final response = await Dio().get<List<int>>(
        AuthorizedFile.resolveUrl(url),
        options: Options(
          responseType: ResponseType.bytes,
          headers: withAuth ? AuthorizedFile.headers() : null,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final status = response.statusCode ?? 0;
      final bytes = response.data ?? const <int>[];
      if (status < 200 || status >= 300 || bytes.isEmpty) {
        return Result.failure(ApiError(message: 'Image $status', statusCode: status));
      }
      return Result.success(bytes);
    } catch (error) {
      return Result.failure(NetworkError(message: '$error', code: 'offline'));
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SavedNetworkImage &&
      other.url == url &&
      other.withAuth == withAuth &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(url, withAuth, scale);
}
