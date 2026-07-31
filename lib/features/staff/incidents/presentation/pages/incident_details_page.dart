import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../controllers/incident_details_controller.dart';
import '../widgets/incident_details/high_severity_alert_banner.dart';
import '../widgets/incident_details/incident_info_section.dart';
import '../widgets/incident_details/incident_people_section.dart';
import '../widgets/incident_details/incident_summary_card.dart';
import '../widgets/staff_incidents_header.dart';

/// Read-only Incident Details screen, reached by tapping "View Details" on
/// an "All Incidents" card.
///
/// Reproduction of the Figma "Incident Details - Incidents" screenshot,
/// built without Figma MCP access (monthly quota exhausted) - see the
/// feature's final report for details on any approximated content and
/// icon placeholders.
class IncidentDetailsPage extends StatefulWidget {
  final String incidentId;

  const IncidentDetailsPage({super.key, required this.incidentId});

  @override
  State<IncidentDetailsPage> createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  late final IncidentDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _resolveController();
    _controller.loadDetail(widget.incidentId);
  }

  IncidentDetailsController _resolveController() {
    try {
      return Get.find<IncidentDetailsController>();
    } catch (_) {
      return Get.put(GetIt.instance<IncidentDetailsController>(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            StaffIncidentsHeader(
              title: 'Incident Details',
              subtitle: 'View full incident report and details',
              onBack: Get.back,
              trailing: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.ios_share_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 20),
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final response = _controller.state.value;
                final detail = response.data;

                if (detail == null && _controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
                }

                if (detail == null) {
                  return Center(
                    child: Padding(
                      padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
                      child: Text(
                        _controller.errorMessage.value.isEmpty
                            ? 'Something went wrong while loading this incident.'
                            : _controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, 20),
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    ResponsiveHelper.getResponsiveWidth(context, 20),
                    ResponsiveHelper.getResponsiveHeight(context, 30),
                  ),
                  children: [
                    IncidentSummaryCard(detail: detail),
                    if (detail.requiresUrgentReview) ...[
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                      const HighSeverityAlertBanner(),
                    ],
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    IncidentInfoSection(detail: detail),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    IncidentPeopleSection(detail: detail),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
