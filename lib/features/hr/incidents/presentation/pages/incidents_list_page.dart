import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../presentation/open_manager_portal_search.dart';
import '../../../presentation/widgets/hr_company_brand.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../controllers/incidents_controller.dart';
import '../widgets/add_investigation_note_sheet.dart';
import '../widgets/closed_incident_card.dart';
import '../widgets/create_incident_button.dart';
import '../widgets/incident_stat_tile_row.dart';
import '../widgets/incidents_filters_bar.dart';
import '../widgets/investigation_incident_card.dart';
import '../widgets/investigation_summary_sheet.dart';
import '../widgets/open_incident_card.dart';
import 'hr_incident_details_page.dart';
import 'incident_creation_page.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

/// Incidents list — web-parity filters (status dropdown, not status tabs).
class IncidentsListPage extends StatelessWidget {
  const IncidentsListPage({super.key});

  IncidentsController _resolveController() {
    IncidentsController controller;
    try {
      controller = Get.find<IncidentsController>();
    } catch (_) {
      controller =
          Get.put(GetIt.instance<IncidentsController>(), permanent: true);
    }
    controller.ensureLoaded();
    return controller;
  }

  Future<void> _openCreationWizard(IncidentsController controller) async {
    final created = await Get.to<bool>(() => const IncidentCreationPage());
    if (created == true) {
      await controller.refresh();
    }
  }

  Future<void> _openDetails(
    IncidentsController controller,
    String incidentId,
  ) async {
    final session =
        Get.isRegistered<UserSession>() ? Get.find<UserSession>() : null;
    final changed = await Get.to<bool>(
      () => HrIncidentDetailsPage(
        incidentId: incidentId,
        canWrite: session?.can('incidents:write') ?? true,
      ),
    );
    if (changed == true) {
      await controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Obx(() {
        final response = controller.state.value;
        final board = response.data;

        if (board == null && controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (board == null) {
          return _IncidentsError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading incidents.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final horizontalPad = ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        );

        return Column(
          children: [
            const ColoredBox(
              color: AppColors.surfaceWhite,
              child: SafeArea(
                bottom: false,
                child: _IncidentsHeader(),
              ),
            ),
            Expanded(
              child: AppRefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 12),
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 14),
                  ),
                  children: _buildListChildren(
                    context,
                    board,
                    controller,
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  0,
                  horizontalPad,
                  ResponsiveHelper.getResponsiveHeight(context, 10),
                ),
                child: Builder(
                  builder: (context) {
                    final session = Get.isRegistered<UserSession>()
                        ? Get.find<UserSession>()
                        : null;
                    final canExport = session == null ||
                        session.can('incidents:export');
                    final canWrite =
                        session == null || session.can('incidents:write');
                    if (!canExport && !canWrite) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canExport)
                      ExportListButton(
                        isLoading: controller.isExporting.value,
                        onTap: controller.exportIncidentList,
                      ),
                    if (canExport && canWrite)
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(
                          context,
                          10,
                        ),
                      ),
                    if (canWrite)
                      CreateIncidentButton(
                        onTap: () => _openCreationWizard(controller),
                      ),
                  ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildListChildren(
    BuildContext context,
    IncidentsBoard board,
    IncidentsController controller,
  ) {
    final gap12 =
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12));
    final gap8 =
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8));
    final status = controller.statusFilter.value;
    final stats = switch (status) {
      IncidentListStatus.open => board.open.stats,
      IncidentListStatus.investigating => board.underReview.stats,
      IncidentListStatus.closed => board.closed.stats,
      null => board.open.stats,
    };
    final openCount = board.open.activeCount;
    final reviewCount = board.underReview.investigationCount;
    final closedCount = board.closed.incidents.length;
    final totalCount = openCount + reviewCount + closedCount;
    final title = switch (status) {
      IncidentListStatus.open => 'Open Incidents',
      IncidentListStatus.investigating => 'Investigating',
      IncidentListStatus.closed => 'Closed Incidents',
      null => 'All Incidents',
    };
    final badgeCount = switch (status) {
      IncidentListStatus.open => openCount,
      IncidentListStatus.investigating => reviewCount,
      IncidentListStatus.closed => closedCount,
      null => totalCount,
    };
    final badgeBg = switch (status) {
      IncidentListStatus.open => AppColors.criticalBackground,
      IncidentListStatus.investigating => AppColors.infoBackground,
      IncidentListStatus.closed => AppColors.activeBackground,
      null => AppColors.infoBackground,
    };
    final badgeFg = switch (status) {
      IncidentListStatus.open => AppColors.criticalRed,
      IncidentListStatus.investigating => AppColors.infoBlue,
      IncidentListStatus.closed => AppColors.activeGreen,
      null => AppColors.infoBlue,
    };

    return [
      IncidentsFiltersBar(
        reportedByMe: controller.reportedByMe.value,
        statusFilter: controller.statusFilter.value,
        severityFilter: controller.severityFilter.value,
        residenceFilterId: controller.residenceFilterId.value,
        clientFilterId: controller.clientFilterId.value,
        investigatorFilterId: controller.investigatorFilterId.value,
        residences: controller.residences.toList(),
        clients: controller.clients.toList(),
        investigators: controller.investigators.toList(),
        fromDate: controller.fromDate.value,
        toDate: controller.toDate.value,
        onReportedByMeChanged: controller.setReportedByMe,
        onStatusChanged: controller.setStatusFilter,
        onSeverityChanged: controller.setSeverityFilter,
        onResidenceChanged: (id) {
          controller.setResidenceFilter(id);
        },
        onClientChanged: controller.setClientFilter,
        onInvestigatorChanged: controller.setInvestigatorFilter,
        onFromChanged: controller.setFromDate,
        onToChanged: controller.setToDate,
        onClearFilters: controller.clearFilters,
      ),
      gap12,
      if (stats.isNotEmpty) ...[
        IncidentStatTileRow(stats: stats),
        gap12,
      ],
      _SectionHeader(
        title: title,
        badgeCount: badgeCount,
        badgeBackground: badgeBg,
        badgeForeground: badgeFg,
      ),
      gap8,
      if (status == null || status == IncidentListStatus.open)
        for (final incident in board.open.incidents) ...[
          OpenIncidentCard(
            key: ValueKey('incident-open-${incident.id}'),
            incident: incident,
            onTap: () => _openDetails(controller, incident.id),
          ),
          gap8,
        ],
      if (status == null || status == IncidentListStatus.investigating)
        for (final incident in board.underReview.incidents) ...[
          GestureDetector(
            key: ValueKey('incident-review-${incident.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _openDetails(controller, incident.id),
            child: InvestigationIncidentCard(
              incident: incident,
              onViewInvestigation: () => showInvestigationSummarySheet(
                context,
                incident: incident,
              ),
              onAddNote: () async {
                final saved = await showAddInvestigationNoteSheet(
                  context,
                  incident: incident,
                );
                if (saved) {
                  await controller.refresh();
                }
              },
            ),
          ),
          gap8,
        ],
      if (status == null || status == IncidentListStatus.closed)
        for (final incident in board.closed.incidents) ...[
          GestureDetector(
            key: ValueKey('incident-closed-${incident.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _openDetails(controller, incident.id),
            child: ClosedIncidentCard(incident: incident),
          ),
          gap8,
        ],
      if (badgeCount == 0)
        Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, vertical: 24),
          child: Text(
            'No incidents match these filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textMuted,
            ),
          ),
        ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _IncidentsHeader extends StatelessWidget {
  const _IncidentsHeader();

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
          const Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: HrCompanyBrand(maxNameWidth: 110),
            ),
          ),
          Expanded(
            child: Text(
              'Incidents',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: AppColors.textHeading,
                letterSpacing: -0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: openManagerPortalSearch,
            behavior: HitTestBehavior.opaque,
            child: Container(
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
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int badgeCount;
  final Color badgeBackground;
  final Color badgeForeground;

  const _SectionHeader({
    required this.title,
    required this.badgeCount,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: AppColors.textHeading,
          ),
        ),
        const Spacer(),
        Container(
          constraints: const BoxConstraints(minWidth: 22),
          height: ResponsiveHelper.getResponsiveSize(context, 22),
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 7),
          decoration: BoxDecoration(
            color: badgeBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            '$badgeCount',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: badgeForeground,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error
// ─────────────────────────────────────────────────────────────────────────────

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
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
