import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../staff_shell.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../domain/entities/staff_linked_item.dart';
import '../../domain/entities/staff_preference_item.dart';
import '../controllers/staff_profile_settings_controller.dart';
import '../widgets/staff_linked_item_row.dart';
import '../widgets/staff_log_out_row.dart';
import '../widgets/staff_preference_tile.dart';
import '../widgets/staff_profile_card.dart';
import '../widgets/staff_profile_settings_header.dart';

/// Profile & Settings for the Staff portal — same visual design as Family.
class StaffProfileSettingsPage extends StatelessWidget {
  const StaffProfileSettingsPage({super.key});

  static const int _moreTabIndex = 4;

  StaffProfileSettingsController _resolveController() {
    try {
      return Get.find<StaffProfileSettingsController>();
    } catch (_) {
      return Get.put(GetIt.instance<StaffProfileSettingsController>(), permanent: true);
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  void _onPreferenceTap(
    BuildContext context,
    StaffProfileSettingsController controller,
    StaffPreferenceItem item,
  ) {
    switch (item.type) {
      case StaffPreferenceType.contactSupport:
        _openSupportDialog(context, controller);
      case StaffPreferenceType.notifications:
        _openNotificationPreferences(context, controller);
      case StaffPreferenceType.changePassword:
        _openChangePassword(context, controller);
      case StaffPreferenceType.helpCenter:
        Get.snackbar(
          'Help Center',
          'Help articles are provided by your care home and are not in this app yet.',
          snackPosition: SnackPosition.BOTTOM,
        );
      case StaffPreferenceType.privacySecurity:
        Get.snackbar(
          'Privacy & Security',
          'Your profile comes from your account. Use Change Password to update credentials.',
          snackPosition: SnackPosition.BOTTOM,
        );
    }
  }

  Future<void> _openSupportDialog(
    BuildContext context,
    StaffProfileSettingsController controller,
  ) async {
    final message = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: TextField(
          controller: message,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'How can we help?'),
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
    StaffProfileSettingsController controller,
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
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
    StaffProfileSettingsController controller,
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
                    title: Text(entry.key),
                    value: entry.value,
                    onChanged: (value) => setState(() => values[entry.key] = value),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
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
          return _StaffProfileSettingsError(
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
                child: StaffProfileSettingsHeader(
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
                    StaffProfileCard(profile: overview.profile),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
                    const SectionHeaderRow(title: 'Assigned Clients'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    _StaffLinkedItemsCard(items: overview.linkedItems),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'Preferences & Support'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    _StaffPreferencesCard(
                      items: overview.preferenceItems,
                      onItemTap: (item) => _onPreferenceTap(context, controller, item),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'App Settings'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    const StaffLogOutRow(),
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

class _StaffLinkedItemsCard extends StatelessWidget {
  final List<StaffLinkedItem> items;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const _StaffLinkedItemsCard({required this.items});

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
      child: items.isEmpty
          ? Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
              child: const Text('No assigned clients for this account.'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16),
                      child: const Divider(height: 1, thickness: 1, color: _divider),
                    ),
                  StaffLinkedItemRow(item: items[i]),
                ],
              ],
            ),
    );
  }
}

class _StaffPreferencesCard extends StatelessWidget {
  final List<StaffPreferenceItem> items;
  final ValueChanged<StaffPreferenceItem> onItemTap;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const _StaffPreferencesCard({required this.items, required this.onItemTap});

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
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16),
                child: const Divider(height: 1, thickness: 1, color: _divider),
              ),
            StaffPreferenceTile(item: items[i], onTap: () => onItemTap(items[i])),
          ],
        ],
      ),
    );
  }
}

class _StaffProfileSettingsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _StaffProfileSettingsError({required this.message, required this.onRetry});

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
