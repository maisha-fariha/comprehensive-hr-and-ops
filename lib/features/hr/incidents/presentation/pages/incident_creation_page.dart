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
import '../widgets/wizard_bottom_bar.dart';
import '../widgets/wizard_header.dart';

/// The 4-step "Create Incident" wizard, reached from the "+ Create
/// Incident" button on the Incidents list screen.
///
/// Pixel-accurate reproduction of the Figma "Details - Incidents",
/// "People - Incidents", "Investigate - Incidents" and
/// "Evidence - Incidents" screens (nodes 517:15782, 517:15946, 517:16075,
/// 517:16198) - built from screenshots after Figma MCP access was
/// exhausted (see the feature's final report for details). These 4 nodes
/// turned out to be the steps of a single "New Incident" creation form
/// (shared header + progress stepper + step body + bottom action bar), not
/// separate tabs on an incident-viewing page.
class IncidentCreationPage extends StatelessWidget {
  const IncidentCreationPage({super.key});

  static const String _mockDraftId = '#INC-8293';

  /// Always starts a fresh controller instance for a new draft rather than
  /// resolving the `get_it`-registered one, which is cached as a lazy
  /// singleton (correct for app-lifetime controllers like
  /// `DashboardController`, but wrong here - reusing the same instance
  /// across multiple "Create Incident" sessions would resurface a
  /// previous draft's field values, and its `TextEditingController`s would
  /// already be disposed after the first time this page is closed).
  IncidentCreationController _resolveController() {
    if (Get.isRegistered<IncidentCreationController>()) {
      Get.delete<IncidentCreationController>(force: true);
    }
    return Get.put(IncidentCreationController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              Container(
                color: AppColors.surfaceWhite,
                child: WizardHeader(
                  currentStep: controller.currentStep.value,
                  draftId: _mockDraftId,
                  onBack: () {
                    if (controller.currentStepIndex > 0) {
                      controller.previousStep();
                    } else {
                      Get.back();
                    }
                  },
                  onClose: Get.back,
                  onStepTap: controller.goToStep,
                ),
              ),
              Expanded(
                child: Container(
                  color: AppColors.scaffoldBackground,
                  child: SingleChildScrollView(
                    padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, vertical: 18),
                    child: _StepBody(controller: controller),
                  ),
                ),
              ),
              WizardBottomBar(
                isLastStep: controller.isLastStep,
                onSaveDraft: Get.back,
                onPrimary: () {
                  if (controller.isLastStep) {
                    Get.back();
                  } else {
                    controller.nextStep();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final IncidentCreationController controller;

  const _StepBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    switch (controller.currentStep.value) {
      case IncidentCreationStep.details:
        return Step1DetailsForm(controller: controller);
      case IncidentCreationStep.people:
        return Step2PeopleForm(controller: controller);
      case IncidentCreationStep.investigate:
        return Step3InvestigateForm(controller: controller);
      case IncidentCreationStep.evidence:
        return Step4EvidenceForm(controller: controller);
    }
  }
}
