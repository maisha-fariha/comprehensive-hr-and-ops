import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_appointment.dart';
import '../controllers/hr_appointments_controller.dart';
import '../widgets/hr_appointment_card.dart';
import '../widgets/hr_appointment_detail_sheet.dart';
import '../widgets/hr_appointment_form_sheet.dart';
import '../widgets/hr_appointment_reason_dialog.dart';
import '../widgets/hr_appointments_kpi_grid.dart';
import '../widgets/hr_appointments_toolbar.dart';

/// Manager "Family Appointments & Approvals" — mirrors web
/// `/dashboard/appointments`.
class HrAppointmentsPage extends StatefulWidget {
  const HrAppointmentsPage({super.key});

  @override
  State<HrAppointmentsPage> createState() => _HrAppointmentsPageState();
}

class _HrAppointmentsPageState extends State<HrAppointmentsPage> {
  late final HrAppointmentsController _c;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<HrAppointmentsController>());
  }

  @override
  void dispose() {
    _search.dispose();
    Get.delete<HrAppointmentsController>();
    super.dispose();
  }

  Future<void> _openForm({HrAppointment? editing}) =>
      showHrAppointmentFormSheet(context, controller: _c, editing: editing);

  Future<void> _view(HrAppointment a) async {
    final edit = await showHrAppointmentDetailSheet(context, controller: _c, appointment: a);
    if (edit && mounted) await _openForm(editing: a);
  }

  Future<void> _confirmDelete(HrAppointment a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text(
          'Delete this appointment?',
          style: handoverText(dialogContext, 17, weight: FontWeight.w700),
        ),
        content: Text(
          'It leaves every list. The request is kept rather than destroyed, so it can be restored.',
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
              key: const ValueKey('appointment-delete-confirm'),
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
    if (confirmed == true) await _c.delete(a);
  }

  void _onAction(HrAppointment a, HrAppointmentAction action) {
    switch (action) {
      case HrAppointmentAction.view:
        _view(a);
      case HrAppointmentAction.approve:
        _c.approve(a);
      case HrAppointmentAction.reject:
        showHrAppointmentReasonDialog(context, controller: _c, appointment: a, reject: true);
      case HrAppointmentAction.edit:
        _openForm(editing: a);
      case HrAppointmentAction.cancel:
        showHrAppointmentReasonDialog(context, controller: _c, appointment: a, reject: false);
      case HrAppointmentAction.delete:
        _confirmDelete(a);
    }
  }

  void _clearFilters() {
    _search.clear();
    _c.clearFilters();
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
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHeading),
                    ),
                    Expanded(
                      child: Text(
                        'Appointments',
                        style: handoverText(context, 18, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: () async {
                if (_c.canRead) await _c.refreshAll();
              },
              child: Obx(
                () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: [
                    _heading(context),
                    const SizedBox(height: 15),
                    if (_c.summary.value case final s?) ...[
                      HrAppointmentsKpiGrid(summary: s),
                      const SizedBox(height: 15),
                    ],
                    HrAppointmentsToolbar(
                      tab: _c.tab.value,
                      counts: _c.tabCounts,
                      search: _search,
                      filtersShown: _c.filtersShown.value,
                      onTab: _c.setTab,
                      onSearch: _c.setSearch,
                      onToggleFilters: _c.toggleFilters,
                    ),
                    const SizedBox(height: 15),
                    _register(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Appointments & Approvals',
          style: handoverText(context, 20, weight: FontWeight.w700, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 2),
        Text(
          'Visit requests from families, and the appointments the home books itself',
          style: handoverText(context, 13, color: AppColors.textMuted),
        ),
        if (_c.canWrite || _c.canExport) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_c.canWrite)
                HandoverButton(
                  key: const ValueKey('appointments-create'),
                  label: 'Create Appointment',
                  icon: Icons.add_rounded,
                  filled: true,
                  onPressed: () => _openForm(),
                ),
              if (_c.canExport)
                HandoverButton(
                  key: const ValueKey('appointments-export'),
                  label: _c.exporting.value ? 'Preparing…' : 'Export List',
                  icon: Icons.download_rounded,
                  foreground: AppColors.secondaryTeal,
                  onPressed: _c.exporting.value ? null : _c.export,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _register(BuildContext context) {
    final total = _c.total.value;
    return HandoverPanel(
      padding: const EdgeInsets.all(14),
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
                    Text(
                      'Requests & Appointments',
                      style: handoverText(context, 16, weight: FontWeight.w600, color: AppColors.primaryNavy),
                    ),
                    Text(
                      'Sorted by the time they are due · earliest first',
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$total ${total == 1 ? 'request' : 'requests'}',
                  style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (_c.filtersShown.value) ...[
            const SizedBox(height: 12),
            HrAppointmentsFilters(
              status: _c.status.value,
              type: _c.type.value,
              residenceId: _c.residenceId.value,
              residences: _c.residences.toList(),
              onChanged: _c.setFilter,
              onClear: _clearFilters,
            ),
          ],
          const SizedBox(height: 14),
          ..._rows(context),
        ],
      ),
    );
  }

  List<Widget> _rows(BuildContext context) {
    if (_c.loading.value && _c.items.isEmpty) {
      return [
        for (var i = 0; i < 3; i++)
          Container(
            height: 96,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ];
    }
    if (_c.items.isEmpty) {
      final error = !_c.canRead
          ? 'You do not have permission to view appointments.'
          : _c.loadError.value;
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_calendar_rounded, size: 19, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                error != null ? 'Requests could not be loaded' : 'Nothing here',
                textAlign: TextAlign.center,
                style: handoverText(context, 15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                error ?? 'Visit requests from families appear here as they arrive.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      for (final a in _c.items) ...[
        HrAppointmentCard(
          key: ValueKey('appointment-${a.id}'),
          appointment: a,
          canWrite: _c.canWrite,
          busy: _c.busyId.value == a.id,
          onAction: (action) => _onAction(a, action),
        ),
        const SizedBox(height: 12),
      ],
      if (_c.total.value > 0)
        AttendancePagination(
          page: _c.page.value,
          limit: _c.limit.value,
          total: _c.total.value,
          totalPages: _c.totalPages.value < 1 ? 1 : _c.totalPages.value,
          limitOptions: HrAppointmentsController.pageSizes,
          onPage: _c.setPage,
          onLimit: _c.setLimit,
        ),
    ];
  }
}
