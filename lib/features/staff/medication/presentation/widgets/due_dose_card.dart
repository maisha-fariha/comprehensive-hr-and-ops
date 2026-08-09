import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../staff_medication_constants.dart';
import 'status_by_row.dart';

/// A single dose card in the "Due" tab (Due Now / Later Today).
class DueDoseCard extends StatelessWidget {
  final DueDose dose;
  final VoidCallback onAdminister;
  final VoidCallback onNotGiven;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _metaColor = Color(0xFF7E8B9A);
  static const Color _accentGreen = Color(0xFF2D8A56);
  static const Color _notGivenBorder = Color(0xFFE5E9EF);

  const DueDoseCard({
    super.key,
    required this.dose,
    required this.onAdminister,
    required this.onNotGiven,
  });

  String get _routeLabel =>
      StaffMedicationConstants.routeLabel(dose.route).replaceAll(' · ', '  •  ');

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final avatarStyle = StaffMedicationConstants.avatarStyle(dose.avatarColor);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
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
                  color: avatarStyle.background,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  dose.residentInitials,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: avatarStyle.foreground,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
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
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: _titleColor,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                    Text(
                      '${dose.medicationName} ${dose.dose}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: _titleColor,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                    Text(
                      _routeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                        color: _metaColor,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Text(
                dose.timeLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: _accentGreen,
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          _buildActionArea(context),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context) {
    switch (dose.status) {
      case DueDoseStatus.upcoming:
      case DueDoseStatus.pending:
        return Row(
          children: [
            Expanded(child: _AdministerButton(onTap: onAdminister)),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(child: _NotGivenButton(onTap: onNotGiven)),
          ],
        );
      case DueDoseStatus.administered:
        return const StatusByRow(
          label: 'Administered',
          byName: 'you',
          background: AppColors.activeBackground,
          foreground: AppColors.activeGreen,
          svgAsset: AppAssets.checkCircle,
        );
      case DueDoseStatus.notGiven:
        return const StatusByRow(
          label: 'Not Given',
          byName: 'you',
          background: AppColors.criticalBackground,
          foreground: AppColors.criticalRed,
          materialIcon: Icons.cancel_rounded,
        );
    }
  }
}

class _AdministerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AdministerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          height: ResponsiveHelper.getResponsiveHeight(context, 44),
          decoration: BoxDecoration(
            color: DueDoseCard._accentGreen,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                'assets/icons/staff_medication/check.svg',
                size: ResponsiveHelper.getResponsiveSize(context, 16),
                color: Colors.white,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                'Administer',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotGivenButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NotGivenButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          height: ResponsiveHelper.getResponsiveHeight(context, 44),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: DueDoseCard._notGivenBorder),
          ),
          child: Center(
            child: Text(
              'Not Given',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: DueDoseCard._titleColor,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
