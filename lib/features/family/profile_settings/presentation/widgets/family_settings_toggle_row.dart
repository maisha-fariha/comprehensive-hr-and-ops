import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/surface_card.dart';

/// A single "App Settings" row: a bold label and a trailing on/off switch,
/// no subtitle. Used for "Push Notifications"/"Dark Mode" — the minimal,
/// plausible completion of the cropped "App Settings" section (see
/// `FamilyProfileSettingsOverview`).
class FamilySettingsToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const FamilySettingsToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: AppDimens.cardPaddingHorizontal,
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: AppColors.textHeading,
              ),
            ),
          ),
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
      ),
    );
  }
}
