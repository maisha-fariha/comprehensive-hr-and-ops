import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/medication_dose.dart';
import 'medication_avatar.dart';

/// A single row in the Overview tab's "Due Today" list: avatar, resident
/// name + "medication dose" subtitle, and a trailing time + "Due" pill.
class MedicationDoseRow extends StatelessWidget {
  final MedicationDose dose;
  final bool showDivider;
  final VoidCallback? onTap;

  const MedicationDoseRow({
    super.key,
    required this.dose,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
              )
            : null,
        padding: ResponsiveHelper.getResponsivePadding(context, top: 12, bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MedicationAvatar(initials: dose.residentInitials, palette: dose.avatarColor),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dose.residentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${dose.medicationName} ${dose.dose}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dose.timeLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                const StatusBadge.chip(
                  label: 'Due',
                  background: AppColors.infoBackground,
                  foreground: AppColors.infoBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
