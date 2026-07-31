import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/daily_note_field.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../staff_daily_logs_constants.dart';

class _FieldStyle {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _FieldStyle({required this.icon, required this.iconColor, required this.iconBackground});
}

// None of these 7 emoji-style glyphs (mood/meals/sleep/hygiene/
// activities/behavior/wellness) have a matching SVG in `assets/icons/*`,
// so every entry here uses a Material `Icons.*` stand-in - flagged in the
// final report.
final Map<DailyNoteFieldKey, _FieldStyle> _fieldStyles = {
  DailyNoteFieldKey.mood: const _FieldStyle(
    icon: Icons.sentiment_satisfied_alt_rounded,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  DailyNoteFieldKey.meals: const _FieldStyle(
    icon: Icons.restaurant_rounded,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
  ),
  DailyNoteFieldKey.sleep: const _FieldStyle(
    icon: Icons.nightlight_round,
    iconColor: AppColors.nightPurple,
    iconBackground: AppColors.nightBackground,
  ),
  DailyNoteFieldKey.hygiene: const _FieldStyle(
    icon: Icons.shower_rounded,
    iconColor: AppColors.infoBlue,
    iconBackground: AppColors.infoIconBackground,
  ),
  DailyNoteFieldKey.activities: const _FieldStyle(
    icon: Icons.directions_run_rounded,
    iconColor: AppColors.secondaryTeal,
    iconBackground: AppColors.quickActionCreateShiftBg,
  ),
  DailyNoteFieldKey.behavior: const _FieldStyle(
    icon: Icons.chat_bubble_rounded,
    iconColor: StaffDailyLogsConstants.roseForeground,
    iconBackground: StaffDailyLogsConstants.roseBackground,
  ),
  DailyNoteFieldKey.wellness: const _FieldStyle(
    icon: Icons.favorite_rounded,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
};

/// A single dropdown-style row on the "Daily Note" screen: a small colored
/// icon circle, the field's label, and its current value with a trailing
/// chevron-down. Tappable but does not open a real selector in this mock -
/// a visually-accurate static row is enough per the reference screenshot.
class DailyNoteFieldRow extends StatelessWidget {
  final DailyNoteField field;
  final bool showDivider;
  final VoidCallback? onTap;

  const DailyNoteFieldRow({super.key, required this.field, required this.showDivider, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _fieldStyles[field.key]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 34);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: showDivider
            ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.dividerLight)))
            : null,
        padding: ResponsiveHelper.getResponsivePadding(context, top: 13, bottom: 13),
        child: Row(
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(color: style.iconBackground, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(
                style.icon,
                size: ResponsiveHelper.getResponsiveSize(context, 17),
                color: style.iconColor,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Text(
              field.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: AppColors.textPrimary,
              ),
            ),
            Expanded(
              child: Text(
                field.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: AppColors.textBody,
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            const AppSvgIcon(AppAssets.chevronDown, size: 14, color: AppColors.iconChevron),
          ],
        ),
      ),
    );
  }
}
