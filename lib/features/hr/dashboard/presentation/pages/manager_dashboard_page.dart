import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_search_bar.dart';
import '../widgets/needs_attention_card.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/todays_overview_section.dart';
import '../widgets/todays_schedule_card.dart';

/// The Manager/HR Dashboard - "Home" tab of the HR portal.
///
/// Pixel-accurate reproduction of the Figma "Dashboard" screen
/// (node 484:12195) inside the "Manager Mobile Screens" section.
class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({super.key});

  DashboardController _resolveController() {
    try {
      return Get.find<DashboardController>();
    } catch (_) {
      return Get.put(GetIt.instance<DashboardController>(), permanent: true);
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
          return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
        }

        if (overview == null) {
          return _DashboardError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading the dashboard.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final topInset = ResponsiveHelper.getResponsiveHeight(
              context,
              AppDimens.searchBarOverlap,
            ) +
            ResponsiveHelper.getResponsiveHeight(context, 18);

        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                DashboardHeader(overview: overview),
                Positioned(
                  left: ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                  right: ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                  bottom: -ResponsiveHelper.getResponsiveHeight(context, AppDimens.searchBarOverlap),
                  child: const DashboardSearchBar(),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    topInset,
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    ResponsiveHelper.getResponsiveHeight(context, 42),
                  ),
                  children: [
                    NeedsAttentionCard(alerts: overview.attentionAlerts),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    TodaysOverviewSection(
                      stats: overview.overviewStats,
                      lastUpdatedLabel: overview.lastUpdatedLabel,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    TodaysScheduleCard(shifts: overview.scheduleShifts),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    QuickActionsSection(actions: overview.quickActions),
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

class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardError({required this.message, required this.onRetry});

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
    );
  }
}
