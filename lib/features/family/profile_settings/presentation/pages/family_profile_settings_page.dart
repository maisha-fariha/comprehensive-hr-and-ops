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
import '../widgets/family_add_client_link.dart';
import '../widgets/family_linked_client_row.dart';
import '../widgets/family_log_out_row.dart';
import '../widgets/family_preference_tile.dart';
import '../widgets/family_profile_card.dart';
import '../widgets/family_profile_settings_header.dart';
import 'family_notification_preferences_page.dart';
import 'family_support_tickets_page.dart';

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

  void _openLinkedClientSwitcher(
    BuildContext context,
    FamilyProfileSettingsController controller,
    List<FamilyLinkedClient> clients,
  ) {
    if (clients.isEmpty) {
      Get.snackbar(
        'Linked clients',
        'No linked clients are available yet. Ask the care home to link a resident.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.bottomSheet(
      SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 20,
                  top: 16,
                  bottom: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch client',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          16,
                        ),
                        color: const Color(0xFF1A2B48),
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    Text(
                      clients.length == 1
                          ? 'Only one linked resident is available on this account.'
                          : 'Choose which linked resident to view.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: const Color(0xFF6B7C93),
                      ),
                    ),
                  ],
                ),
              ),
              for (final client in clients)
                Obx(() {
                  final selected =
                      Get.find<UserSession>().selectedClientId == client.id;
                  return ListTile(
                    title: Text(
                      client.name,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: client.subtitle.isEmpty
                        ? null
                        : Text(client.subtitle),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0E7C7B),
                          )
                        : const Icon(
                            Icons.radio_button_unchecked,
                            color: Color(0xFFB0BACA),
                          ),
                    onTap: () async {
                      if (Get.isBottomSheetOpen ?? false) {
                        Get.back<void>();
                      }
                      await controller.switchLinkedClient(client);
                    },
                  );
                }),
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 20,
                  bottom: 12,
                ),
                child: Text(
                  'New residents can only be linked by the care home.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: const Color(0xFF8E9BAE),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _onPreferenceTap(
    BuildContext context,
    FamilyProfileSettingsController controller,
    FamilyPreferenceItem item,
  ) {
    switch (item.type) {
      case FamilyPreferenceType.contactSupport:
        Get.to(() => const FamilySupportTicketsPage());
      case FamilyPreferenceType.notifications:
        Get.to(() => const FamilyNotificationPreferencesPage());
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

  Future<void> _openChangePassword(
    BuildContext context,
    FamilyProfileSettingsController controller,
  ) async {
    final result = await showDialog<({String current, String next})>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
    if (result == null) return;
    if (result.current.isEmpty || result.next.isEmpty) return;
    await controller.changePassword(
      currentPassword: result.current,
      newPassword: result.next,
    );
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
                      onSelect: controller.switchLinkedClient,
                      onAddSwitchTap: () => _openLinkedClientSwitcher(
                        context,
                        controller,
                        overview.linkedClients,
                      ),
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
  final VoidCallback onAddSwitchTap;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const _LinkedClientsCard({
    required this.clients,
    required this.onSelect,
    required this.onAddSwitchTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: _shadow.withValues(alpha: 0.04),
              offset:
                  Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
            ),
            BoxShadow(
              color: _shadow.withValues(alpha: 0.05),
              offset:
                  Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              final selectedId = Get.find<UserSession>().selectedClientId;
              if (clients.isEmpty) {
                return Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: const Text(
                    'No linked clients are available for this account yet.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7C93),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < clients.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 16,
                        ),
                        child: const Divider(
                          height: 1,
                          thickness: 1,
                          color: _divider,
                        ),
                      ),
                    FamilyLinkedClientRow(
                      client: clients[i],
                      isSelected: selectedId == clients[i].id,
                      onTap: () => onSelect(clients[i]),
                    ),
                  ],
                ],
              );
            }),
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
              ),
              child: const Divider(height: 1, thickness: 1, color: _divider),
            ),
            // Keep outside Obx so the tap target is not rebuilt mid-gesture.
            FamilyAddClientLink(onTap: onAddSwitchTap),
          ],
        ),
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

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  late final TextEditingController _current;
  late final TextEditingController _next;

  @override
  void initState() {
    super.initState();
    _current = TextEditingController();
    _next = TextEditingController();
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          TextField(
            controller: _next,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            (current: _current.text, next: _next.text),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
