import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/medication_alert.dart';
import '../../domain/entities/medication_enums.dart';
import 'medication_avatar.dart';

class _AlertKindStyle {
  final Color background;
  final Color foreground;
  final String label;

  const _AlertKindStyle({required this.background, required this.foreground, required this.label});
}

const Map<AlertKind, _AlertKindStyle> _alertKindStyles = {
  AlertKind.refused: _AlertKindStyle(
    background: AppColors.urgentBackground,
    foreground: AppColors.urgentAmber,
    label: 'Refused',
  ),
  AlertKind.missed: _AlertKindStyle(
    background: AppColors.criticalBackground,
    foreground: AppColors.criticalRed,
    label: 'Missed',
  ),
};

/// A single row in the Overview tab's "Missed / Refused Alerts" card:
/// avatar + name + "medication · time" subtitle + status pill, plus a
/// note row underneath (e.g. "Resident declined medication").
class MedicationAlertTile extends StatelessWidget {
  final MedicationAlert alert;
  final bool showDivider;
  final VoidCallback? onTap;

  const MedicationAlertTile({
    super.key,
    required this.alert,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _alertKindStyles[alert.kind]!;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MedicationAvatar(initials: alert.residentInitials, palette: alert.avatarColor),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alert.residentName,
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
                        '${alert.medicationName} · ${alert.timeLabel}',
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
                StatusBadge.chip(
                  label: style.label,
                  background: style.background,
                  foreground: style.foreground,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            Padding(
              padding: EdgeInsets.only(
                left: ResponsiveHelper.getResponsiveWidth(context, 49),
              ),
              child: Row(
                children: [
                  AppSvgIcon(AppAssets.notePencil, size: 13, color: AppColors.textFaint),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                  Expanded(
                    child: Text(
                      alert.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
