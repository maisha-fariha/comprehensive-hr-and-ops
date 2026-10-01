import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/stock_ops.dart';
import '../controllers/stock_counts_controller.dart';
import '../inventory_labels.dart';
import '../widgets/inventory_common.dart';
import '../widgets/stock_count_sheets.dart';

/// Web "Stock counts".
class StockCountsView extends StatefulWidget {
  const StockCountsView({super.key});

  @override
  State<StockCountsView> createState() => _StockCountsViewState();
}

class _StockCountsViewState extends State<StockCountsView> {
  late final StockCountsController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<StockCountsController>());
  }

  @override
  void dispose() {
    Get.delete<StockCountsController>();
    super.dispose();
  }

  Future<void> _start() async {
    final id = await showStartCountSheet(context, controller: _c);
    if (id != null && mounted) await showStockCountSheet(context, controller: _c, countId: id);
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return RefreshIndicator(
      color: AppColors.secondaryTeal,
      onRefresh: _c.load,
      child: Obx(
        () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
          children: [
            if (_c.canAdjust)
              InventoryToolbar(
                children: [
                  HandoverButton(
                    key: const ValueKey('count-start'),
                    label: 'Start a count',
                    icon: Icons.add_rounded,
                    filled: true,
                    onPressed: _start,
                  ),
                ],
              ),
            ..._list(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _list(BuildContext context) {
    if (_c.loading.value && _c.counts.isEmpty) return const [InventorySkeleton()];
    if (_c.counts.isEmpty) {
      return const [
        InventoryEmptyState(
          key: ValueKey('count-empty'),
          icon: Icons.assignment_outlined,
          title: 'No stock counts yet',
          message: 'Opening a count snapshots what the system believes is on the shelf, ready '
              'to be checked against it.',
        ),
      ];
    }
    return [
      for (final count in _c.counts) ...[
        _card(context, count),
        const SizedBox(height: 12),
      ],
      AttendancePagination(
        page: _c.page.value,
        limit: _c.limit.value,
        total: _c.total.value,
        totalPages: _c.totalPages,
        limitOptions: StockCountsController.pageSizes,
        onPage: _c.setPage,
        onLimit: _c.setLimit,
      ),
    ];
  }

  Widget _card(BuildContext context, StockCount count) {
    Widget cell(String label, Widget value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: handoverText(context, 11.5, color: AppColors.textMuted)),
              const SizedBox(height: 3),
              value,
            ],
          ),
        );
    return HandoverPanel(
      key: ValueKey('count-${count.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  count.residenceName ?? '—',
                  style: handoverText(context, 15, weight: FontWeight.w600),
                ),
              ),
              AttendancePill(
                label: InventoryLabels.humanise(count.status),
                tone: InventoryLabels.countTone(count.status),
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              cell('Items', Text('${count.lines.length}', style: handoverText(context, 13))),
              cell(
                'Differences',
                Align(
                  alignment: Alignment.centerLeft,
                  child: count.varianceCount == 0
                      ? Text('None', style: handoverText(context, 13, color: AppColors.textMuted))
                      : AttendancePill(label: '${count.varianceCount}', tone: AttendanceTone.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              HandoverButton(
                key: ValueKey('count-open-${count.id}'),
                label: count.isEditable ? 'Continue' : 'View',
                compact: true,
                onPressed: () => showStockCountSheet(context, controller: _c, countId: count.id),
              ),
              if (_c.canAdjust && count.isEditable)
                HandoverButton(
                  key: ValueKey('count-cancel-${count.id}'),
                  label: 'Cancel',
                  compact: true,
                  onPressed: () => _c.cancel(count),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
