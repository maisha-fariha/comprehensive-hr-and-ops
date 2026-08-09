import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../controllers/incident_details_controller.dart';
import '../widgets/incident_details/incident_activity_log_section.dart';
import '../widgets/incident_details/incident_description_section.dart';
import '../widgets/incident_details/incident_details_actions.dart';
import '../widgets/incident_details/incident_evidence_section.dart';
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
///
/// Hosts [StaffBottomNavBar] with "More" selected so the pushed route still
/// matches reference frames that show the staff bottom nav.
class IncidentDetailsPage extends StatefulWidget {
  final String incidentId;

  /// Index of the "More" slot in [StaffBottomNavBar.items].
  static const int _moreTabIndex = 4;

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

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: IncidentDetailsPage._moreTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StaffIncidentsHeader(
              title: 'Incident Details',
              subtitle: 'View full incident report and details',
              onBack: Get.back,
              trailing: StaffIncidentsHeader.iconButton(
                context: context,
                onTap: () {},
                child: AppSvgIcon(
                  'assets/icons/staff_incidents/share.svg',
                  size: 18,
                  color: AppColors.textHeading,
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
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    IncidentInfoSection(detail: detail),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    IncidentPeopleSection(detail: detail),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const IncidentDescriptionSection(),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const IncidentEvidenceSection(),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const IncidentActivityLogSection(),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                    const IncidentDetailsActions(),
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
