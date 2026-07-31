import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
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
class StaffIncidentsListPage extends StatefulWidget {
  const StaffIncidentsListPage({super.key});

  @override
  State<StaffIncidentsListPage> createState() => _StaffIncidentsListPageState();
}

class _StaffIncidentsListPageState extends State<StaffIncidentsListPage> {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
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

          return Column(
            children: [
              StaffIncidentsHeader(title: 'Incidents', onBack: Get.back),
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20),
                child: StaffIncidentsTabBar(
                  selected: selectedTab,
                  totalCount: _controller.incidents.length,
                  onSelected: _controller.selectTab,
                ),
              ),
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 14),
                child: StaffIncidentsSearchBar(
                  controller: _searchController,
                  onChanged: _controller.updateSearchQuery,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.refresh,
                  child: incidents.isEmpty
                      ? ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getResponsiveWidth(context, 20),
                            vertical: ResponsiveHelper.getResponsiveHeight(context, 40),
                          ),
                          children: const [_NoResults()],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveHelper.getResponsiveWidth(context, 20),
                            ResponsiveHelper.getResponsiveHeight(context, 16),
                            ResponsiveHelper.getResponsiveWidth(context, 20),
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                          ),
                          itemCount: incidents.length,
                          separatorBuilder: (_, _) => SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                          itemBuilder: (context, index) {
                            final incident = incidents[index];
                            return StaffIncidentCard(
                              incident: incident,
                              tab: selectedTab,
                              onViewDetails: () => _openIncidentDetails(incident.id),
                            );
                          },
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.getResponsiveWidth(context, 20),
                  0,
                  ResponsiveHelper.getResponsiveWidth(context, 20),
                  ResponsiveHelper.getResponsiveHeight(context, 14),
                ),
                child: StaffPrimaryButton(
                  label: 'Create Incident',
                  icon: Icons.add_rounded,
                  onTap: _openCreateIncident,
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
