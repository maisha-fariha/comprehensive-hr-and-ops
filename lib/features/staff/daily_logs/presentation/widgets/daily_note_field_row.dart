import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/daily_note_field.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';

/// SVG paths under `assets/icons/staff_daily_logs/`.
const Map<DailyNoteFieldKey, String> _fieldIcons = {
  DailyNoteFieldKey.mood: 'assets/icons/staff_daily_logs/mood.svg',
  DailyNoteFieldKey.meals: 'assets/icons/staff_daily_logs/meals.svg',
  DailyNoteFieldKey.sleep: 'assets/icons/staff_daily_logs/sleep.svg',
  DailyNoteFieldKey.hygiene: 'assets/icons/staff_daily_logs/hygiene.svg',
  DailyNoteFieldKey.activities: 'assets/icons/staff_daily_logs/activities.svg',
  DailyNoteFieldKey.behavior: 'assets/icons/staff_daily_logs/behaviour.svg',
  DailyNoteFieldKey.wellness: 'assets/icons/staff_daily_logs/wellness.svg',
};

/// A Daily Note status row matched to the fields-card reference:
/// mint icon tile + bold label + light grey dropdown chip (~45% width).
class DailyNoteFieldRow extends StatelessWidget {
  final DailyNoteField field;
  final bool showDivider;
  final VoidCallback? onTap;

  static const Color _ink = Color(0xFF1A3338);
  static const Color _iconBg = Color(0xFFF0F8F6);
  static const Color _chipBg = Color(0xFFF5F9FA);
  static const Color _chevron = Color(0xFFAAB7C6);
  static const Color _divider = Color(0xFFEDF2F5);

  const DailyNoteFieldRow({
    super.key,
    required this.field,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconAsset = _fieldIcons[field.key]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 38);
    final iconRadius = ResponsiveHelper.getResponsiveRadius(context, 12);
    final chipRadius = ResponsiveHelper.getResponsiveRadius(context, 12);
    final inset = ResponsiveHelper.getResponsiveWidth(context, 2);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              top: 13,
              bottom: 13,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(iconRadius),
                  ),
                  alignment: Alignment.center,
                  child: AppSvgIcon(iconAsset, size: 18,),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                Expanded(
                  flex: 7,
                  child: Text(
                    field.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: _ink,
                      height: 1.2,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                Expanded(
                  flex: 13,
                  child: Container(
                    width: double.infinity,
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _chipBg,
                      borderRadius: BorderRadius.circular(chipRadius),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            field.value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                              color: _ink,
                              height: 1.25,
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                        const AppSvgIcon(
                          AppAssets.chevronDown,
                          size: 14,
                          color: _chevron,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: const Divider(height: 1, thickness: 1, color: _divider),
            ),
        ],
      ),
    );
  }
}
