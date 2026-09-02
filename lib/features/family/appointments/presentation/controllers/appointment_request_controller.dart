import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/network/iso_date_range.dart';
import '../../domain/entities/family_appointments_enums.dart';
import '../../domain/repositories/family_appointments_repository.dart';
import '../../family_appointments_constants.dart';
import 'family_appointments_controller.dart';

class AppointmentRequestController extends GetxController {
  final FamilyAppointmentsRepository repository;

  AppointmentRequestController({FamilyAppointmentsRepository? repository})
      : repository = repository ?? GetIt.instance<FamilyAppointmentsRepository>();

  final Rx<AppointmentRequestType> requestType = AppointmentRequestType.visit.obs;
  final Rx<DateTime> preferredAt = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 1,
    14,
  ).obs;
  final TextEditingController noteController = TextEditingController(
    text: FamilyAppointmentsConstants.visitPresetNote,
  );
  final RxInt noteLength = FamilyAppointmentsConstants.visitPresetNote.length.obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    noteController.addListener(() => noteLength.value = noteController.text.length);
  }

  String get pageTitle =>
      requestType.value == AppointmentRequestType.visit ? 'Request Visit' : 'Request Appointment';

  bool get isVisit => requestType.value == AppointmentRequestType.visit;

  String get preferredDate => IsoDateRange.formatMonthDay(preferredAt.value);
  String get preferredTime => IsoDateRange.timeLabel(preferredAt.value);

  String get thirdFieldLabel => isVisit ? 'Purpose' : 'Appointment Type';
  String get thirdFieldValue => isVisit ? 'Family Visit' : 'Physician Visit';

  String get locationModeValue => isVisit ? 'In-Person at Residence' : 'In-Person at Clinic';

  String get notePlaceholder => isVisit ? '' : 'Add any relevant details for the care team...';

  String get bannerMessage => isVisit
      ? 'Your request will be reviewed by the care team. You will be notified once a decision has been made.'
      : 'Your appointment request will be reviewed by the care team. You will be notified once a decision has been made.';

  void selectRequestType(AppointmentRequestType type) {
    if (requestType.value == type) return;
    requestType.value = type;
    noteController.text = type == AppointmentRequestType.visit
        ? FamilyAppointmentsConstants.visitPresetNote
        : '';
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: preferredAt.value,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected == null) return;
    preferredAt.value = DateTime(
      selected.year,
      selected.month,
      selected.day,
      preferredAt.value.hour,
      preferredAt.value.minute,
    );
  }

  Future<void> pickTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(preferredAt.value),
    );
    if (selected == null) return;
    preferredAt.value = DateTime(
      preferredAt.value.year,
      preferredAt.value.month,
      preferredAt.value.day,
      selected.hour,
      selected.minute,
    );
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    final result = await repository.createAppointment(
      type: isVisit ? 'family_visit' : 'appointment',
      scheduledAt: preferredAt.value,
      location: locationModeValue,
      notes: noteController.text,
    );
    isSubmitting.value = false;
    result.when(
      success: (_) {
        Get.snackbar(
          'Request submitted',
          'The care team will review this and notify you.',
          snackPosition: SnackPosition.BOTTOM,
        );
        if (Get.isRegistered<FamilyAppointmentsController>()) {
          Get.find<FamilyAppointmentsController>().refresh();
        }
        Get.back();
      },
      failure: (error) => Get.snackbar(
        'Could not submit',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
