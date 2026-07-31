import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/family_appointments_enums.dart';
import '../../family_appointments_constants.dart';

/// GetX controller for the single-page "Create Appointment" form (the
/// "Request Visit" / "Request Appointment" screen).
///
/// This is a mock, front-end-only form: every field below the "Request
/// Type" toggle is a static display-only value (no real dropdown menus or
/// persistence exist yet), matching the current scope of the Staff
/// Incidents feature's analogous "Create Incident" form. Only the note
/// textarea and the request-type toggle itself carry real, observable state.
class AppointmentRequestController extends GetxController {
  final Rx<AppointmentRequestType> requestType = AppointmentRequestType.visit.obs;

  final TextEditingController noteController = TextEditingController(
    text: FamilyAppointmentsConstants.visitPresetNote,
  );
  final RxInt noteLength = FamilyAppointmentsConstants.visitPresetNote.length.obs;

  AppointmentRequestController() {
    noteController.addListener(() => noteLength.value = noteController.text.length);
  }

  String get pageTitle =>
      requestType.value == AppointmentRequestType.visit ? 'Request Visit' : 'Request Appointment';

  bool get isVisit => requestType.value == AppointmentRequestType.visit;

  String get preferredDate => 'May 18, 2025';
  String get preferredTime => '2:00 PM';

  String get thirdFieldLabel => isVisit ? 'Purpose' : 'Appointment Type';
  String get thirdFieldValue => isVisit ? 'Family Visit' : 'Physician Visit';

  String get locationModeValue => isVisit ? 'In-Person at Residence' : 'In-Person at Clinic';

  String get notePlaceholder => isVisit ? '' : 'Add any relevant details for the care team...';

  String get bannerMessage => isVisit
      ? 'Your request will be reviewed by the care team. You will be notified once a decision has been made.'
      : 'Your appointment request will be reviewed by the care team. You will be notified once a decision has been made.';

  /// Switches the active "Request Type" segment, resetting the note field
  /// to match the state shown for that segment in the Figma screenshots -
  /// pre-filled for "Visit", empty for "Appointment".
  void selectRequestType(AppointmentRequestType type) {
    if (requestType.value == type) return;
    requestType.value = type;
    noteController.text = type == AppointmentRequestType.visit ? FamilyAppointmentsConstants.visitPresetNote : '';
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
