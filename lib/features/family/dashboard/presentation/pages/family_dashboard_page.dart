import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../appointments/presentation/pages/create_appointment_page.dart';
import '../../../documents/presentation/pages/family_documents_page.dart';
import '../../../family_shell.dart';
import '../../../messages/presentation/pages/compose_message_page.dart';
import '../../../profile_settings/presentation/pages/family_profile_settings_page.dart';
import '../controllers/family_dashboard_controller.dart';
import '../widgets/family_dashboard_header.dart';
import '../widgets/family_needs_attention_card.dart';
import '../widgets/family_next_appointment_section.dart';
import '../widgets/family_quick_actions_section.dart';
import '../widgets/family_recent_update_section.dart';
import '../widgets/family_today_at_a_glance_section.dart';
import '../widgets/family_todays_overview_section.dart';
import 'family_notifications_page.dart';
import 'family_search_page.dart';

/// The Family Dashboard - "Home" tab of the Family portal.
///
/// Pixel-accurate reproduction of the reference "Home" screenshot. This page
/// is embedded as the body of a shared `FamilyShell` (bottom navigation is
/// supplied centrally), so it intentionally does not build its own
/// `Scaffold` bottom nav bar.
class FamilyDashboardPage extends StatelessWidget {
  const FamilyDashboardPage({super.key});

  FamilyDashboardController _resolveController() {
    try {
      return Get.find<FamilyDashboardController>();
    } catch (_) {
      return Get.put(GetIt.instance<FamilyDashboardController>(), permanent: true);
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
          return _FamilyDashboardError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading the dashboard.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final horizontalPad = ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        );

        return RefreshIndicator(
          color: AppColors.secondaryTeal,
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FamilyDashboardHeader(
                  overview: overview,
                  onNotificationsTap: () =>
                      Get.to(() => const FamilyNotificationsPage()),
                  onAvatarTap: () =>
                      Get.to(() => const FamilyProfileSettingsPage()),
                  onSearchTap: () => Get.to(() => const FamilySearchPage()),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 18),
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 42),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (overview.attentionAlerts.isNotEmpty) ...[
                        FamilyNeedsAttentionCard(alerts: overview.attentionAlerts),
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                      ],
                      if (overview.overviewStats.isNotEmpty)
                        FamilyTodaysOverviewSection(
                          stats: overview.overviewStats,
                          lastUpdatedLabel: overview.lastUpdatedLabel,
                        ),
                      if (overview.nextAppointment != null) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                        FamilyNextAppointmentSection(
                          appointment: overview.nextAppointment!,
                          onTap: () => Get.offAll(
                            () => const FamilyShell(initialIndex: 2),
                          ),
                        ),
                      ],
                      if (overview.recentUpdate != null) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                        FamilyRecentUpdateSection(
                          update: overview.recentUpdate!,
                          onTap: () => Get.offAll(
                            () => const FamilyShell(initialIndex: 1),
                          ),
                        ),
                      ],
                      if (overview.glanceItems.isNotEmpty) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                        FamilyTodayAtAGlanceSection(
                          items: overview.glanceItems,
                        ),
                      ],
                      if (overview.quickActions.isNotEmpty) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                        FamilyQuickActionsSection(
                          actions: overview.quickActions,
                          onActionTap: (action) {
                            switch (action.id) {
                              case 'request-visit':
                                Get.to(() => const CreateAppointmentPage());
                              case 'send-message':
                                Get.to(() => const ComposeMessagePage());
                              case 'view-documents':
                                Get.to(() => const FamilyDocumentsPage());
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _FamilyDashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FamilyDashboardError({required this.message, required this.onRetry});

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
