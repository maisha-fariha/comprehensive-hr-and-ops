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
class IncidentCreationPage extends StatefulWidget {
  const IncidentCreationPage({super.key});

  @override
  State<IncidentCreationPage> createState() => _IncidentCreationPageState();
}

class _IncidentCreationPageState extends State<IncidentCreationPage> {
  late final IncidentCreationController _controller;

  @override
  void initState() {
    super.initState();
    // One controller for this page visit — never recreate inside build().
    if (Get.isRegistered<IncidentCreationController>()) {
      Get.delete<IncidentCreationController>(force: true);
    }
    _controller = Get.put(IncidentCreationController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<IncidentCreationController>()) {
      Get.delete<IncidentCreationController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              Container(
                color: AppColors.surfaceWhite,
                child: WizardHeader(
                  currentStep: _controller.currentStep.value,
                  draftId: _controller.draftId.value,
                  onBack: () {
                    if (_controller.currentStepIndex > 0) {
                      _controller.previousStep();
                    } else {
                      Get.back();
                    }
                  },
                  onClose: Get.back,
                  onStepTap: _controller.goToStep,
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
                    child: _StepBody(controller: _controller),
                  ),
                ),
              ),
              WizardBottomBar(
                isLastStep: _controller.isLastStep,
                onSaveDraft: _controller.isSubmitting.value
                    ? null
                    : () async {
                        final ok = await _controller.submit(asDraft: true);
                        if (ok && mounted) Get.back(result: true);
                      },
                onPrimary: _controller.isSubmitting.value
                    ? null
                    : () async {
                        if (!_controller.isLastStep) {
                          _controller.nextStep();
                          return;
                        }
                        final ok = await _controller.submit();
                        if (ok && mounted) Get.back(result: true);
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
