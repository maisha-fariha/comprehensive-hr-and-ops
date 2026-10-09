import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/emergency_alert.dart';
import '../controllers/emergency_controller.dart';
import '../emergency_labels.dart';
import '../widgets/emergency_alert_card.dart';
import '../widgets/emergency_detail_sheet.dart';
import '../widgets/emergency_kpi_grid.dart';
import '../widgets/raise_emergency_sheet.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Manager "Emergency Alarms" — mirrors web `/dashboard/emergency`.
class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  late final EmergencyController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<EmergencyController>());
  }

  @override
  void dispose() {
    Get.delete<EmergencyController>();
    super.dispose();
  }

  Future<void> _raise() async {
    final raised = await showRaiseEmergencySheet(context, repository: _c.repository);
    if (raised == true) await _c.refreshAll();
  }

  Future<void> _confirmDelete(EmergencyAlert alert) async {
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text(
          'Delete this alert?',
          style: handoverText(dialogContext, 17, weight: FontWeight.w700),
        ),
        content: Text(
          'It leaves the board. The alert, its actions and who answered it are '
          'kept rather than destroyed, so it can be restored.',
          style: handoverText(dialogContext, 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          HandoverButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          Material(
            color: AppColors.criticalRed,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              key: const ValueKey('emergency-delete-confirm'),
              borderRadius: BorderRadius.circular(9),
              onTap: () => Navigator.of(dialogContext).pop(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Delete',
                  style: handoverText(
                    dialogContext,
                    13.5,
                    weight: FontWeight.w600,
                    color: AppColors.surfaceWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _c.delete(alert);
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Emergency Alarms',
                        style: handoverText(context, 18, weight: FontWeight.w700),
                      ),
                    ),
                    if (_c.canRaise) EmergencyRaiseButton(onPressed: _raise),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: _c.refreshAll,
              child: Obx(
                () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: [
                    _statusFilter(context),
                    const SizedBox(height: 15),
                    EmergencyKpiGrid(stats: _c.stats.value),
                    const SizedBox(height: 15),
                    ..._list(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusFilter(BuildContext context) {
    final options = [('', 'All'), ...EmergencyLabels.statuses];
    final current = _c.status.value ?? '';
    final label = options.firstWhere((o) => o.$1 == current).$2;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          key: const ValueKey('emergency-status-filter'),
          borderRadius: BorderRadius.circular(9),
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: 'Status',
              options: options,
              selected: current,
            );
            if (picked != null) _c.setStatus(picked.isEmpty ? null : picked);
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 150),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: handoverText(context, 13.5, weight: FontWeight.w500)),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _list(BuildContext context) {
    if (_c.loading.value && _c.alerts.isEmpty) {
      return [
        for (var i = 0; i < 3; i++)
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ];
    }
    if (_c.alerts.isEmpty) {
      final failed = _c.loadError.value != null;
      return [
        HandoverPanel(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.crisis_alert_rounded,
                  size: 19,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                failed ? 'Alarms could not be loaded' : 'Nothing to respond to',
                textAlign: TextAlign.center,
                style: handoverText(context, 15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                failed
                    ? 'The list will reappear on the next refresh.'
                    : 'Raised alarms appear here the moment they come in.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      for (final alert in _c.alerts) ...[
        EmergencyAlertCard(
          key: ValueKey('emergency-${alert.id}'),
          alert: alert,
          busy: _c.busyId.value == alert.id,
          canRespond: _c.canRespond,
          onOpen: () => showEmergencyDetailSheet(
            context,
            controller: _c,
            alertId: alert.id,
          ),
          onAcknowledge: () => _c.acknowledge(alert),
          onResolve: () => _c.resolve(alert),
          onDelete: () => _confirmDelete(alert),
        ),
        const SizedBox(height: 12),
      ],
      if (_c.total.value > 0)
        AttendancePagination(
          page: _c.page.value,
          limit: _c.limit.value,
          total: _c.total.value,
          totalPages: _c.totalPages,
          limitOptions: EmergencyController.pageSizes,
          onPage: _c.setPage,
          onLimit: _c.setLimit,
        ),
    ];
  }
}
