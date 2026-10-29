import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/time_off_request.dart';
import '../controllers/attendance_controller.dart';
import 'time_off_request_sheet.dart';

class TimeOffSection extends StatelessWidget {
  final AttendanceController controller;
  final bool managerMode;

  const TimeOffSection({
    super.key,
    required this.controller,
    this.managerMode = true,
  });

  Future<void> _openRequest(BuildContext context) async {
    final draft = await showTimeOffRequestSheet(
      context: context,
      pickStaff: managerMode,
      repository: managerMode ? controller.repository : null,
    );
    if (draft == null) return;
    await controller.submitTimeOffRequest(
      type: draft.type,
      startDate: draft.startDate,
      endDate: draft.endDate,
      staffId: draft.staffId,
      reason: draft.reason,
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.timeOffLoading.value;
      final error = controller.timeOffError.value;
      final rows = controller.timeOffRequests;
      final tab = controller.timeOffTab.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  managerMode ? 'Time-off requests' : 'My time off',
                  style: handoverText(context, 15, weight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('time-off-request-btn'),
                onPressed: () => _openRequest(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Request'),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.loadTimeOffRequests,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            managerMode
                ? 'Leave requests submitted by your team.'
                : 'Your submitted leave requests and their status.',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in TimeOffStatusTab.values)
                ChoiceChip(
                  key: ValueKey('time-off-tab-${t.name}'),
                  label: Text(_tabLabel(t)),
                  selected: tab == t,
                  onSelected: (_) => controller.setTimeOffTab(t),
                  selectedColor: AppColors.secondaryTeal.withValues(alpha: 0.15),
                  labelStyle: handoverText(
                    context,
                    12,
                    weight: FontWeight.w600,
                    color: tab == t ? AppColors.secondaryTeal : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: tab == t ? AppColors.secondaryTeal : AppColors.cardBorder,
                  ),
                  backgroundColor: AppColors.surfaceWhite,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading && rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null && rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: handoverText(context, 13, color: AppColors.criticalRed),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.loadTimeOffRequests,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No time-off requests yet.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13, color: AppColors.textMuted),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final request = rows[i];
                return _TimeOffTile(
                  request: request,
                  showStaff: managerMode,
                  rangeLabel: request.startDate == request.endDate
                      ? _fmt(request.startDate)
                      : '${_fmt(request.startDate)} → ${_fmt(request.endDate)}',
                );
              },
            ),
        ],
      );
    });
  }

  String _tabLabel(TimeOffStatusTab t) => switch (t) {
        TimeOffStatusTab.pending => 'Pending',
        TimeOffStatusTab.approved => 'Approved',
        TimeOffStatusTab.rejected => 'Rejected',
        TimeOffStatusTab.all => 'All',
      };
}

class _TimeOffTile extends StatelessWidget {
  final TimeOffRequest request;
  final bool showStaff;
  final String rangeLabel;

  const _TimeOffTile({
    required this.request,
    required this.showStaff,
    required this.rangeLabel,
  });

  Color _statusColor(TimeOffStatus s) {
    switch (s) {
      case TimeOffStatus.approved:
        return AppColors.successGreen;
      case TimeOffStatus.rejected:
        return AppColors.criticalRed;
      case TimeOffStatus.pending:
        return AppColors.urgentAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.type.label,
                  style: handoverText(context, 14, weight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request.status.label,
                  style: handoverText(
                    context,
                    11.5,
                    weight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rangeLabel,
            style: handoverText(context, 12.5, color: AppColors.textSecondary),
          ),
          if (request.days > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${request.days} day${request.days == 1 ? '' : 's'}',
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
          ],
          if (showStaff && request.staffName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(request.staffName, style: handoverText(context, 12.5)),
          ],
          if (request.reason != null && request.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              request.reason!,
              style: handoverText(context, 12.5, color: AppColors.textMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
