import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../staff_core_constants.dart';
import '../../domain/entities/staff_shift.dart';
import 'shift_avatar_circle.dart';

/// A single shift row inside the shared "My Shifts" card (no outer card).
class ShiftCard extends StatelessWidget {
  final StaffShift shift;
  final VoidCallback? onTap;
  final bool showDividerBar;

  static const Color _primaryText = Color(0xFF1A232E);
  static const Color _secondaryText = Color(0xFF72849A);

  const ShiftCard({
    super.key,
    required this.shift,
    this.onTap,
    this.showDividerBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = staffingLevelStyles[shift.staffingLevel]!;
    final fill = (shift.filled / shift.total).clamp(0.0, 1.0);
    final rowGap = ResponsiveHelper.getResponsiveHeight(context, 6);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title · TODAY .................. Confirmed
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  shift.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                    color: _primaryText,
                    height: 1.2,
                  ),
                ),
              ),
              if (shift.isToday) ...[
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                _Badge(
                  label: 'TODAY',
                  color: const Color(0xFF2D8C83),
                  background: const Color(0xFFEBF7F6),
                  radius: 8,
                ),
              ],
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              _Badge(
                label: shift.statusLabel,
                color: const Color(0xFF2E8C58),
                background: const Color(0xFFEAF5EF),
                radius: 999,
              ),
            ],
          ),
          SizedBox(height: rowGap),
          Text(
            shift.dateTimeLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: _secondaryText,
              height: 1.3,
            ),
          ),
          SizedBox(height: rowGap),
          Row(
            children: [
              const AppSvgIcon(
                'assets/icons/staff_core/location.svg',
                size: 12,
                color: _secondaryText,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Flexible(
                child: Text(
                  shift.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: _secondaryText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          // Avatars + staff ........ ratio · role
          Row(
            children: [
              Flexible(
                child: Row(
                  children: [
                    for (var i = 0; i < shift.avatars.length; i++)
                      ShiftAvatarCircle(
                        avatar: shift.avatars[i],
                        paletteIndex: i,
                        isFirst: i == 0,
                      ),
                    if (shift.extraStaffCount > 0) ...[
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                      Flexible(
                        child: Text(
                          '+${shift.extraStaffCount} staff',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            color: _secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Text(
                '${shift.filled}/${shift.total}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: _primaryText,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              _Badge(
                label: shift.roleTag,
                color: const Color(0xFF3D6FB6),
                background: const Color(0xFFE8F0FE),
                radius: 8,
              ),
            ],
          ),
          if (showDividerBar) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(
                  context,
                  StaffDimens.progressBarHeight,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0xFFF1F3F4)),
                    FractionallySizedBox(
                      widthFactor: fill,
                      alignment: Alignment.centerLeft,
                      child: ColoredBox(color: style.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final double radius;

  const _Badge({
    required this.label,
    required this.color,
    required this.background,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, radius),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}
