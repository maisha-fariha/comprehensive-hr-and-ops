import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/refused_medication.dart';
import 'medication_avatar.dart';

/// Refused Medication card — header, reason box, REFUSED/REPORTED BY row,
/// and optional follow-up footer banner. Matched to the Refused tab reference.
class RefusedMedicationCard extends StatelessWidget {
  final RefusedMedication medication;
  final VoidCallback? onLogFollowUpTap;

  static const Color _accent = Color(0xFFB36B21);
  static const Color _accentSoft = Color(0xFFFCF5ED);
  static const Color _border = Color(0xFFF3E6D6);
  static const Color _reasonBg = Color(0xFFF7F8FA);
  static const Color _linkTeal = Color(0xFF0E7C7B);

  const RefusedMedicationCard({
    super.key,
    required this.medication,
    this.onLogFollowUpTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MedicationAvatar(
                      initials: medication.residentInitials,
                      palette: medication.avatarColor,
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
                    Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Refused',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                          color: _accent,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                Container(
                  width: double.infinity,
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _reasonBg,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: ResponsiveHelper.getResponsiveHeight(context, 1),
                        ),
                        child: const AppSvgIcon(
                          'assets/icons/medication/medication_comment.svg',
                          size: 14,
                          color: _accent,
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'REASON',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                                color: AppColors.textFaint,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                            Text(
                              medication.reason,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                                color: AppColors.textHeading,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _MiniInfoColumn(
                          caption: 'REFUSED',
                          child: Text(
                            medication.refusedTime,
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
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.getResponsiveWidth(context, 10),
                        ),
                        child: const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: AppColors.dividerLight,
                        ),
                      ),
                      Expanded(
                        child: _MiniInfoColumn(
                          caption: 'REPORTED BY',
                          child: Row(
                            children: [
                              MedicationAvatar(
                                initials: medication.reportedByInitials,
                                palette: medication.reportedByAvatarColor,
                                size: 20,
                              ),
                              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                              Flexible(
                                child: Text(
                                  medication.reportedByName,
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (medication.needsFollowUp)
            Container(
              width: double.infinity,
              color: _accentSoft,
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getResponsiveSize(context, 7),
                    height: ResponsiveHelper.getResponsiveSize(context, 7),
                    decoration: const BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                  Expanded(
                    child: Text(
                      'Follow-up required',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: _accent,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                  GestureDetector(
                    onTap: onLogFollowUpTap,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'Log follow-up →',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: _linkTeal,
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
