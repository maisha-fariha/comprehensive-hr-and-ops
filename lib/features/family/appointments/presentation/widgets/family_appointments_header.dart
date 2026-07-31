import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Shared top app bar for the Family Appointments feature: a bordered
/// rounded-square back button plus a centered title, used by both the
/// Appointments list screen and the Create Appointment form.
///
/// Icon note: the back chevron has no matching SVG in `assets/icons/*`, so
/// this uses the Material `Icons.arrow_back_ios_new_rounded` as a temporary
/// stand-in, matching the pattern already used by the Staff Incidents
/// feature's header.
class FamilyAppointmentsHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const FamilyAppointmentsHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 8, bottom: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border.all(color: AppColors.searchBorder),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 17),
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 19),
                color: AppColors.textHeading,
              ),
            ),
          ),
          SizedBox(width: buttonSize),
        ],
      ),
    );
  }
}
