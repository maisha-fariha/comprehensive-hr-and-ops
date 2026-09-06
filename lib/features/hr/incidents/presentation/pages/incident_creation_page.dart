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
class IncidentCreationPage extends StatelessWidget {
  const IncidentCreationPage({super.key});

  /// Always starts a fresh controller instance for a new draft rather than
  /// resolving the `get_it`-registered one.
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
                  draftId: controller.draftId.value,
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
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: _StepBody(controller: controller),
                  ),
                ),
              ),
              WizardBottomBar(
                isLastStep: controller.isLastStep,
                onSaveDraft: controller.isSubmitting.value
                    ? null
                    : () async {
                        final ok = await controller.submit(asDraft: true);
                        if (ok) Get.back(result: true);
                      },
                onPrimary: controller.isSubmitting.value
                    ? null
                    : () async {
                        if (!controller.isLastStep) {
                          controller.nextStep();
                          return;
                        }
                        final ok = await controller.submit();
                        if (ok) Get.back(result: true);
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
    return switch (controller.currentStep.value) {
      IncidentCreationStep.details => Step1DetailsForm(controller: controller),
      IncidentCreationStep.people => Step2PeopleForm(controller: controller),
      IncidentCreationStep.investigate =>
        Step3InvestigateForm(controller: controller),
      IncidentCreationStep.evidence => Step4EvidenceForm(controller: controller),
    };
  }
}
