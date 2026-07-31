import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../controllers/team_reports_controller.dart';
import '../widgets/messages_tab_view.dart';
import '../widgets/reports_tab_view.dart';
import '../widgets/team_reports_error_view.dart';
import '../widgets/team_reports_header.dart';
import '../widgets/team_reports_segmented_tabs.dart';
import '../widgets/team_tab_view.dart';

/// The "Team & Reports" screen: one page hosting three segmented tabs
/// ("Team", "Reports", "Messages") behind a shared header, matching the
/// reference design where all three destinations share identical chrome.
class TeamReportsPage extends StatelessWidget {
  const TeamReportsPage({super.key});

  TeamReportsController _resolveController() {
    try {
      return Get.find<TeamReportsController>();
    } catch (_) {
      return Get.put(GetIt.instance<TeamReportsController>(), permanent: true);
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
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: AppDimens.screenPaddingHorizontal,
                  top: 8,
                  bottom: 14,
                ),
                child: Column(
                  children: [
                    TeamReportsHeader(
                      selectedTab: selectedTab,
                      onTrailingTap: () {},
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    TeamReportsSegmentedTabs(
                      selectedTab: selectedTab,
                      messagesBadgeCount: unreadBadgeCount,
                      onTabSelected: controller.selectTab,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (data == null && controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.secondaryTeal),
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
                      TeamReportsTab.messages => MessagesTabView(overview: data.messages),
                    };

                    return RefreshIndicator(
                      color: AppColors.secondaryTeal,
                      onRefresh: controller.refresh,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                          0,
                          ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                          ResponsiveHelper.getResponsiveHeight(context, 32),
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
      ),
    );
  }
}
