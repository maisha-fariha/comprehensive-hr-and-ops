import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Shared top app bar for every Staff Incidents page: a back chevron plus
/// either a centered title (list page) or a left-aligned title + subtitle
/// (Create Incident / Incident Details pages), with an optional trailing
/// action (e.g. the Incident Details share button).
///
/// Icon note: the back chevron has no matching SVG in `assets/icons/*`, so
/// this uses the Material `Icons.arrow_back_ios_new_rounded` as a temporary
/// stand-in, matching the pattern already used by the Manager Incidents
/// feature's wizard header.
class StaffIncidentsHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const StaffIncidentsHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 22);
    final backButton = GestureDetector(
      onTap: onBack,
      behavior: HitTestBehavior.opaque,
      child: Icon(Icons.arrow_back_ios_new_rounded, size: buttonSize, color: AppColors.textPrimary),
    );

    final titleText = Text(
      title,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 19),
        color: AppColors.textHeading,
      ),
    );

    if (subtitle == null) {
      return Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 8, bottom: 14),
        child: Row(
          children: [
            backButton,
            Expanded(child: Center(child: titleText)),
            SizedBox(width: buttonSize, child: trailing),
          ],
        ),
      );
    }

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 8, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 2)),
            child: backButton,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleText,
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            trailing!,
          ],
        ],
      ),
    );
  }
}
