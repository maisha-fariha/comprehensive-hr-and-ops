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
import '../widgets/staff_administer_dose_dialog.dart';

/// GetX controller for the Staff Medication MAR screen.
class StaffMedicationController extends BaseController<StaffMedicationOverview> {
  final StaffMedicationRepository repository;

  final Rx<StaffMedicationTab> selectedTab = StaffMedicationTab.due.obs;
  final RxBool isRecording = false.obs;

  /// Web Not Given reason → API status mapping (BUG_Report018/019 nested).
  static const List<({String label, String status})> notGivenReasons = [
    (label: 'Resident refused', status: 'refused'),
    (label: 'Asleep / unavailable', status: 'missed'),
    (label: 'Away / hospital appointment', status: 'missed'),
    (label: 'Withheld on clinical advice', status: 'missed'),
    (label: 'Other / missed', status: 'missed'),
  ];

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

    final dialogContext = Get.overlayContext ?? Get.context;
    if (dialogContext == null) return;
    final wizard = await StaffAdministerDoseDialog.show(
      dialogContext,
      dose: dose,
    );
    if (wizard == null) return;

    await _record(
      dose,
      status: 'administered',
      clinicalNotes: wizard.notes.isEmpty ? null : wizard.notes,
      safetyChecks: {
        'safetyConfirmed': wizard.safetyConfirmed,
        'identityVerified': wizard.identityVerified,
        'medicationVerified': wizard.medicationVerified,
        'dosageVerified': wizard.dosageVerified,
        'routeVerified': wizard.routeVerified,
        'timeVerified': wizard.timeVerified,
      },
      vitals: {
        'bloodPressure': wizard.bloodPressure,
        'heartRate': wizard.heartRate,
        'temperature': wizard.temperature,
        'bloodSugar': wizard.bloodSugar,
      },
    );
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
    var reasonIndex = 0;

    final saved = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Not given'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      key: ValueKey(reasonIndex),
                      initialValue: reasonIndex,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                      ),
                      items: [
                        for (var i = 0; i < notGivenReasons.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(notGivenReasons[i].label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setLocal(() => reasonIndex = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('staff-mar-not-given-notes'),
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Details / notes',
                        hintText: 'Add any extra context for the record…',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  key: const Key('staff-mar-not-given-save'),
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
    final reason = notGivenReasons[reasonIndex];
    // Defer dispose until after dialog route teardown.
    Future<void>.delayed(Duration.zero, notes.dispose);
    if (saved != true) return null;
    final composed = text.isEmpty
        ? reason.label
        : '${reason.label}: $text';
    return _NotGivenOutcome(status: reason.status, notes: composed);
  }

  Future<void> _record(
    DueDose dose, {
    required String status,
    String? notes,
    String? clinicalNotes,
    Map<String, bool>? safetyChecks,
    Map<String, String>? vitals,
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
      clinicalNotes: clinicalNotes,
      isPrn: dose.isPrn,
      safetyChecks: safetyChecks,
      vitals: vitals,
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
