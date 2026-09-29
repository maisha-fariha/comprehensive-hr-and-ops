import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../profile_settings/domain/entities/family_linked_client.dart';
import '../../../profile_settings/data/mappers/family_profile_mapper.dart';
import '../../domain/repositories/family_appointments_repository.dart';
import 'family_appointments_controller.dart';

class AppointmentRequestController extends GetxController {
  final FamilyAppointmentsRepository repository;
  final AppApiClient _api;
  final UserSession _session;

  AppointmentRequestController({
    FamilyAppointmentsRepository? repository,
    AppApiClient? api,
    UserSession? session,
  })  : repository =
            repository ?? GetIt.instance<FamilyAppointmentsRepository>(),
        _api = api ?? GetIt.instance<AppApiClient>(),
        _session = session ?? Get.find<UserSession>();

  final RxList<FamilyLinkedClient> residents = <FamilyLinkedClient>[].obs;
  final RxnString selectedClientId = RxnString();
  final Rxn<DateTime> preferredAt = Rxn<DateTime>();
  final TextEditingController locationController = TextEditingController();
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
    if (id == null) return null;
    for (final r in residents) {
      if (r.id == id) return r;
    }
    return null;
  }

  String get residentFieldValue {
    final selected = selectedResident;
    if (selected != null) return selected.name;
    if (residents.isEmpty) return 'No linked residents yet';
    return 'Select a resident';
  }

  String get preferredTimeLabel {
    final at = preferredAt.value;
    if (at == null) return 'dd/mm/yyyy, --:--';
    final d = at.day.toString().padLeft(2, '0');
    final m = at.month.toString().padLeft(2, '0');
    final y = at.year.toString();
    final time = IsoDateRange.timeLabel(at);
    return '$d/$m/$y, $time';
  }

  Future<void> loadResidents() async {
    isLoadingResidents.value = true;
    final result = await _api.get(ApiEndpoints.familyClients);
    result.when(
      success: (body) {
        final overview = FamilyProfileMapper.compose(
          session: _session,
          clientsBody: body,
        );
        residents.assignAll(overview.linkedClients);
        final selected = _session.selectedClientId;
        if (selected != null &&
            residents.any((r) => r.id == selected)) {
          selectedClientId.value = selected;
        } else if (residents.length == 1) {
          selectedClientId.value = residents.first.id;
        }
      },
      failure: (_) {
        residents.clear();
      },
    );
    isLoadingResidents.value = false;
  }

  Future<void> pickResident(BuildContext context) async {
    if (residents.isEmpty) {
      formError.value = 'Choose who you would like to visit.';
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Who would you like to visit',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF14263B),
                  ),
                ),
              ),
            ),
            for (final r in residents)
              ListTile(
                title: Text(
                  r.name,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: r.subtitle.isEmpty
                    ? null
                    : Text(
                        r.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12.5,
                          color: Color(0xFF8A97A8),
                        ),
                      ),
                onTap: () => Navigator.pop(ctx, r.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null) return;
    selectedClientId.value = selected;
    _session.selectClient(selected);
    formError.value = null;
  }

  Future<void> pickPreferredTime(BuildContext context) async {
    final now = DateTime.now();
    final initial = preferredAt.value ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    preferredAt.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;
    final clientId = selectedClientId.value;
    if (clientId == null || clientId.isEmpty) {
      formError.value = 'Choose who you would like to visit.';
      return;
    }
    formError.value = null;

    final scheduled = preferredAt.value ??
        () {
          final base = DateTime.now().add(const Duration(days: 1));
          return DateTime(base.year, base.month, base.day, 14);
        }();

    isSubmitting.value = true;
    final result = await repository.createAppointment(
      type: 'family_visit',
      clientId: clientId,
      scheduledAt: scheduled,
      location: locationController.text.trim(),
      notes: noteController.text.trim(),
    );
    isSubmitting.value = false;
    result.when(
      success: (_) {
        Get.snackbar(
          'Request sent',
          'The care home will confirm the time with you.',
          snackPosition: SnackPosition.BOTTOM,
        );
        if (Get.isRegistered<FamilyAppointmentsController>()) {
          Get.find<FamilyAppointmentsController>().refresh();
        }
        Get.back();
      },
      failure: (error) {
        final message = error.message;
        if (message.toLowerCase().contains('client')) {
          formError.value = 'Choose who you would like to visit.';
        }
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not send request',
        );
      },
    );
  }

  @override
  void onClose() {
    locationController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
