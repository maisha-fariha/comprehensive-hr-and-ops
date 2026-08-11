import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
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
                      child: const FamilyAppointmentsFilterPills(),
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
                                    fontFamily: 'Outfit',
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
          fontFamily: 'Outfit',
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
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
