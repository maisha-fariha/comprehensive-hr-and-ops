import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/incidents_enums.dart';

/// GetX controller for the 4-step "Create Incident" wizard.
///
/// This is a mock, front-end-only form: it owns simple mutable/observable
/// field state plus Next/Back step navigation, with no real validation or
/// persistence - matching the current scope of the Incidents feature (no
/// backend contract exists yet).
class IncidentCreationController extends GetxController {
  static const List<IncidentCreationStep> steps = IncidentCreationStep.values;

  final Rx<IncidentCreationStep> currentStep = IncidentCreationStep.details.obs;

  int get currentStepIndex => steps.indexOf(currentStep.value);
  bool get isLastStep => currentStep.value == IncidentCreationStep.evidence;

  // Step 1 - Incident Details
  final Rx<String?> incidentCategory = Rx<String?>(null);
  final TextEditingController incidentTitleController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final Rx<String?> residence = Rx<String?>('Sunrise Home');
  final TextEditingController incidentDateController = TextEditingController();
  final TextEditingController incidentTimeController = TextEditingController();
  final Rx<IncidentSeverity> severity = IncidentSeverity.high.obs;
  final Rx<String?> detectedDuring = Rx<String?>('Medication Round');

  // Step 2 - People & Location
  final TextEditingController involvedClientController = TextEditingController(text: 'Arthur Morgan');
  final TextEditingController staffInvolvedController = TextEditingController();
  final Rx<String?> reportedBy = Rx<String?>('Sarah Williams');
  final TextEditingController locationController = TextEditingController();
  final RxList<String> witnesses = <String>['Marcus Chen'].obs;

  // Step 3 - Immediate Action & Investigation
  final TextEditingController immediateActionController = TextEditingController();
  final TextEditingController investigationNotesController = TextEditingController();
  final RxBool followUpRequired = true.obs;
  final TextEditingController followUpDateController = TextEditingController();
  final Rx<String?> supervisorAssignment = Rx<String?>(null);

  // Step 4 - Evidence & Submission
  final RxList<String> uploadedFileNames = <String>['incident-scene-01.jpg'].obs;
  final TextEditingController additionalNotesController = TextEditingController();

  void goToStep(IncidentCreationStep step) => currentStep.value = step;

  void nextStep() {
    final index = currentStepIndex;
    if (index < steps.length - 1) {
      currentStep.value = steps[index + 1];
    }
  }

  void previousStep() {
    final index = currentStepIndex;
    if (index > 0) {
      currentStep.value = steps[index - 1];
    }
  }

  void addWitness(String name) {
    if (name.trim().isEmpty || witnesses.contains(name)) return;
    witnesses.add(name.trim());
  }

  void removeWitness(String name) => witnesses.remove(name);

  void removeUploadedFile(String name) => uploadedFileNames.remove(name);

  @override
  void onClose() {
    incidentTitleController.dispose();
    clientController.dispose();
    incidentDateController.dispose();
    incidentTimeController.dispose();
    involvedClientController.dispose();
    staffInvolvedController.dispose();
    locationController.dispose();
    immediateActionController.dispose();
    investigationNotesController.dispose();
    followUpDateController.dispose();
    additionalNotesController.dispose();
    super.onClose();
  }
}
