import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../family_shell.dart';
import '../../../presentation/widgets/family_bottom_nav_bar.dart';
import '../../domain/entities/family_visit_requests_enums.dart';
import '../controllers/family_visit_requests_controller.dart';
import '../widgets/family_visit_requests_header.dart';
import '../widgets/family_visit_requests_tab_bar.dart';
import '../widgets/my_visit_request_card.dart';
import '../widgets/my_visit_requests_stat_chips.dart';
import '../widgets/visit_request_row_card.dart';
import 'visit_request_details_page.dart';

/// The Family Visit Requests list screen - "All / My Requests / History"
/// tabs of the Family portal.
///
/// Pushed as a standalone route from the Family "More" hub, so it owns its
/// own `Scaffold` rather than being embedded in a shell.
///
/// Hosts [FamilyBottomNavBar] with "More" selected so the pushed route still
/// matches reference frames that show the family bottom nav.
class FamilyVisitRequestsListPage extends StatefulWidget {
  const FamilyVisitRequestsListPage({super.key});

  @override
  State<FamilyVisitRequestsListPage> createState() => _FamilyVisitRequestsListPageState();
}

class _FamilyVisitRequestsListPageState extends State<FamilyVisitRequestsListPage> {
  /// Index of the "More" slot in [FamilyBottomNavBar.items].
  static const int _moreTabIndex = 4;

  late final FamilyVisitRequestsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _resolveController();
  }

  FamilyVisitRequestsController _resolveController() {
    try {
      return Get.find<FamilyVisitRequestsController>();
    } catch (_) {
      return Get.put(GetIt.instance<FamilyVisitRequestsController>(), permanent: true);
    }
  }

  void _openRequestDetails(String requestId) {
    Get.to(() => VisitRequestDetailsPage(requestId: requestId));
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => FamilyShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: FamilyBottomNavBar(
        currentIndex: _moreTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final overview = _controller.state.value.data;

          if (overview == null && _controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
          }

          if (overview == null) {
            return _VisitRequestsError(
              message: _controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading visit requests.'
                  : _controller.errorMessage.value,
              onRetry: _controller.refresh,
            );
          }

          final selectedTab = _controller.selectedTab.value;

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    FamilyVisitRequestsHeader(onBackTap: Get.back),
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 16,
                        bottom: 16,
                      ),
                      child: FamilyVisitRequestsTabBar(
                        selected: selectedTab,
                        onSelected: _controller.selectTab,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.refresh,
                  child: _buildTabContent(context, selectedTab),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, FamilyVisitRequestsTab tab) {
    switch (tab) {
      case FamilyVisitRequestsTab.all:
        return _AllRequestsTab(controller: _controller);
      case FamilyVisitRequestsTab.myRequests:
        return _MyRequestsTab(controller: _controller, onViewDetails: _openRequestDetails);
      case FamilyVisitRequestsTab.history:
        return _HistoryTab(controller: _controller);
    }
  }
}

class _AllRequestsTab extends StatelessWidget {
  final FamilyVisitRequestsController controller;

  static const Color _sectionTitle = Color(0xFF1A2B48);

  const _AllRequestsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final requests = controller.allRequests;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsiveWidth(context, 16),
        ResponsiveHelper.getResponsiveHeight(context, 18),
        ResponsiveHelper.getResponsiveWidth(context, 16),
        ResponsiveHelper.getResponsiveHeight(context, 24),
      ),
      itemCount: requests.length + 1,
      separatorBuilder: (context, index) =>
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'All Requests',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: _sectionTitle,
              height: 1.2,
            ),
          );
        }
        return VisitRequestRowCard(request: requests[index - 1]);
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final FamilyVisitRequestsController controller;

  static const Color _sectionTitle = Color(0xFF1A2B48);

  const _HistoryTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final requests = controller.historyRequests;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsiveWidth(context, 16),
        ResponsiveHelper.getResponsiveHeight(context, 18),
        ResponsiveHelper.getResponsiveWidth(context, 16),
        ResponsiveHelper.getResponsiveHeight(context, 24),
      ),
      itemCount: requests.length + 1,
      separatorBuilder: (context, index) =>
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'Past Requests',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: _sectionTitle,
              height: 1.2,
            ),
          );
        }
        return VisitRequestRowCard(request: requests[index - 1]);
      },
    );
  }
}

class _MyRequestsTab extends StatelessWidget {
  final FamilyVisitRequestsController controller;
  final ValueChanged<String> onViewDetails;

  static const Color _sectionTitle = Color(0xFF1A2B48);

  const _MyRequestsTab({required this.controller, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final requests = controller.myRequests;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsiveWidth(context, 16),
        ResponsiveHelper.getResponsiveHeight(context, 18),
        ResponsiveHelper.getResponsiveWidth(context, 16),
        ResponsiveHelper.getResponsiveHeight(context, 24),
      ),
      itemCount: requests.length + 2,
      separatorBuilder: (context, index) =>
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
      itemBuilder: (context, index) {
        if (index == 0) {
          return MyVisitRequestsStatChips(
            pendingCount: controller.pendingCount,
            approvedCount: controller.approvedCount,
            rejectedCount: controller.rejectedCount,
          );
        }
        if (index == 1) {
          return Padding(
            padding: EdgeInsets.only(
              top: ResponsiveHelper.getResponsiveHeight(context, 4),
            ),
            child: Text(
              'My Requests',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                color: _sectionTitle,
                height: 1.2,
              ),
            ),
          );
        }
        final request = requests[index - 2];
        return MyVisitRequestCard(
          request: request,
          onViewDetails: () => onViewDetails(request.id),
        );
      },
    );
  }
}

class _VisitRequestsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _VisitRequestsError({required this.message, required this.onRetry});

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
