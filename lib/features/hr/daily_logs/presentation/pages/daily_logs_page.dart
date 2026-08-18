import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../hr_shell.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../controllers/daily_logs_controller.dart';
import '../widgets/handover_tab_view.dart';
import '../widgets/missing_tab_view.dart';
import '../widgets/review_tab_view.dart';

/// The "Daily Logs" screen: a single page hosting three segmented tabs
/// (Review / Missing / Handover) that share the same white app bar and
/// tab-bar header. Tab UIs match their Figma references.
///
/// Hosts [HrBottomNavBar] with "More" selected so the pushed route still
/// matches the reference frames that show the manager bottom nav.
class DailyLogsPage extends StatelessWidget {
  const DailyLogsPage({super.key});

  /// Index of the "More" slot in [HrBottomNavBar.items].
  static const int _moreTabIndex = 4;

  DailyLogsController _resolveController() {
    try {
      return Get.find<DailyLogsController>();
    } catch (_) {
      return Get.put(GetIt.instance<DailyLogsController>(), permanent: true);
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
      body: Obx(() {
        final response = controller.state.value;
        final overview = response.data;

        if (overview == null && controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (overview == null) {
          return _DailyLogsError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading Daily Logs.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final selectedTab = controller.selectedTab.value;

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const _DailyLogsHeader(),
                    _DailyLogsTabBar(
                      selectedTab: selectedTab,
                      missingBadgeCount: overview.missingLogs.length,
                      onTabSelected: controller.selectTab,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: switch (selectedTab) {
                  DailyLogsTab.review => ReviewTabView(
                      stats: overview.reviewStats,
                      submittedLogs: overview.submittedLogs,
                      submittedLogsTotalCount: overview.submittedLogsTotalCount,
                      clientStatusSummaries: overview.clientStatusSummaries,
                    ),
                  DailyLogsTab.missing => MissingTabView(
                      stats: overview.missingStats,
                      missingLogs: overview.missingLogs,
                    ),
                  DailyLogsTab.handover => HandoverTabView(
                      stats: overview.handoverStats,
                      handoverEntries: overview.handoverEntries,
                    ),
                },
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: HrBottomNavBar(
        currentIndex: _moreTabIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _DailyLogsHeader extends StatelessWidget {
  const _DailyLogsHeader();

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 36);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 8,
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 24),
            color: AppColors.textHeading,
          ),
          Expanded(
            child: Text(
              'Daily Logs',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: AppColors.textHeading,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(
              AppAssets.search,
              size: 18,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _DailyLogsTabBar extends StatelessWidget {
  final DailyLogsTab selectedTab;
  final int missingBadgeCount;
  final ValueChanged<DailyLogsTab> onTabSelected;

  const _DailyLogsTabBar({
    required this.selectedTab,
    required this.missingBadgeCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (DailyLogsTab.review, 'Review', null),
      (DailyLogsTab.missing, 'Missing', missingBadgeCount),
      (DailyLogsTab.handover, 'Handover', null),
    ];

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        bottom: 14,
      ),
      child: Container(
        height: ResponsiveHelper.getResponsiveHeight(context, 44),
        padding: ResponsiveHelper.getResponsivePadding(context, all: 3),
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 14),
          ),
        ),
        child: Row(
          children: [
            for (final (tab, label, badge) in tabs)
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabSelected(tab),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveWidth(context, 2),
                    ),
                    decoration: BoxDecoration(
                      color: tab == selectedTab
                          ? AppColors.surfaceWhite
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, 12),
                      ),
                      boxShadow: tab == selectedTab
                          ? [
                              BoxShadow(
                                color: AppColors.shadowNavy.withValues(alpha: 0.08),
                                offset: Offset(
                                  0,
                                  ResponsiveHelper.getResponsiveHeight(context, 1),
                                ),
                                blurRadius: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  3,
                                ),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: tab == selectedTab
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                13,
                              ),
                              color: tab == selectedTab
                                  ? AppColors.secondaryTeal
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        if (tab != selectedTab && (badge ?? 0) > 0) ...[
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveWidth(context, 5),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 18),
                            height: ResponsiveHelper.getResponsiveSize(context, 18),
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.criticalRed,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$badge',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  10,
                                ),
                                color: AppColors.surfaceWhite,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error
// ─────────────────────────────────────────────────────────────────────────────

class _DailyLogsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DailyLogsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.criticalRed,
              size: 40,
            ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
