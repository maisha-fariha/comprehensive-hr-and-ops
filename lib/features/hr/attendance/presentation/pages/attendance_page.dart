import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/manual_entry_options.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_filters.dart';
import '../widgets/attendance_header.dart';
import '../widgets/attendance_kpi_grid.dart';
import '../widgets/attendance_pagination.dart';
import '../widgets/attendance_record_card.dart';
import 'attendance_clock_page.dart';
import 'manual_attendance_entry_page.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Manager "Attendance" — mirrors web `/dashboard/attendance`.
class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  static const _allResidences = ManualEntryResidenceOption(
    id: '',
    name: 'All Residences',
  );

  AttendanceController _resolveController() {
    try {
      return Get.find<AttendanceController>();
    } catch (_) {
      return Get.put(GetIt.instance<AttendanceController>(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    final horizontalPad = ResponsiveHelper.getResponsiveWidth(
      context,
      AppDimens.screenPaddingHorizontal,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: SafeArea(
              bottom: false,
              child: AttendanceHeader(
                onCalendarTap: () => _pickWeek(context, controller),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: controller.refresh,
              child: Obx(
                () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 14),
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 24),
                  ),
                  children: [
                    ..._filters(context, controller),
                    if (!controller.appliesWeek) ...[
                      _gap(context, 12),
                      const _PendingBanner(),
                    ],
                    if (controller.canManage) ...[
                      _gap(context, 14),
                      AttendanceKpiGrid(
                        summary:
                            controller.summary.value ?? const AttendanceSummary(),
                        activeStatus: controller.status.value,
                        onSelect: controller.toggleKpi,
                      ),
                    ],
                    _gap(context, 16),
                    ..._records(context, controller),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _gap(BuildContext context, double height) =>
      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, height));

  List<Widget> _filters(BuildContext context, AttendanceController controller) {
    final spacing = ResponsiveHelper.getResponsiveWidth(context, 10);
    final residenceOptions = [_allResidences, ...controller.residences];
    final selectedResidence = residenceOptions.firstWhere(
      (r) => r.id == (controller.residenceId.value ?? ''),
      orElse: () => _allResidences,
    );
    final open = controller.myOpenAttendance.value;

    return [
      AttendanceWeekButton(
        label: controller.week.value.label,
        onTap: () => _pickWeek(context, controller),
      ),
      _gap(context, 10),
      Row(
        children: [
          Expanded(
            child: AttendanceSelectField<ManualEntryResidenceOption>(
              key: const ValueKey('attendance-residence-filter'),
              title: 'Residence',
              value: selectedResidence,
              options: residenceOptions,
              labelOf: (r) => r.name,
              onChanged: (r) => controller.setResidence(r.id),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: AttendanceSelectField<AttendanceStatusFilter?>(
              key: const ValueKey('attendance-status-filter'),
              title: 'Status',
              value: controller.status.value,
              options: const [null, ...AttendanceStatusFilter.values],
              labelOf: (s) => s?.label ?? 'Any status',
              onChanged: controller.setStatus,
            ),
          ),
        ],
      ),
      if (controller.canWrite || controller.canManage) ...[
        _gap(context, 10),
        Row(
          children: [
            if (controller.canWrite)
              Expanded(
                child: _HeaderButton(
                  key: const ValueKey('attendance-clock'),
                  label: open == null ? 'Clock in' : 'Clock out',
                  icon: open == null ? Icons.login_rounded : Icons.logout_rounded,
                  color: open == null
                      ? AppColors.activeGreen
                      : AppColors.criticalRed,
                  onTap: () => _openClock(controller),
                ),
              ),
            if (controller.canWrite && controller.canManage)
              SizedBox(width: spacing),
            if (controller.canManage)
              Expanded(
                child: _HeaderButton(
                  key: const ValueKey('attendance-manual-entry'),
                  label: 'Manual Entry',
                  icon: Icons.add_rounded,
                  filled: true,
                  onTap: () async {
                    final saved = await openManualAttendanceEntry(
                      defaultResidenceId: controller.residenceId.value,
                    );
                    if (saved == true) await controller.refresh();
                  },
                ),
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _records(BuildContext context, AttendanceController controller) {
    final data = controller.state.value.data;
    final error = controller.errorMessage.value;

    if (data == null && controller.isLoading.value) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          ),
        ),
      ];
    }

    final page = data ?? AttendanceRecordPage.empty;
    return [
      if (page.records.isEmpty)
        _EmptyState(
          message: error.isNotEmpty && data == null
              ? error
              : 'No attendance matches these filters.',
          onRetry: error.isNotEmpty && data == null ? controller.refresh : null,
        )
      else
        for (final record in page.records) ...[
          AttendanceRecordCard(
            key: ValueKey('attendance-record-${record.id}'),
            record: record,
            canManage: controller.canManage,
            busy: controller.busyId.value == record.id,
            onCorrect: () async {
              final saved = await openManualAttendanceEntry(record: record);
              if (saved == true) await controller.refresh();
            },
            onDelete: () => _confirmDelete(context, controller, record),
            onReject: () => controller.reject(record),
            onApprove: () => controller.approve(record),
          ),
          _gap(context, 10),
        ],
      _gap(context, 6),
      AttendancePagination(
        page: controller.page.value,
        limit: controller.limit.value,
        total: page.total,
        totalPages: page.totalPages,
        limitOptions: AttendanceController.limitOptions,
        onPage: controller.setPage,
        onLimit: controller.setLimit,
      ),
    ];
  }

  Future<void> _pickWeek(
    BuildContext context,
    AttendanceController controller,
  ) async {
    final day = await showAttendanceWeekPicker(
      context,
      week: controller.week.value,
    );
    if (day != null) controller.selectWeek(day);
  }

  Future<void> _openClock(AttendanceController controller) async {
    final open = controller.myOpenAttendance.value;
    final done = await openAttendanceClock(
      clockOut: open != null,
      openAttendance: open,
      residences: controller.residences.toList(),
      defaultResidenceId: controller.residenceId.value,
    );
    if (done == true) await controller.refresh();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AttendanceController controller,
    AttendanceRecord record,
  ) async {
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete this attendance record?',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textHeading,
          ),
        ),
        content: const Text(
          'It leaves the list and stops counting towards pay. The record and '
          'any approval on it are kept, so it can be restored.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('attendance-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.criticalRed,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(record);
  }
}

class _HeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final Color? color;
  final VoidCallback? onTap;

  const _HeaderButton({
    super.key,
    required this.label,
    required this.icon,
    this.filled = false,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : (color ?? AppColors.textHeading);
    final radius = BorderRadius.circular(
      ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusButton),
    );
    return Material(
      color: filled ? AppColors.secondaryTeal : AppColors.surfaceWhite,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: ResponsiveHelper.getResponsiveHeight(context, 40),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: filled
                ? null
                : Border.all(color: foreground.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: ResponsiveHelper.getResponsiveSize(context, 16),
                color: foreground,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Showing every claim awaiting a decision, whenever it was typed — '
        'the week above does not apply.',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: AppColors.secondaryTeal,
          height: 1.4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _EmptyState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              color: AppColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
