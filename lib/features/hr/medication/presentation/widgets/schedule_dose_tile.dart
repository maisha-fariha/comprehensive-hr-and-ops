import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/schedule_dose.dart';
import 'medication_avatar.dart';

class _DoseStatusStyle {
  final Color background;
  final Color foreground;
  final String label;

  const _DoseStatusStyle({required this.background, required this.foreground, required this.label});
}

const Map<DoseStatus, _DoseStatusStyle> _doseStatusStyles = {
  DoseStatus.dueSoon: _DoseStatusStyle(
    background: AppColors.criticalBackground,
    foreground: AppColors.criticalRed,
    label: 'Due Soon',
  ),
  DoseStatus.upcoming: _DoseStatusStyle(
    background: AppColors.infoBackground,
    foreground: AppColors.infoBlue,
    label: 'Upcoming',
  ),
  DoseStatus.completed: _DoseStatusStyle(
    background: AppColors.activeBackground,
    foreground: AppColors.activeGreen,
    label: 'Completed',
  ),
  DoseStatus.due: _DoseStatusStyle(
    background: AppColors.infoBackground,
    foreground: AppColors.infoBlue,
    label: 'Due',
  ),
};

/// A single medication row card in the "Due" tab's schedule list (used for
/// both "Priority Medications" and "Later Today"). Shows the resident +
/// dose in the header row, then a "SCHEDULED"/"ASSIGNED" two-column mini
/// info row underneath. Completed doses render at reduced opacity.
class ScheduleDoseTile extends StatelessWidget {
  final ScheduleDose dose;
  final VoidCallback? onTap;

  const ScheduleDoseTile({super.key, required this.dose, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _doseStatusStyles[dose.status]!;
    final isCompleted = dose.status == DoseStatus.completed;

    return Opacity(
      opacity: isCompleted ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SurfaceCard.card(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  StatusBadge.chip(
                    label: style.label,
                    background: style.background,
                    foreground: style.foreground,
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              Container(height: 1, color: AppColors.dividerLight),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MiniInfoColumn(
                      caption: 'SCHEDULED',
                      child: Row(
                        children: [
                          AppSvgIcon(AppAssets.clock, size: 12, color: AppColors.textFaint),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                          Text(
                            dose.scheduledTime,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              color: AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _MiniInfoColumn(
                      caption: 'ASSIGNED',
                      child: Row(
                        children: [
                          MedicationAvatar(
                            initials: dose.assigneeInitials,
                            palette: dose.assigneeAvatarColor,
                            size: 18,
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                          Flexible(
                            child: Text(
                              dose.assigneeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                color: AppColors.textBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfoColumn extends StatelessWidget {
  final String caption;
  final Widget child;

  const _MiniInfoColumn({required this.caption, required this.child});

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
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9.5),
            color: AppColors.textFaint,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
        child,
      ],
    );
  }
}
