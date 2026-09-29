import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/daily_log.dart';
import '../daily_logs_labels.dart';
import 'daily_log_common.dart';

class _QueueRow extends StatelessWidget {
  final String client;
  final Widget day;
  final String dayLabel;
  final Widget? extra;
  final String extraLabel;
  final String action;
  final Key actionKey;
  final VoidCallback onAction;

  const _QueueRow({
    super.key,
    required this.client,
    required this.day,
    required this.dayLabel,
    required this.action,
    required this.actionKey,
    required this.onAction,
    this.extra,
    this.extraLabel = '',
  });

  Widget _column(BuildContext context, String label, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          child,
        ],
      );

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _column(
            context,
            'Resident',
            Text(client, style: handoverText(context, 14, weight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _column(context, dayLabel, day)),
              if (extra != null) Expanded(child: _column(context, extraLabel, extra!)),
              HandoverButton(key: actionKey, label: action, compact: true, onPressed: onAction),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  final String text;

  const _ListMessage(this.text);

  @override
  Widget build(BuildContext context) => HandoverPanel(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: handoverText(context, 13.5, color: AppColors.textMuted),
        ),
      );
}

List<Widget> _spaced(List<Widget> rows) => [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        rows[i],
      ],
    ];

class ReviewQueueList extends StatelessWidget {
  final List<DailyLogReviewRow> rows;
  final bool loading;
  final String? error;
  final void Function(DailyLogReviewRow) onOpen;

  const ReviewQueueList({
    super.key,
    required this.rows,
    required this.loading,
    required this.error,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return _ListMessage(loading ? 'Loading…' : error ?? 'Nothing waiting to be reviewed.');
    }
    return Column(
      children: _spaced([
        for (final r in rows)
          _QueueRow(
            key: ValueKey('dl-review-${r.clientId}-${r.logDate}'),
            client: r.clientName,
            dayLabel: 'Day',
            day: Text(r.logDate, style: handoverText(context, 13.5)),
            extraLabel: 'Entries',
            extra: Align(
              alignment: Alignment.centerLeft,
              child: DailyLogPill('${r.entriesCount}', tone: DailyLogTone.info),
            ),
            action: 'Open day',
            actionKey: ValueKey('dl-open-day-${r.clientId}-${r.logDate}'),
            onAction: () => onOpen(r),
          ),
      ]),
    );
  }
}

class MissingLogsList extends StatelessWidget {
  final List<DailyLogMissingRow> rows;
  final bool loading;
  final String? error;
  final void Function(DailyLogMissingRow) onWrite;

  const MissingLogsList({
    super.key,
    required this.rows,
    required this.loading,
    required this.error,
    required this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return _ListMessage(
        loading ? 'Loading…' : error ?? 'Every resident has a log for this period.',
      );
    }
    return Column(
      children: _spaced([
        for (final r in rows)
          _QueueRow(
            key: ValueKey('dl-missing-${r.clientId}-${r.logDate}'),
            client: r.clientName,
            dayLabel: 'Day with no log',
            day: Align(
              alignment: Alignment.centerLeft,
              child: DailyLogPill(r.logDate, tone: DailyLogTone.danger),
            ),
            action: 'Write entry',
            actionKey: ValueKey('dl-write-${r.clientId}-${r.logDate}'),
            onAction: () => onWrite(r),
          ),
      ]),
    );
  }
}

/// House activity feed; [openFor] returns the navigation for an entity type.
class HouseActivityList extends StatelessWidget {
  final List<ResidenceActivityRow> rows;
  final bool loading;
  final VoidCallback? Function(String? entityType, String? entityId) openFor;

  const HouseActivityList({
    super.key,
    required this.rows,
    required this.loading,
    required this.openFor,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _ListMessage('Loading…');
    if (rows.isEmpty) {
      return const _ListMessage('Nothing recorded for this home in the period chosen.');
    }
    return HandoverPanel(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.cardBorder),
            _ActivityRow(row: rows[i], onOpen: openFor(rows[i].entityType, rows[i].entityId)),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ResidenceActivityRow row;
  final VoidCallback? onOpen;

  const _ActivityRow({required this.row, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final who = [row.staffName, row.residenceName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return Padding(
      key: ValueKey('dl-activity-${row.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WebFormat.time(row.occurredAt),
                  style: handoverText(context, 12.5, weight: FontWeight.w600),
                ),
                Text(
                  WebFormat.date(row.occurredAt),
                  style: handoverText(context, 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DailyLogPill(
                      DailyLogLabels.underscores(row.activityType),
                      tone: DailyLogLabels.moduleTones[row.module] ?? DailyLogTone.neutral,
                    ),
                    if (row.clientName != null)
                      Text(
                        row.clientName!,
                        style: handoverText(context, 11.5, color: AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(row.summary, style: handoverText(context, 13)),
                if (who.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(who, style: handoverText(context, 11.5, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          if (onOpen != null)
            TextButton(
              key: ValueKey('dl-activity-open-${row.id}'),
              onPressed: onOpen,
              child: Text(
                'Open',
                style: handoverText(
                  context,
                  12,
                  weight: FontWeight.w600,
                  color: AppColors.secondaryTeal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
