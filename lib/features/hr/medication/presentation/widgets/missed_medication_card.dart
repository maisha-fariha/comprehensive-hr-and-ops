import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/missed_medication.dart';

/// Missed Medication card — avatar/name/tags, 3-column info row, and
/// Review / Contact Staff action bar. Matched to the Missed tab reference.
class MissedMedicationCard extends StatelessWidget {
  final MissedMedication medication;
  final VoidCallback? onReviewTap;
  final VoidCallback? onContactStaffTap;

  static const Color _alertRed = Color(0xFFD64545);
  static const Color _alertSoft = Color(0xFFFBEDED);
  static const Color _criticalBorder = Color(0xFFF3DADA);

  const MissedMedicationCard({
    super.key,
    required this.medication,
    this.onReviewTap,
    this.onContactStaffTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: medication.isCritical ? _criticalBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundedAvatar(
                initials: medication.residentInitials,
                palette: medication.avatarColor,
                size: 40,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      medication.residentName,
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
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                    Text(
                      '${medication.medicationName} ${medication.dose}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.textMuted,
                        height: 1.25,
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
                  if (medication.isCritical) ...[
                    const _SoftTag(label: 'Critical'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  ],
                  const _SoftTag(label: 'Missed'),
                ],
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MiniInfo(
                    caption: 'SCHEDULED',
                    child: Text(
                      medication.scheduledTime,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                ),
                _VDivider(),
                Expanded(
                  child: _MiniInfo(
                    caption: 'MISSED',
                    child: Text(
                      medication.missedTimeAgo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                        color: _alertRed,
                      ),
                    ),
                  ),
                ),
                _VDivider(),
                Expanded(
                  child: _MiniInfo(
                    caption: 'ASSIGNED',
                    child: Row(
                      children: [
                        _RoundedAvatar(
                          initials: medication.assigneeInitials,
                          palette: medication.assigneeAvatarColor,
                          size: 18,
                          radius: 5,
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                        Flexible(
                          child: Text(
                            medication.assigneeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              color: AppColors.textHeading,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          const Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onReviewTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppSvgIcon(
                          'assets/icons/medication/medication_alert.svg',
                          size: 14,
                          color: _alertRed,
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                        Flexible(
                          child: Text(
                            'Review Medication Issue',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                              color: _alertRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveWidth(context, 6),
                  ),
                  child: const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.dividerLight,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onContactStaffTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppSvgIcon(
                          'assets/icons/medication/medication_call.svg',
                          size: 14,
                          color: AppColors.textHeading,
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                        Flexible(
                          child: Text(
                            'Contact Staff',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                              color: AppColors.textHeading,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftTag extends StatelessWidget {
  final String label;

  const _SoftTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: MissedMedicationCard._alertSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
          color: MissedMedicationCard._alertRed,
          height: 1.1,
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveWidth(context, 8),
      ),
      child: const VerticalDivider(
        width: 1,
        thickness: 1,
        color: AppColors.dividerLight,
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String caption;
  final Widget child;

  const _MiniInfo({required this.caption, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
            color: AppColors.textFaint,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
        child,
      ],
    );
  }
}

class _RoundedAvatar extends StatelessWidget {
  final String initials;
  final AvatarPalette palette;
  final double size;
  final double radius;

  const _RoundedAvatar({
    required this.initials,
    required this.palette,
    required this.size,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (palette) {
      AvatarPalette.blue => (AppColors.infoBackground, AppColors.infoBlue),
      AvatarPalette.green => (AppColors.activeBackground, AppColors.activeGreen),
      AvatarPalette.purple => (AppColors.nightBackground, AppColors.nightPurple),
    };
    final resolved = ResponsiveHelper.getResponsiveSize(context, size);

    return Container(
      width: resolved,
      height: resolved,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, radius),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.32),
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}
