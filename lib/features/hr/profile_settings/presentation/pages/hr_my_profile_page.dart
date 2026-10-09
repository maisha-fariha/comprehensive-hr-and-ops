import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../hr_profile_settings_constants.dart';
import '../controllers/hr_profile_settings_controller.dart';
import '../widgets/hr_change_password_dialog.dart';
import '../widgets/hr_initials_avatar.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// "My profile": profile picture (change / remove), account info and
/// password change — mirrors the web portal's My profile page.
class HrMyProfilePage extends StatelessWidget {
  const HrMyProfilePage({super.key});

  HrProfileSettingsController _resolveController() {
    try {
      return Get.find<HrProfileSettingsController>();
    } catch (_) {
      return Get.put(
        GetIt.instance<HrProfileSettingsController>(),
        permanent: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    final session = Get.find<UserSession>();
    final gap = ResponsiveHelper.getResponsiveHeight(context, 14);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, 'My profile'),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final avatarUrl = session.avatarUrl;
          final busy = controller.avatarBusy.value;
          final initials = session.avatarInitials.isEmpty
              ? 'ME'
              : session.avatarInitials;

          return ListView(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: AppDimens.screenPaddingHorizontal,
              vertical: 16,
            ),
            children: [
              HrSectionCard(
                title: 'Profile picture',
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        HrInitialsAvatar(
                          initials: initials,
                          imageUrl: avatarUrl,
                          size: 84,
                          background:
                              HrProfileSettingsConstants.profileAvatarBackground,
                          foreground:
                              HrProfileSettingsConstants.profileAvatarForeground,
                        ),
                        if (busy)
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.secondaryTeal,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: busy ? null : controller.changeAvatar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondaryTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                                label: const Text('Upload'),
                              ),
                              if (avatarUrl != null)
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => _confirmRemove(context, controller),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.criticalRed,
                                    side: const BorderSide(
                                      color: AppColors.criticalBackground,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Remove'),
                                ),
                            ],
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                          Text(
                            'JPEG, PNG, WebP or HEIC, up to 25MB. If you are a staff member and set none, the photo on your staff record is shown.',
                            style: AppTextStyles.base(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              fontWeight: AppFontWeight.regular,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              HrSectionCard(
                title: 'Account',
                child: Column(
                  children: [
                    HrInfoRow(
                      label: 'Name',
                      value: session.displayName.isEmpty ? '—' : session.displayName,
                    ),
                    HrInfoRow(
                      label: 'Email',
                      value: session.email.isEmpty ? '—' : session.email,
                    ),
                    HrInfoRow(
                      label: 'Organisation',
                      value: session.organizationName ?? '—',
                    ),
                    HrInfoRow(
                      label: 'Role',
                      value: hrHumanize(session.roleRaw ?? session.role.label),
                    ),
                    if (session.residenceName != null)
                      HrInfoRow(label: 'Residence', value: session.residenceName!),
                  ],
                ),
              ),
              SizedBox(height: gap),
              HrSectionCard(
                title: 'Security',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => showHrChangePasswordDialog(context, controller),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textHeading,
                      side: const BorderSide(color: AppColors.searchBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.lock_outline_rounded, size: 18),
                    label: const Text('Change password'),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    HrProfileSettingsController controller,
  ) async {
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (context) => AppSheetDialog(
        title: const Text('Remove photo?'),
        content: const Text('Your initials will be shown instead.'),
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
