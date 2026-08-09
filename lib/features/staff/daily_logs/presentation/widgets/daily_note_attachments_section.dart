import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Attachments block matched to the Daily Note reference: title, Photo /
/// Upload File actions, and dashed "+ Add image / file" drop zone.
class DailyNoteAttachmentsSection extends StatelessWidget {
  final VoidCallback? onAddPhoto;
  final VoidCallback? onAddFiles;

  static const String _cameraAsset = 'assets/icons/staff_daily_logs/camera.svg';
  static const String _uploadAsset = 'assets/icons/staff_daily_logs/upload.svg';

  static const Color _title = Color(0xFF1A2533);
  static const Color _iconTeal = Color(0xFF006B6B);
  static const Color _dash = Color(0xFFCBD8DE);
  static const Color _buttonBorder = Color(0xFFE2E8F0);

  const DailyNoteAttachmentsSection({
    super.key,
    this.onAddPhoto,
    this.onAddFiles,
  });

  @override
  Widget build(BuildContext context) {
    final buttonRadius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final dashRadius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Attachments',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: _title,
            height: 1.2,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
        Row(
          children: [
            Expanded(
              child: _AttachmentButton(
                asset: _cameraAsset,
                label: 'Photo',
                radius: buttonRadius,
                onTap: onAddPhoto,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: _AttachmentButton(
                asset: _uploadAsset,
                label: 'Upload File',
                radius: buttonRadius,
                onTap: onAddFiles,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        GestureDetector(
          onTap: onAddFiles ?? onAddPhoto,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: _dash,
              radius: dashRadius,
              strokeWidth: 1.5,
              dashWidth: 5,
              dashGap: 4,
            ),
            child: Container(
              width: double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                vertical: 20,
                horizontal: 16,
              ),
              alignment: Alignment.center,
              child: Text(
                '+ Add image / file',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: Color(0xFF64748B),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  final String asset;
  final String label;
  final double radius;
  final VoidCallback? onTap;

  const _AttachmentButton({
    required this.asset,
    required this.label,
    required this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 14,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: DailyNoteAttachmentsSection._buttonBorder),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              asset,
              size: 18,
              color: DailyNoteAttachmentsSection._iconTeal,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: DailyNoteAttachmentsSection._title,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}
