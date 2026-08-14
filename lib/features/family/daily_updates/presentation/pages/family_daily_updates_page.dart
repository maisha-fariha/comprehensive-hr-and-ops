import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../controllers/family_daily_updates_controller.dart';
import '../widgets/family_daily_update_timeline_tile.dart';
import '../widgets/family_daily_updates_app_bar.dart';
import '../widgets/family_daily_updates_date_chip.dart';
import '../widgets/family_daily_updates_footer_banner.dart';

/// The Family "Daily Updates" screen: an approved-only timeline of the
/// resident's day.
///
/// Pixel-accurate reproduction of the reference "Daily Updates" screenshot.
/// This page is embedded as the body of a shared `FamilyShell` (bottom
/// navigation is supplied centrally), so it intentionally does not build
/// its own `Scaffold` bottom nav bar.
class FamilyDailyUpdatesPage extends StatelessWidget {
  const FamilyDailyUpdatesPage({super.key});

  FamilyDailyUpdatesController _resolveController() {
    try {
      return Get.find<FamilyDailyUpdatesController>();
    } catch (_) {
      return Get.put(GetIt.instance<FamilyDailyUpdatesController>(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(() {
          final response = controller.state.value;
          final overview = response.data;

          if (overview == null && controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
          }

          if (overview == null) {
            return _FamilyDailyUpdatesError(
              message: controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading Daily Updates.'
                  : controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          return Column(
            children: [
              FamilyDailyUpdatesAppBar(
                title: overview.screenTitle,
                subtitle: overview.screenSubtitle,
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
                      FamilyDailyUpdatesDateChip(label: overview.dateSectionLabel),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                      for (final entry in overview.entries) FamilyDailyUpdateTimelineTile(entry: entry),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                      FamilyDailyUpdatesFooterBanner(message: overview.footerNote),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _FamilyDailyUpdatesError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FamilyDailyUpdatesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
