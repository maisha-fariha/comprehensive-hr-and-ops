import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../staff_core_constants.dart';

/// Dark navy card showing the "Time Worked" label, a large tabular-figures
/// timer, and an "HH : MM : SS" caption beneath it.
///
/// Reuses `AppColors.primaryNavy` — the exact same dark-navy token already
/// used elsewhere in the app — so no new color is introduced for this card.
class TimeWorkedCard extends StatelessWidget {
  final String elapsedTimeLabel;

  const TimeWorkedCard({super.key, required this.elapsedTimeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusCard),
        ),
      ),
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 22, horizontal: 16),
      child: Column(
        children: [
          Text(
            'Time Worked',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.whiteOpacity70,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            elapsedTimeLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, StaffDimens.timerFontSize),
              color: Colors.white,
              letterSpacing: 1.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            'HH : MM : SS',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
              color: AppColors.whiteOpacity62,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
