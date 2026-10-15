import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/incidents_enums.dart';
import '../controllers/incident_creation_controller.dart';
import '../widgets/steps/step1_details_form.dart';
import '../widgets/steps/step2_people_form.dart';
import '../widgets/steps/step3_investigate_form.dart';
import '../widgets/steps/step4_evidence_form.dart';
import '../widgets/steps/step5_report_form.dart';
import '../widgets/wizard_bottom_bar.dart';

/// The 5-step "Create Incident" wizard, reached from the "+ Create
/// Incident" button on the Incidents list screen, or in edit mode from
/// View Investigation → Edit.
///
/// Web parity: Details → Location & People → Investigation →
/// Evidence & Submission → Report Form.
class IncidentCreationPage extends StatefulWidget {
  final String? editIncidentId;

  const IncidentCreationPage({super.key, this.editIncidentId});

  @override
  State<IncidentCreationPage> createState() => _IncidentCreationPageState();
}

class _IncidentCreationPageState extends State<IncidentCreationPage> {
  late final IncidentCreationController _controller;
  final ScrollController _scroll = ScrollController();
  Worker? _stepWatcher;

  @override
  void initState() {
    super.initState();
    // One controller for this page visit — never recreate inside build().
    if (Get.isRegistered<IncidentCreationController>()) {
      Get.delete<IncidentCreationController>(force: true);
    }
    _controller = Get.put(
      IncidentCreationController(editIncidentId: widget.editIncidentId),
    );
    _stepWatcher = ever(_controller.currentStep, (_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _stepWatcher?.dispose();
    _scroll.dispose();
    if (Get.isRegistered<IncidentCreationController>()) {
      Get.delete<IncidentCreationController>(force: true);
    }
    super.dispose();
  }

  Future<void> _saveDraft() async {
    final ok = await _controller.submit(asDraft: true);
    if (ok && mounted) Get.back(result: true);
  }

  Future<void> _primary() async {
    final showSubmit =
        _controller.currentStepIndex >= IncidentCreationStep.evidence.index;
    if (!showSubmit) {
      _controller.nextStep();
      return;
    }
    final ok = await _controller.submit();
    if (ok && mounted) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(
          () {
            if (_controller.isLoadingEdit.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.secondaryTeal),
              );
            }
            final index = _controller.currentStepIndex;
            final showSubmit = index >= IncidentCreationStep.evidence.index;
            final next = index < IncidentCreationController.steps.length - 1
                ? IncidentCreationController.steps[index + 1]
                : null;
            final primaryLabel = showSubmit
                ? 'Submit Incident'
                : 'Next: ${IncidentCreationController.stepTitles[next]}';
            final severity = _controller.severity.value;
            return Column(
              children: [
                _WizardTop(
                  title: _controller.isEditMode ? 'Edit Incident' : 'Add New Incident',
                  badge: _controller.draftId.value == 'Draft' || _controller.draftId.value.isEmpty
                      ? 'NEW'
                      : _controller.draftId.value,
                  onClose: Get.back,
                ),
                if (severity == IncidentSeverity.critical || severity == IncidentSeverity.high)
                  _SeverityBanner(severity: severity),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 14,
                    ),
                    children: [
                      _StepNavigator(controller: _controller),
                      const SizedBox(height: 12),
                      _ReportProgress(controller: _controller),
                      const SizedBox(height: 14),
                      _StepBody(controller: _controller),
                      const SizedBox(height: 16),
                      _IncidentPreview(controller: _controller),
                      const SizedBox(height: 12),
                      _ReportChecklist(controller: _controller),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                WizardBottomBar(
                  progressLabel:
                      '${_controller.completedStepCount} of ${IncidentCreationController.steps.length} steps complete',
                  primaryLabel: primaryLabel,
                  primaryIsSubmit: showSubmit,
                  onCancel: Get.back,
                  onSaveDraft: _controller.isSubmitting.value ? null : _saveDraft,
                  onPrimary: _controller.isSubmitting.value ? null : _primary,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WizardTop extends StatelessWidget {
  final String title;
  final String badge;
  final VoidCallback onClose;

  const _WizardTop({
    required this.title,
    required this.badge,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, top: 10, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.criticalRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                          color: AppColors.textHeading,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Create an incident report for safety, compliance and supervisor review.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _SeverityBanner extends StatelessWidget {
  final IncidentSeverity severity;

  const _SeverityBanner({required this.severity});

  @override
  Widget build(BuildContext context) {
    final critical = severity == IncidentSeverity.critical;
    final color = critical ? AppColors.criticalRed : AppColors.urgentAmber;
    final background = critical ? AppColors.criticalBackgroundSoft : const Color(0xFFFFF6E8);
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  critical
                      ? 'Critical incident — immediate supervisor review required'
                      : 'High priority incident — supervisor review required',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                Text(
                  critical
                      ? 'Must be reviewed and signed off by a supervisor immediately upon submission.'
                      : 'Must be reviewed and signed off by a supervisor within 24 hours of submission.',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepNavigator extends StatelessWidget {
  final IncidentCreationController controller;

  const _StepNavigator({required this.controller});

  static const _icons = {
    IncidentCreationStep.details: Icons.assignment_outlined,
    IncidentCreationStep.people: Icons.place_outlined,
    IncidentCreationStep.investigate: Icons.shield_outlined,
    IncidentCreationStep.evidence: Icons.upload_file_outlined,
    IncidentCreationStep.reportForm: Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final current = controller.currentStep.value;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          for (final step in IncidentCreationController.steps)
            InkWell(
              onTap: () => controller.goToStep(step),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: step == current ? const Color(0xFFF4F7FB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _icons[step],
                      size: 18,
                      color: step == current ? AppColors.primaryNavy : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            IncidentCreationController.stepTitles[step]!,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: step == current ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 13.5,
                              color: AppColors.textHeading,
                            ),
                          ),
                          Text(
                            IncidentCreationController.stepDescriptions[step]!,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.stepChecked(step))
                      const Icon(Icons.check_circle, size: 16, color: AppColors.secondaryTeal),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportProgress extends StatelessWidget {
  final IncidentCreationController controller;

  const _ReportProgress({required this.controller});

  @override
  Widget build(BuildContext context) {
    final index = controller.currentStepIndex;
    final total = IncidentCreationController.steps.length;
    final fraction = (index + 1) / total;
    final step = controller.currentStep.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REPORT PROGRESS',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'STEP ${index + 1} OF $total',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: const Color(0xFFE6ECF2),
              color: AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(fraction * 100).round()}% complete',
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            IncidentCreationController.stepTips[step]!,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _IncidentPreview extends StatelessWidget {
  final IncidentCreationController controller;

  const _IncidentPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final title = controller.incidentTitleController.text.trim();
    final client = controller.selectedClient.value?.name;
    final residence = controller.residence.value;
    final where = client != null && client.isNotEmpty
        ? '$client · ${residence ?? 'Residence not set'}'
        : (residence ?? 'Location not set yet');
    final category = controller.incidentCategory;
    final status = controller.investigationStatus.value ?? 'open';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text(
              'Incident Preview',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textHeading,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(
              'Live summary',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF1C2E4A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'New Incident' : title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  where,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white70),
                ),
                if (category != null && category.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.4,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _PreviewRow(label: 'Severity', value: controller.severityLabel),
          _PreviewRow(label: 'Reported By', value: controller.reportedBy.value ?? 'Not set'),
          _PreviewRow(label: 'Status', value: status),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.5, color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportChecklist extends StatelessWidget {
  final IncidentCreationController controller;

  const _ReportChecklist({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Checklist',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textHeading,
            ),
          ),
          for (final step in IncidentCreationController.steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    controller.stepChecked(step) ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: controller.stepChecked(step)
                        ? AppColors.secondaryTeal
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    IncidentCreationController.stepTitles[step]!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5,
                      color: controller.stepChecked(step)
                          ? AppColors.textHeading
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final IncidentCreationController controller;

  const _StepBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return switch (controller.currentStep.value) {
      IncidentCreationStep.details => Step1DetailsForm(controller: controller),
      IncidentCreationStep.people => Step2PeopleForm(controller: controller),
      IncidentCreationStep.investigate =>
        Step3InvestigateForm(controller: controller),
      IncidentCreationStep.evidence => Step4EvidenceForm(controller: controller),
      IncidentCreationStep.reportForm => Step5ReportForm(controller: controller),
    };
  }
}
