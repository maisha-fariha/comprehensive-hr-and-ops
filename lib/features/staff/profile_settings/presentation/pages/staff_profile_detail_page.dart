import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/staff_profile.dart';
import '../../staff_profile_settings_constants.dart';
import '../controllers/staff_profile_settings_controller.dart';
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
                  _PictureSection(initials: profile.initials),
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

class _PictureSection extends StatelessWidget {
  final String initials;

  const _PictureSection({required this.initials});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StaffProfileSettingsController>();
    final session = Get.find<UserSession>();
    return Obx(() {
      final url = session.avatarUrl;
      final busy = controller.avatarBusy.value;
      return Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 20),
          ),
          border: Border.all(color: const Color(0xFFEEF1F4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Picture',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    StaffInitialsAvatar(
                      initials: initials,
                      imageUrl: url,
                      size: 64,
                      background: StaffProfileSettingsConstants
                          .profileAvatarBackground,
                      foreground: StaffProfileSettingsConstants
                          .profileAvatarForeground,
                    ),
                    if (busy)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                  ],
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            key: const Key('staff-profile-upload-photo'),
                            onPressed: busy ? null : controller.changeAvatar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryTeal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.photo_camera_outlined, size: 16),
                            label: const Text('Upload'),
                          ),
                          if (url != null && url.isNotEmpty)
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => _confirmRemove(context, controller),
                              child: const Text('Remove'),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 6),
                      ),
                      Text(
                        'JPEG, PNG, WebP or HEIC, up to 25MB. If you are a staff member and set none, the photo on your staff record is shown.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12,
                          ),
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _confirmRemove(
    BuildContext context,
    StaffProfileSettingsController controller,
  ) async {
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (context) => AppSheetDialog(
        title: const Text('Remove photo?'),
        content: const Text(
          'If you are a staff member and set none, the photo on your staff record is shown.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.removeAvatar();
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
