import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../../domain/entities/staff_appointment.dart';
import '../controllers/staff_appointments_controller.dart';
import '../widgets/staff_appointments_metrics_strip.dart';
import '../widgets/staff_appointments_registry.dart';
import '../widgets/staff_appointments_tabs_bar.dart';
import '../widgets/staff_create_appointment_sheet.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Staff Family Appointments & Approvals — web `/dashboard/appointments`.
class StaffAppointmentsPage extends StatefulWidget {
  const StaffAppointmentsPage({super.key});

  @override
  State<StaffAppointmentsPage> createState() => _StaffAppointmentsPageState();
}

class _StaffAppointmentsPageState extends State<StaffAppointmentsPage> {
  late final StaffAppointmentsController _controller;
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<StaffAppointmentsController>();
    } catch (_) {
      _controller = Get.put(
        GetIt.instance<StaffAppointmentsController>(),
        permanent: true,
      );
    }
    _searchController = TextEditingController(
      text: _controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _controller.setSearch(value);
    });
  }

  Future<void> _handleResult(
    Future<dynamic> Function() action, {
    required String successTitle,
  }) async {
    final result = await action();
    result.when(
      success: (_) => Get.snackbar(successTitle, ''),
      failure: (e) => Get.snackbar('Something went wrong', e.message),
    );
  }

  Future<void> _confirmApprove(StaffAppointment item) async {
    final ok = await showAppPopup<bool>(
      context: context,
      builder: (ctx) => AppSheetDialog(
        title: const Text(
          'Approve request?',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Approve ${item.shortId} for ${item.clientName}?',
          style: const TextStyle(fontFamily: 'Outfit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.activeGreen,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _handleResult(
      () => _controller.approve(item.id),
      successTitle: 'Appointment approved',
    );
  }

  Future<void> _confirmReject(StaffAppointment item) async {
    final reasonController = TextEditingController();
    final ok = await showAppPopup<bool>(
      context: context,
      builder: (ctx) => AppSheetDialog(
        title: const Text(
          'Reject request?',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${item.shortId} for ${item.clientName}?',
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.criticalRed,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (ok != true) return;
    await _handleResult(
      () => _controller.reject(
        item.id,
        reason: reason.isEmpty ? null : reason,
      ),
      successTitle: 'Appointment rejected',
    );
  }

  Future<void> _confirmWithdraw(StaffAppointment item) async {
    final ok = await showAppPopup<bool>(
      context: context,
      builder: (ctx) => AppSheetDialog(
        title: const Text(
          'Cancel appointment?',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Cancel ${item.shortId}? It will move to the cancelled register.',
          style: const TextStyle(fontFamily: 'Outfit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.criticalRed,
            ),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _handleResult(
      () => _controller.cancel(item.id),
      successTitle: 'Appointment cancelled',
    );
  }

  Future<void> _confirmDelete(StaffAppointment item) async {
    final ok = await showAppPopup<bool>(
      context: context,
      builder: (ctx) => AppSheetDialog(
        title: const Text(
          'Delete appointment?',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Permanently delete ${item.shortId}? This cannot be undone.',
          style: const TextStyle(fontFamily: 'Outfit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.criticalRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _handleResult(
      () => _controller.delete(item.id),
      successTitle: 'Appointment deleted',
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();
    final canWrite = session.canWriteAppointments;

    return Scaffold(
      key: const Key('staff-appointments-page'),
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: 4,
        onTap: (i) => Get.offAll(() => StaffShell(initialIndex: i)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              canWrite: canWrite,
              onBack: () => Navigator.maybePop(context),
              onCreate: canWrite
                  ? () => showStaffCreateAppointmentSheet(
                        context,
                        _controller,
                      )
                  : null,
            ),
            Expanded(
              child: Obx(() {
                final loading = _controller.isLoading.value;
                final summary = _controller.summary.value;
                final items = _controller.appointments.toList();

                if (loading && items.isEmpty && summary.total == 0) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.reload,
                  child: ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      Text(
                        'Family Appointments & Approvals',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            24,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review family visit requests, book external appointments, and track decisions.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      if (_controller.errorMessage.value.isNotEmpty &&
                          items.isEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _controller.errorMessage.value,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.criticalRed,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      StaffAppointmentsMetricsStrip(
                        summary: summary,
                        onMetricTap: _controller.setTab,
                      ),
                      const SizedBox(height: 16),
                      StaffAppointmentsTabsBar(
                        selected: _controller.selectedTab.value,
                        summary: summary,
                        onChanged: _controller.setTab,
                        searchController: _searchController,
                        onSearchChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: 16),
                      StaffAppointmentsRegistry(
                        appointments: items,
                        totalCount: _controller.total.value,
                        canWrite: canWrite,
                        page: _controller.page.value,
                        totalPages: _controller.totalPages.value,
                        onPageChanged: _controller.goToPage,
                        onView: (item) =>
                            showStaffAppointmentDetailsSheet(context, item),
                        onApprove: _confirmApprove,
                        onReject: _confirmReject,
                        onEdit: (item) => showStaffCreateAppointmentSheet(
                          context,
                          _controller,
                          editing: item,
                        ),
                        onCancel: _confirmWithdraw,
                        onDelete: _confirmDelete,
                        onRestore: (item) => _handleResult(
                          () => _controller.restore(item.id),
                          successTitle: 'Appointment restored',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool canWrite;
  final VoidCallback onBack;
  final VoidCallback? onCreate;

  const _Header({
    required this.canWrite,
    required this.onBack,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.textHeading,
                ),
                const Expanded(
                  child: Text(
                    'Appointments',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
              ],
            ),
            if (canWrite && onCreate != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create Appointment'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
