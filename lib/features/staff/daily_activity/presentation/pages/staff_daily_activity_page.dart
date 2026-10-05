import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../../domain/entities/staff_daily_activity_option.dart';
import '../../domain/entities/staff_daily_activity_overview.dart';
import '../controllers/staff_daily_activity_controller.dart';
import '../widgets/staff_daily_activity_filters_bar.dart';
import '../widgets/staff_daily_activity_metrics_strip.dart';
import '../widgets/staff_daily_activity_registry_list.dart';
import '../widgets/staff_daily_activity_tab_bar.dart';

/// Staff Daily Activity — web-parity registry, metrics, filters, record sheet.
class StaffDailyActivityPage extends StatefulWidget {
  const StaffDailyActivityPage({super.key});

  @override
  State<StaffDailyActivityPage> createState() => _StaffDailyActivityPageState();
}

class _StaffDailyActivityPageState extends State<StaffDailyActivityPage> {
  static const int _moreTabIndex = 4;
  late final StaffDailyActivityController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<StaffDailyActivityController>();
    } catch (_) {
      _controller = Get.put(
        GetIt.instance<StaffDailyActivityController>(),
        permanent: true,
      );
    }
    _searchController = TextEditingController(
      text: _controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();

    return Scaffold(
      key: const Key('staff-daily-activity-page'),
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: _moreTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: Obx(() {
        final response = _controller.state.value;
        final overview = response.data;
        final loading = _controller.isLoading.value;

        if (overview == null && loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (overview == null &&
            _controller.errorMessage.value.isNotEmpty) {
          return _ErrorBody(
            message: _controller.errorMessage.value,
            onRetry: _controller.refresh,
          );
        }

        final safe = overview ?? StaffDailyActivityOverview.empty;
        final needsResident =
            _controller.selectedTab.value ==
                StaffDailyActivityTab.residentHistory &&
            (_controller.clientId.value == null ||
                _controller.clientId.value!.isEmpty);

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: AppDimens.screenPaddingHorizontal,
                    top: 8,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('staff-daily-activity-back'),
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.textHeading,
                      ),
                      const Expanded(
                        child: Text(
                          'Daily Activity',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      if (session.canWriteClientActivities)
                        FilledButton.icon(
                          key: const Key('staff-daily-activity-add'),
                          onPressed: _controller.openRecordSheet,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Record activity',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: _controller.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(
                      context,
                      AppDimens.screenPaddingHorizontal,
                    ),
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    ResponsiveHelper.getResponsiveWidth(
                      context,
                      AppDimens.screenPaddingHorizontal,
                    ),
                    ResponsiveHelper.getResponsiveHeight(context, 32),
                  ),
                  children: [
                    StaffDailyActivityMetricsStrip(metrics: safe.metrics),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 16),
                    ),
                    StaffDailyActivityTabBar(
                      selectedTab: _controller.selectedTab.value,
                      onTabSelected: _controller.selectTab,
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 14),
                    ),
                    StaffDailyActivityFiltersBar(
                      searchController: _searchController,
                      clientId: _controller.clientId.value,
                      staffId: _controller.staffId.value,
                      activityType: _controller.activityType.value,
                      status: _controller.status.value,
                      date: _controller.dateFilter.value,
                      clients: _controller.clientOptions.toList(),
                      staff: _controller.staffOptions.toList(),
                      onSearchChanged: _controller.setSearch,
                      onClientChanged: _controller.setClientId,
                      onStaffChanged: _controller.setStaffId,
                      onTypeChanged: _controller.setActivityType,
                      onStatusChanged: _controller.setStatus,
                      onDateChanged: _controller.setDate,
                      formatDate: _controller.formatFilterDate,
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 16),
                    ),
                    if (needsResident)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Text(
                          'Choose a resident to view their activity history.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      StaffDailyActivityRegistryList(
                        overview: safe,
                        onPrev: () =>
                            _controller.setPage(_controller.page.value - 1),
                        onNext: () =>
                            _controller.setPage(_controller.page.value + 1),
                        onLimitChanged: _controller.setLimit,
                      ),
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

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
