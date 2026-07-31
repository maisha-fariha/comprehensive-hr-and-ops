import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../controllers/incidents_controller.dart';
import '../widgets/closed_incident_card.dart';
import '../widgets/create_incident_button.dart';
import '../widgets/incident_stat_tile_row.dart';
import '../widgets/incidents_header.dart';
import '../widgets/incidents_tab_bar.dart';
import '../widgets/investigation_incident_card.dart';
import '../widgets/open_incident_card.dart';
import 'incident_creation_page.dart';

/// The Incidents list screen - "Open / Under Review / Closed" tabs of the
/// Manager Incidents feature.
///
/// Pixel-accurate reproduction of the Figma "Open - Incidents",
/// "Under Review - Incidents" and "Closed - Incidents" screens (nodes
/// 517:15128, 517:15348, 517:15580) inside the "Manager Mobile Screens"
/// section - built from screenshots after Figma MCP access was exhausted,
/// so it is a close, judgement-based reproduction rather than a
/// measurement-exact one (see the feature's final report for details).
class IncidentsListPage extends StatelessWidget {
  const IncidentsListPage({super.key});

  IncidentsController _resolveController() {
    try {
      return Get.find<IncidentsController>();
    } catch (_) {
      return Get.put(GetIt.instance<IncidentsController>(), permanent: true);
    }
  }

  void _openCreationWizard() {
    Get.to(() => const IncidentCreationPage());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final response = controller.state.value;
          final board = response.data;

          if (board == null && controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
          }

          if (board == null) {
            return _IncidentsError(
              message: controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading incidents.'
                  : controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          final selectedTab = controller.selectedTab.value;

          return Column(
            children: [
              const IncidentsHeader(),
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20),
                child: IncidentsTabBar(
                  selected: selectedTab,
                  openBadgeCount: board.open.activeCount,
                  onSelected: controller.selectTab,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(context, 20),
                      ResponsiveHelper.getResponsiveHeight(context, 18),
                      ResponsiveHelper.getResponsiveWidth(context, 20),
                      ResponsiveHelper.getResponsiveHeight(context, 14),
                    ),
                    children: _buildTabChildren(context, selectedTab, board),
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
                child: CreateIncidentButton(onTap: _openCreationWizard),
              ),
            ],
          );
        }),
      ),
    );
  }

  List<Widget> _buildTabChildren(BuildContext context, IncidentsTab tab, IncidentsBoard board) {
    final gap12 = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12));
    final gap10 = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10));

    switch (tab) {
      case IncidentsTab.open:
        final section = board.open;
        return [
          IncidentStatTileRow(stats: section.stats),
          gap12,
          SectionHeaderRow(
            title: 'Active Incidents',
            trailing: _CountBadge(
              count: section.activeCount,
              background: AppColors.criticalBackground,
              foreground: AppColors.criticalRed,
            ),
          ),
          gap10,
          for (final incident in section.incidents) ...[
            OpenIncidentCard(incident: incident),
            gap10,
          ],
        ];
      case IncidentsTab.underReview:
        final section = board.underReview;
        return [
          IncidentStatTileRow(stats: section.stats),
          gap12,
          SectionHeaderRow(
            title: 'In Investigation',
            trailing: _CountBadge(
              count: section.investigationCount,
              background: AppColors.infoBackground,
              foreground: AppColors.infoBlue,
            ),
          ),
          gap10,
          for (final incident in section.incidents) ...[
            InvestigationIncidentCard(incident: incident),
            gap10,
          ],
        ];
      case IncidentsTab.closed:
        final section = board.closed;
        return [
          IncidentStatTileRow(stats: section.stats),
          gap12,
          const SectionHeaderRow(title: 'Resolved Incidents', trailing: _ThisWeekLabel()),
          gap10,
          for (final incident in section.incidents) ...[
            ClosedIncidentCard(incident: incident),
            gap10,
          ],
        ];
    }
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color background;
  final Color foreground;

  const _CountBadge({required this.count, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: ResponsiveHelper.getResponsiveSize(context, 22),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 7),
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
          color: foreground,
        ),
      ),
    );
  }
}

class _ThisWeekLabel extends StatelessWidget {
  const _ThisWeekLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'This week',
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
        color: AppColors.textFaint,
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
