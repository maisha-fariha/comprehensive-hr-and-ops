import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/offline/offline_outbox.dart';
import '../../../../../core/offline/outbox_context.dart';
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
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// GetX controller for the Staff Medication MAR screen.
class StaffMedicationController extends BaseController<StaffMedicationOverview> {
  final StaffMedicationRepository repository;
  final UserSession? _injectedSession;

  final Rx<StaffMedicationTab> selectedTab = StaffMedicationTab.mar.obs;
  final RxBool isRecording = false.obs;
  final RxList<StaffClientMedicationItem> prnItems =
      <StaffClientMedicationItem>[].obs;
  final RxList<AdministeredDose> givenItems = <AdministeredDose>[].obs;
  final RxList<StaffMedClientOption> chartClients =
      <StaffMedClientOption>[].obs;

  /// `GET /residences` — the web "All residences" options.
  final RxList<StaffMedResidenceOption> residences =
      <StaffMedResidenceOption>[].obs;

  /// `GET /medications` — the prescriptions behind registry rows (Edit).
  final RxList<StaffClientMedicationItem> medications =
      <StaffClientMedicationItem>[].obs;
  final RxBool loadingExtras = false.obs;
  int _loadSerial = 0;

  static const String notInList =
      'That prescription is not in the current list.';

  /// Web MAR registry filters (client-side, same as console).
  final RxString filterSearch = ''.obs;
  final RxString filterResidenceId = ''.obs;
  final RxString filterClientId = ''.obs;
  final RxString filterMedication = ''.obs;
  final RxString filterState = ''.obs;
  final TextEditingController searchController = TextEditingController();

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

  StaffMedicationController({
    required this.repository,
    UserSession? session,
  }) : _injectedSession = session {
    loadOverview();
  }

  UserSession get _session => _injectedSession ?? Get.find<UserSession>();

  StaffMedicationOverview? get overview => state.value.data;

  /// Web tab badges count the filtered rows.
  int get marTabCount => filteredScheduledDoses.length;
  int get prnTabCount => filteredPrnItems.length;
  int get givenTabCount => givenItems.length;

  /// Web Edit on a registry row (`mar:write`).
  bool get canEditMedicines => _session.can('mar:write');

  bool get hasActiveFilters =>
      filterSearch.value.trim().isNotEmpty ||
      filterResidenceId.value.isNotEmpty ||
      filterClientId.value.isNotEmpty ||
      filterMedication.value.isNotEmpty ||
      filterState.value.isNotEmpty;

  /// Web MAR tab rows: every occurrence on today's round.
  List<DueDose> get allScheduledDoses {
    final current = overview;
    if (current == null) return const [];
    if (current.registryDoses.isNotEmpty) return current.registryDoses;
    return [...current.dueNowDoses, ...current.laterTodayDoses];
  }

  List<({String value, String label})> get residenceFilterOptions {
    final map = <String, String>{
      for (final r in residences) r.id: r.name,
    };
    for (final d in allScheduledDoses) {
      if (d.residenceId.isEmpty) continue;
      map.putIfAbsent(
        d.residenceId,
        () => d.residenceName.isEmpty ? d.residenceId : d.residenceName,
      );
    }
    for (final p in prnItems) {
      if (p.residenceId.isEmpty) continue;
      map.putIfAbsent(
        p.residenceId,
        () => p.residenceName.isEmpty ? p.residenceId : p.residenceName,
      );
    }
    return [
      for (final e in map.entries) (value: e.key, label: e.value),
    ];
  }

  /// Residents of the MAR and PRN rows, sorted by name (web `e6`).
  List<({String value, String label})> get residentFilterOptions {
    final map = <String, String>{};
    for (final d in allScheduledDoses) {
      if (d.clientId.isEmpty) continue;
      map[d.clientId] = d.residentName.isEmpty ? 'Resident' : d.residentName;
    }
    for (final p in prnItems) {
      if (p.clientId.isEmpty) continue;
      map[p.clientId] = p.clientName.isEmpty ? 'Outside your access' : p.clientName;
    }
    final list = map.entries
        .map((e) => (value: e.key, label: e.value))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  /// Medicine names of the MAR and PRN rows, sorted (web `e4`).
  List<({String value, String label})> get medicationFilterOptions {
    final names = <String>{
      for (final d in allScheduledDoses)
        if (d.medicationName.isNotEmpty) d.medicationName,
      for (final p in prnItems)
        if (p.name.isNotEmpty) p.name,
    }.toList()
      ..sort();
    return [for (final n in names) (value: n, label: n)];
  }

  /// Web PRN tab rows after the shared registry filters (a PRN has no
  /// state, so any status filter hides every PRN row like the web).
  List<StaffClientMedicationItem> get filteredPrnItems {
    final q = filterSearch.value.trim().toLowerCase();
    final residence = filterResidenceId.value;
    final client = filterClientId.value;
    final med = filterMedication.value;
    final state = filterState.value;
    return prnItems.where((p) {
      if (residence.isNotEmpty && p.residenceId != residence) return false;
      if (client.isNotEmpty && p.clientId != client) return false;
      if (med.isNotEmpty && p.name != med) return false;
      if (state.isNotEmpty) return false;
      if (q.isEmpty) return true;
      final resident =
          p.clientId.isEmpty ? 'House stock' : p.clientName;
      return resident.toLowerCase().contains(q) ||
          p.name.toLowerCase().contains(q);
    }).toList();
  }

  /// Name of whoever signed a charted dose, from the Given history.
  String administeredByName(DueDose dose) {
    final adminId = dose.administrationId;
    if (adminId != null) {
      for (final g in givenItems) {
        if (g.id == adminId && g.administeredByName != '—') {
          return g.administeredByName;
        }
      }
    }
    final own = _session.staffId;
    if (own != null && own.isNotEmpty && dose.administeredBy == own) {
      final name = _session.displayName;
      return name.isEmpty ? 'you' : name;
    }
    return '—';
  }

  List<DueDose> get filteredScheduledDoses {
    final q = filterSearch.value.trim().toLowerCase();
    final residence = filterResidenceId.value;
    final client = filterClientId.value;
    final med = filterMedication.value;
    final state = filterState.value;

    return allScheduledDoses.where((d) {
      if (residence.isNotEmpty && d.residenceId != residence) return false;
      if (client.isNotEmpty && d.clientId != client) return false;
      if (med.isNotEmpty && d.medicationName != med) return false;
      if (state.isNotEmpty && d.state != state) return false;
      if (q.isEmpty) return true;
      return d.residentName.toLowerCase().contains(q) ||
          d.medicationName.toLowerCase().contains(q);
    }).toList();
  }

  void updateFilters({
    String? search,
    String? residenceId,
    String? clientId,
    String? medication,
    String? state,
  }) {
    if (search != null) filterSearch.value = search;
    if (clientId != null) filterClientId.value = clientId;
    if (medication != null) filterMedication.value = medication;
    if (state != null) filterState.value = state;
    if (residenceId != null && residenceId != filterResidenceId.value) {
      filterResidenceId.value = residenceId;
      // The web re-asks the round and PRN register for the chosen house.
      loadOverview();
    }
  }

  void clearFilters() {
    final hadResidence = filterResidenceId.value.isNotEmpty;
    filterSearch.value = '';
    filterResidenceId.value = '';
    filterClientId.value = '';
    filterMedication.value = '';
    filterState.value = '';
    searchController.clear();
    if (hadResidence) loadOverview();
  }

  /// Web Missed panel "Review All" — jump to MAR tab with overdue filter.
  void reviewAllMissed() {
    selectedTab.value = StaffMedicationTab.mar;
    filterState.value = 'overdue';
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Reloads every list a medicine or dose can appear in — the round, the
  /// PRN register, the prescriptions, the Given history and the pickers —
  /// the way the web invalidates every `mar` query after a save.
  Future<void> loadOverview() async {
    final serial = ++_loadSerial;
    final residence = filterResidenceId.value.isEmpty
        ? null
        : filterResidenceId.value;
    setLoading(true);
    loadingExtras.value = true;
    final result = await repository.getOverview(residenceId: residence);
    if (serial != _loadSerial) return;
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);

    // Web loads these separately from the round summary (metrics ≠ tab badges).
    final (prnResult, givenResult, medsResult, clientsResult, homesResult) =
        await (
      repository.listPrnMedications(residenceId: residence),
      repository.listAdministrations(),
      repository.listMedications(residenceId: residence),
      repository.getClients(),
      repository.getResidences(),
    ).wait;
    if (serial != _loadSerial) return;
    prnItems.assignAll(prnResult.value ?? const []);
    givenItems.assignAll(givenResult.value ?? const []);
    medications.assignAll(medsResult.value ?? const []);
    chartClients.assignAll(clientsResult.value ?? const []);
    if (homesResult.value case final homes?) residences.assignAll(homes);
    loadingExtras.value = false;
  }

  /// Web Edit on a MAR row: the prescription behind it, from `/medications`.
  Future<void> editDose(BuildContext context, DueDose dose) async {
    StaffClientMedicationItem? match;
    for (final m in dose.isPrn ? prnItems : medications) {
      if (m.id == dose.medicationId) {
        match = m;
        break;
      }
    }
    if (match == null) {
      AppSnackbar.show(notInList, '');
      return;
    }
    await editMedication(context, match);
  }

  Future<void> editMedication(
    BuildContext context,
    StaffClientMedicationItem item,
  ) async {
    if (!canEditMedicines) {
      AppErrorDialog.showPageError(
        title: 'Cannot edit medicine',
        message: 'Editing medicines needs mar:write permission.',
      );
      return;
    }
    final saved = await StaffAddMedicineSheet.show(context, editing: item);
    if (saved == true) await loadOverview();
  }

  void selectTab(StaffMedicationTab tab) => selectedTab.value = tab;

  Future<void> givePrn(StaffClientMedicationItem item) async {
    final session = _session;
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
    final session = _session;
    if (!session.canWriteMar) {
      AppErrorDialog.showPageError(
        title: 'Cannot add medicine',
        message: 'Adding medicines needs mar:write permission.',
      );
      return;
    }
    final created = await StaffAddMedicineSheet.show(context);
    if (created == true) await loadOverview();
  }

  Future<void> startRecordAdministration(BuildContext context) async {
    final session = _session;
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
    final session = _session;
    if (!session.canWriteMar) {
      AppErrorDialog.showPageError(
        title: 'Cannot administer',
        message: 'Administering doses needs mar:write permission.',
      );
      return;
    }
    if (_blockIfRecordedOffline(dose)) return;

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
    final session = _session;
    if (!session.canWriteMar) {
      AppErrorDialog.showPageError(
        title: 'Cannot record',
        message: 'Recording a missed or refused dose needs mar:write permission.',
      );
      return;
    }
    if (_blockIfRecordedOffline(dose)) return;

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

    final saved = await showAppPopup<bool>(
      context: dialogContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AppSheetDialog(
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
        : (_session.residenceId ?? '');
    if (dose.clientId.isEmpty ||
        dose.medicationId.isEmpty ||
        residenceId.isEmpty) {
      AppErrorDialog.showPageError(
        title: 'Could not record dose',
        message: 'This dose is missing client or medication details.',
      );
      return;
    }

    if (_blockIfRecordedOffline(dose)) return;

    isRecording.value = true;
    final result = await OutboxContext.run(
      () => repository.recordAdministration(
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
      ),
      meta: {
        if (_isTrackedScheduledDose(dose)) 'doseId': dose.id,
        'clientId': dose.clientId,
        'medicationId': dose.medicationId,
        if (dose.slotLabel.isNotEmpty) 'slot': dose.slotLabel,
      },
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

  /// A scheduled round dose from the loaded MAR (not PRN, not a dose built
  /// from the medicine picker).
  bool _isTrackedScheduledDose(DueDose dose) =>
      !dose.isPrn && dose.scheduled && _findDose(dose.id) != null;

  /// True when [dose] was recorded on this device and has not reached the
  /// server yet, so the card can show "Pending sync".
  bool isPendingSync(DueDose dose) {
    final outbox = OfflineOutbox.maybe;
    if (outbox == null || !_isTrackedScheduledDose(dose)) return false;
    outbox.store.items.length;
    return outbox.hasUnsentDose(
      doseId: dose.id,
      clientId: dose.clientId,
      medicationId: dose.medicationId,
      slot: dose.slotLabel,
    );
  }

  /// Stops a scheduled dose being recorded twice while the first record is
  /// still waiting on this device.
  bool _blockIfRecordedOffline(DueDose dose) {
    if (!isPendingSync(dose)) return false;
    AppErrorDialog.showPageError(
      title: 'Recorded offline – pending sync',
      message: 'This dose is already recorded on this device and will be '
          'sent when you are back online. Check Unsent changes in Profile '
          'before recording it again.',
    );
    return true;
  }

  DueDose? _findDose(String doseId) {
    final current = overview;
    if (current == null) return null;
    for (final dose in [
      ...allScheduledDoses,
      ...current.dueNowDoses,
      ...current.laterTodayDoses,
    ]) {
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
