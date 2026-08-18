import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/missing_log_entry.dart';

/// A single card in the Missing tab's "Missing Logs" list — matched to the
/// "Missing - Daily-logs" Figma reference: person avatar, name + home
/// location, overdue/late pill, expected-shift / assigned-staff meta row,
/// and a divider footer with Send Reminder / Contact Staff actions.
class MissingLogCard extends StatelessWidget {
  final MissingLogEntry entry;
  final VoidCallback? onSendReminder;
  final VoidCallback? onContactStaff;

  const MissingLogCard({
    super.key,
    required this.entry,
    this.onSendReminder,
    this.onContactStaff,
  });

  bool get _isLate =>
      entry.overdueLabel.toLowerCase().contains('late') &&
      !entry.overdueLabel.toLowerCase().contains('overdue');

  @override
  Widget build(BuildContext context) {
    final isLate = _isLate;
    final accent = isLate ? AppColors.urgentAmber : AppColors.criticalRed;
    final accentBg =
        isLate ? AppColors.urgentBackground : AppColors.criticalIconBackground;
    final iconBg = isLate
        ? AppColors.urgentIconBackground
        : AppColors.criticalIconBackground;
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final staffAvatarSize = ResponsiveHelper.getResponsiveSize(context, 22);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(
          color: isLate
              ? AppColors.cardBorder
              : AppColors.criticalBackground,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.03),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/daily_logs/daily_log_person.svg',
                        width: ResponsiveHelper.getResponsiveSize(context, 22),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 11),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.staffName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                14.5,
                              ),
                              color: AppColors.textHeading,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              3,
                            ),
                          ),
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/daily_logs/daily_log_home.svg',
                                width: ResponsiveHelper.getResponsiveSize(
                                  context,
                                  13,
                                ),
                              ),
                              SizedBox(
                                width: ResponsiveHelper.getResponsiveWidth(
                                  context,
                                  4,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  entry.locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w400,
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      12,
                                    ),
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 8),
                    ),
                    Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 8),
                        ),
                      ),
                      child: Text(
                        entry.overdueLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            11,
                          ),
                          color: accent,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MetaColumn(
                        label: 'EXPECTED SHIFT',
                        child: Text(
                          entry.expectedShiftLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              13,
                            ),
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 10),
                    ),
                    Expanded(
                      child: _MetaColumn(
                        label: 'ASSIGNED STAFF',
                        child: Row(
                          children: [
                            Container(
                              width: staffAvatarSize,
                              height: staffAvatarSize,
                              decoration: const BoxDecoration(
                                color: AppColors.infoBackground,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                entry.assignedStaffInitials,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    9,
                                  ),
                                  color: AppColors.infoBlue,
                                  height: 1,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: ResponsiveHelper.getResponsiveWidth(
                                context,
                                6,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                entry.assignedStaffName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    13,
                                  ),
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
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _FooterAction(
                    svgAsset: 'assets/icons/daily_logs/daily_log_reminder.svg',
                    label: 'Send Reminder',
                    color: AppColors.secondaryTeal,
                    onTap: onSendReminder,
                  ),
                ),
                VerticalDivider(
                  width: ResponsiveHelper.getResponsiveWidth(context, 1),
                  thickness: 1,
                  color: AppColors.dividerLight,
                ),
                Expanded(
                  child: _FooterAction(
                    svgAsset: 'assets/icons/daily_logs/phone.svg',
                    label: 'Contact Staff',
                    color: AppColors.textBody,
                    onTap: onContactStaff,
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

class _MetaColumn extends StatelessWidget {
  final String label;
  final Widget child;

  const _MetaColumn({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
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

class _FooterAction extends StatelessWidget {
  final String svgAsset;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _FooterAction({
    required this.svgAsset,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            vertical: 14,
            horizontal: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(svgAsset, size: 15, color: color),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12.5,
                    ),
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
