import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../controllers/incidents_controller.dart';
import '../widgets/closed_incident_card.dart';
import '../widgets/create_incident_button.dart';
import '../widgets/incident_stat_tile_row.dart';
import '../widgets/investigation_incident_card.dart';
import '../widgets/open_incident_card.dart';
import 'incident_creation_page.dart';

/// The Incidents list screen — "Open / Under Review / Closed" tabs.
/// Open tab UI matches the "Open - Incidents" Figma reference.
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

        final selectedTab = controller.selectedTab.value;
        final horizontalPad = ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        );

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const _IncidentsHeader(),
                    _IncidentsTabBar(
                      selected: selectedTab,
                      openBadgeCount: board.open.activeCount,
                      onSelected: controller.selectTab,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 14),
                  ),
                  children: _buildTabChildren(context, selectedTab, board),
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
                child: CreateIncidentButton(onTap: _openCreationWizard),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildTabChildren(
    BuildContext context,
    IncidentsTab tab,
    IncidentsBoard board,
  ) {
    final gap12 = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18));
    final gap10 = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10));

    switch (tab) {
      case IncidentsTab.open:
        final section = board.open;
        return [
          IncidentStatTileRow(stats: section.stats),
          gap12,
          _SectionHeader(
            title: 'Active Incidents',
            badgeCount: section.activeCount,
            badgeBackground: AppColors.criticalBackground,
            badgeForeground: AppColors.criticalRed,
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
          _SectionHeader(
            title: 'In Investigation',
            badgeCount: section.investigationCount,
            badgeBackground: AppColors.infoBackground,
            badgeForeground: AppColors.infoBlue,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resolved Incidents',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Text(
                'This week',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
          gap10,
          for (final incident in section.incidents) ...[
            ClosedIncidentCard(incident: incident),
            gap10,
          ],
        ];
    }
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
          Icon(
            Icons.menu_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 24),
            color: AppColors.textHeading,
          ),
          Expanded(
            child: Text(
              'Incidents',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: AppColors.textHeading,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _IncidentsTabBar extends StatelessWidget {
  final IncidentsTab selected;
  final int openBadgeCount;
  final ValueChanged<IncidentsTab> onSelected;

  const _IncidentsTabBar({
    required this.selected,
    required this.openBadgeCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (IncidentsTab.open, 'Open', openBadgeCount),
      (IncidentsTab.underReview, 'Under Review', null),
      (IncidentsTab.closed, 'Closed', null),
    ];

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        bottom: 14,
      ),
      child: Container(
        height: ResponsiveHelper.getResponsiveHeight(context, 44),
        padding: ResponsiveHelper.getResponsivePadding(context, all: 3),
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 14),
          ),
        ),
        child: Row(
          children: [
            for (final (tab, label, badge) in tabs)
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(tab),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveWidth(context, 2),
                    ),
                    decoration: BoxDecoration(
                      color: tab == selected
                          ? AppColors.surfaceWhite
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, 12),
                      ),
                      boxShadow: tab == selected
                          ? [
                              BoxShadow(
                                color: AppColors.shadowNavy.withValues(alpha: 0.08),
                                offset: Offset(
                                  0,
                                  ResponsiveHelper.getResponsiveHeight(context, 1),
                                ),
                                blurRadius: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  3,
                                ),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: tab == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                12.5,
                              ),
                              color: tab == selected
                                  ? AppColors.secondaryTeal
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        if (tab != selected && (badge ?? 0) > 0) ...[
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveWidth(context, 5),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 18),
                            height: ResponsiveHelper.getResponsiveSize(context, 18),
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.criticalRed,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$badge',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  10,
                                ),
                                color: AppColors.surfaceWhite,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
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
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
