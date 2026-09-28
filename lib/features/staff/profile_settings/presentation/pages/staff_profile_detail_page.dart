import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/staff_profile.dart';
import '../../staff_profile_settings_constants.dart';
import '../widgets/staff_initials_avatar.dart';
import '../widgets/staff_profile_settings_header.dart';

/// Read-only profile details opened from the upper Profile card (BUG_Report001).
class StaffProfileDetailPage extends StatelessWidget {
  final StaffProfile profile;

  const StaffProfileDetailPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('staff-profile-detail-page'),
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StaffProfileSettingsHeader(
              onBackTap: Get.back,
              initials: profile.initials,
              title: 'My Profile',
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.getResponsiveWidth(
                    context,
                    AppDimens.screenPaddingHorizontal,
                  ),
                  ResponsiveHelper.getResponsiveHeight(context, 20),
                  ResponsiveHelper.getResponsiveWidth(
                    context,
                    AppDimens.screenPaddingHorizontal,
                  ),
                  ResponsiveHelper.getResponsiveHeight(context, 32),
                ),
                children: [
                  Center(
                    child: StaffInitialsAvatar(
                      initials: profile.initials,
                      size: 72,
                      background: StaffProfileSettingsConstants
                          .profileAvatarBackground,
                      foreground: StaffProfileSettingsConstants
                          .profileAvatarForeground,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 16),
                  ),
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 22),
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 4),
                  ),
                  Text(
                    profile.role,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: const Color(0xFF2D7D72),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 24),
                  ),
                  _DetailCard(
                    rows: [
                      _DetailRow(
                        label: 'Email',
                        value: profile.email,
                        icon: Icons.mail_outline_rounded,
                      ),
                      if ((profile.residenceName ?? '').isNotEmpty)
                        _DetailRow(
                          label: 'Residence / Organization',
                          value: profile.residenceName!,
                          icon: Icons.home_work_outlined,
                        ),
                      _DetailRow(
                        label: 'Role',
                        value: profile.role,
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 16),
                  ),
                  Text(
                    'Profile details are managed by your care home. '
                    'Use Change Password in Preferences to update credentials.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textMuted,
                      height: 1.4,
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

class _DetailCard extends StatelessWidget {
  final List<_DetailRow> rows;

  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 20),
        ),
        border: Border.all(color: const Color(0xFFEEF1F4)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEEF1F4)),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryTeal),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 2),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                    color: AppColors.textHeading,
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
