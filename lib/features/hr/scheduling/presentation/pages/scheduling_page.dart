import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../ai/presentation/widgets/ai_draft_sheet.dart';
import '../../../ai/presentation/widgets/ai_feature_sheets.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../controllers/scheduling_controller.dart';
import '../widgets/board_tab_view.dart';
import '../widgets/calendar_tab_view.dart';
import '../widgets/requests_tab_view.dart';
import '../widgets/scheduling_filter_bar.dart';
import '../widgets/scheduling_segmented_tabs.dart';
import '../widgets/open_shift_bids_sheet.dart';
import '../widgets/schedule_side_rails.dart';
import '../widgets/schedule_span_panel.dart';
import '../widgets/scheduling_top_bar.dart';
import '../widgets/staff_rostered_hours_sheet.dart';
import '../../domain/entities/calendar_shift.dart';
import 'create_shift_page.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

/// The Manager/HR Scheduling screen — the "Schedule" tab of the HR portal.
///
/// Reproduction of the Figma "Scheduling" group's 3 frames ("Calendar -
/// Scheduling", "Board - Scheduling", "Requests - Scheduling"), which all
/// share the exact same header and segmented tab bar and only swap their
/// main content area — implemented here as a single page with an internal
/// segmented-tab state rather than 3 separate pages.
class SchedulingPage extends StatefulWidget {
  const SchedulingPage({super.key});

  @override
  State<SchedulingPage> createState() => _SchedulingPageState();
}

class _SchedulingPageState extends State<SchedulingPage> {
  bool? _aiEnabled;

  SchedulingController _resolveController() {
    try {
      return Get.find<SchedulingController>();
    } catch (_) {
      return Get.put(GetIt.instance<SchedulingController>(), permanent: true);
    }
  }

  @override
  void initState() {
    super.initState();
    aiDraftingEnabled().then((enabled) {
      if (mounted) setState(() => _aiEnabled = enabled);
    });
  }

  Future<void> _reviewRota(SchedulingController controller) async {
    await controller.loadResidences();
    if (!mounted) return;
    final week = controller.weekOf.value;
    final from =
        '${week.year.toString().padLeft(4, '0')}-${week.month.toString().padLeft(2, '0')}-${week.day.toString().padLeft(2, '0')}';
    await openRotaReviewSheet(
      context,
      fromDate: from,
      initialResidenceId: controller.residenceFilter.value,
      residences: [
        for (final r in controller.residences)
          AiSelectOption(r.id, r.name),
      ],
    );
  }

  Future<void> _openCreateShift(SchedulingController controller) async {
    final created = await Get.to<bool>(
      () => CreateShiftPage(
        initialResidenceId: controller.residenceFilter.value,
        initialShiftDate: controller.selectedDay.value,
      ),
    );
    if (created == true) {
      await controller.refresh();
    }
  }

  Future<void> _openEditShift(
    SchedulingController controller,
    String shiftId,
  ) async {
    final saved = await Get.to<bool>(
      () => CreateShiftPage(editShiftId: shiftId),
    );
    if (saved == true) {
      await controller.refresh();
    }
  }

  /// Web Open shift dialog — always opens for write; never skips to edit.
  Future<void> _openOpenShift(
    BuildContext context,
    SchedulingController controller,
    CalendarShift shift,
  ) async {
    if (!controller.canWrite) return;
    await showOpenShiftBidsSheet(
      context: context,
      controller: controller,
      shift: shift,
      onEditShift: () => _openEditShift(controller, shift.id),
      onCancelShift: () => _confirmCancelShift(context, controller, shift),
      onDeleteShift: () => _confirmDeleteShift(context, controller, shift),
    );
  }

  Future<void> _confirmCancelShift(
    BuildContext context,
    SchedulingController controller,
    CalendarShift shift,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this shift?'),
        content: const Text(
          'The shift will be cancelled and staff will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel shift',
              style: TextStyle(color: AppColors.urgentAmber),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.cancelShift(shift.id);
    }
  }

  Future<void> _confirmDeleteShift(
    BuildContext context,
    SchedulingController controller,
    CalendarShift shift,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this open shift?'),
        content: Text(
          '${shift.title?.trim().isNotEmpty == true ? shift.title : shift.name}'
          ' will be removed permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.criticalRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteShift(shift.id);
    }
  }

  Future<void> _onCalendarShiftTap(
    SchedulingController controller,
    CalendarShift shift,
  ) async {
    if (!controller.canWrite) return;
    // Shift list / calendar rows always open Edit for writers. Accept/reject
    // stays on the Open shifts section only — do not route list taps there.
    await _openEditShift(controller, shift.id);
  }

  Future<void> _pickDate(
    BuildContext context,
    SchedulingController controller,
  ) async {
    final selected = controller.selectedDay.value;
    final date = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(selected.year - 2),
      lastDate: DateTime(selected.year + 2, 12, 31),
      helpText: 'Jump to week',
    );
    if (date == null) return;
    await controller.jumpToDate(date);
  }

  Future<void> _openFilters(
    BuildContext context,
    SchedulingController controller,
  ) async {
    await controller.loadResidences();
    if (!context.mounted) return;
    final selection = await showSchedulingFiltersSheet(
      context,
      residences: controller.residences,
      residenceId: controller.residenceFilter.value,
      status: controller.statusFilter.value,
    );
    if (selection == null) return;
    await controller.applyFilters(
      residenceId: selection.residenceId,
      status: selection.status,
    );
  }

  Future<void> _openStaffHours(
    BuildContext context,
    SchedulingController controller,
  ) async {
    final overview = controller.state.value.data;
    if (overview == null) return;
    await showStaffRosteredHoursSheet(
      context: context,
      weekOf: controller.weekOf.value,
      weekRows: overview.staffRosteredHours,
      residenceId: controller.residenceFilter.value,
      status: controller.statusFilter.value,
      mine: controller.mineOnly.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final response = controller.state.value;
          final overview = response.data;

          if (overview == null && controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
          }

          if (overview == null) {
            return _SchedulingError(
              message: controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading the schedule.'
                  : controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    SchedulingTopBar(
                      onReviewRotaTap: _aiEnabled == true
                          ? () => _reviewRota(controller)
                          : null,
                      onStaffHoursTap: () =>
                          _openStaffHours(context, controller),
                      onCreateShiftTap: controller.canWrite
                          ? () => _openCreateShift(controller)
                          : null,
                    ),
                    SchedulingFilterBar(
                      weekOf: controller.weekOf.value,
                      activeFilterCount: controller.activeFilterCount,
                      onDateTap: () => _pickDate(context, controller),
                      onFiltersTap: () => _openFilters(context, controller),
                      mineOnly: controller.mineOnly.value,
                      onMineTap:
                          controller.canWrite ? controller.toggleMine : null,
                    ),
                    SchedulingSegmentedTabs(
                      selectedTab: controller.selectedTab.value,
                      requestsBadgeCount: overview.requests.pendingRequests.length,
                      onTabSelected: controller.selectTab,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AppRefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: switch (controller.selectedTab.value) {
                    SchedulingTab.calendar => switch (controller.span.value) {
                      ScheduleSpan.month => ScheduleMonthView(
                        controller: controller,
                        shifts: overview.calendar.weekShifts,
                      ),
                      ScheduleSpan.list => ScheduleAllShiftsView(
                        controller: controller,
                        shifts: overview.calendar.weekShifts,
                        coverage: overview.weekCoverage,
                        onOpenShift: controller.canWrite
                            ? (shiftId) => _openEditShift(controller, shiftId)
                            : null,
                      ),
                      ScheduleSpan.week => CalendarTabView(
                        data: overview.calendar,
                        onPreviousWeek: controller.goToPreviousWeek,
                        onNextWeek: controller.goToNextWeek,
                        onDaySelected: (day) =>
                            controller.selectCalendarDay(day.date),
                        onShiftTap: controller.canWrite
                            ? (shift) => _onCalendarShiftTap(controller, shift)
                            : null,
                        leading: [
                          ScheduleSpanSwitch(
                            selected: ScheduleSpan.week,
                            onSelected: controller.selectSpan,
                          ),
                        ],
                        trailing: [
                          OpenShiftsRail(
                            controller: controller,
                            openShifts: overview.openShifts,
                            onOpenShift: controller.canWrite
                                ? (shift) => _openOpenShift(
                                      context,
                                      controller,
                                      shift,
                                    )
                                : null,
                            onEditShift: controller.canWrite
                                ? (shift) =>
                                    _openEditShift(controller, shift.id)
                                : null,
                            onCancelShift: controller.canWrite
                                ? (shift) => _confirmCancelShift(
                                      context,
                                      controller,
                                      shift,
                                    )
                                : null,
                            onDeleteShift: controller.canWrite
                                ? (shift) => _confirmDeleteShift(
                                      context,
                                      controller,
                                      shift,
                                    )
                                : null,
                            onBid: controller.canBid
                                ? (shift) async {
                                    await controller.placeShiftBid(shift.id);
                                  }
                                : null,
                          ),
                          StaffRosteredHoursRail(
                            rows: overview.staffRosteredHours,
                            weekStart: controller.weekOf.value,
                            onViewBreakdown: () =>
                                _openStaffHours(context, controller),
                          ),
                          WeekSwapRail(
                            controller: controller,
                            shifts: overview.calendar.weekShifts,
                            pending: overview.requests.pendingRequests,
                          ),
                        ],
                      ),
                    },
                    SchedulingTab.board => BoardTabView(
                      data: overview.board,
                      onShiftTap: controller.canWrite
                          ? (shift) => _openEditShift(controller, shift.id)
                          : null,
                    ),
                    SchedulingTab.requests => RequestsTabView(
                      data: overview.requests,
                      onApprove: controller.canWrite
                          ? controller.approveRequest
                          : null,
                      onDecline: controller.canWrite
                          ? controller.declineRequest
                          : null,
                      onOpenShift: controller.canWrite
                          ? (id) {
                              CalendarShift? match;
                              for (final s in overview.openShifts) {
                                if (s.id == id) {
                                  match = s;
                                  break;
                                }
                              }
                              if (match != null) {
                                _openOpenShift(
                                  context,
                                  controller,
                                  match,
                                );
                                return;
                              }
                              _openEditShift(controller, id);
                            }
                          : null,
                    ),
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SchedulingError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _SchedulingError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.criticalRed, size: 40),
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
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
