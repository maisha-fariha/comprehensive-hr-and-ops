import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// "Mark as Priority" row on the "New Message" compose screen: a bell icon
/// in a light rounded box, a bold label + grey description, and an on/off
/// switch, mirroring the styling of
/// `lib/features/hr/incidents/presentation/widgets/follow_up_toggle_row.dart`.
class PriorityToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PriorityToggleRow({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 38);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: AppColors.urgentIconBackground,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 11),
            ),
          ),
          alignment: Alignment.center,
          child: const AppSvgIcon(AppAssets.bell, size: 17, color: AppColors.urgentAmber),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mark as Priority',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: AppColors.textHeading,
                ),
              ),
              Text(
                'Notify the recipient immediately',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.textFaint,
                ),
              ),
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
        ),
      ],
    );
  }
}
