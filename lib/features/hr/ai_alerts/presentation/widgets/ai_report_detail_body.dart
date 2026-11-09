import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/ai_report.dart';
import '../ai_alerts_styles.dart';

class AiReportDetailBody extends StatelessWidget {
  final AiReportDetail report;

  const AiReportDetailBody({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final written = aiReportTimeLabel(report.createdAt);
    final reorder = report.reorder;
    final showReorder = report.kind == 'reorder_alert' && reorder != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            aiSeverityChip(context, report.severity),
            if ((report.label ?? '').isNotEmpty) aiMetaChip(context, report.label!),
            if (report.residence != null) aiMetaChip(context, report.residence!.name),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          report.title,
          style: handoverText(context, 20, weight: FontWeight.w700),
        ),
        if (written.isNotEmpty || (report.period ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            [
              if (written.isNotEmpty) written,
              if ((report.period ?? '').isNotEmpty) report.period!,
            ].join(' · '),
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
        ],
        if ((report.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
            ),
            child: Text(
              report.description!.trim(),
              style: handoverText(context, 13, color: AppColors.textBody),
            ),
          ),
        ],
        if (showReorder) ...[
          const SizedBox(height: 16),
          _ReorderSummaryTiles(data: reorder),
          const SizedBox(height: 12),
          _ReorderTable(items: reorder.items),
        ],
        if (report.body.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            report.body.trim(),
            style: handoverText(context, 14, color: AppColors.textBody, weight: FontWeight.w400),
          ),
        ],
        if ((report.schedule ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Schedule: ${report.schedule}',
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

class _ReorderSummaryTiles extends StatelessWidget {
  final AiReportReorderData data;

  const _ReorderSummaryTiles({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Items to order',
            value: data.toOrder?.toString() ?? '${data.items.length}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'At or below reorder',
            value: data.underReorderLevel?.toString() ??
                '${data.items.where((i) => i.atOrBelowReorderLevel).length}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Usage days',
            value: data.usageDays?.toString() ?? '—',
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: handoverText(context, 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: handoverText(context, 16, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ReorderTable extends StatelessWidget {
  final List<AiReportReorderLine> items;

  const _ReorderTable({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'No stock lines in this report.',
        style: handoverText(context, 13, color: AppColors.textMuted),
      );
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(0.8),
        2: FlexColumnWidth(0.8),
        3: FlexColumnWidth(0.9),
        4: FlexColumnWidth(0.9),
      },
      border: TableBorder.all(color: AppColors.cardBorder),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.filterButtonBackground),
          children: [
            _cell(context, 'Item', header: true),
            _cell(context, 'Stock', header: true),
            _cell(context, 'Days left', header: true),
            _cell(context, 'On order', header: true),
            _cell(context, 'Suggest', header: true),
          ],
        ),
        for (final row in items)
          TableRow(
            children: [
              _cell(
                context,
                row.unit == null || row.unit!.isEmpty
                    ? row.item
                    : '${row.item} (${row.unit})',
              ),
              _cell(context, row.stock.toString()),
              _cell(context, row.daysLeft?.toString() ?? '—'),
              _cell(context, row.onOrder.toString()),
              _cell(context, row.suggestedOrder.toString()),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, String text, {bool header = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: handoverText(
          context,
          header ? 11.5 : 12,
          weight: header ? FontWeight.w600 : FontWeight.w400,
          color: header ? AppColors.textMuted : AppColors.textBody,
        ),
      ),
    );
  }
}
