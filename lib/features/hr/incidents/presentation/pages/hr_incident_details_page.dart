import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../staff/incidents/presentation/controllers/incident_details_controller.dart';
import '../../../../staff/incidents/presentation/widgets/incident_details/incident_activity_log_section.dart';
import '../../../../staff/incidents/presentation/widgets/incident_details/incident_cir_report_section.dart';
import '../../../../staff/incidents/presentation/widgets/incident_details/incident_description_section.dart';
import '../../../../staff/incidents/presentation/widgets/incident_details/incident_details_actions.dart';
import '../../../../staff/incidents/presentation/widgets/incident_details/incident_evidence_section.dart';
import '../../../../staff/incidents/presentation/widgets/incident_details/incident_investigation_findings_section.dart';
import '../../../../staff/incidents/presentation/widgets/incident_details/incident_meta_grid.dart';
import '../../../../staff/incidents/presentation/widgets/incident_details/incident_status_ack_section.dart';
import '../../../../staff/incidents/presentation/widgets/incident_details/incident_web_header_card.dart';
import '../../../../staff/incidents/presentation/widgets/staff_incidents_header.dart';
import '../../domain/repositories/incidents_repository.dart';
import '../widgets/incident_witness_statements_card.dart';
import 'incident_creation_page.dart';

/// Manager Incident Details — the web incidents "View" modal: details,
/// description, witness statements, report form / summary PDF, status,
/// investigation, evidence, activity, then Close / Acknowledge / Edit.
class HrIncidentDetailsPage extends StatefulWidget {
  final String incidentId;

  /// `incidents:write` — Edit and the witness take/sign actions.
  final bool canWrite;

  const HrIncidentDetailsPage({
    super.key,
    required this.incidentId,
    this.canWrite = true,
  });

  @override
  State<HrIncidentDetailsPage> createState() => _HrIncidentDetailsPageState();
}

class _HrIncidentDetailsPageState extends State<HrIncidentDetailsPage> {
  late final IncidentDetailsController _controller;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.instance<IncidentDetailsController>();
    _controller.loadDetail(widget.incidentId);
  }

  void _close() => Get.back(result: _changed);

  Future<void> _acknowledge() async {
    await _controller.acknowledge();
    _changed = true;
  }

  Future<void> _edit() async {
    final saved = await Get.to<bool>(
      () => IncidentCreationPage(editIncidentId: widget.incidentId),
    );
    if (saved == true) {
      _changed = true;
      await _controller.loadDetail(widget.incidentId, force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              StaffIncidentsHeader(
                title: 'Incident Details',
                subtitle: 'View full incident report and details',
                onBack: _close,
              ),
              Expanded(child: Obx(_body)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final detail = _controller.state.value.data;

    if (detail == null && _controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryTeal),
      );
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

    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14));
    final cirSections = detail.cirReport?.formSections ?? const [];
    final hasReportForm = detail.cirReport != null;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsiveWidth(context, 20),
        ResponsiveHelper.getResponsiveHeight(context, 16),
        ResponsiveHelper.getResponsiveWidth(context, 20),
        ResponsiveHelper.getResponsiveHeight(context, 30),
      ),
      children: [
        IncidentWebHeaderCard(detail: detail),
        gap,
        IncidentMetaGrid(detail: detail),
        gap,
        IncidentDescriptionSection(description: detail.description),
        gap,
        IncidentWitnessStatementsCard(
          incidentId: widget.incidentId,
          repository: GetIt.instance<IncidentsRepository>(),
          canWrite: widget.canWrite,
        ),
        gap,
        if (hasReportForm && cirSections.isNotEmpty)
          IncidentCirReportSection(
            sections: cirSections,
            pdfBusy: _controller.isOpeningCirPdf.value,
            onPrint: _controller.printCirPdf,
            onDownload: _controller.shareCirPdf,
          )
        else
          _IncidentSummaryCard(
            busy: _controller.isOpeningCirPdf.value,
            onDownload: _controller.shareCirPdf,
          ),
        gap,
        IncidentStatusAckSection(
          statusLabel: detail.statusLabel,
          acknowledged: detail.acknowledged,
          acknowledgedAtLabel: detail.acknowledgedAtLabel,
        ),
        if (detail.hasInvestigationContent) ...[
          gap,
          IncidentInvestigationFindingsSection(detail: detail),
        ],
        gap,
        IncidentEvidenceSection(
          items: detail.evidence,
          isBusy: _controller.isOpeningEvidence.value,
          onDownload: _controller.openEvidence,
        ),
        gap,
        IncidentActivityLogSection(entries: detail.activity),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        IncidentDetailsActions(
          onClose: _close,
          onEdit: _edit,
          onAcknowledge: _acknowledge,
          showAcknowledge: !detail.acknowledged,
          showEdit: widget.canWrite,
        ),
      ],
    );
  }
}

/// Web "Incident summary" card, shown when no statutory form was filed.
class _IncidentSummaryCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onDownload;

  const _IncidentSummaryCard({required this.busy, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incident summary',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Not filed on a statutory form — this is the home's own summary.",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('incident-summary-pdf'),
            onPressed: busy ? null : onDownload,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondaryTeal,
              textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download summary PDF'),
          ),
        ],
      ),
    );
  }
}
