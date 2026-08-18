import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../hr_shell.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';
import '../../domain/entities/hr_linked_item.dart';
import '../../domain/entities/hr_preference_item.dart';
import '../controllers/hr_profile_settings_controller.dart';
import '../widgets/hr_add_linked_item_link.dart';
import '../widgets/hr_linked_item_row.dart';
import '../widgets/hr_log_out_row.dart';
import '../widgets/hr_preference_tile.dart';
import '../widgets/hr_profile_card.dart';
import '../widgets/hr_profile_settings_header.dart';

/// Profile & Settings for the Hr portal — same visual design as Family.
class HrProfileSettingsPage extends StatelessWidget {
  const HrProfileSettingsPage({super.key});

  static const int _moreTabIndex = 4;

  HrProfileSettingsController _resolveController() {
    try {
      return Get.find<HrProfileSettingsController>();
    } catch (_) {
      return Get.put(GetIt.instance<HrProfileSettingsController>(), permanent: true);
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => HrShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: HrBottomNavBar(
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
          return _HrProfileSettingsError(
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
                child: HrProfileSettingsHeader(
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
                    HrProfileCard(profile: overview.profile),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
                    const SectionHeaderRow(title: 'Managed Residences'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    _HrLinkedItemsCard(items: overview.linkedItems),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'Preferences & Support'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    _HrPreferencesCard(items: overview.preferenceItems),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'App Settings'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    const HrLogOutRow(),
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

class _HrLinkedItemsCard extends StatelessWidget {
  final List<HrLinkedItem> items;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const _HrLinkedItemsCard({required this.items});

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
            HrLinkedItemRow(item: items[i]),
          ],
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16),
            child: const Divider(height: 1, thickness: 1, color: _divider),
          ),
          const HrAddLinkedItemLink(),
        ],
      ),
    );
  }
}

class _HrPreferencesCard extends StatelessWidget {
  final List<HrPreferenceItem> items;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const _HrPreferencesCard({required this.items});

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
            HrPreferenceTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _HrProfileSettingsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _HrProfileSettingsError({required this.message, required this.onRetry});

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
