import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../family_messages_constants.dart';

class _AttachmentStyle {
  final String asset;
  final String label;

  const _AttachmentStyle({required this.asset, required this.label});
}

const Map<MessageAttachmentType, _AttachmentStyle> _attachmentStyles = {
  MessageAttachmentType.photo: _AttachmentStyle(
    asset: 'assets/icons/family_messages/photo.svg',
    label: 'Photo',
  ),
  MessageAttachmentType.pdf: _AttachmentStyle(
    asset: 'assets/icons/family_messages/pdf.svg',
    label: 'PDF',
  ),
  MessageAttachmentType.document: _AttachmentStyle(
    asset: 'assets/icons/family_messages/document.svg',
    label: 'Document',
  ),
};

/// One dashed attachment tile: icon box above label.
class AttachmentOptionTile extends StatelessWidget {
  final MessageAttachmentType type;
  final bool selected;
  final VoidCallback onTap;

  static const Color _border = Color(0xFFC5D0DA);
  static const Color _selectedBorder = Color(0xFF0E7C7B);
  static const Color _iconBg = Color(0xFFE7F4F1);
  static const Color _iconColor = Color(0xFF0E7C7B);
  static const Color _label = Color(0xFF6B7B8A);
  static const Color _selectedLabel = Color(0xFF0C5E5C);

  const AttachmentOptionTile({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _attachmentStyles[type]!;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 36);
    final borderColor = selected ? _selectedBorder : _border;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: borderColor,
          radius: radius,
          strokeWidth: ResponsiveHelper.getResponsiveWidth(context, 1.2),
          dashWidth: 4.5,
          dashGap: 3.5,
        ),
        child: Container(
          height: ResponsiveHelper.getResponsiveHeight(
            context,
            FamilyMessagesDimens.attachmentTileHeight,
          ),
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 10),
                  ),
                ),
                alignment: Alignment.center,
                child: AppSvgIcon(style.asset, size: 18, color: _iconColor),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
              Text(
                style.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: selected ? _selectedLabel : _label,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  const _DashedRRectPainter({
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
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = Path();

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashed.addPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          Offset.zero,
        );
        distance = next + dashGap;
      }
    }

    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}
