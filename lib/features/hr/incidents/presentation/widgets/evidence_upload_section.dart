import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../incidents_constants.dart';

/// "Upload Evidence" dashed drop-zone on the wizard's Evidence step.
class EvidenceUploadDropzone extends StatelessWidget {
  final VoidCallback? onBrowseFiles;

  static const Color _zoneBackground = Color(0xFFF4F7F9);
  static const Color _zoneBorder = Color(0xFFD5DEE6);
  static const Color _iconTile = Color(0xFFE8EEF3);

  const EvidenceUploadDropzone({super.key, this.onBrowseFiles});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 48);

    return GestureDetector(
      onTap: onBrowseFiles,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedRectPainter(color: _zoneBorder, radius: radius),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _zoneBackground,
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            vertical: 28,
            horizontal: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: _iconTile,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: const AppSvgIcon(
                  'assets/icons/incidents/upload.svg',
                  size: 22,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textHeading,
                  ),
                  children: [
                    const TextSpan(text: 'Drag & drop, or '),
                    TextSpan(
                      text: 'browse files',
                      style: TextStyle(
                        color: AppColors.secondaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
              Text(
                'Images, PDF and documents · up to 25MB each',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRectPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = 0.7;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const dashWidth = 5.5;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Uploaded file row below the drop-zone.
class EvidenceFileChip extends StatelessWidget {
  final String fileName;
  final String subtitle;
  final VoidCallback onRemove;

  const EvidenceFileChip({
    super.key,
    required this.fileName,
    required this.subtitle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: IncidentsColors.evidenceAccentBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 10),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(
              'assets/icons/incidents/image.svg',
              size: 18,
              color: AppColors.secondaryTeal,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
              child: Icon(
                Icons.close_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: AppColors.textFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
