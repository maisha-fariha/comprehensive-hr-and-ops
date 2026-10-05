import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/offline/outbox_feature.dart';
import '../../../../../core/offline/presentation/pending_outbox_section.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../controllers/staff_incidents_controller.dart';
import '../widgets/staff_incident_card.dart';
import '../widgets/staff_incidents_filters_bar.dart';
import '../widgets/staff_incidents_header.dart';
import '../widgets/staff_incidents_metrics_row.dart';
import '../widgets/staff_incidents_search_bar.dart';
import '../widgets/staff_incidents_side_panels.dart';
import '../widgets/staff_incidents_tab_bar.dart';
import 'create_incident_page.dart';
import 'incident_details_page.dart';

/// Staff Incident Reports list — metrics, tabs, filters, side panels, cards.
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
      final existing = Get.find<StaffIncidentsController>();
      // Permanent controller may hold stale list from earlier in the session.
      existing.refresh();
      return existing;
    } catch (_) {
      return Get.put(
        GetIt.instance<StaffIncidentsController>(),
        permanent: true,
      );
    }
  }

  void _openCreateIncident() {
    Get.to(() => const CreateIncidentPage())?.then((_) {
      if (mounted) _controller.refresh();
    });
  }

  void _openIncidentDetails(String incidentId) {
    Get.to(() => IncidentDetailsPage(incidentId: incidentId))?.then((_) {
      if (mounted) _controller.refresh();
    });
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialStart = _controller.fromDate.value ??
        now.subtract(const Duration(days: 30));
    final initialEnd = _controller.toDate.value ?? now;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (range == null) return;
    _controller.setDateRange(from: range.start, to: range.end);
  }

  Widget _addIncidentButton(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      key: const Key('staff-incidents-add'),
      color: AppColors.secondaryTeal,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: _openCreateIncident,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 16),
                color: Colors.white,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Text(
                'Add Incident',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            );
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
          final summary = _controller.summary.value;
          final myCount = selectedTab == StaffIncidentsTab.myIncidents
              ? incidents.length
              : _controller.myIncidentsCount.value;
          final allCount = summary.total > 0
              ? summary.total
              : (selectedTab == StaffIncidentsTab.allIncidents
                  ? incidents.length
                  : _controller.allIncidentsCount.value);

          return Column(
            children: [
              StaffIncidentsHeader(
                title: 'Incident Reports',
                onBack: Get.back,
                trailing: Get.find<UserSession>().can('incidents:write')
                    ? _addIncidentButton(context)
                    : null,
              ),
              PendingOutboxSection(
                features: const {OutboxFeature.incidents},
                onSynced: () => _controller.refresh(),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(context, 20),
                      ResponsiveHelper.getResponsiveHeight(context, 14),
                      ResponsiveHelper.getResponsiveWidth(context, 20),
                      ResponsiveHelper.getResponsiveHeight(context, 14),
                    ),
                    children: [
                      StaffIncidentsMetricsRow(summary: summary),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      StaffIncidentsTabBar(
                        selected: selectedTab,
                        myIncidentsCount: myCount,
                        allIncidentsCount: allCount,
                        onSelected: _controller.selectTab,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 12),
                      ),
                      StaffIncidentsFiltersBar(
                        statusFilter: _controller.statusFilter.value,
                        severityFilter: _controller.severityFilter.value,
                        residenceFilterId: _controller.residenceFilterId.value,
                        clientFilterId: _controller.clientFilterId.value,
                        residences: _controller.residences.toList(),
                        clients: _controller.clients.toList(),
                        fromDate: _controller.fromDate.value,
                        toDate: _controller.toDate.value,
                        onStatusChanged: _controller.setStatusFilter,
                        onSeverityChanged: _controller.setSeverityFilter,
                        onResidenceChanged: (id) {
                          _controller.setResidenceFilter(id);
                        },
                        onClientChanged: _controller.setClientFilter,
                        onPickDateRange: _pickDateRange,
                        onClearFilters: _controller.clearFilters,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 12),
                      ),
                      StaffIncidentsSearchBar(
                        controller: _searchController,
                        onChanged: _controller.updateSearchQuery,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      if (incidents.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveHelper.getResponsiveHeight(
                              context,
                              40,
                            ),
                          ),
                          child: const _NoResults(),
                        )
                      else
                        for (var i = 0; i < incidents.length; i++) ...[
                          if (i > 0)
                            SizedBox(
                              height: ResponsiveHelper.getResponsiveHeight(
                                context,
                                12,
                              ),
                            ),
                          StaffIncidentCard(
                            incident: incidents[i],
                            tab: selectedTab,
                            onViewDetails: () =>
                                _openIncidentDetails(incidents[i].id),
                          ),
                        ],
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      StaffIncidentsSidePanels(
                        summary: summary,
                        onViewQueue: _controller.viewInvestigationQueue,
                        onOpenIncident: _openIncidentDetails,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
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
