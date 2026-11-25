import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../hr/attendance/domain/entities/time_off_request.dart';
import '../../../../hr/attendance/presentation/widgets/time_off_request_sheet.dart';
import '../../../../hr/handovers/presentation/widgets/handover_common.dart';
import '../controllers/staff_attendance_controller.dart';

class StaffTimeOffSection extends StatelessWidget {
  final StaffAttendanceController controller;

  const StaffTimeOffSection({super.key, required this.controller});

  Future<void> _openRequest(BuildContext context) async {
    final draft = await showTimeOffRequestSheet(
      context: context,
      pickStaff: false,
    );
    if (draft == null) return;
    await controller.submitTimeOffRequest(
      type: draft.type,
      startDate: draft.startDate,
      endDate: draft.endDate,
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
                  'My time off',
                  style: handoverText(context, 15, weight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('staff-time-off-request-btn'),
                onPressed: () => _openRequest(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Request'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your leave requests and their status.',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in TimeOffStatusTab.values)
                ChoiceChip(
                  key: ValueKey('staff-time-off-tab-${t.name}'),
                  label: Text(switch (t) {
                    TimeOffStatusTab.pending => 'Pending',
                    TimeOffStatusTab.approved => 'Approved',
                    TimeOffStatusTab.rejected => 'Rejected',
                    TimeOffStatusTab.all => 'All',
                  }),
                  selected: tab == t,
                  onSelected: (_) => controller.setTimeOffTab(t),
                  selectedColor: AppColors.secondaryTeal.withValues(alpha: 0.15),
                  labelStyle: handoverText(
                    context,
                    12,
                    weight: FontWeight.w600,
                    color: tab == t
                        ? AppColors.secondaryTeal
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: tab == t
                        ? AppColors.secondaryTeal
                        : AppColors.cardBorder,
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
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null && rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style:
                        handoverText(context, 13, color: AppColors.criticalRed),
                  ),
                  TextButton(
                    onPressed: controller.loadTimeOffRequests,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No time-off requests yet.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13, color: AppColors.textMuted),
              ),
            )
          else
            for (final request in rows) ...[
              _Tile(
                typeLabel: request.type.label,
                statusLabel: request.status.label,
                statusColor: switch (request.status) {
                  TimeOffStatus.approved => AppColors.successGreen,
                  TimeOffStatus.rejected => AppColors.criticalRed,
                  TimeOffStatus.pending => AppColors.urgentAmber,
                },
                rangeLabel: request.startDate == request.endDate
                    ? _fmt(request.startDate)
                    : '${_fmt(request.startDate)} → ${_fmt(request.endDate)}',
                reason: request.reason,
              ),
              const SizedBox(height: 8),
            ],
        ],
      );
    });
  }
}

class _Tile extends StatelessWidget {
  final String typeLabel;
  final String statusLabel;
  final Color statusColor;
  final String rangeLabel;
  final String? reason;

  const _Tile({
    required this.typeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.rangeLabel,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
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
                  typeLabel,
                  style: handoverText(context, 14, weight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
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
          if (reason != null && reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reason!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
