import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_appointment.dart';
import '../../domain/entities/family_appointments_enums.dart';
import '../../../visit_requests/presentation/pages/visit_request_details_page.dart';
import '../controllers/family_appointments_controller.dart';
import '../widgets/family_appointment_card.dart';
import '../widgets/family_appointments_filter_pills.dart';
import '../widgets/family_appointments_header.dart';
import '../widgets/family_appointments_tab_bar.dart';
import '../widgets/family_primary_button.dart';
import 'create_appointment_page.dart';

/// The Family Appointments list screen - the "All / Upcoming / Completed"
/// tabs of the Family portal.
///
/// Reproduction of the Figma "All - Appointments", "Upcoming -
/// Appointments" and "Completed - Appointments" screenshots, built without
/// Figma MCP access (monthly quota exhausted) - see the feature's final
/// report for details on any approximated content and icon placeholders.
class FamilyAppointmentsListPage extends StatefulWidget {
  const FamilyAppointmentsListPage({super.key});

  @override
  State<FamilyAppointmentsListPage> createState() =>
      _FamilyAppointmentsListPageState();
}

class _FamilyAppointmentsListPageState
    extends State<FamilyAppointmentsListPage> {
  late final FamilyAppointmentsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _resolveController();
  }

  FamilyAppointmentsController _resolveController() {
    try {
      return Get.find<FamilyAppointmentsController>();
    } catch (_) {
      return Get.put(
        GetIt.instance<FamilyAppointmentsController>(),
        permanent: true,
      );
    }
  }

  void _openCreateAppointment() {
    Get.to(() => const CreateAppointmentPage());
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _controller.dateRange.value,
    );
    _controller.setDateRange(selected);
  }

  Future<void> _pickType(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All types'),
              onTap: () => Navigator.pop(context, ''),
            ),
            ListTile(
              title: const Text('Visits'),
              onTap: () => Navigator.pop(context, 'visit'),
            ),
            ListTile(
              title: const Text('Medical'),
              onTap: () => Navigator.pop(context, 'medical'),
            ),
            ListTile(
              title: const Text('Therapy'),
              onTap: () => Navigator.pop(context, 'therapy'),
            ),
            ListTile(
              title: const Text('Activity'),
              onTap: () => Navigator.pop(context, 'activity'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    _controller.setTypeFilter(selected.isEmpty ? null : selected);
  }

  Future<void> _onAppointmentTap(
    BuildContext context,
    FamilyAppointment appointment,
  ) async {
    if (appointment.iconKind == FamilyAppointmentIconKind.familyVisit) {
      Get.to(() => VisitRequestDetailsPage(requestId: appointment.id));
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
              title: const Text('Cancel'),
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
              message: _controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading appointments.'
                  : _controller.errorMessage.value,
              onRetry: _controller.refresh,
            );
          }

          final selectedTab = _controller.selectedTab.value;
          final sections = _controller.visibleSections;

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FamilyAppointmentsHeader(
                      title: 'Appointments',
                      onBack: Get.back,
                    ),
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 20,
                      ),
                      child: FamilyAppointmentsTabBar(
                        selected: selectedTab,
                        onSelected: _controller.selectTab,
                      ),
                    ),
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 20,
                        top: 14,
                        bottom: 14,
                      ),
                      child: FamilyAppointmentsFilterPills(
                        dateLabel: _controller.dateRangeLabel,
                        typeLabel: _controller.typeFilterLabel,
                        onDateTap: () => _pickDateRange(context),
                        onTypeTap: () => _pickType(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.refresh,
                  child: sections.isEmpty
                      ? ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getResponsiveWidth(
                              context,
                              20,
                            ),
                            vertical: ResponsiveHelper.getResponsiveHeight(
                              context,
                              40,
                            ),
                          ),
                          children: const [_NoResults()],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveHelper.getResponsiveWidth(context, 20),
                            ResponsiveHelper.getResponsiveHeight(context, 16),
                            ResponsiveHelper.getResponsiveWidth(context, 20),
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                          ),
                          itemCount: sections.length,
                          itemBuilder: (context, sectionIndex) {
                            final section = sections[sectionIndex];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sectionIndex != 0)
                                  SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveHeight(
                                          context,
                                          24,
                                        ),
                                  ),
                                Text(
                                  section.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w700,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      18,
                                    ),
                                    color: const Color(0xFF11212E),
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(
                                  height: ResponsiveHelper.getResponsiveHeight(
                                    context,
                                    12,
                                  ),
                                ),
                                for (
                                  var i = 0;
                                  i < section.appointments.length;
                                  i++
                                ) ...[
                                  if (i != 0)
                                    SizedBox(
                                      height:
                                          ResponsiveHelper.getResponsiveHeight(
                                            context,
                                            12,
                                          ),
                                    ),
                                  FamilyAppointmentCard(
                                    appointment: section.appointments[i],
                                    onTap: () => _onAppointmentTap(
                                      context,
                                      section.appointments[i],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
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
                    label: 'Create Appointment',
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

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No appointments to show.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
          color: AppColors.textSecondary,
        ),
      ),
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
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
