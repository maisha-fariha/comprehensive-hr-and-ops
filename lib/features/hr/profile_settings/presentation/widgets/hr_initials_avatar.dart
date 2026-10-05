import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/offline/offline_image.dart';

/// Circular avatar that shows [imageUrl] when available and falls back to
/// [initials] while loading or when the image fails.
class HrInitialsAvatar extends StatelessWidget {
  final String initials;
  final Color background;
  final Color foreground;
  final double size;
  final String? imageUrl;

  const HrInitialsAvatar({
    super.key,
    required this.initials,
    required this.background,
    required this.foreground,
    this.size = 44,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);
    final fallback = Center(
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.32),
          color: foreground,
        ),
      ),
    );
    final url = imageUrl?.trim();
    return Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? fallback
          : Image(
              image: OfflineImage.provider(url, withAuth: true),
              key: ValueKey(url),
              width: resolvedSize,
              height: resolvedSize,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : fallback,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}
