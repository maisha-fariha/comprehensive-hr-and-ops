import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/repositories/incidents_repository.dart';

/// GetX controller for the 4-step "Create Incident" wizard.
class IncidentCreationController extends GetxController {
  static const List<IncidentCreationStep> steps = IncidentCreationStep.values;

  final IncidentsRepository repository;
  final UserSession session;

  IncidentCreationController({
    IncidentsRepository? repository,
    UserSession? session,
  })  : repository = repository ?? GetIt.instance<IncidentsRepository>(),
        session = session ?? Get.find<UserSession>();

  final Rx<IncidentCreationStep> currentStep = IncidentCreationStep.details.obs;
  final RxBool isSubmitting = false.obs;
  final RxString draftId = ''.obs;
  final RxString submitError = ''.obs;

  int get currentStepIndex => steps.indexOf(currentStep.value);
  bool get isLastStep => currentStep.value == IncidentCreationStep.evidence;

  // Step 1 - Incident Details
  final Rx<String?> incidentCategory = Rx<String?>(null);
  final TextEditingController incidentTitleController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final Rx<String?> residence = Rx<String?>(null);
  final TextEditingController incidentDateController = TextEditingController();
  final TextEditingController incidentTimeController = TextEditingController();
  final Rx<IncidentSeverity> severity = IncidentSeverity.high.obs;
  final Rx<String?> detectedDuring = Rx<String?>(null);

  // Step 2 - People & Location
  final TextEditingController involvedClientController = TextEditingController();
  final TextEditingController staffInvolvedController = TextEditingController();
  final Rx<String?> reportedBy = Rx<String?>(null);
  final TextEditingController locationController = TextEditingController();
  final RxList<String> witnesses = <String>[].obs;

  // Step 3 - Immediate Action & Investigation
  final TextEditingController immediateActionController = TextEditingController();
  final TextEditingController investigationNotesController = TextEditingController();
  final RxBool followUpRequired = false.obs;
  final TextEditingController followUpDateController = TextEditingController();
  final Rx<String?> supervisorAssignment = Rx<String?>(null);

  // Step 4 - Evidence & Submission
  final RxList<String> uploadedFileNames = <String>[].obs;
  final TextEditingController additionalNotesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    residence.value = session.residenceName;
    reportedBy.value = session.displayName;
    draftId.value = 'Draft';
  }

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

  Future<bool> submit({bool asDraft = false}) async {
    final title = incidentTitleController.text.trim();
    if (title.isEmpty) {
      submitError.value = 'Please enter an incident title.';
      Get.snackbar('Missing details', submitError.value,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    isSubmitting.value = true;
    submitError.value = '';

    final payload = <String, dynamic>{
      'title': title,
      'category': incidentCategory.value,
      'clientName': clientController.text.trim().isEmpty
          ? involvedClientController.text.trim()
          : clientController.text.trim(),
      'residenceId': session.residenceId,
      'residenceName': residence.value ?? session.residenceName,
      'incidentDate': incidentDateController.text.trim(),
      'incidentTime': incidentTimeController.text.trim(),
      'severity': severity.value.name,
      'detectedDuring': detectedDuring.value,
      'involvedClient': involvedClientController.text.trim(),
      'staffInvolved': staffInvolvedController.text.trim(),
      'reportedBy': reportedBy.value,
      'location': locationController.text.trim(),
      'witnesses': witnesses.toList(),
      'immediateAction': immediateActionController.text.trim(),
      'investigationNotes': investigationNotesController.text.trim(),
      'followUpRequired': followUpRequired.value,
      'followUpDate': followUpDateController.text.trim(),
      'supervisorAssignment': supervisorAssignment.value,
      'additionalNotes': additionalNotesController.text.trim(),
      'evidenceFileNames': uploadedFileNames.toList(),
      'status': asDraft ? 'draft' : 'open',
      'isDraft': asDraft,
    };

    final result = await repository.createIncident(payload);
    isSubmitting.value = false;

    return result.when(
      success: (id) {
        if (id.isNotEmpty) draftId.value = id.startsWith('#') ? id : '#$id';
        Get.snackbar(
          asDraft ? 'Draft saved' : 'Incident submitted',
          asDraft
              ? 'Your draft was saved on the care home.'
              : 'The incident was created successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      },
      failure: (error) {
        submitError.value = error.message;
        Get.snackbar(
          asDraft ? 'Could not save draft' : 'Could not submit',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      },
    );
  }

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
