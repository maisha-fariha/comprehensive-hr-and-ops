import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../incidents_constants.dart';

/// "Upload Evidence" dashed drop-zone on the wizard's "Evidence" step:
/// upload-cloud icon, "Drag & drop, or **browse files**" text and a size/
/// format caption.
///
/// Icon note: no existing SVG matches an upload-cloud glyph, so this uses
/// Material `Icons.upload_rounded` as a temporary stand-in.
class EvidenceUploadDropzone extends StatelessWidget {
  final VoidCallback? onBrowseFiles;

  const EvidenceUploadDropzone({super.key, this.onBrowseFiles});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBrowseFiles,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedRectPainter(color: AppColors.searchBorder),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, vertical: 28, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 44),
                height: ResponsiveHelper.getResponsiveSize(context, 44),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.upload_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 20),
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                  ),
                  children: const [
                    TextSpan(text: 'Drag & drop, or '),
                    TextSpan(text: 'browse files', style: TextStyle(color: AppColors.secondaryTeal)),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
              Text(
                'Images, PDF and documents · up to 25MB each',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                  color: AppColors.textFaint,
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

  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => oldDelegate.color != color;
}

/// A single uploaded-file row below the drop-zone, e.g.
/// "incident-scene-01.jpg / JPG · 2.4 MB" with a trailing remove button.
///
/// Icon note: no existing SVG matches an image-file glyph, so this uses
/// Material `Icons.image_outlined` as a temporary stand-in.
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
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 36);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 13),
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
            child: Icon(
              Icons.image_outlined,
              size: ResponsiveHelper.getResponsiveSize(context, 17),
              color: AppColors.secondaryTeal,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
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
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.close_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}
