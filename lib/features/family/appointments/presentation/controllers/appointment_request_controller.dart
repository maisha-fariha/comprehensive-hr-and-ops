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
  final RxString appointmentKind = 'medical'.obs;
  final Rx<DateTime> preferredAt = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 1,
    14,
  ).obs;
  final TextEditingController locationController = TextEditingController(
    text: 'In-Person at Residence',
  );
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

  String get thirdFieldValue {
    if (isVisit) return 'Family Visit';
    switch (appointmentKind.value) {
      case 'therapy':
        return 'Therapy';
      case 'activity':
        return 'Activity';
      default:
        return 'Medical';
    }
  }

  String get notePlaceholder => isVisit ? '' : 'Add any relevant details for the care team...';

  String get bannerMessage => isVisit
      ? 'Your request will be reviewed by the care team. You will be notified once a decision has been made.'
      : 'Your appointment request will be reviewed by the care team. You will be notified once a decision has been made.';

  void selectRequestType(AppointmentRequestType type) {
    if (requestType.value == type) return;
    requestType.value = type;
    locationController.text =
        type == AppointmentRequestType.visit
            ? 'In-Person at Residence'
            : 'In-Person at Clinic';
    noteController.text = type == AppointmentRequestType.visit
        ? FamilyAppointmentsConstants.visitPresetNote
        : '';
  }

  Future<void> pickAppointmentKind(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Medical'),
              onTap: () => Navigator.pop(context, 'medical'),
            ),
            ListTile(
              title: const Text('Therapy'),
              onTap: () => Navigator.pop(context, 'therapy'),
            ),
            ListTile(
              title: const Text('Activity'),
              onTap: () => Navigator.pop(context, 'activity'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) appointmentKind.value = selected;
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
      type: isVisit ? 'visit' : appointmentKind.value,
      scheduledAt: preferredAt.value,
      location: locationController.text.trim(),
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
    locationController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
