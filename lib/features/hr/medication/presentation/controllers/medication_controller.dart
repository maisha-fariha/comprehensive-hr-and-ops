import 'dart:async';
import 'dart:typed_data';

import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../domain/entities/mar_administration.dart';
import '../../domain/entities/mar_medication.dart';
import '../../domain/entities/mar_medication_stock.dart';
import '../../domain/entities/mar_options.dart';
import '../../domain/entities/mar_round.dart';
import '../../domain/repositories/medication_repository.dart';
import '../mar_row.dart';
import '../medication_labels.dart';

/// Saves the exported CSV; returns an error message or null.
typedef MarFileSaver = Future<String?> Function(String fileName, List<int> bytes);

Future<String?> _saveAndOpen(String fileName, List<int> bytes) async {
  final saved = await MediaStoreDownload.saveFileAndOpen(
    fileName: fileName,
    bytes: Uint8List.fromList(bytes),
    mimeType: 'text/csv',
    chooserTitle: 'Open CSV',
  );
  return saved.success ? null : saved.error ?? 'Could not save the export.';
}

/// Web `/dashboard/medication` ("Medication Administration Record (MAR)"):
/// KPI cards, the MAR / PRN / Given / Stock / Resident chart tabs, Due Now
/// and Missed / Overdue panels, and every add / edit / chart / correct /
/// discontinue / delete / export / count-stock action.
class MedicationController extends GetxController {
  final MedicationRepository repository;
  final UserSession session;
  final MarFileSaver saveFile;

  MedicationController({
    required this.repository,
    UserSession? session,
    MarFileSaver? saveFile,
  })  : session = session ?? Get.find<UserSession>(),
        saveFile = saveFile ?? _saveAndOpen;

  static const List<int> pageSizes = [10, 20, 50];
  static const String notInList = 'That prescription is not in the current list.';

  final Rxn<MarRound> round = Rxn<MarRound>();
  final RxBool roundLoading = true.obs;
  final RxnString roundError = RxnString();
  final RxList<MarMedication> medications = <MarMedication>[].obs;
  final RxList<MarMedication> prns = <MarMedication>[].obs;
  final RxBool prnLoading = true.obs;
  final RxnString prnError = RxnString();
  final RxList<MarAdministration> given = <MarAdministration>[].obs;
  final RxBool givenLoading = true.obs;
  final RxnString givenError = RxnString();

  /// Stock tab — scheduled + PRN prescriptions joined to trolley counts.
  final RxList<MarMedication> stockScheduled = <MarMedication>[].obs;
  final RxList<MarMedication> stockPrns = <MarMedication>[].obs;
  final RxList<MarMedicationStock> stocks = <MarMedicationStock>[].obs;
  final RxBool stockLoading = false.obs;
  final RxnString stockError = RxnString();
  final RxString stockResidenceFilter = ''.obs;

  final RxList<MarOption> residences = <MarOption>[].obs;
  final RxList<MarClientOption> clients = <MarClientOption>[].obs;
  final RxList<MarOption> staff = <MarOption>[].obs;

  final RxString tab = 'mar'.obs;
  final RxString search = ''.obs;
  final RxString filterResidence = ''.obs;
  final RxString filterClient = ''.obs;
  final RxString filterMedication = ''.obs;
  final RxString filterState = ''.obs;
  final RxInt page = 1.obs;
  final RxInt limit = 10.obs;

  final RxString chartClientId = ''.obs;
  final Rxn<MarResidentChart> chart = Rxn<MarResidentChart>();
  final RxBool chartLoading = false.obs;

  final RxBool exporting = false.obs;
  final RxBool busy = false.obs;

  Timer? _debounce;
  int _roundSerial = 0;

  bool get canRead => session.can('mar:read');
  bool get canWrite => session.can('mar:write');
  bool get canManage => session.can('mar:manage');
  bool get canExport => session.can('mar:export');

  /// Charting needs `mar:write` and either approval to give medicine or
  /// `mar:manage`.
  bool get canAdminister => canWrite && (session.medAdminApproved || canManage);

  String? get administerDisabledReason => canWrite && !canAdminister
      ? 'Medication administration is restricted to approved staff'
      : null;

  /// A correction is for managers, or for the person who signed the dose.
  bool canCorrect(MarAdministration a) {
    final own = session.staffId;
    return canWrite && (canManage || (own != null && own.isNotEmpty && a.administeredBy == own));
  }

  String get ownStaffId => session.staffId ?? '';

  String? get _residenceQuery => filterResidence.value.isEmpty ? null : filterResidence.value;

  @override
  void onInit() {
    super.onInit();
    if (!canRead) {
      roundLoading.value = false;
      prnLoading.value = false;
      givenLoading.value = false;
      return;
    }
    refreshAll();
    loadOptions();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadRound(),
      loadMedications(),
      loadPrn(),
      loadGiven(),
      if (tab.value == 'stock') loadStock(),
      if (chartClientId.value.isNotEmpty) loadChart(chartClientId.value),
    ]);
  }

  Future<void> loadRound() async {
    final serial = ++_roundSerial;
    roundLoading.value = true;
    final result = await repository.round(residenceId: _residenceQuery);
    if (serial != _roundSerial) return;
    result.when(
      success: (r) {
        round.value = r;
        roundError.value = null;
      },
      failure: (e) => roundError.value = e.message,
    );
    roundLoading.value = false;
  }

  Future<void> loadMedications() async {
    final result = await repository.medications(residenceId: _residenceQuery);
    result.when(success: medications.assignAll, failure: (_) {});
  }

  Future<void> loadPrn() async {
    prnLoading.value = true;
    final result = await repository.prnMedications(residenceId: _residenceQuery);
    result.when(
      success: (list) {
        prns.assignAll(list);
        prnError.value = null;
      },
      failure: (e) => prnError.value = e.message,
    );
    prnLoading.value = false;
  }

  Future<void> loadGiven() async {
    givenLoading.value = true;
    final result = await repository.administrations();
    result.when(
      success: (list) {
        given.assignAll(list);
        givenError.value = null;
      },
      failure: (e) => givenError.value = e.message,
    );
    givenLoading.value = false;
  }

  Future<void> loadOptions() async {
    final (homes, people, team) =
        await (repository.residences(), repository.clients(), repository.approvedStaff()).wait;
    homes.when(success: residences.assignAll, failure: (_) {});
    people.when(success: clients.assignAll, failure: (_) {});
    team.when(success: staff.assignAll, failure: (_) {});
  }

  Future<void> loadChart(String clientId) async {
    chartClientId.value = clientId;
    if (clientId.isEmpty) {
      chart.value = null;
      return;
    }
    chartLoading.value = true;
    final result = await repository.residentChart(clientId);
    if (chartClientId.value != clientId) return;
    result.when(success: (c) => chart.value = c, failure: (_) => chart.value = null);
    chartLoading.value = false;
  }

  Map<String, String> get clientNames => {for (final c in clients) c.id: c.name};
  Map<String, String> get residenceNames => {for (final r in residences) r.id: r.label};
  Map<String, String> get staffNames => {for (final s in staff) s.id: s.label};

  /// Web MAR registry: scheduled round doses only (not PRN / off-round given).
  List<MarRow> get marRows {
    final names = staffNames;
    return [
      for (final o in round.value?.occurrences ?? const <MarOccurrence>[])
        if (o.scheduled) MarRow.fromOccurrence(o, staffNames: names),
    ];
  }

  List<MarRow> get prnRows {
    final people = clientNames;
    final homes = residenceNames;
    return [
      for (final p in prns) MarRow.fromPrn(p, clientNames: people, residenceNames: homes),
    ];
  }

  List<MarRow> _filter(List<MarRow> rows) {
    final q = search.value.trim().toLowerCase();
    return rows.where((r) {
      final text = q.isEmpty ||
          r.residentName.toLowerCase().contains(q) ||
          r.medication.toLowerCase().contains(q);
      return text &&
          (filterResidence.value.isEmpty || r.residenceId == filterResidence.value) &&
          (filterClient.value.isEmpty || r.clientId == filterClient.value) &&
          (filterMedication.value.isEmpty || r.medication == filterMedication.value) &&
          (filterState.value.isEmpty || r.state == filterState.value);
    }).toList();
  }

  List<MarRow> get filteredMar => _filter(marRows);
  List<MarRow> get filteredPrn => _filter(prnRows);

  List<MarRow> get tabRows => tab.value == 'prn' ? filteredPrn : filteredMar;

  List<MarRow> get pagedRows {
    final rows = tabRows;
    final start = (page.value - 1) * limit.value;
    if (start >= rows.length) return const [];
    return rows.sublist(start, (start + limit.value).clamp(0, rows.length));
  }

  int get totalPages {
    final n = tabRows.length;
    return n == 0 ? 1 : (n / limit.value).ceil();
  }

  bool get hasActiveFilters =>
      filterResidence.value.isNotEmpty ||
      filterClient.value.isNotEmpty ||
      filterMedication.value.isNotEmpty ||
      filterState.value.isNotEmpty;

  List<MarChoice> get residentOptions {
    final map = <String, String>{};
    for (final r in [...marRows, ...prnRows]) {
      if (r.clientId.isNotEmpty) map[r.clientId] = r.residentName;
    }
    return map.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
  }

  List<MarChoice> get medicationOptions {
    final names = {for (final r in [...marRows, ...prnRows]) r.medication}.toList()..sort();
    return [for (final n in names) (n, n)];
  }

  /// Due Now: due or upcoming doses, earliest first.
  List<MarRow> get dueNow {
    final rows = marRows.where((r) => r.state == 'due' || r.state == 'upcoming').toList();
    rows.sort(_byDue);
    return rows;
  }

  /// Missed / Overdue panel: overdue, missed or refused doses.
  List<MarRow> get alerts {
    final rows = marRows
        .where((r) => r.state == 'overdue' || r.state == 'missed' || r.state == 'refused')
        .toList();
    rows.sort(_byDue);
    return rows;
  }

  static int _byDue(MarRow a, MarRow b) =>
      (a.dueAt?.toIso8601String() ?? '').compareTo(b.dueAt?.toIso8601String() ?? '');

  /// Same-resident doses not yet charted, opened alongside a Due Now dose.
  List<MarRow> companionsOf(MarRow row) => marRows
      .where((r) =>
          r.clientId == row.clientId &&
          r.medicationId != row.medicationId &&
          r.administrationId == null)
      .toList();

  void setTab(String id) {
    tab.value = id;
    page.value = 1;
    if (id == 'stock') loadStock();
  }

  /// Web Stock tab home filter (independent of the MAR registry filter).
  void setStockResidence(String residenceId) {
    stockResidenceFilter.value = residenceId;
    loadStock();
  }

  Future<void> loadStock() async {
    stockLoading.value = true;
    stockError.value = null;
    final residenceId =
        stockResidenceFilter.value.isEmpty ? null : stockResidenceFilter.value;
    final (scheduled, prnList, stockList) = await (
      repository.medications(residenceId: residenceId, type: 'scheduled'),
      repository.prnMedications(residenceId: residenceId),
      repository.medicationStock(residenceId: residenceId),
    ).wait;
    String? error;
    scheduled.when(
      success: stockScheduled.assignAll,
      failure: (e) => error ??= e.message,
    );
    prnList.when(
      success: stockPrns.assignAll,
      failure: (e) => error ??= e.message,
    );
    stockList.when(
      success: stocks.assignAll,
      failure: (e) => error ??= e.message,
    );
    stockError.value = error;
    stockLoading.value = false;
  }

  List<MarStockRow> get stockRows {
    final people = clientNames;
    final homes = residenceNames;
    final filter = stockResidenceFilter.value;
    final counts = stocks.toList();

    MarMedicationStock? matchStock({
      String? medicationId,
      String? prnMedicationId,
      required String residenceId,
    }) {
      for (final row in counts) {
        if (filter.isNotEmpty && row.residenceId != residenceId) continue;
        if (medicationId != null &&
            medicationId.isNotEmpty &&
            row.medicationId == medicationId) {
          return row;
        }
        if (prnMedicationId != null &&
            prnMedicationId.isNotEmpty &&
            row.prnMedicationId == prnMedicationId) {
          return row;
        }
      }
      return null;
    }

    String displayName(MarMedication m) {
      final dose = (m.dose ?? '').trim();
      if (dose.isEmpty || dose == '—') return m.name;
      return '${m.name} — $dose';
    }

    final rows = <MarStockRow>[
      for (final m in stockScheduled.where((m) => m.isActive))
        MarStockRow(
          key: 'med:${m.id}',
          medicationId: m.id,
          residenceId: m.residenceId,
          residenceName: homes[m.residenceId] ?? '—',
          name: displayName(m),
          kind: 'Scheduled',
          resident: m.clientId.isEmpty
              ? 'House stock'
              : (people[m.clientId] ?? 'Resident'),
          unitsPerDose: m.stockUnitsPerDose,
          stock: matchStock(
            medicationId: m.id,
            residenceId: m.residenceId,
          ),
        ),
      for (final p in stockPrns.where((p) => p.isActive))
        MarStockRow(
          key: 'prn:${p.id}',
          prnMedicationId: p.id,
          residenceId: p.residenceId,
          residenceName: homes[p.residenceId] ?? '—',
          name: displayName(p),
          kind: 'PRN',
          resident: p.clientId.isEmpty
              ? 'House stock'
              : (people[p.clientId] ?? 'Resident'),
          unitsPerDose: p.stockUnitsPerDose,
          stock: matchStock(
            prnMedicationId: p.id,
            residenceId: p.residenceId,
          ),
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return rows;
  }

  int get stockLowCount =>
      stockRows.where((r) => r.stock?.needsRefill == true).length;

  Future<bool> countStock(MarStockCountDraft draft) async {
    busy.value = true;
    final result = await repository.setMedicationStock(draft);
    busy.value = false;
    return result.when(
      success: (saved) {
        final idx = stocks.indexWhere((s) => s.id == saved.id);
        if (idx >= 0) {
          stocks[idx] = saved;
        } else {
          stocks.add(saved);
        }
        stocks.refresh();
        final name = stockRows
            .where(
              (r) =>
                  (draft.medicationId != null &&
                      r.medicationId == draft.medicationId) ||
                  (draft.prnMedicationId != null &&
                      r.prnMedicationId == draft.prnMedicationId),
            )
            .map((r) => r.name)
            .firstOrNull;
        AppSnackbar.show(
          saved.needsRefill
              ? 'Stock saved — ${name ?? 'Medicine'} is at or below its refill level'
              : 'Stock saved',
          '',
        );
        return true;
      },
      failure: (error) {
        AppSnackbar.show('Could not save stock count', error.message);
        return false;
      },
    );
  }

  void setSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      search.value = text;
      page.value = 1;
    });
  }

  void setFilter(String key, String value) {
    switch (key) {
      case 'residenceId':
        filterResidence.value = value;
      case 'clientId':
        filterClient.value = value;
      case 'medication':
        filterMedication.value = value;
      case 'state':
        filterState.value = value;
    }
    page.value = 1;
    if (key == 'residenceId') {
      loadRound();
      loadMedications();
      loadPrn();
    }
  }

  void clearFilters() {
    final hadResidence = filterResidence.value.isNotEmpty;
    filterResidence.value = '';
    filterClient.value = '';
    filterMedication.value = '';
    filterState.value = '';
    page.value = 1;
    if (hadResidence) {
      loadRound();
      loadMedications();
      loadPrn();
    }
  }

  /// "Review All" narrows the registry to overdue doses.
  void reviewAll() {
    tab.value = 'mar';
    setFilter('state', 'overdue');
  }

  void setPage(int value) => page.value = value;

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
  }

  /// The prescription or PRN medicine behind a registry row.
  MarMedication? medicationFor(MarRow row) {
    final list = row.isPrn ? prns : medications;
    return list.firstWhereOrNull((m) => m.id == row.medicationId);
  }

  /// Medicines the Record Administration form can chart.
  List<MarMedicationChoice> get medicationChoices => [
        for (final m in medications.where((m) => m.isActive))
          MarMedicationChoice(
            id: m.id,
            label: '${m.name}${m.dose != null && m.dose != '—' ? ' — ${m.dose}' : ''}',
            recordType: 'MAR',
            clientId: m.clientId,
            residenceId: m.residenceId,
            dosage: m.dose ?? '—',
            isControlled: m.isControlled,
            scheduledTime: marScheduleLabel(m),
          ),
        for (final p in prns.where((p) => p.isActive))
          MarMedicationChoice(
            id: p.id,
            label: '${p.name} (PRN)',
            recordType: 'PRN',
            clientId: p.clientId,
            residenceId: p.residenceId,
            dosage: p.dose ?? '—',
            isControlled: p.isControlled,
            scheduledTime: '',
          ),
      ];

  Future<String?> _run(Future<Result<void>> Function() action, String success) async {
    busy.value = true;
    final result = await action();
    busy.value = false;
    return result.when(
      success: (_) {
        AppSnackbar.show(success, '');
        refreshAll();
        return null;
      },
      failure: (e) => e.message,
    );
  }

  /// Adds one or several medicines, or saves a correction to [editing].
  /// Returns the error for the form banner.
  Future<String?> saveMedicines(List<MarMedicineDraft> drafts, {MarMedication? editing}) {
    final first = drafts.first;
    if (editing != null) {
      return first.isPrn
          ? _run(() => repository.updatePrn(editing.id, first), 'Medicine updated')
          : _run(() => repository.updateMedication(editing.id, first), 'Prescription updated');
    }
    if (drafts.length > 1) {
      return first.isPrn
          ? _run(() => repository.createPrnBatch(drafts), '${drafts.length} medicines added')
          : _run(
              () => repository.createMedicationBatch(drafts),
              '${drafts.length} medicines prescribed',
            );
    }
    return first.isPrn
        ? _run(() => repository.createPrn(first), 'Medicine added')
        : _run(() => repository.createMedication(first), 'Prescription added');
  }

  Future<void> discontinue(MarMedication m) async {
    final error = await _run(
      () => m.isPrn ? repository.discontinuePrn(m.id) : repository.discontinueMedication(m.id),
      'Discontinued — it stays on file',
    );
    if (error != null) AppSnackbar.show(error, '');
  }

  /// The web deletes from the PRN register on the PRN tab, otherwise from
  /// the prescriptions.
  Future<void> delete(MarMedication m) async {
    final error = await _run(
      () => tab.value == 'prn' ? repository.deletePrn(m.id) : repository.deleteMedication(m.id),
      'Prescription deleted',
    );
    if (error != null) AppSnackbar.show(error, '');
  }

  /// Charts the round, then files any evidence. Returns the error for the
  /// wizard banner.
  Future<String?> recordRound(MarRoundDraft draft, {required String day}) async {
    busy.value = true;
    final result = await repository.chartRound(draft);
    if (result.isFailure) {
      busy.value = false;
      return result.error?.message ?? 'Could not record the round.';
    }
    final count = draft.items.length;
    final withFiles = draft.items.where((i) => i.evidence.isNotEmpty).toList();
    if (withFiles.isEmpty) {
      busy.value = false;
      AppSnackbar.show(count == 1 ? 'Dose recorded' : '$count medicines charted', '');
      refreshAll();
      return null;
    }
    String? evidenceError;
    for (final item in withFiles) {
      for (final file in item.evidence) {
        if (evidenceError != null) break;
        final filed = await repository.fileEvidence(
          file: file,
          name: 'MAR evidence — ${item.medicationName} $day',
          clientId: draft.clientId,
        );
        if (filed.isFailure) evidenceError = filed.error?.message ?? 'Upload failed';
      }
    }
    busy.value = false;
    AppSnackbar.show(
      evidenceError != null
          ? 'Charted, but the evidence was not filed: $evidenceError'
          : count == 1
              ? 'Dose recorded, evidence filed in Documents'
              : '$count medicines charted, evidence filed in Documents',
      '',
    );
    refreshAll();
    return null;
  }

  /// Returns the error for the correction dialog.
  Future<String?> amend(
    MarAdministration a, {
    required String reason,
    String? status,
    String? doseReason,
  }) =>
      _run(
        () => repository.amend(a.id, reason: reason, status: status, doseReason: doseReason),
        'Correction recorded. The original stays on the chart.',
      );

  /// Resolve a charted dose for Edit on an unscheduled MAR row (web `tW`).
  Future<MarAdministration?> administrationForUnscheduled(MarRow row) async {
    final id = row.administrationId;
    if (id == null || id.isEmpty) return null;
    for (final a in given) {
      if (a.id == id) return a;
    }
    final result = await repository.administrations();
    return result.when(
      success: (list) {
        given.assignAll(list);
        for (final a in list) {
          if (a.id == id) return a;
        }
        return null;
      },
      failure: (_) => null,
    );
  }

  static const cantDeleteGivenUnscheduledTitle = "This dose can't be deleted";
  static const cantDeleteGivenUnscheduledBody =
      'It was already given, so it stays on the medication record. '
      'If it was recorded by mistake, use Edit to correct it — the original '
      'stays visible with your reason.';
  static const correctPermissionDenied =
      'Only the person who gave this dose, or a supervisor, can correct it.';
  static const doseNotFound =
      'This dose could not be found. Refresh the page and try again.';

  Future<List<MarOption>> witnessesFor(String residenceId) async {
    if (residenceId.isEmpty) return const [];
    final result = await repository.witnesses(residenceId);
    return result.value ?? const [];
  }

  Future<List<MarOption>> checksFor(String? clientId) async {
    final result = await repository.checkSchedules(clientId: clientId);
    return result.value ?? const [];
  }

  Future<void> export() async {
    if (exporting.value) return;
    exporting.value = true;
    final result = await repository.exportMarCsv();
    final error = await result.when(
      success: (bytes) => saveFile('mar_administrations.csv', bytes),
      failure: (e) async => e.message,
    );
    exporting.value = false;
    AppSnackbar.show(error ?? 'Export ready', '');
  }
}
