import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../controllers/family_profile_settings_controller.dart';
import '../widgets/family_add_client_link.dart';
import '../widgets/family_linked_client_row.dart';
import '../widgets/family_log_out_row.dart';
import '../widgets/family_preference_tile.dart';
import '../widgets/family_profile_card.dart';
import '../widgets/family_profile_settings_header.dart';
import '../widgets/family_settings_toggle_row.dart';

/// "Profile & Settings" — the Family portal's screen for the signed-in
/// family member's own profile, linked clients, and app preferences.
///
/// Pushed as a standalone route (e.g. `Get.to(() => const
/// FamilyProfileSettingsPage())`) from the Family "More" hub, so it owns
/// its own `Scaffold`/`SafeArea` rather than being embedded in a shell —
/// the same convention used by `StaffAttendancePage` when pushed outside
/// the Staff bottom-nav shell.
class FamilyProfileSettingsPage extends StatelessWidget {
  const FamilyProfileSettingsPage({super.key});

  FamilyProfileSettingsController _resolveController() {
    try {
      return Get.find<FamilyProfileSettingsController>();
    } catch (_) {
      return Get.put(GetIt.instance<FamilyProfileSettingsController>(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Obx(() {
        final response = controller.state.value;
        final overview = response.data;

        if (overview == null && controller.isLoading.value) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal)),
          );
        }

        if (overview == null) {
          return _FamilyProfileSettingsError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading your profile.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: SafeArea(
                bottom: false,
                child: FamilyProfileSettingsHeader(onBackTap: () => Navigator.maybePop(context)),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    ResponsiveHelper.getResponsiveHeight(context, 32),
                  ),
                  children: [
                    // Profile is only editable via the settings "More" hub
                    // consolidation step; no destination screen exists yet.
                    FamilyProfileCard(profile: overview.profile),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
                    const SectionHeaderRow(title: 'Linked Clients'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    for (final client in overview.linkedClients) ...[
                      FamilyLinkedClientRow(client: client),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                    ],
                    const FamilyAddClientLink(),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'Preferences & Support'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    for (final item in overview.preferenceItems) ...[
                      FamilyPreferenceTile(item: item),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    ],
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                    const SectionHeaderRow(title: 'App Settings'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    Obx(
                      () => FamilySettingsToggleRow(
                        label: 'Push Notifications',
                        value: controller.pushNotificationsEnabled.value,
                        onChanged: controller.togglePushNotifications,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    Obx(
                      () => FamilySettingsToggleRow(
                        label: 'Dark Mode',
                        value: controller.darkModeEnabled.value,
                        onChanged: controller.toggleDarkMode,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    const FamilyLogOutRow(),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _FamilyProfileSettingsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FamilyProfileSettingsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.criticalRed, size: 40),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryTeal),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
