import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../errors/app_snackbar.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

export 'package:image_picker/image_picker.dart' show CameraDevice;

enum _AttachmentSource { camera, gallery, files }

/// Drop-in replacement for `FilePicker.platform.pickFiles` that also offers
/// "Take photo" and "Photo library" on Android / iOS.
///
/// Returns the same [FilePickerResult] shape, so callers keep their existing
/// validation and upload code. The source sheet only appears when the allowed
/// types accept a JPEG photo; otherwise (and on web / desktop) this goes
/// straight to the system file picker exactly as before.
abstract final class AppFilePicker {
  /// Long edge cap + JPEG quality for camera / library photos. Keeps a typical
  /// phone photo well under 2 MB without visible quality loss.
  static const double _maxPhotoDimension = 2560;
  static const int _photoQuality = 85;

  static Future<FilePickerResult?> pickFiles({
    BuildContext? context,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
    String? title,
    CameraDevice preferredCamera = CameraDevice.rear,
  }) async {
    final sheetContext = context ?? Get.overlayContext ?? Get.context;
    if (!_supportsCamera ||
        !_acceptsPhotos(type, allowedExtensions) ||
        sheetContext == null ||
        !sheetContext.mounted) {
      return _browseFiles(type, allowedExtensions, allowMultiple, withData);
    }

    final imagesOnly = type == FileType.image;
    final source = await showAppBottomSheet<_AttachmentSource>(
      context: sheetContext,
      backgroundColor: AppColors.surfaceWhite,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AttachmentSourceSheet(
        title: title ?? (imagesOnly ? 'Add photo' : 'Add attachment'),
        showFiles: !imagesOnly,
        allowMultiple: allowMultiple,
      ),
    );

    switch (source) {
      case null:
        return null;
      case _AttachmentSource.files:
        return _browseFiles(type, allowedExtensions, allowMultiple, withData);
      case _AttachmentSource.camera:
        return _fromCamera(preferredCamera, withData);
      case _AttachmentSource.gallery:
        return _fromGallery(
          type: type,
          allowedExtensions: allowedExtensions,
          allowMultiple: allowMultiple,
          withData: withData,
        );
    }
  }

  static bool get _supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool _acceptsPhotos(FileType type, List<String>? extensions) {
    switch (type) {
      case FileType.any:
      case FileType.image:
      case FileType.media:
        return true;
      case FileType.custom:
        final allowed = _normalized(extensions);
        return allowed.contains('jpg') || allowed.contains('jpeg');
      default:
        return false;
    }
  }

  static Set<String> _normalized(List<String>? extensions) => {
        for (final e in extensions ?? const <String>[])
          e.toLowerCase().replaceFirst('.', ''),
      };

  static Future<FilePickerResult?> _browseFiles(
    FileType type,
    List<String>? allowedExtensions,
    bool allowMultiple,
    bool withData,
  ) {
    return FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: type == FileType.custom ? allowedExtensions : null,
      allowMultiple: allowMultiple,
      withData: withData,
    );
  }

  static Future<FilePickerResult?> _fromCamera(
    CameraDevice preferredCamera,
    bool withData,
  ) async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCamera,
        maxWidth: _maxPhotoDimension,
        maxHeight: _maxPhotoDimension,
        imageQuality: _photoQuality,
      );
      if (photo == null) return null;
      return FilePickerResult([await _toPlatformFile(photo, withData)]);
    } on PlatformException catch (error) {
      _showAccessError(error, camera: true);
      return null;
    }
  }

  static Future<FilePickerResult?> _fromGallery({
    required FileType type,
    required List<String>? allowedExtensions,
    required bool allowMultiple,
    required bool withData,
  }) async {
    try {
      final picker = ImagePicker();
      final List<XFile> picked;
      if (allowMultiple) {
        picked = await picker.pickMultiImage(
          maxWidth: _maxPhotoDimension,
          maxHeight: _maxPhotoDimension,
          imageQuality: _photoQuality,
        );
      } else {
        final single = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: _maxPhotoDimension,
          maxHeight: _maxPhotoDimension,
          imageQuality: _photoQuality,
        );
        picked = single == null ? const [] : [single];
      }
      if (picked.isEmpty) return null;

      final allowed =
          type == FileType.custom ? _normalized(allowedExtensions) : null;
      final files = <PlatformFile>[];
      final rejected = <String>[];
      for (final image in picked) {
        final ext = image.name.split('.').last.toLowerCase();
        if (allowed != null && !allowed.contains(ext)) {
          rejected.add(image.name);
          continue;
        }
        files.add(await _toPlatformFile(image, withData));
      }
      if (rejected.isNotEmpty) {
        AppSnackbar.show(
          'Unsupported photo',
          '${rejected.join(', ')} ${rejected.length == 1 ? 'is' : 'are'} '
              'not an allowed format. Try Take photo or Browse files.',
          force: true,
        );
      }
      return files.isEmpty ? null : FilePickerResult(files);
    } on PlatformException catch (error) {
      _showAccessError(error, camera: false);
      return null;
    }
  }

  static Future<PlatformFile> _toPlatformFile(XFile file, bool withData) async {
    final bytes = withData ? await file.readAsBytes() : null;
    final size = bytes?.length ?? await File(file.path).length();
    return PlatformFile(
      path: file.path,
      name: file.name,
      size: size,
      bytes: bytes,
    );
  }

  static void _showAccessError(PlatformException error, {required bool camera}) {
    final denied = error.code.contains('access_denied') ||
        error.code.contains('permission');
    AppSnackbar.show(
      camera ? 'Camera unavailable' : 'Photos unavailable',
      denied
          ? 'Allow ${camera ? 'camera' : 'photo library'} access in Settings, '
              'then try again.'
          : (error.message ?? 'Something went wrong. Please try again.'),
      force: true,
    );
  }
}

class _AttachmentSourceSheet extends StatelessWidget {
  final String title;
  final bool showFiles;
  final bool allowMultiple;

  const _AttachmentSourceSheet({
    required this.title,
    required this.showFiles,
    required this.allowMultiple,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose where to add it from.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _SourceTile(
              key: const Key('attachment-source-camera'),
              icon: Icons.photo_camera_outlined,
              iconColor: AppColors.secondaryTeal,
              iconBackground: AppColors.quickActionCreateShiftBg,
              title: 'Take photo',
              subtitle: 'Use the camera now',
              onTap: () => Navigator.of(context).pop(_AttachmentSource.camera),
            ),
            const SizedBox(height: 10),
            _SourceTile(
              key: const Key('attachment-source-gallery'),
              icon: Icons.photo_library_outlined,
              iconColor: AppColors.infoBlue,
              iconBackground: AppColors.infoBackground,
              title: 'Photo library',
              subtitle: allowMultiple
                  ? 'Pick one or more saved photos'
                  : 'Pick a saved photo',
              onTap: () => Navigator.of(context).pop(_AttachmentSource.gallery),
            ),
            if (showFiles) ...[
              const SizedBox(height: 10),
              _SourceTile(
                key: const Key('attachment-source-files'),
                icon: Icons.upload_file_outlined,
                iconColor: AppColors.urgentAmber,
                iconBackground: AppColors.urgentBackgroundSoft,
                title: 'Browse files',
                subtitle: 'PDFs, documents and other files',
                onTap: () => Navigator.of(context).pop(_AttachmentSource.files),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
