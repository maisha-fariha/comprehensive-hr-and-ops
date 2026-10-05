import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/roles/user_session.dart';
import '../../../profile_settings/domain/entities/family_linked_client.dart';
import '../../../visit_requests/presentation/controllers/family_visit_requests_controller.dart';
import '../../domain/repositories/family_appointments_repository.dart';
import 'family_appointments_controller.dart';

/// A value/label option of the web "Request a Visit" selects.
@immutable
class VisitFormOption {
  final String value;
  final String label;

  const VisitFormOption(this.value, this.label);
}

/// Web Family Portal "Request a Visit" modal state and submit
/// (`POST /family/appointments`).
class AppointmentRequestController extends GetxController {
  static const String residentRequiredMessage =
      'Choose who you would like to visit.';
  static const String dateRequiredMessage =
      'Please select a date for your visit.';
  static const String successMessage =
      'Visit requested! The care team will review and confirm.';

  static const List<VisitFormOption> timeSlots = [
    VisitFormOption('10:00', 'Morning (10:00 AM – 11:30 AM)'),
    VisitFormOption('14:00', 'Afternoon (02:00 PM – 03:30 PM)'),
    VisitFormOption('16:00', 'Late Afternoon (04:00 PM – 05:30 PM)'),
    VisitFormOption('18:00', 'Evening (06:00 PM – 07:30 PM)'),
  ];

  static const List<VisitFormOption> visitingAreas = [
    VisitFormOption('Resident Room', "Resident's Private Room"),
    VisitFormOption('Garden Gazebo', 'Outdoor Garden Gazebo'),
    VisitFormOption('Family Lounge', 'Family Guest Lounge'),
    VisitFormOption('Dining Room', 'Main Dining Hall'),
  ];

  final FamilyAppointmentsRepository repository;
  final UserSession? _session;

  AppointmentRequestController({
    FamilyAppointmentsRepository? repository,
    UserSession? session,
  })  : repository =
            repository ?? GetIt.instance<FamilyAppointmentsRepository>(),
        _session = session ??
            (Get.isRegistered<UserSession>() ? Get.find<UserSession>() : null);

  final RxList<FamilyLinkedClient> residents = <FamilyLinkedClient>[].obs;
  final RxnString selectedClientId = RxnString();
  final Rxn<DateTime> visitDate = Rxn<DateTime>();
  final RxString timeSlot = '14:00'.obs;
  final RxString visitingArea = 'Resident Room'.obs;
  final TextEditingController visitorsController =
      TextEditingController(text: '2');
  final TextEditingController noteController = TextEditingController();
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingResidents = false.obs;
  final RxnString formError = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadResidents();
  }

  FamilyLinkedClient? get selectedResident {
    final id = selectedClientId.value;
    for (final r in residents) {
      if (r.id == id) return r;
    }
    return residents.isEmpty ? null : residents.first;
  }

  String get visitDateLabel {
    final date = visitDate.value;
    if (date == null) return 'dd/mm/yyyy';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String get timeSlotLabel => _labelOf(timeSlots, timeSlot.value);

  String get visitingAreaLabel => _labelOf(visitingAreas, visitingArea.value);

  static String _labelOf(List<VisitFormOption> options, String value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  Future<void> loadResidents() async {
    isLoadingResidents.value = true;
    final result = await repository.getLinkedResidents();
    result.when(
      success: (items) {
        residents.assignAll(items);
        final preferred = _session?.selectedClientId;
        if (preferred != null && items.any((r) => r.id == preferred)) {
          selectedClientId.value = preferred;
        } else if (items.isNotEmpty) {
          selectedClientId.value = items.first.id;
        }
      },
      failure: (_) => residents.clear(),
    );
    isLoadingResidents.value = false;
  }

  void selectResident(String clientId) {
    selectedClientId.value = clientId;
    _session?.selectClient(clientId);
    formError.value = null;
  }

  void selectDate(DateTime date) {
    visitDate.value = DateTime(date.year, date.month, date.day);
    formError.value = null;
  }

  /// Validates like the web modal and sends the request. Returns `true` when
  /// the visit was created and the lists were refetched.
  Future<bool> submit() async {
    if (isSubmitting.value) return false;
    formError.value = null;

    final clientId = selectedResident?.id;
    if (clientId == null || clientId.isEmpty) {
      formError.value = residentRequiredMessage;
      return false;
    }
    final date = visitDate.value;
    if (date == null) {
      formError.value = dateRequiredMessage;
      return false;
    }

    final parts = timeSlot.value.split(':');
    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts.first) ?? 14,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final note = noteController.text.trim();
    final notes = [
      'Visitors: ${visitorsController.text.trim()} people',
      if (note.isNotEmpty) 'Notes: $note',
    ].join(' · ');

    isSubmitting.value = true;
    final result = await repository.createAppointment(
      type: 'family_visit',
      clientId: clientId,
      scheduledAt: scheduledAt,
      location: visitingArea.value.trim(),
      notes: notes,
    );
    isSubmitting.value = false;

    return result.when(
      success: (_) {
        _refreshLists();
        return true;
      },
      failure: (error) {
        formError.value = error.message;
        return false;
      },
    );
  }

  void _refreshLists() {
    if (Get.isRegistered<FamilyAppointmentsController>()) {
      Get.find<FamilyAppointmentsController>().refresh();
    }
    if (Get.isRegistered<FamilyVisitRequestsController>()) {
      Get.find<FamilyVisitRequestsController>().refresh();
    }
  }

  @override
  void onClose() {
    visitorsController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
