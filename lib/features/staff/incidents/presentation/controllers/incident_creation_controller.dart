import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/staff_incidents_enums.dart';

/// GetX controller for the single-page "Create Incident" form.
///
/// This is a mock, front-end-only form: it owns simple mutable/observable
/// field state with no real validation or persistence - matching the
/// current scope of the Staff Incidents feature (no backend contract
/// exists yet). Unlike the Manager Incidents feature's 4-step wizard, the
/// Staff version is a single scrollable page, so there is no step
/// navigation state here.
class IncidentCreationController extends GetxController {
  // Section 1 - Incident Details
  final Rx<String?> incidentCategory = Rx<String?>(null);
  final TextEditingController incidentTitleController = TextEditingController();
  final TextEditingController incidentDateController = TextEditingController(text: '05/12/2025');
  final TextEditingController incidentTimeController = TextEditingController(text: '09:15 AM');
  final Rx<String?> detectedDuring = Rx<String?>(null);

  // Section 2 - Severity
  final Rx<IncidentSeverity> severity = IncidentSeverity.medium.obs;

  // Section 3 - People & Location
  final Rx<String?> resident = Rx<String?>(null);
  final Rx<String?> location = Rx<String?>(null);

  // Section 4 - Description
  final TextEditingController descriptionController = TextEditingController();

  void selectSeverity(IncidentSeverity value) => severity.value = value;

  @override
  void onClose() {
    incidentTitleController.dispose();
    incidentDateController.dispose();
    incidentTimeController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
