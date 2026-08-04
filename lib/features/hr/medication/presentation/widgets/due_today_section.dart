import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/medication_dose.dart';
import '../../domain/entities/medication_enums.dart';

/// Overview tab "Due Today" block: title + soft count badge, then a white
/// list card of doses and an optional "+N more / View all" footer.
/// Matched to the Due Today reference screenshot.
class DueTodaySection extends StatelessWidget {
  final List<MedicationDose> doses;
  final int moreCount;
  final VoidCallback? onViewAll;
  final ValueChanged<MedicationDose>? onDoseTap;

  static const Color _dueBlue = Color(0xFF2A5DA6);
  static const Color _dueBlueSoft = Color(0xFFEAF0F9);

  const DueTodaySection({
    super.key,
    required this.doses,
    required this.moreCount,
    this.onViewAll,
    this.onDoseTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = doses.length + moreCount;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Due Today',
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
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < doses.length; i++)
                _DueDoseRow(
                  dose: doses[i],
                  showDivider: i != doses.length - 1 || moreCount > 0,
                  onTap: onDoseTap == null ? null : () => onDoseTap!(doses[i]),
                ),
              if (moreCount > 0)
                GestureDetector(
                  onTap: onViewAll,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      top: 12,
                      bottom: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: ResponsiveHelper.getResponsiveSize(context, 22),
                          height: ResponsiveHelper.getResponsiveSize(context, 22),
                          decoration: const BoxDecoration(
                            color: _dueBlueSoft,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add_rounded,
                            size: ResponsiveHelper.getResponsiveSize(context, 14),
                            color: _dueBlue,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                        Expanded(
                          child: Text(
                            '$moreCount more medications due',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w500,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          'View all',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                            color: AppColors.secondaryTeal,
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
    );
  }
}

/// Soft light-blue circular badge with navy count (far right of section header).
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
        color: DueTodaySection._dueBlueSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: DueTodaySection._dueBlue,
          height: 1,
        ),
      ),
    );
  }
}

class _DueDoseRow extends StatelessWidget {
  final MedicationDose dose;
  final bool showDivider;
  final VoidCallback? onTap;

  const _DueDoseRow({
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
        padding: ResponsiveHelper.getResponsivePadding(context, top: 13, bottom: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RoundedAvatar(initials: dose.residentInitials, palette: dose.avatarColor),
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
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textHeading,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    '${dose.medicationName} ${dose.dose}',
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
                Text(
                  dose.timeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DueTodaySection._dueBlueSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Due',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                      color: DueTodaySection._dueBlue,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded-square initials avatar used by Due Today list rows.
class _RoundedAvatar extends StatelessWidget {
  final String initials;
  final AvatarPalette palette;

  const _RoundedAvatar({required this.initials, required this.palette});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (palette) {
      AvatarPalette.blue => (AppColors.infoBackground, AppColors.infoBlue),
      AvatarPalette.green => (AppColors.activeBackground, AppColors.activeGreen),
      AvatarPalette.purple => (AppColors.nightBackground, AppColors.nightPurple),
    };
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
        initials,
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
