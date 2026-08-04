import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../hr_shell.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../controllers/team_reports_controller.dart';
import '../widgets/messages_tab_view.dart';
import '../widgets/reports_tab_view.dart';
import '../widgets/team_reports_error_view.dart';
import '../widgets/team_reports_header.dart';
import '../widgets/team_reports_segmented_tabs.dart';
import '../widgets/team_tab_view.dart';

/// "Team & Reports" screen — shared white header + pill tabs, with Team /
/// Reports / Messages body content.
///
/// Hosts [HrBottomNavBar] with "More" selected so the pushed route still
/// matches the reference frames that show the manager bottom nav.
class TeamReportsPage extends StatelessWidget {
  const TeamReportsPage({super.key});

  /// Index of the "More" slot in [HrBottomNavBar.items].
  static const int _moreTabIndex = 4;

  TeamReportsController _resolveController() {
    try {
      return Get.find<TeamReportsController>();
    } catch (_) {
      return Get.put(GetIt.instance<TeamReportsController>(), permanent: true);
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
        final data = response.data;
        final selectedTab = controller.selectedTab.value;
        final unreadBadgeCount = data == null
            ? 0
            : int.tryParse(
                  data.messages.stats
                      .firstWhere((stat) => stat.tag == MessageStatTag.unread)
                      .value,
                ) ??
                0;

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: Column(
                children: [
                  TeamReportsHeader(
                    selectedTab: selectedTab,
                    onTrailingTap: () {},
                  ),
                  Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 4,
                      bottom: 12,
                    ),
                    child: TeamReportsSegmentedTabs(
                      selectedTab: selectedTab,
                      messagesBadgeCount: unreadBadgeCount,
                      onTabSelected: controller.selectTab,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (data == null && controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryTeal,
                      ),
                    );
                  }

                  if (data == null) {
                    return TeamReportsErrorView(
                      message: controller.errorMessage.value.isEmpty
                          ? 'Something went wrong while loading Team & Reports.'
                          : controller.errorMessage.value,
                      onRetry: controller.refresh,
                    );
                  }

                  final Widget tabContent = switch (selectedTab) {
                    TeamReportsTab.team => TeamTabView(overview: data.team),
                    TeamReportsTab.reports => ReportsTabView(overview: data.reports),
                    TeamReportsTab.messages =>
                      MessagesTabView(overview: data.messages),
                  };

                  return RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: controller.refresh,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        ResponsiveHelper.getResponsiveWidth(context, 16),
                        ResponsiveHelper.getResponsiveHeight(context, 12),
                        ResponsiveHelper.getResponsiveWidth(context, 16),
                        ResponsiveHelper.getResponsiveHeight(context, 28),
                      ),
                      children: [tabContent],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
