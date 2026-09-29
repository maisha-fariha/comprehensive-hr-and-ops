import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../controllers/incident_details_controller.dart';
import '../widgets/incident_details/incident_activity_log_section.dart';
import '../widgets/incident_details/incident_cir_report_section.dart';
import '../widgets/incident_details/incident_description_section.dart';
import '../widgets/incident_details/incident_details_actions.dart';
import '../widgets/incident_details/incident_evidence_section.dart';
import '../widgets/incident_details/incident_investigation_findings_section.dart';
import '../widgets/incident_details/incident_meta_grid.dart';
import '../widgets/incident_details/incident_status_ack_section.dart';
import '../widgets/incident_details/incident_web_header_card.dart';
import '../widgets/incident_details/incident_witness_statements_section.dart';
import '../widgets/staff_incidents_header.dart';

/// Read-only Incident Details screen — web modal content order on mobile scroll.
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
      return Get.put(
        GetIt.instance<IncidentDetailsController>(),
        permanent: true,
      );
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  void _onEdit() {
    AppSnackbar.show('Edit', 'Editing opens on web for now');
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
                onTap: _controller.shareCirPdf,
                child: Obx(
                  () => _controller.isOpeningCirPdf.value
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textHeading,
                          ),
                        )
                      : AppSvgIcon(
                          'assets/icons/staff_incidents/share.svg',
                          size: 18,
                          color: AppColors.textHeading,
                        ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final response = _controller.state.value;
                final detail = response.data;

                if (detail == null && _controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  );
                }

                if (detail == null) {
                  return Center(
                    child: Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        all: 24,
                      ),
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

                final gap =
                    ResponsiveHelper.getResponsiveHeight(context, 14);
                final cirSections = detail.cirReport?.formSections ?? const [];
                final showCir =
                    detail.cirReport != null && cirSections.isNotEmpty;

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, 20),
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    ResponsiveHelper.getResponsiveWidth(context, 20),
                    ResponsiveHelper.getResponsiveHeight(context, 30),
                  ),
                  children: [
                    IncidentWebHeaderCard(detail: detail),
                    SizedBox(height: gap),
                    IncidentMetaGrid(detail: detail),
                    SizedBox(height: gap),
                    IncidentDescriptionSection(
                      description: detail.description,
                    ),
                    SizedBox(height: gap),
                    IncidentWitnessStatementsSection(
                      witnessNames: detail.witnessNames,
                    ),
                    if (showCir) ...[
                      SizedBox(height: gap),
                      Obx(
                        () => IncidentCirReportSection(
                          sections: cirSections,
                          pdfBusy: _controller.isOpeningCirPdf.value,
                          onPrint: _controller.printCirPdf,
                          onDownload: _controller.shareCirPdf,
                        ),
                      ),
                    ],
                    SizedBox(height: gap),
                    IncidentStatusAckSection(
                      statusLabel: detail.statusLabel,
                      acknowledged: detail.acknowledged,
                      acknowledgedAtLabel: detail.acknowledgedAtLabel,
                    ),
                    if (detail.hasInvestigationContent) ...[
                      SizedBox(height: gap),
                      IncidentInvestigationFindingsSection(detail: detail),
                    ],
                    SizedBox(height: gap),
                    IncidentEvidenceSection(
                      items: detail.evidence,
                      isBusy: _controller.isOpeningEvidence.value,
                      onDownload: _controller.openEvidence,
                    ),
                    SizedBox(height: gap),
                    IncidentActivityLogSection(entries: detail.activity),
                    SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveHeight(context, 20),
                    ),
                    IncidentDetailsActions(
                      onClose: Get.back,
                      onEdit: _onEdit,
                      onAcknowledge: _controller.acknowledge,
                      showAcknowledge: !detail.acknowledged,
                    ),
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
