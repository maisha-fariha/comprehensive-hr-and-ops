import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_incidents_summary.dart';

/// Critical Watchlist + Investigation Queue side panels (web Incident Reports).
class StaffIncidentsSidePanels extends StatelessWidget {
  final StaffIncidentsSummary summary;
  final VoidCallback onViewQueue;
  final ValueChanged<String>? onOpenIncident;

  const StaffIncidentsSidePanels({
    super.key,
    required this.summary,
    required this.onViewQueue,
    this.onOpenIncident,
  });

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveHeight(context, 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WatchlistCard(
          items: summary.watchlist,
          onOpenIncident: onOpenIncident,
        ),
        SizedBox(height: gap),
        _InvestigationQueueCard(
          awaitingInvestigation: summary.awaitingInvestigation,
          openInvestigations: summary.openInvestigations,
          queue: summary.investigationQueue,
          onViewQueue: onViewQueue,
          onOpenIncident: onOpenIncident,
        ),
      ],
    );
  }
}

class _PanelShell extends StatelessWidget {
  final Key? panelKey;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _PanelShell({
    this.panelKey,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Container(
      key: panelKey,
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          child,
        ],
      ),
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  final List<StaffIncidentWatchlistItem> items;
  final ValueChanged<String>? onOpenIncident;

  const _WatchlistCard({
    required this.items,
    this.onOpenIncident,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      panelKey: const Key('staff-incidents-watchlist'),
      title: 'Critical Watchlist',
      child: items.isEmpty
          ? Text(
              'Nothing serious is open right now.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveHeight(context, 8),
                    ),
                  _WatchlistRow(
                    item: items[i],
                    onTap: onOpenIncident == null
                        ? null
                        : () => onOpenIncident!(items[i].id),
                  ),
                ],
              ],
            ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  final StaffIncidentWatchlistItem item;
  final VoidCallback? onTap;

  const _WatchlistRow({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (item.residence.isNotEmpty) item.residence,
      if (item.client.isNotEmpty) item.client,
      if (item.stageLabel.isNotEmpty) item.stageLabel,
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              top: ResponsiveHelper.getResponsiveHeight(context, 3),
            ),
            width: ResponsiveHelper.getResponsiveSize(context, 8),
            height: ResponsiveHelper.getResponsiveSize(context, 8),
            decoration: const BoxDecoration(
              color: AppColors.criticalRed,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                    height: 1.25,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 2),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        11.5,
                      ),
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.severityLabel.isNotEmpty)
            Text(
              item.severityLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                color: AppColors.criticalRed,
                height: 1.2,
              ),
            ),
        ],
      ),
    );
  }
}

class _InvestigationQueueCard extends StatelessWidget {
  final int awaitingInvestigation;
  final int openInvestigations;
  final List<StaffIncidentQueueItem> queue;
  final VoidCallback onViewQueue;
  final ValueChanged<String>? onOpenIncident;

  const _InvestigationQueueCard({
    required this.awaitingInvestigation,
    required this.openInvestigations,
    required this.queue,
    required this.onViewQueue,
    this.onOpenIncident,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      panelKey: const Key('staff-incidents-queue'),
      title: 'Investigation Queue',
      trailing: GestureDetector(
        key: const Key('staff-incidents-view-queue'),
        onTap: onViewQueue,
        behavior: HitTestBehavior.opaque,
        child: Text(
          'View Queue',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: AppColors.secondaryTeal,
            height: 1.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _QueueCountTile(
                  label: 'Not started',
                  count: awaitingInvestigation,
                  accent: AppColors.urgentAmber,
                  background: AppColors.urgentBackgroundSoft,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: _QueueCountTile(
                  label: 'Open Investigations',
                  count: openInvestigations,
                  accent: AppColors.infoBlue,
                  background: AppColors.infoBackground,
                ),
              ),
            ],
          ),
          if (queue.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (var i = 0; i < queue.take(3).length; i++) ...[
              if (i > 0)
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 6),
                ),
              _QueueRow(
                item: queue[i],
                onTap: onOpenIncident == null
                    ? null
                    : () => onOpenIncident!(queue[i].id),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _QueueCountTile extends StatelessWidget {
  final String label;
  final int count;
  final Color accent;
  final Color background;

  const _QueueCountTile({
    required this.label,
    required this.count,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              color: accent,
              height: 1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final StaffIncidentQueueItem item;
  final VoidCallback? onTap;

  const _QueueRow({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.caseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textHeading,
                height: 1.2,
              ),
            ),
          ),
          if (item.stage.isNotEmpty)
            Text(
              item.stage,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
        ],
      ),
    );
  }
}
