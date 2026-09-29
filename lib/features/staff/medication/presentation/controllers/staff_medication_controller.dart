import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/administered_dose.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/staff_client_medication_item.dart';
import '../../domain/entities/staff_med_options.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../domain/entities/staff_medication_overview.dart';
import '../../domain/repositories/staff_medication_repository.dart';
import '../widgets/staff_add_medicine_sheet.dart';
import '../widgets/staff_record_administration_dialog.dart';

/// GetX controller for the Staff Medication MAR screen.
class StaffMedicationController extends BaseController<StaffMedicationOverview> {
  final StaffMedicationRepository repository;

  final Rx<StaffMedicationTab> selectedTab = StaffMedicationTab.mar.obs;
  final RxBool isRecording = false.obs;
  final RxList<StaffClientMedicationItem> prnItems =
      <StaffClientMedicationItem>[].obs;
  final RxList<AdministeredDose> givenItems = <AdministeredDose>[].obs;
  final RxList<StaffMedClientOption> chartClients =
      <StaffMedClientOption>[].obs;
  final RxBool loadingExtras = false.obs;

  /// Web Not Given reason → API status (+ doseReason label for notes).
  static const List<({String label, String status, String doseReason})>
      notGivenReasons = [
    (label: 'Resident refused', status: 'refused', doseReason: 'patient_refused'),
    (
      label: 'Asleep / unavailable',
      status: 'missed',
      doseReason: 'resident_asleep',
    ),
    (
      label: 'Away / hospital appointment',
      status: 'missed',
      doseReason: 'hospitalized',
    ),
    (
      label: 'Withheld on clinical advice',
      status: 'withheld',
      doseReason: 'clinical_hold',
    ),
    (
      label: 'Not available — none in stock',
      status: 'not_available',
      doseReason: 'drug_unavailable',
    ),
    (label: 'Other / missed', status: 'missed', doseReason: 'other'),
  ];

  StaffMedicationController({required this.repository}) {
    loadOverview();
  }

  StaffMedicationOverview? get overview => state.value.data;

  int get marTabCount => overview?.scheduledCount ?? 0;
  int get prnTabCount => prnItems.length;
  int get givenTabCount => givenItems.length;

  Future<void> loadOverview() async {
    setLoading(true);
    loadingExtras.value = true;
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);

    // Web loads these separately from the round summary (metrics ≠ tab badges).
    final prnResult = await repository.listPrnMedications();
    prnItems.assignAll(prnResult.value ?? const []);

    final givenResult = await repository.listAdministrations();
    givenItems.assignAll(givenResult.value ?? const []);

    final clientsResult = await repository.getClients();
    chartClients.assignAll(clientsResult.value ?? const []);
    loadingExtras.value = false;
  }

  void selectTab(StaffMedicationTab tab) => selectedTab.value = tab;

  Future<void> givePrn(StaffClientMedicationItem item) async {
    final session = Get.find<UserSession>();
    if (!session.canWriteMar) {
      AppErrorDialog.showPageError(
        title: 'Cannot administer',
        message: 'Administering doses needs mar:write permission.',
      );
      return;
    }
    if (item.clientId.isEmpty || item.residenceId.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Cannot give PRN',
        message: 'This PRN is missing resident or residence details.',
      );
      return;
    }
    await _openWizardForMedication(item);
  }

  Future<void> openAddMedicine(BuildContext context) async {
    final session = Get.find<UserSession>();
    if (!session.canWriteMar) {
      AppErrorDialog.showPageError(
        title: 'Cannot add medicine',
        message: 'Adding medicines needs mar:write permission.',
      );
      return;
    }
    final created = await StaffAddMedicineSheet.show(
      context,
      onCreated: () {},
    );
    if (created == true) await loadOverview();
  }

  Future<void> startRecordAdministration(BuildContext context) async {
    final session = Get.find<UserSession>();
    if (!session.canWriteMar) {
      AppErrorDialog.showPageError(
        title: 'Cannot administer',
        message: 'Administering doses needs mar:write permission.',
      );
      return;
    }

    // Web opens the Record Administration dialog immediately — resident and
    // medicine are chosen inside step 1, not via a pre-picker sheet.
    var clients = chartClients.toList();
    if (clients.isEmpty) {
      clients = (await repository.getClients()).value ?? const [];
    }
    final current = overview;
    final due = current == null
        ? const <DueDose>[]
        : [...current.dueNowDoses, ...current.laterTodayDoses];
    DueDose? preselected;
    if (due.length == 1) preselected = due.first;

    final dialogContext = Get.overlayContext ?? Get.context;
    if (dialogContext == null) return;
    final result = await StaffRecordAdministrationDialog.show(
      dialogContext,
      clients: clients,
      preselectedDose: preselected,
    );
    if (result == null) return;
    await _recordFromResult(result);
  }

  Future<void> _openWizardForMedication(StaffClientMedicationItem item) async {
    final clients = chartClients.isNotEmpty
        ? chartClients.toList()
        : (await repository.getClients()).value ?? const <StaffMedClientOption>[];
    final synthetic = DueDose(
      id: '${item.isPrn ? 'prn' : 'med'}-${item.id}',
      residentName: item.clientName.isEmpty ? 'Resident' : item.clientName,
      residentInitials: item.clientName.isEmpty
          ? 'R'
          : item.clientName
              .trim()
              .split(RegExp(r'\s+'))
              .where((p) => p.isNotEmpty)
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join(),
      avatarColor: AvatarPalette.blue,
      medicationName: item.name,
      dose: item.dose,
      route: MedicationRoute.tabletOral,
      timeLabel: item.isPrn
          ? (item.instructions?.isNotEmpty == true
              ? item.instructions!
              : 'PRN / as needed')
          : (item.scheduleLabel ?? ''),
      section: DueDoseSection.dueNow,
      clientId: item.clientId,
      residenceId: item.residenceId,
      residenceName: item.residenceName,
      medicationId: item.id,
      isPrn: item.isPrn,
    );
    final dialogContext = Get.overlayContext ?? Get.context;
    if (dialogContext == null) return;
    final result = await StaffRecordAdministrationDialog.show(
      dialogContext,
      clients: clients,
      preselectedDose: synthetic,
    );
    if (result == null) return;
    await _recordFromResult(result);
  }

  Future<void> _recordFromResult(StaffRecordAdministrationResult result) async {
    final evidenceNote = result.evidencePaths.isEmpty
        ? null
        : 'Evidence attached locally: ${result.evidencePaths.map((p) => p.split('/').last).join(', ')}';
    final notes = [
      if (result.notes.isNotEmpty) result.notes,
      ?evidenceNote,
    ].join('\n');
    await _record(
      result.dose,
      status: result.status,
      notes: notes.isEmpty ? null : notes,
      clinicalNotes:
          result.clinicalNotes.isEmpty ? null : result.clinicalNotes,
      doseReason: result.doseReason,
      safetyChecks: {
        'safetyConfirmed': result.safetyConfirmed,
        'identityVerified': result.identityVerified,
        'medicationVerified': result.medicationVerified,
        'dosageVerified': result.dosageVerified,
        'routeVerified': result.routeVerified,
        'timeVerified': result.timeVerified,
      },
      vitals: {
        'bloodPressure': result.bloodPressure,
        'heartRate': result.heartRate,
        'temperature': result.temperature,
        'bloodSugar': result.bloodSugar,
      },
    );
  }

  Future<void> markAdministered(String doseId) async {
    final dose = _findDose(doseId);
    if (dose == null) return;
    final session = Get.find<UserSession>();
    if (!session.canWriteMar) {
      AppErrorDialog.showPageError(
        title: 'Cannot administer',
        message: 'Administering doses needs mar:write permission.',
      );
      return;
    }

    var clients = chartClients.toList();
    if (clients.isEmpty) {
      clients = (await repository.getClients()).value ?? const [];
    }
    final dialogContext = Get.overlayContext ?? Get.context;
    if (dialogContext == null) return;
    final result = await StaffRecordAdministrationDialog.show(
      dialogContext,
      clients: clients,
      preselectedDose: dose,
    );
    if (result == null) return;
    await _recordFromResult(result);
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
      doseReason: outcome.doseReason,
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
    return _NotGivenOutcome(
      status: reason.status,
      notes: composed,
      doseReason: reason.doseReason,
    );
  }

  Future<void> _record(
    DueDose dose, {
    required String status,
    String? notes,
    String? clinicalNotes,
    String? doseReason,
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
      doseReason: doseReason,
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
  final String doseReason;

  const _NotGivenOutcome({
    required this.status,
    required this.notes,
    required this.doseReason,
  });
}
