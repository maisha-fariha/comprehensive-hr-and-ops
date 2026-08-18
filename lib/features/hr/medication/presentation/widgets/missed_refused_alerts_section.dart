import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/medication_alert.dart';
import '../../domain/entities/medication_enums.dart';

/// Overview tab "Missed / Refused Alerts" block: title + soft count badge,
/// then separate soft pink-bordered white cards per alert.
/// Matched to the Missed / Refused Alerts reference screenshot.
class MissedRefusedAlertsSection extends StatelessWidget {
  final List<MedicationAlert> alerts;
  final int totalCount;
  final ValueChanged<MedicationAlert>? onAlertTap;

  static const Color _alertBorder = Color(0xFFFDECEC);
  static const Color _countSoft = Color(0xFFFDECEC);
  static const Color _countFg = Color(0xFFD32F2F);

  static const Color _refusedAccent = Color(0xFFB75C00);
  static const Color _refusedSoft = Color(0xFFFFF3E0);
  static const Color _refusedAvatarBg = Color(0xFFFFF3E0);
  static const Color _refusedAvatarFg = Color(0xFFB75C00);

  static const Color _missedAccent = Color(0xFFD32F2F);
  static const Color _missedSoft = Color(0xFFFDECEC);

  const MissedRefusedAlertsSection({
    super.key,
    required this.alerts,
    required this.totalCount,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Missed / Refused Alerts',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            _SoftCountBadge(count: totalCount),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < alerts.length; i++) ...[
          if (i > 0) SizedBox(height: cardGap),
          _AlertCard(
            alert: alerts[i],
            onTap: onAlertTap == null ? null : () => onAlertTap!(alerts[i]),
          ),
        ],
      ],
    );
  }
}

class _SoftCountBadge extends StatelessWidget {
  final int count;

  const _SoftCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 22);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: MissedRefusedAlertsSection._countSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: MissedRefusedAlertsSection._countFg,
          height: 1,
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final MedicationAlert alert;
  final VoidCallback? onTap;

  const _AlertCard({required this.alert, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRefused = alert.kind == AlertKind.refused;
    final badgeBg = isRefused
        ? MissedRefusedAlertsSection._refusedSoft
        : MissedRefusedAlertsSection._missedSoft;
    final badgeFg = isRefused
        ? MissedRefusedAlertsSection._refusedAccent
        : MissedRefusedAlertsSection._missedAccent;
    final badgeLabel = isRefused ? 'Refused' : 'Missed';
    final noteIcon = isRefused
        ? 'assets/icons/medication/medication_comment.svg'
        : 'assets/icons/medication/medication_clock.svg';
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: MissedRefusedAlertsSection._alertBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoundedAvatar(alert: alert),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          alert.residentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                            color: AppColors.textHeading,
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                      Container(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                            color: badgeFg,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                  Text(
                    '${alert.medicationName} · ${alert.timeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textBody,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 7)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: ResponsiveHelper.getResponsiveHeight(context, 1),
                        ),
                        child: AppSvgIcon(
                          noteIcon,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                      Expanded(
                        child: Text(
                          alert.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
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

class _RoundedAvatar extends StatelessWidget {
  final MedicationAlert alert;

  const _RoundedAvatar({required this.alert});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;

    if (alert.kind == AlertKind.refused) {
      bg = MissedRefusedAlertsSection._refusedAvatarBg;
      fg = MissedRefusedAlertsSection._refusedAvatarFg;
    } else {
      final colors = switch (alert.avatarColor) {
        AvatarPalette.blue => (AppColors.infoBackground, AppColors.infoBlue),
        AvatarPalette.green => (AppColors.activeBackground, AppColors.activeGreen),
        AvatarPalette.purple => (AppColors.nightBackground, AppColors.nightPurple),
      };
      bg = colors.$1;
      fg = colors.$2;
    }

    final size = ResponsiveHelper.getResponsiveSize(context, 40);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        alert.residentInitials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}
