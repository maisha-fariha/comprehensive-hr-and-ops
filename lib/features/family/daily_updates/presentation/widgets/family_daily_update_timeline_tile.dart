import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_daily_update_entry.dart';
import '../../domain/entities/family_daily_update_enums.dart';

class _CategoryStyle {
  final String asset;
  final Color accent;
  final Color background;

  const _CategoryStyle({
    required this.asset,
    required this.accent,
    required this.background,
  });
}

const Map<DailyUpdateCategory, _CategoryStyle> _categoryStyles = {
  DailyUpdateCategory.mood: _CategoryStyle(
    asset: 'assets/icons/family_core/emoji.svg',
    accent: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
  ),
  DailyUpdateCategory.meals: _CategoryStyle(
    asset: 'assets/icons/family_core/meals.svg',
    accent: Color(0xFF5B6B8C),
    background: Color(0xFFEBEEF7),
  ),
  DailyUpdateCategory.activities: _CategoryStyle(
    asset: 'assets/icons/family_core/activities.svg',
    accent: Color(0xFF6A4BC7),
    background: Color(0xFFF0ECFB),
  ),
  DailyUpdateCategory.communityOuting: _CategoryStyle(
    asset: 'assets/icons/family_core/image.svg',
    accent: Color(0xFF3D7A6A),
    background: Color(0xFFE8F3EE),
  ),
  DailyUpdateCategory.sleep: _CategoryStyle(
    asset: 'assets/icons/family_core/sleep.svg',
    accent: Color(0xFFD98324),
    background: Color(0xFFFBF1E6),
  ),
};

/// A single Daily Updates timeline row: time, dashed track + node, and card.
class FamilyDailyUpdateTimelineTile extends StatelessWidget {
  final FamilyDailyUpdateEntry entry;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _bodyColor = Color(0xFF707B81);
  static const Color _nodeColor = Color(0xFF0E7C7B);
  static const Color _lineColor = Color(0xFFD1D9DB);
  static const Color _border = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const FamilyDailyUpdateTimelineTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyles[entry.category]!;
    final nodeSize = ResponsiveHelper.getResponsiveSize(context, 12);
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final timeColumnWidth = ResponsiveHelper.getResponsiveWidth(context, 68);
    final trackWidth = ResponsiveHelper.getResponsiveWidth(context, 18);
    final cardRadius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: timeColumnWidth,
            child: Padding(
              padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 18)),
              child: Text(
                entry.timeLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: _titleColor,
                  height: 1.2,
                ),
              ),
            ),
          ),
          SizedBox(
            width: trackWidth,
            child: Column(
              children: [
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                Container(
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _nodeColor, width: 2),
                  ),
                ),
                if (entry.showTimelineDivider)
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: CustomPaint(
                        painter: _DashedLinePainter(color: _lineColor),
                        child: SizedBox(width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 12)),
              child: Container(
                padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: _shadow.withValues(alpha: 0.04),
                      offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
                      blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
                    ),
                    BoxShadow(
                      color: _shadow.withValues(alpha: 0.05),
                      offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
                      blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                              color: _titleColor,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                          Text(
                            entry.description,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w400,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                              color: _bodyColor,
                              height: 1.4,
                            ),
                          ),
                          if (entry.hasPhoto) ...[
                            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                            Row(
                              children: [
                                Icon(
                                  Icons.photo_outlined,
                                  size: 14,
                                  color: style.accent,
                                ),
                                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                                Text(
                                  'Photo attached',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w600,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                                    color: style.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: style.background,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: AppSvgIcon(style.asset, size: 20, color: style.accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashHeight = 4.0;
    const dashGap = 4.0;
    var y = 0.0;
    final x = size.width / 2;

    while (y < size.height) {
      final endY = (y + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, endY), paint);
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
