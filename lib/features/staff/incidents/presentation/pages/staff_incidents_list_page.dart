import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../controllers/staff_incidents_controller.dart';
import '../widgets/staff_incident_card.dart';
import '../widgets/staff_incidents_header.dart';
import '../widgets/staff_incidents_search_bar.dart';
import '../widgets/staff_incidents_tab_bar.dart';
import '../widgets/staff_primary_button.dart';
import 'create_incident_page.dart';
import 'incident_details_page.dart';

/// The Staff Incidents list screen - "My Incidents / All Incidents" tabs
/// of the Staff (care-worker) portal.
///
/// Reproduction of the Figma "My Incidents - Incidents" and "All Incidents
/// - Incidents" screenshots, built without Figma MCP access (monthly quota
/// exhausted) - see the feature's final report for details on any
/// approximated content and icon placeholders.
///
/// Hosts [StaffBottomNavBar] with "More" selected so the pushed route still
/// matches reference frames that show the staff bottom nav.
class StaffIncidentsListPage extends StatefulWidget {
  const StaffIncidentsListPage({super.key});

  @override
  State<StaffIncidentsListPage> createState() => _StaffIncidentsListPageState();
}

class _StaffIncidentsListPageState extends State<StaffIncidentsListPage> {
  /// Index of the "More" slot in [StaffBottomNavBar.items].
  static const int _moreTabIndex = 4;

  late final StaffIncidentsController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = _resolveController();
  }

  StaffIncidentsController _resolveController() {
    try {
      return Get.find<StaffIncidentsController>();
    } catch (_) {
      return Get.put(GetIt.instance<StaffIncidentsController>(), permanent: true);
    }
  }

  void _openCreateIncident() {
    Get.to(() => const CreateIncidentPage());
  }

  void _openIncidentDetails(String incidentId) {
    Get.to(() => IncidentDetailsPage(incidentId: incidentId));
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: _moreTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final response = _controller.state.value;
          final hasData = response.data != null;

          if (!hasData && _controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
          }

          if (!hasData) {
            return _IncidentsError(
              message: _controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading incidents.'
                  : _controller.errorMessage.value,
              onRetry: _controller.refresh,
            );
          }

          final selectedTab = _controller.selectedTab.value;
          final incidents = _controller.visibleIncidents;
          final showCreateButton = selectedTab == StaffIncidentsTab.myIncidents;

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StaffIncidentsHeader(title: 'Incidents', onBack: Get.back),
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 20,
                        bottom: 12,
                      ),
                      child: StaffIncidentsTabBar(
                        selected: selectedTab,
                        totalCount: _controller.incidents.length,
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
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(context, 20),
                      ResponsiveHelper.getResponsiveHeight(context, 14),
                      ResponsiveHelper.getResponsiveWidth(context, 20),
                      ResponsiveHelper.getResponsiveHeight(context, 14),
                    ),
                    children: [
                      StaffIncidentsSearchBar(
                        controller: _searchController,
                        onChanged: _controller.updateSearchQuery,
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                      if (incidents.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveHelper.getResponsiveHeight(context, 40),
                          ),
                          child: const _NoResults(),
                        )
                      else
                        for (var i = 0; i < incidents.length; i++) ...[
                          if (i > 0)
                            SizedBox(
                              height: ResponsiveHelper.getResponsiveHeight(context, 12),
                            ),
                          StaffIncidentCard(
                            incident: incidents[i],
                            tab: selectedTab,
                            onViewDetails: () => _openIncidentDetails(incidents[i].id),
                          ),
                        ],
                      if (showCreateButton) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                        StaffPrimaryButton(
                          label: 'Create Incident',
                          icon: Icons.add_rounded,
                          onTap: _openCreateIncident,
                        ),
                      ],
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

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No incidents match your search.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _IncidentsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _IncidentsError({required this.message, required this.onRetry});

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
