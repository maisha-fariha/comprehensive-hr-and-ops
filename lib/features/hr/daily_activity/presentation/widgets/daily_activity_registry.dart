import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_activity.dart';
import '../daily_activity_labels.dart';
import 'daily_activity_common.dart';

/// The web "Client Activity Registry" table, as a card list.
class DailyActivityRegistry extends StatelessWidget {
  final String title;
  final String subtitle;
  final int pendingReview;
  final List<DailyActivity> items;
  final bool loading;
  final String emptyTitle;
  final String emptyMessage;
  final ValueChanged<DailyActivity> onView;
  final ValueChanged<DailyActivity>? onEdit;
  final ValueChanged<DailyActivity>? onDelete;
  final Widget? footer;

  const DailyActivityRegistry({
    super.key,
    this.title = 'Client Activity Registry',
    this.subtitle = 'Most recent activity first',
    required this.pendingReview,
    required this.items,
    required this.loading,
    this.emptyTitle = 'Nothing recorded',
    this.emptyMessage = 'Outings, programmes and observations appear here.',
    required this.onView,
    this.onEdit,
    this.onDelete,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: handoverText(context, 15, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DailyActivityPill(
                label: '$pendingReview pending review',
                tone: DailyActivityTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading && items.isEmpty)
            for (var i = 0; i < 3; i++)
              Container(
                height: 110,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
          else if (items.isEmpty)
            DailyActivityEmpty(
              icon: Icons.monitor_heart_outlined,
              title: emptyTitle,
              message: emptyMessage,
            )
          else
            for (final item in items)
              DailyActivityCard(
                key: ValueKey('daily-activity-${item.id}'),
                activity: item,
                onView: onView,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
          if (footer != null) ...[const SizedBox(height: 4), footer!],
        ],
      ),
    );
  }
}

class DailyActivityCard extends StatelessWidget {
  final DailyActivity activity;
  final ValueChanged<DailyActivity> onView;
  final ValueChanged<DailyActivity>? onEdit;
  final ValueChanged<DailyActivity>? onDelete;

  const DailyActivityCard({
    super.key,
    required this.activity,
    required this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final a = activity;
    Widget label(String text) => Text(
          text.toUpperCase(),
          style: handoverText(context, 10.5, weight: FontWeight.w600, color: AppColors.textMuted)
              .copyWith(letterSpacing: 0.5),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onView(a),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.code,
                        style: handoverText(
                          context,
                          13.5,
                          weight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    DailyActivityPill(
                      label: DailyActivityLabels.humanise(a.status),
                      tone: DailyActivityLabels.statusTone(a.status),
                    ),
                    _RowActions(
                      activity: a,
                      onView: onView,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.clientName ?? 'Resident no longer on file',
                        style: handoverText(context, 14.5, weight: FontWeight.w600),
                      ),
                      Text(
                        a.clientResidence ?? '—',
                        style: handoverText(context, 11.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      DailyActivityPill(
                        label: DailyActivityLabels.humanise(a.activityType),
                        tone: DailyActivityLabels.typeTone(a.activityType),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.description ?? '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: handoverText(context, 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                label('Recorded By'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    DailyActivityInitials(
                                      text: DailyActivityLabels.initials(a.recordedByName),
                                      size: 26,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        a.recordedByName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: handoverText(context, 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              label('Date & Time'),
                              const SizedBox(height: 4),
                              Text(
                                DailyActivityLabels.dateTime(a),
                                style: handoverText(context, 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  final DailyActivity activity;
  final ValueChanged<DailyActivity> onView;
  final ValueChanged<DailyActivity>? onEdit;
  final ValueChanged<DailyActivity>? onDelete;

  const _RowActions({
    required this.activity,
    required this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    PopupMenuItem<String> item(String value, IconData icon, String text, {Color? color}) =>
        PopupMenuItem(
          value: value,
          key: ValueKey('daily-activity-$value-${activity.id}'),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color ?? AppColors.textHeading),
              const SizedBox(width: 10),
              Text(
                text,
                style: handoverText(context, 13.5, color: color ?? AppColors.textHeading),
              ),
            ],
          ),
        );
    return PopupMenuButton<String>(
      key: ValueKey('daily-activity-actions-${activity.id}'),
      tooltip: 'Row actions',
      color: AppColors.surfaceWhite,
      icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
      onSelected: (value) => switch (value) {
        'edit' => onEdit?.call(activity),
        'delete' => onDelete?.call(activity),
        _ => onView(activity),
      },
      itemBuilder: (_) => [
        item('view', Icons.visibility_outlined, 'View'),
        if (onEdit != null) item('edit', Icons.edit_outlined, 'Edit'),
        if (onDelete != null)
          item('delete', Icons.delete_outline_rounded, 'Delete', color: AppColors.criticalRed),
      ],
    );
  }
}
