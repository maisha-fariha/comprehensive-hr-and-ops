import 'dart:async';
import 'dart:typed_data';

import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/holidays_service.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../domain/entities/hr_appointment.dart';
import '../../domain/entities/hr_outing.dart';
import '../../domain/repositories/hr_appointments_repository.dart';
import '../hr_appointments_labels.dart';

/// Saves the exported CSV; returns an error message or null.
typedef HrAppointmentsFileSaver = Future<String?> Function(
  String fileName,
  List<int> bytes,
);

Future<String?> _saveAndOpen(String fileName, List<int> bytes) async {
  final saved = await MediaStoreDownload.saveFileAndOpen(
    fileName: fileName,
    bytes: Uint8List.fromList(bytes),
    mimeType: 'text/csv',
    chooserTitle: 'Open export',
  );
  return saved.success ? null : saved.error ?? 'Could not save the export.';
}

/// Web `/dashboard/appointments` ("Family Appointments & Approvals"): KPI
/// tiles, queue tabs with counts, search, filters, the paged register and
/// every create / edit / approve / decline / cancel / delete action.
class HrAppointmentsController extends GetxController {
  final HrAppointmentsRepository repository;
  final UserSession session;
  final HrAppointmentsFileSaver saveFile;

  HrAppointmentsController({
    required this.repository,
    UserSession? session,
    HrAppointmentsFileSaver? saveFile,
  })  : session = session ?? Get.find<UserSession>(),
        saveFile = saveFile ?? _saveAndOpen;

  static const List<int> pageSizes = [10, 20, 50];
  static const Duration searchDebounce = Duration(milliseconds: 300);

  final RxList<HrAppointment> items = <HrAppointment>[].obs;
  final RxList<HrOuting> outings = <HrOuting>[].obs;
  final RxInt total = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();
  final Rxn<HrAppointmentSummary> summary = Rxn<HrAppointmentSummary>();

  final RxString tab = 'pending'.obs;
  /// Web Outing requests sub-tab: `pending` (Awaiting decision) or `all`.
  final RxString outingScope = 'pending'.obs;
  final RxString status = ''.obs;
  final RxString type = ''.obs;
  final RxString residenceId = ''.obs;
  final RxString search = ''.obs;
  final RxInt page = 1.obs;
  final RxInt limit = 20.obs;
  final RxBool filtersShown = false.obs;

  final RxList<HrAppointmentOption> residences = <HrAppointmentOption>[].obs;
  final RxList<HrAppointmentClient> clients = <HrAppointmentClient>[].obs;
  final RxnString busyId = RxnString();
  final RxBool exporting = false.obs;

  Timer? _debounce;
  int _serial = 0;

  static const _outingDecideRoles = {
    'tenant_admin',
    'manager',
    'residence_manager',
  };

  bool get canRead => session.can('appointments:read');
  bool get canWrite => session.can('appointments:write');
  bool get canExport => session.can('appointments:export');
  bool get canReadDailyLogs => session.can('daily-logs:read');

  /// Web: assigned-staff picker needs `staff:directory` or `staff:read`.
  bool get canPickStaff => session.canAny(['staff:directory', 'staff:read']);

  // ── Calendar view (web `?view=calendar`) ────────────────────────────────
  final RxString view = 'list'.obs;
  final Rx<DateTime> calendarMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final RxList<HrAppointment> calendarItems = <HrAppointment>[].obs;
  final RxBool calendarLoading = false.obs;
  /// True once a calendar fetch has finished (success or failure), so an
  /// empty month shows the grid instead of a spinner.
  final RxBool calendarLoaded = false.obs;
  final RxBool calendarTruncated = false.obs;
  final RxMap<String, Holiday> holidays = <String, Holiday>{}.obs;
  int _calendarSerial = 0;

  bool get calendarView => view.value == 'calendar';

  String? holidayName(DateTime date) => holidays[HolidaysService.key(date)]?.name;

  void setView(String value) {
    if (view.value == value) return;
    view.value = value;
    if (value == 'calendar') {
      loadCalendar();
    } else {
      load();
    }
  }

  void shiftMonth(int delta) {
    final m = calendarMonth.value;
    calendarMonth.value = DateTime(m.year, m.month + delta, 1);
    loadCalendar();
  }

  void goToThisMonth() {
    final n = DateTime.now();
    calendarMonth.value = DateTime(n.year, n.month, 1);
    loadCalendar();
  }

  /// Month grid window, Sunday-first, as the web builds it.
  (DateTime, DateTime) get calendarWindow {
    final m = calendarMonth.value;
    final first = DateTime(m.year, m.month, 1);
    final last = DateTime(m.year, m.month + 1, 0);
    final start = first.subtract(Duration(days: first.weekday % 7));
    final end = last.add(Duration(days: 6 - (last.weekday % 7)));
    return (start, end);
  }

  Future<void> loadCalendar() async {
    if (!canRead) {
      calendarLoaded.value = true;
      calendarLoading.value = false;
      return;
    }
    final serial = ++_calendarSerial;
    calendarLoading.value = true;
    try {
      final (start, end) = calendarWindow;
      final base = query;
      final listFuture = repository
          .list(
            HrAppointmentQuery(
              page: 1,
              limit: 100,
              status: base.status,
              type: base.type,
              residenceId: base.residenceId,
              search: base.search,
              from: start.subtract(const Duration(days: 1)),
              to: end.add(const Duration(days: 2)),
            ),
          )
          .timeout(const Duration(seconds: 25));
      final holidayFuture = HolidaysService.fetch(
        from: start,
        to: end,
        residenceId: residenceId.value.isEmpty ? null : residenceId.value,
      ).timeout(const Duration(seconds: 10), onTimeout: () => const {});
      final result = await listFuture;
      final holidayMap = await holidayFuture;
      if (serial != _calendarSerial) return;
      result.when(
        success: (data) {
          calendarItems.assignAll(data.items);
          calendarTruncated.value = data.total > data.items.length;
          loadError.value = null;
        },
        failure: (error) {
          calendarItems.clear();
          calendarTruncated.value = false;
          loadError.value = error.message;
        },
      );
      holidays.assignAll(holidayMap);
    } catch (_) {
      if (serial != _calendarSerial) return;
      calendarItems.clear();
      loadError.value = 'Could not load the calendar. Pull to retry.';
    } finally {
      if (serial == _calendarSerial) {
        calendarLoaded.value = true;
        calendarLoading.value = false;
      }
    }
  }

  /// Appointments on [day], earliest first.
  List<HrAppointment> calendarOn(DateTime day) {
    final rows = [
      for (final a in calendarItems)
        if (a.scheduledAt != null &&
            a.scheduledAt!.toLocal().year == day.year &&
            a.scheduledAt!.toLocal().month == day.month &&
            a.scheduledAt!.toLocal().day == day.day)
          a,
    ]..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    return rows;
  }

  final RxList<HrAppointmentOption> staffOptions = <HrAppointmentOption>[].obs;
  final RxBool staffLoading = false.obs;

  Future<void> loadStaffOptions(String? residenceId) async {
    if (!canPickStaff) return;
    staffLoading.value = true;
    final result = await repository.staffOptions(residenceId: residenceId);
    result.when(success: staffOptions.assignAll, failure: (_) {});
    staffLoading.value = false;
  }

  /// Web: approve/decline outings only for management roles (+ `appointments:write`).
  bool get canDecideOutings {
    if (!canWrite) return false;
    if (session.permissions.contains('*')) return true;
    final raw = (session.roleRaw ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');
    return _outingDecideRoles.contains(raw);
  }

  bool get showingOutings => HrAppointmentsLabels.isOutingsTab(tab.value);

  bool get hasActiveFilters =>
      status.value.isNotEmpty || type.value.isNotEmpty || residenceId.value.isNotEmpty;

  /// Counts shown on the tabs; family / external carry none on the web.
  Map<String, int> get tabCounts {
    final s = summary.value;
    if (s == null) return const {};
    return {
      'pending': s.pending,
      'approved': s.approved,
      'closed': s.rejected,
      'all': s.total,
    };
  }

  HrAppointmentQuery get query {
    final t = HrAppointmentsLabels.tabs.firstWhere(
      (t) => t.id == tab.value,
      orElse: () => HrAppointmentsLabels.tabs.first,
    );
    return HrAppointmentQuery(
      page: page.value,
      limit: limit.value,
      status: status.value.isNotEmpty ? status.value : t.status,
      type: type.value.isNotEmpty ? type.value : t.type,
      residenceId: residenceId.value,
      search: search.value,
    );
  }

  @override
  void onInit() {
    super.onInit();
    if (!canRead) {
      loading.value = false;
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

  Future<void> refreshAll() =>
      Future.wait([calendarView ? loadCalendar() : load(), loadSummary()]);

  Future<void> load() async {
    if (calendarView && !showingOutings) {
      await loadCalendar();
      return;
    }
    if (showingOutings) {
      await loadOutings();
      return;
    }
    final serial = ++_serial;
    loading.value = true;
    final result = await repository.list(query);
    if (serial != _serial) return;
    result.when(
      success: (data) {
        items.assignAll(data.items);
        outings.clear();
        total.value = data.total;
        totalPages.value = data.totalPages;
        loadError.value = null;
      },
      failure: (error) {
        items.clear();
        outings.clear();
        total.value = 0;
        totalPages.value = 0;
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  Future<void> loadOutings() async {
    final serial = ++_serial;
    loading.value = true;
    final result = await repository.listOutings(
      HrOutingQuery(
        page: 1,
        limit: 50,
        status: outingScope.value == 'pending' ? 'pending' : null,
        residenceId: residenceId.value,
      ),
    );
    if (serial != _serial) return;
    result.when(
      success: (data) {
        outings.assignAll(data.items);
        items.clear();
        total.value = data.total;
        totalPages.value = data.totalPages;
        loadError.value = null;
      },
      failure: (error) {
        outings.clear();
        items.clear();
        total.value = 0;
        totalPages.value = 0;
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  Future<void> loadSummary() async {
    final result = await repository.summary();
    result.when(success: (s) => summary.value = s, failure: (_) {});
  }

  Future<void> loadOptions() async {
    final (homes, people) = await (repository.residences(), repository.clients()).wait;
    homes.when(success: residences.assignAll, failure: (_) {});
    people.when(success: clients.assignAll, failure: (_) {});
  }

  /// Switching tab drops the status / type filters, like the web.
  void setTab(String id) {
    tab.value = id;
    status.value = '';
    type.value = '';
    page.value = 1;
    if (HrAppointmentsLabels.isOutingsTab(id)) {
      outingScope.value = 'pending';
    }
    load();
  }

  void setOutingScope(String scope) {
    if (outingScope.value == scope) return;
    outingScope.value = scope;
    loadOutings();
  }

  void setFilter(String key, String value) {
    switch (key) {
      case 'status':
        status.value = value;
      case 'type':
        type.value = value;
      case 'residenceId':
        residenceId.value = value;
    }
    page.value = 1;
    load();
  }

  void clearFilters() {
    _debounce?.cancel();
    search.value = '';
    status.value = '';
    type.value = '';
    residenceId.value = '';
    tab.value = 'pending';
    page.value = 1;
    load();
  }

  void toggleFilters() => filtersShown.toggle();

  void setSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      if (search.value == text.trim()) return;
      search.value = text.trim();
      page.value = 1;
      load();
    });
  }

  void setPage(int value) {
    page.value = value;
    load();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    load();
  }

  Future<String?> _run(
    String id,
    Future<Result<void>> Function() action,
    String success, {
    bool toastErrors = true,
  }) async {
    busyId.value = id;
    final result = await action();
    busyId.value = null;
    return result.when(
      success: (_) {
        AppSnackbar.show(success, '');
        refreshAll();
        return null;
      },
      failure: (error) {
        if (toastErrors) AppSnackbar.show(error.message, '');
        return error.message;
      },
    );
  }

  Future<String?> approve(HrAppointment a) => _run(
        a.id,
        () => repository.approve(a.id),
        'Visit approved — the family can see it',
      );

  /// Approve or decline an outing. Decline requires [notes] (web validation).
  Future<String?> decideOuting(
    HrOuting outing, {
    required bool approve,
    String? notes,
  }) {
    final text = notes?.trim() ?? '';
    if (!approve && text.isEmpty) {
      return Future.value('Say why — the family reads this.');
    }
    return _run(
      outing.id,
      () => repository.decideOuting(
        outing.id,
        decision: approve ? 'approved' : 'declined',
        notes: text.isEmpty ? null : text,
      ),
      approve
          ? 'Outing approved — the family has been told'
          : 'Outing declined — the family has been told',
      toastErrors: false,
    );
  }

  /// Decline (reject) or cancel with an optional reason. Errors are shown
  /// inside the reason dialog, so they are returned rather than toasted.
  Future<String?> decide(HrAppointment a, {required bool reject, String? reason}) {
    final text = reason?.trim();
    final r = text == null || text.isEmpty ? null : text;
    return reject
        ? _run(
            a.id,
            () => repository.reject(a.id, reason: r),
            'Visit declined — the family has been told',
            toastErrors: false,
          )
        : _run(
            a.id,
            () => repository.cancel(a.id, reason: r),
            'Appointment cancelled',
            toastErrors: false,
          );
  }

  Future<String?> delete(HrAppointment a) => _run(
        a.id,
        () => repository.delete(a.id),
        'Appointment deleted',
      );

  /// Creates, proposes a new time (pending family visit) or updates. Returns
  /// the error for the form's banner.
  Future<String?> save(HrAppointmentInput input, {HrAppointment? editing}) {
    if (editing == null) {
      return _run(
        '',
        () => repository.create(input),
        input.type == 'family_visit'
            ? 'Visit request created — it is pending approval'
            : 'Appointment booked',
        toastErrors: false,
      );
    }
    if (editing.isDecidable) {
      return _run(
        editing.id,
        () => repository.reschedule(editing.id, input),
        'A new time was proposed to the family',
        toastErrors: false,
      );
    }
    return _run(
      editing.id,
      () => repository.update(editing.id, input),
      'Appointment updated',
      toastErrors: false,
    );
  }

  /// Today's notes for the "Recent Daily Log Context" panel; null when the
  /// signed-in user cannot read daily logs.
  Future<Result<List<HrAppointmentLogNote>>?> dayLog(
    String clientId,
    String residenceId,
  ) async {
    if (!canReadDailyLogs || clientId.isEmpty || residenceId.isEmpty) return null;
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return repository.dayLog(
      clientId: clientId,
      residenceId: residenceId,
      logDate: '${now.year}-${two(now.month)}-${two(now.day)}',
    );
  }

  Future<void> export() async {
    if (exporting.value) return;
    exporting.value = true;
    final result = await repository.exportCsv();
    final error = await result.when(
      success: (bytes) => saveFile('appointment_log.csv', bytes),
      failure: (e) async => e.message,
    );
    exporting.value = false;
    AppSnackbar.show(error ?? 'Export ready', '');
  }
}
