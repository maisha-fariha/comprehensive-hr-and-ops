import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../appointments/presentation/pages/create_appointment_page.dart';
import '../../../appointments/presentation/widgets/family_primary_button.dart';
import '../../../family_shell.dart';
import '../../../presentation/widgets/family_bottom_nav_bar.dart';
import '../../domain/entities/family_visit_requests_enums.dart';
import '../../domain/entities/family_visit_requests_overview.dart';
import '../controllers/family_visit_requests_controller.dart';
import '../widgets/family_visit_requests_header.dart';
import '../widgets/family_visit_requests_tab_bar.dart';
import '../widgets/my_visit_request_card.dart';
import 'visit_request_details_page.dart';

/// Family Visit Requests — own `family_visit` appointments with status tabs
/// (All / Pending / Approved / Rejected / Cancelled / Completed).
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
    if (Get.isRegistered<FamilyVisitRequestsController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.refresh();
      });
      return Get.find<FamilyVisitRequestsController>();
    }
    return Get.put(GetIt.instance<FamilyVisitRequestsController>(), permanent: true);
  }

  Future<void> _openRequestDetails(String requestId) async {
    await Get.to(() => VisitRequestDetailsPage(requestId: requestId));
    _controller.refresh();
  }

  void _openRequestVisit() {
    Get.to(() => const CreateAppointmentPage());
  }

  void _onBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    // Fallback: Visit Requests lives under More.
    Get.offAll(() => const FamilyShell(initialIndex: _moreTabIndex));
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
          final selectedTab = _controller.selectedTab.value;

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    FamilyVisitRequestsHeader(onBackTap: _onBack),
                    if (overview != null)
                      Padding(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 16,
                          bottom: 16,
                        ),
                        child: FamilyVisitRequestsTabBar(
                          selected: selectedTab,
                          countFor: overview.countFor,
                          onSelected: _controller.selectTab,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(overview, selectedTab)),
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: FamilyPrimaryButton(
                    label: 'Request a Visit',
                    icon: Icons.add_rounded,
                    onTap: _openRequestVisit,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBody(
    FamilyVisitRequestsOverview? overview,
    FamilyVisitRequestsTab selectedTab,
  ) {
    if (overview == null && _controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryTeal),
      );
    }

    if (overview == null) {
      return _VisitRequestsError(
        message: _controller.errorMessage.value.isEmpty
            ? 'Something went wrong while loading visit requests.'
            : _controller.errorMessage.value,
        onRetry: _controller.refresh,
      );
    }

    final requests = overview.requestsFor(selectedTab);
    return RefreshIndicator(
      color: AppColors.secondaryTeal,
      onRefresh: _controller.refresh,
      child: requests.isEmpty
          ? ListView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveWidth(context, 16),
                vertical: ResponsiveHelper.getResponsiveHeight(context, 40),
              ),
              children: [_EmptyRequests(tab: selectedTab)],
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.getResponsiveWidth(context, 16),
                ResponsiveHelper.getResponsiveHeight(context, 18),
                ResponsiveHelper.getResponsiveWidth(context, 16),
                ResponsiveHelper.getResponsiveHeight(context, 24),
              ),
              itemCount: requests.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              itemBuilder: (context, index) {
                final request = requests[index];
                return MyVisitRequestCard(
                  key: ValueKey('visit-request-${request.id}'),
                  request: request,
                  onViewDetails: () => _openRequestDetails(request.id),
                );
              },
            ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  final FamilyVisitRequestsTab tab;

  const _EmptyRequests({required this.tab});

  @override
  Widget build(BuildContext context) {
    final message = tab == FamilyVisitRequestsTab.all
        ? 'No visit requests yet.'
        : 'No ${tab.name} visit requests.';
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w500,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
        color: AppColors.textSecondary,
      ),
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
