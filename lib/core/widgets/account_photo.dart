import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../offline/offline_image.dart';

/// Account photo, or [fallback] when there is no photo or it cannot be loaded.
///
/// The web shows whatever file `avatarUrl` points at. A dark frame is still
/// that photo, so it is drawn rather than replaced with initials.
class AccountPhoto extends StatelessWidget {
  final String? url;
  final double size;
  final Widget fallback;
  final Color background;
  final BorderRadius? borderRadius;

  const AccountPhoto({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
    required this.background,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius;
    final trimmed = url?.trim();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: trimmed == null || trimmed.isEmpty
          ? fallback
          : Image(
              image: OfflineImage.provider(trimmed, withAuth: true),
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}

/// True when the picture is effectively a black frame.
Future<bool> _isBlank(ui.Image image) async {
  const side = 8;
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    const Rect.fromLTWH(0, 0, 8, 8),
    Paint(),
  );
  final small = await recorder.endRecording().toImage(side, side);
  final data = await small.toByteData(format: ui.ImageByteFormat.rawRgba);
  small.dispose();
  if (data == null || data.lengthInBytes < 4) return true;
  var sum = 0;
  final pixels = data.lengthInBytes ~/ 4;
  for (var i = 0; i < data.lengthInBytes; i += 4) {
    sum += data.getUint8(i) + data.getUint8(i + 1) + data.getUint8(i + 2);
  }
  return sum / (pixels * 3) < 8;
}

/// True when a picked photo file decodes as a blank frame.
Future<bool> photoFileIsBlank(String path) async {
  try {
    final bytes = await ui.ImmutableBuffer.fromFilePath(path);
    final descriptor = await ui.ImageDescriptor.encoded(bytes);
    final codec = await descriptor.instantiateCodec(targetWidth: 24);
    descriptor.dispose();
    bytes.dispose();
    final frame = await codec.getNextFrame();
    codec.dispose();
    final blank = await _isBlank(frame.image);
    frame.image.dispose();
    return blank;
  } catch (_) {
    return false;
  }
}
