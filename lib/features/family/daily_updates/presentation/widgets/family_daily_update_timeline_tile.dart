import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_daily_update_entry.dart';
import '../../domain/entities/family_daily_update_enums.dart';
import '../../family_daily_updates_constants.dart';

class _CategoryStyle {
  final IconData icon;
  final Color color;
  final Color background;

  const _CategoryStyle({required this.icon, required this.color, required this.background});
}

// None of these 5 emoji-style glyphs (mood/meals/activities/community
// outing/sleep) have a matching SVG in `assets/icons/*`, so every entry here
// uses a Material `Icons.*` stand-in - flagged in the final report.
final Map<DailyUpdateCategory, _CategoryStyle> _categoryStyles = {
  DailyUpdateCategory.mood: const _CategoryStyle(
    icon: Icons.sentiment_satisfied_alt_rounded,
    color: AppColors.activeGreen,
    background: AppColors.activeIconBackground,
  ),
  DailyUpdateCategory.meals: const _CategoryStyle(
    icon: Icons.restaurant_rounded,
    color: FamilyDailyUpdatesColors.mealsForeground,
    background: FamilyDailyUpdatesColors.mealsBackground,
  ),
  DailyUpdateCategory.activities: const _CategoryStyle(
    icon: Icons.self_improvement_rounded,
    color: AppColors.nightPurple,
    background: AppColors.nightBackground,
  ),
  DailyUpdateCategory.communityOuting: const _CategoryStyle(
    icon: Icons.image_rounded,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
  ),
  DailyUpdateCategory.sleep: const _CategoryStyle(
    icon: Icons.nightlight_round,
    color: FamilyDailyUpdatesColors.sleepForeground,
    background: FamilyDailyUpdatesColors.sleepBackground,
  ),
};

/// A single row in the "Daily Updates" vertical timeline: a time label, a
/// colored dot connected by a vertical divider to the next row, the
/// entry's title/description, and a small colored icon-in-rounded-box on
/// the row's trailing edge.
class FamilyDailyUpdateTimelineTile extends StatelessWidget {
  final FamilyDailyUpdateEntry entry;

  const FamilyDailyUpdateTimelineTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyles[entry.category]!;
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 11);
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 38);
    final timeColumnWidth = ResponsiveHelper.getResponsiveWidth(context, 62);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: timeColumnWidth,
            child: Padding(
              padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 1)),
              child: Text(
                entry.timeLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          SizedBox(
            width: ResponsiveHelper.getResponsiveWidth(context, 16),
            child: Column(
              children: [
                Container(
                  width: dotSize,
                  height: dotSize,
                  margin: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
                ),
                if (entry.showTimelineDivider)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      child: Center(
                        child: Container(width: 2, color: AppColors.timelineDivider),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 22)),
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
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                        Text(
                          entry.description,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
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
                        ResponsiveHelper.getResponsiveRadius(context, 11),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      style.icon,
                      size: ResponsiveHelper.getResponsiveSize(context, 18),
                      color: style.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
