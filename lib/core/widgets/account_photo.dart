import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../offline/offline_image.dart';

/// Account photo, or [fallback] when there is no photo, it cannot be loaded,
/// or the file is a blank frame (a known camera-compression failure).
class AccountPhoto extends StatefulWidget {
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
  State<AccountPhoto> createState() => _AccountPhotoState();
}

class _AccountPhotoState extends State<AccountPhoto> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  String? _subscribed;
  ImageInfo? _frame;
  int _request = 0;
  bool _useFallback = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribe();
  }

  @override
  void didUpdateWidget(AccountPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _subscribe();
  }

  void _subscribe() {
    final url = widget.url?.trim();
    if (url == null || url.isEmpty) {
      _unsubscribe();
      _subscribed = null;
      _request++;
      _frame?.dispose();
      _frame = null;
      if (!_useFallback) setState(() => _useFallback = true);
      return;
    }
    if (url == _subscribed) return;
    _unsubscribe();
    _subscribed = url;
    _request++;
    _frame?.dispose();
    _frame = null;
    _useFallback = true;
    final stream = OfflineImage.provider(url, withAuth: true).resolve(
      createLocalImageConfiguration(context),
    );
    final listener = ImageStreamListener(_onImage, onError: _onError);
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  Future<void> _onImage(ImageInfo info, bool synchronousCall) async {
    final kept = info.clone();
    info.dispose();
    final request = _request;
    final blank = await _isBlank(kept.image);
    if (!mounted || request != _request) {
      kept.dispose();
      return;
    }
    if (blank) {
      kept.dispose();
      setState(() {
        _frame?.dispose();
        _frame = null;
        _useFallback = true;
      });
      return;
    }
    setState(() {
      _frame?.dispose();
      _frame = kept;
      _useFallback = false;
    });
  }

  void _onError(Object exception, StackTrace? stackTrace) {
    if (!mounted) return;
    setState(() {
      _frame?.dispose();
      _frame = null;
      _useFallback = true;
    });
  }

  void _unsubscribe() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    _frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius;
    final frame = _frame;
    return Container(
      width: widget.size,
      height: widget.size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.background,
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: _useFallback || frame == null
          ? widget.fallback
          : RawImage(
              image: frame.image,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
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
