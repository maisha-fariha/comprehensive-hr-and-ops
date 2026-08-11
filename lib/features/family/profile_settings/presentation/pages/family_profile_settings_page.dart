import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../family_shell.dart';
import '../../../presentation/widgets/family_bottom_nav_bar.dart';
import '../../domain/entities/family_linked_client.dart';
import '../../domain/entities/family_preference_item.dart';
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
/// its own `Scaffold`/`SafeArea` rather than being embedded in a shell.
///
/// Hosts [FamilyBottomNavBar] with "More" selected so the pushed route still
/// matches reference frames that show the family bottom nav.
class FamilyProfileSettingsPage extends StatelessWidget {
  const FamilyProfileSettingsPage({super.key});

  /// Index of the "More" slot in [FamilyBottomNavBar.items].
  static const int _moreTabIndex = 4;

  FamilyProfileSettingsController _resolveController() {
    try {
      return Get.find<FamilyProfileSettingsController>();
    } catch (_) {
      return Get.put(GetIt.instance<FamilyProfileSettingsController>(), permanent: true);
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => FamilyShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: FamilyBottomNavBar(
        currentIndex: _moreTabIndex,
        onTap: _onBottomNavTap,
      ),
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
                child: FamilyProfileSettingsHeader(
                  onBackTap: () => Navigator.maybePop(context),
                  initials: overview.profile.initials,
                ),
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
                    _LinkedClientsCard(clients: overview.linkedClients),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'Preferences & Support'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    _PreferencesCard(items: overview.preferenceItems),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'App Settings'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    // Obx(
                    //   () => FamilySettingsToggleRow(
                    //     label: 'Push Notifications',
                    //     value: controller.pushNotificationsEnabled.value,
                    //     onChanged: controller.togglePushNotifications,
                    //   ),
                    // ),
                    // SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    // Obx(
                    //   () => FamilySettingsToggleRow(
                    //     label: 'Dark Mode',
                    //     value: controller.darkModeEnabled.value,
                    //     onChanged: controller.toggleDarkMode,
                    //   ),
                    // ),
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

/// White card wrapping linked-client rows, a divider, and the add/switch link.
class _LinkedClientsCard extends StatelessWidget {
  final List<FamilyLinkedClient> clients;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const _LinkedClientsCard({required this.clients});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
          ),
          BoxShadow(
            color: _shadow.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < clients.length; i++) ...[
            if (i > 0)
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                ),
                child: const Divider(height: 1, thickness: 1, color: _divider),
              ),
            FamilyLinkedClientRow(client: clients[i]),
          ],
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 16,
            ),
            child: const Divider(height: 1, thickness: 1, color: _divider),
          ),
          const FamilyAddClientLink(),
        ],
      ),
    );
  }
}

/// White card wrapping Preferences & Support rows with inset dividers.
class _PreferencesCard extends StatelessWidget {
  final List<FamilyPreferenceItem> items;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const _PreferencesCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
          ),
          BoxShadow(
            color: _shadow.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                ),
                child: const Divider(height: 1, thickness: 1, color: _divider),
              ),
            FamilyPreferenceTile(item: items[i]),
          ],
        ],
      ),
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
