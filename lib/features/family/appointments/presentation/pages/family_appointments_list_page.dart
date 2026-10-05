import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../family_shell.dart';
import '../../../visit_requests/presentation/pages/visit_request_details_page.dart';
import '../../domain/entities/family_appointment.dart';
import '../../domain/entities/family_appointments_enums.dart';
import '../controllers/family_appointments_controller.dart';
import '../widgets/family_appointment_card.dart';
import '../widgets/family_appointments_header.dart';
import '../widgets/family_appointments_tab_bar.dart';
import '../widgets/family_primary_button.dart';
import 'create_appointment_page.dart';

/// The Family Visits & Appointments list - web `/family/appointments`:
/// "Upcoming Visits" / "Past Visits" tabs over `GET /family/appointments`.
///
/// The list is refetched whenever the screen becomes visible again (shell
/// tab switch, re-entry, app resume) so staff decisions such as Rejected or
/// Cancelled replace a stale Pending pill.
class FamilyAppointmentsListPage extends StatefulWidget {
  const FamilyAppointmentsListPage({super.key});

  @override
  State<FamilyAppointmentsListPage> createState() =>
      _FamilyAppointmentsListPageState();
}

class _FamilyAppointmentsListPageState extends State<FamilyAppointmentsListPage>
    with WidgetsBindingObserver {
  late final FamilyAppointmentsController _controller;
  bool? _wasVisible;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = _resolveController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // FamilyShell keeps tabs alive in an IndexedStack (a Visibility per
    // child), so a tab switch only flips Visibility.of.
    final visible = Visibility.of(context);
    if (_wasVisible == false && visible) _refreshAfterFrame();
    _wasVisible = visible;
  }

  void _refreshAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && (_wasVisible ?? true)) {
      _controller.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  FamilyAppointmentsController _resolveController() {
    if (Get.isRegistered<FamilyAppointmentsController>()) {
      _refreshAfterFrame();
      return Get.find<FamilyAppointmentsController>();
    }
    return Get.put(
      GetIt.instance<FamilyAppointmentsController>(),
      permanent: true,
    );
  }

  void _openCreateAppointment() {
    Get.to(() => const CreateAppointmentPage());
  }

  Future<void> _onAppointmentTap(
    BuildContext context,
    FamilyAppointment appointment,
  ) async {
    if (appointment.status == FamilyAppointmentStatus.rejected ||
        appointment.iconKind == FamilyAppointmentIconKind.familyVisit) {
      await Get.to(() => VisitRequestDetailsPage(requestId: appointment.id));
      _controller.refresh();
      return;
    }
    if (!_controller.canAct(appointment)) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Reschedule'),
              onTap: () => Navigator.pop(context, 'reschedule'),
            ),
            ListTile(
              title: const Text('Withdraw'),
              onTap: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        ),
      ),
    );
    if (action == 'reschedule' && context.mounted) {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: now.add(const Duration(days: 1)),
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          appointment.scheduledAt ?? DateTime(date.year, date.month, date.day, 14),
        ),
      );
      if (time == null) return;
      await _controller.rescheduleTo(
        appointment.id,
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      );
    } else if (action == 'cancel') {
      await _controller.cancelAppointment(appointment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final response = _controller.state.value;
          final hasData = response.data != null;

          if (!hasData && _controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            );
          }

          if (!hasData) {
            return _AppointmentsError(
              message: _controller.errorMessage.value,
              onRetry: _controller.refresh,
            );
          }

          final selectedTab = _controller.selectedTab.value;
          final items = _controller.visibleAppointments;

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FamilyAppointmentsHeader(
                      title: 'Visits & Appointments',
                      onBack: () {
                        final navigator = Navigator.of(context);
                        if (navigator.canPop()) {
                          navigator.pop();
                          return;
                        }
                        // Embedded as a FamilyShell tab — return to Home.
                        Get.offAll(() => const FamilyShell(initialIndex: 0));
                      },
                    ),
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 20,
                        bottom: 14,
                      ),
                      child: FamilyAppointmentsTabBar(
                        selected: selectedTab,
                        counts: {
                          FamilyAppointmentsTab.upcoming:
                              _controller.upcomingAppointments.length,
                          FamilyAppointmentsTab.past:
                              _controller.pastAppointments.length,
                        },
                        onSelected: _controller.selectTab,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.refresh,
                  child: items.isEmpty
                      ? ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getResponsiveWidth(context, 20),
                            vertical: ResponsiveHelper.getResponsiveHeight(context, 40),
                          ),
                          children: [_EmptyVisits(tab: selectedTab)],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveHelper.getResponsiveWidth(context, 20),
                            ResponsiveHelper.getResponsiveHeight(context, 16),
                            ResponsiveHelper.getResponsiveWidth(context, 20),
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                          ),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(context, 12),
                          ),
                          itemBuilder: (context, index) => FamilyAppointmentCard(
                            key: ValueKey('family-appointment-${items[index].id}'),
                            appointment: items[index],
                            onTap: () => _onAppointmentTap(context, items[index]),
                          ),
                        ),
                ),
              ),
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, 20),
                    ResponsiveHelper.getResponsiveHeight(context, 14),
                    ResponsiveHelper.getResponsiveWidth(context, 20),
                    ResponsiveHelper.getResponsiveHeight(context, 14),
                  ),
                  child: FamilyPrimaryButton(
                    label: 'Request a Visit',
                    icon: Icons.add_rounded,
                    onTap: _openCreateAppointment,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _EmptyVisits extends StatelessWidget {
  final FamilyAppointmentsTab tab;

  const _EmptyVisits({required this.tab});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = tab == FamilyAppointmentsTab.upcoming;
    return Column(
      children: [
        Text(
          isUpcoming ? 'No upcoming visits scheduled' : 'No past visits recorded',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
        Text(
          isUpcoming
              ? 'Plan time with your loved one. Request a visit above and the care team will confirm your slot.'
              : 'Completed and archived visits will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AppointmentsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _AppointmentsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.criticalRed,
              size: 40,
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            const Text(
              'Visits could not be loaded',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                color: AppColors.textHeading,
              ),
            ),
            if (message.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
