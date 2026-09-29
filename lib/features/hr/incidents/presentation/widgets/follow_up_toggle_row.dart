import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Pale teal on/off card used across People / Investigate wizard steps
/// (Emergency Services, Family Notified, Follow-up, Debrief, etc.).
class FollowUpToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  static const Color _cardBackground = Color(0xFFEAF7F5);
  static const Color _cardBorder = Color(0xFFB7E0DB);

  const FollowUpToggleRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.title = 'Schedule a follow-up review',
    this.subtitle = 'Assign a supervisor to re-check this incident',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: _cardBackground,
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                    height: 1.25,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 3),
                  ),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.secondaryTeal,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.cardBorder,
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
