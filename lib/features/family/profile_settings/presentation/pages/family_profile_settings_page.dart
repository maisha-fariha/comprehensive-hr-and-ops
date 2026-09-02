import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../family_shell.dart';
import '../../../presentation/widgets/family_bottom_nav_bar.dart';
import '../../domain/entities/family_linked_client.dart';
import '../../domain/entities/family_preference_item.dart';
import '../controllers/family_profile_settings_controller.dart';
import '../widgets/family_linked_client_row.dart';
import '../widgets/family_log_out_row.dart';
import '../widgets/family_preference_tile.dart';
import '../widgets/family_profile_card.dart';
import '../widgets/family_profile_settings_header.dart';

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

  void _onPreferenceTap(
    BuildContext context,
    FamilyProfileSettingsController controller,
    FamilyPreferenceItem item,
  ) {
    switch (item.type) {
      case FamilyPreferenceType.contactSupport:
        _openSupportDialog(context, controller);
      case FamilyPreferenceType.notifications:
        _openNotificationPreferences(context, controller);
      case FamilyPreferenceType.changePassword:
        _openChangePassword(context, controller);
      case FamilyPreferenceType.helpCenter:
        Get.snackbar(
          'Help Center',
          'Help articles are provided by your care home and are not in this app yet.',
          snackPosition: SnackPosition.BOTTOM,
        );
      case FamilyPreferenceType.privacySecurity:
        Get.snackbar(
          'Privacy & Security',
          'Your profile is read-only here. Use Change Password to update credentials.',
          snackPosition: SnackPosition.BOTTOM,
        );
    }
  }

  Future<void> _openSupportDialog(
    BuildContext context,
    FamilyProfileSettingsController controller,
  ) async {
    final message = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: TextField(
          controller: message,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'How can the care team help?',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    final body = message.text.trim();
    message.dispose();
    if (sent == true && body.isNotEmpty) {
      await controller.submitSupportTicket(body);
    }
  }

  Future<void> _openChangePassword(
    BuildContext context,
    FamilyProfileSettingsController controller,
  ) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final currentValue = current.text;
    final nextValue = next.text;
    current.dispose();
    next.dispose();
    if (confirmed == true && currentValue.isNotEmpty && nextValue.isNotEmpty) {
      await controller.changePassword(
        currentPassword: currentValue,
        newPassword: nextValue,
      );
    }
  }

  Future<void> _openNotificationPreferences(
    BuildContext context,
    FamilyProfileSettingsController controller,
  ) async {
    final values = Map<String, bool>.from(
      await controller.loadNotificationPreferences(),
    );
    if (values.isEmpty) {
      Get.snackbar(
        'Notification preferences',
        'No notification settings are available for this account yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Notification Preferences'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in values.entries)
                  SwitchListTile(
                    title: Text(_preferenceLabel(entry.key)),
                    value: entry.value,
                    onChanged: (value) => setState(() => values[entry.key] = value),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.saveNotificationPreferences(values);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _preferenceLabel(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
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
                    _LinkedClientsCard(
                      clients: overview.linkedClients,
                      onSelect: (client) {
                        if (client.id.isEmpty) return;
                        Get.find<UserSession>().selectClient(client.id);
                        controller.refresh();
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'Preferences & Support'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    _PreferencesCard(
                      items: overview.preferenceItems,
                      onItemTap: (item) => _onPreferenceTap(context, controller, item),
                    ),
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
  final ValueChanged<FamilyLinkedClient> onSelect;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const _LinkedClientsCard({required this.clients, required this.onSelect});

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
            FamilyLinkedClientRow(
              client: clients[i],
              isSelected: Get.find<UserSession>().selectedClientId == clients[i].id,
              onTap: () => onSelect(clients[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// White card wrapping Preferences & Support rows with inset dividers.
class _PreferencesCard extends StatelessWidget {
  final List<FamilyPreferenceItem> items;
  final ValueChanged<FamilyPreferenceItem> onItemTap;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const _PreferencesCard({required this.items, required this.onItemTap});

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
            FamilyPreferenceTile(item: items[i], onTap: () => onItemTap(items[i])),
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
                  fontFamily: 'Manrope',
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
