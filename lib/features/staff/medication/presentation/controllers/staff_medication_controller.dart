import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../domain/entities/staff_medication_overview.dart';
import '../../domain/repositories/staff_medication_repository.dart';

/// GetX controller for the Staff Medication MAR screen.
class StaffMedicationController extends BaseController<StaffMedicationOverview> {
  final StaffMedicationRepository repository;

  final Rx<StaffMedicationTab> selectedTab = StaffMedicationTab.due.obs;
  final RxBool isRecording = false.obs;

  StaffMedicationController({required this.repository}) {
    loadOverview();
  }

  StaffMedicationOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  void selectTab(StaffMedicationTab tab) => selectedTab.value = tab;

  Future<void> markAdministered(String doseId) async {
    final dose = _findDose(doseId);
    if (dose == null) return;
    final session = Get.find<UserSession>();
    if (!session.canAdministerMarDose(isPrn: dose.isPrn)) {
      AppErrorDialog.showPageError(
        title: dose.isPrn ? 'PRN not allowed' : 'Cannot administer',
        message: dose.isPrn
            ? 'PRN doses require medication-administration certification.'
            : 'Administering doses needs mar:write permission.',
      );
      return;
    }
    await _record(dose, status: 'administered');
  }

  Future<void> markNotGiven(String doseId) async {
    final dose = _findDose(doseId);
    if (dose == null) return;
    final session = Get.find<UserSession>();
    if (!session.canWriteMar) {
      AppErrorDialog.showPageError(
        title: 'Cannot record',
        message: 'Recording a missed or refused dose needs mar:write permission.',
      );
      return;
    }

    final outcome = await _promptNotGiven();
    if (outcome == null) return;
    await _record(
      dose,
      status: outcome.status,
      notes: outcome.notes,
    );
  }

  Future<_NotGivenOutcome?> _promptNotGiven() async {
    final dialogContext = Get.overlayContext ?? Get.context;
    if (dialogContext == null) return null;

    final notes = TextEditingController();
    var status = 'refused';

    final saved = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Not given'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(status),
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'refused',
                        child: Text('Refused'),
                      ),
                      DropdownMenuItem(
                        value: 'missed',
                        child: Text('Missed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocal(() => status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reason / notes',
                      hintText: 'Why was this dose not given?',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    final text = notes.text.trim();
    // Defer dispose until after dialog route teardown.
    Future<void>.delayed(Duration.zero, notes.dispose);
    if (saved != true) return null;
    if (text.isEmpty) {
      AppSnackbar.show('Reason required', 'Add a note explaining why.');
      return null;
    }
    return _NotGivenOutcome(status: status, notes: text);
  }

  Future<void> _record(
    DueDose dose, {
    required String status,
    String? notes,
  }) async {
    if (isRecording.value) return;
    final residenceId = dose.residenceId.isNotEmpty
        ? dose.residenceId
        : (Get.find<UserSession>().residenceId ?? '');
    if (dose.clientId.isEmpty ||
        dose.medicationId.isEmpty ||
        residenceId.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Could not record dose',
        message: 'This dose is missing client or medication details.',
      );
      return;
    }

    isRecording.value = true;
    final result = await repository.recordAdministration(
      clientId: dose.clientId,
      residenceId: residenceId,
      medicationId: dose.medicationId,
      status: status,
      notes: notes,
      isPrn: dose.isPrn,
    );
    isRecording.value = false;

    if (result.isFailure) {
      await Future<void>.delayed(Duration.zero);
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not record dose',
      );
      return;
    }

    await Future<void>.delayed(Duration.zero);
    AppSnackbar.show(
      'Recorded',
      status == 'administered'
          ? 'Dose marked as administered.'
          : 'Dose marked as $status.',
    );
    await loadOverview();
  }

  DueDose? _findDose(String doseId) {
    final current = overview;
    if (current == null) return null;
    for (final dose in [...current.dueNowDoses, ...current.laterTodayDoses]) {
      if (dose.id == doseId) return dose;
    }
    return null;
  }

  @override
  Future<void> refresh() => loadOverview();
}

class _NotGivenOutcome {
  final String status;
  final String notes;

  const _NotGivenOutcome({required this.status, required this.notes});
}
