import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/daily_logs_repository.dart';

enum DailyLogsTab { review, missing, day, activity }

/// Web `/dashboard/daily-logs`: residence / resident / date filters, the
/// review and missing queues, a resident's day, house activity, shift
/// documentation and the Priority Notes board.
class DailyLogsController extends GetxController {
  final DailyLogsRepository repository;
  final UserSession session;

  DailyLogsController({required this.repository, required this.session});

  static const limitOptions = [10, 25, 50];

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Web opens on Operational Logbook, across every residence.
  final Rx<DailyLogsTab> tab = DailyLogsTab.activity.obs;

  final RxList<DailyLogOption> residences = <DailyLogOption>[].obs;
  final RxList<DailyLogOption> clients = <DailyLogOption>[].obs;
  final RxList<DailyLogOption> staff = <DailyLogOption>[].obs;
  final RxString residenceId = ''.obs;
  final RxString clientId = ''.obs;
  final RxString staffId = ''.obs;
  final RxString from = dayKey(DateTime.now().subtract(const Duration(days: 6))).obs;
  final RxString to = dayKey(DateTime.now()).obs;
  final RxString logDate = dayKey(DateTime.now()).obs;

  final RxInt page = 1.obs;
  final RxInt limit = 20.obs;

  final Rxn<DailyLogPage<DailyLogReviewRow>> review = Rxn();
  final RxBool reviewLoading = false.obs;
  final RxnString reviewError = RxnString();

  final Rxn<DailyLogPage<DailyLogMissingRow>> missing = Rxn();
  final RxBool missingLoading = false.obs;
  final RxnString missingError = RxnString();

  final Rxn<DailyLogPage<ResidenceActivityRow>> activity = Rxn();
  final RxBool activityLoading = false.obs;

  final Rxn<DailyLogDay> day = Rxn();
  final RxBool dayLoading = false.obs;
  final RxnString dayError = RxnString();

  final RxList<DailyLogShiftRow> shiftLogs = <DailyLogShiftRow>[].obs;
  final RxBool shiftLogsLoading = false.obs;
  final RxnString busyShiftId = RxnString();

  final RxList<CareFlag> flags = <CareFlag>[].obs;
  final RxInt flagsTotal = 0.obs;
  final RxBool flagsLoading = false.obs;
  final RxnString flagsError = RxnString();

  int _queueSerial = 0;
  int _daySerial = 0;
  int _activitySerial = 0;
  int _shiftSerial = 0;
  int _flagSerial = 0;
  int _clientSerial = 0;

  bool get canWrite => session.can('daily-logs:write');
  bool get canReview => session.can('daily-logs:review');
  bool get canResolveFlags => session.can('care-flags:resolve');
  bool get canReadFlags => session.can('care-flags:read');
  bool get hasResidence => residenceId.value.isNotEmpty;
  /// Reads the observables before the permission so an `Obx` always subscribes.
  bool get showAddEntry =>
      tab.value == DailyLogsTab.day && clientId.value.isNotEmpty && hasResidence && canWrite;

  String get residenceName => _labelOf(residences, residenceId.value);
  String get staffName => _labelOf(staff, staffId.value);
  /// Falls back to the name from the queue row that opened the day, since
  /// residents outside the user's client scope aren't in [clients].
  String get clientName {
    final label = _labelOf(clients, clientId.value);
    if (label.isNotEmpty) return label;
    final known = _openedClient;
    return known != null && known.$1 == clientId.value ? known.$2 : '';
  }

  (String, String)? _openedClient;

  /// Residence of the day being viewed when the filter is "All residences".
  String? _openedResidence;

  static String _labelOf(List<DailyLogOption> options, String id) =>
      options.firstWhereOrNull((o) => o.id == id)?.label ?? '';

  /// Sum of `entriesCount` on the review page being shown.
  int get entriesLogged =>
      review.value?.items.fold<int>(0, (sum, r) => sum + r.entriesCount) ?? 0;

  /// Paging for whichever list tab is showing.
  (int total, int totalPages) get paging => switch (tab.value) {
        DailyLogsTab.missing => (missing.value?.total ?? 0, missing.value?.totalPages ?? 0),
        DailyLogsTab.activity => (activity.value?.total ?? 0, activity.value?.totalPages ?? 0),
        _ => (review.value?.total ?? 0, review.value?.totalPages ?? 0),
      };

  @override
  void onInit() {
    super.onInit();
    _boot();
  }

  Future<void> _boot() async {
    final homes = await repository.residences();
    homes.when(success: residences.assignAll, failure: (_) {});
    await Future.wait([
      _loadClients(),
      _loadStaff(),
      loadFlags(),
      loadQueues(),
      loadActivity(),
    ]);
  }

  Future<void> _loadStaff() async {
    final result = await repository.staff();
    result.when(success: staff.assignAll, failure: (_) => staff.clear());
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadFlags(),
      loadQueues(),
      if (tab.value == DailyLogsTab.activity) loadActivity(),
      if (hasResidence) loadShiftLogs(),
      if (tab.value == DailyLogsTab.day) loadDay(),
    ]);
  }

  void setTab(DailyLogsTab value) {
    if (tab.value == value) return;
    tab.value = value;
    if (value == DailyLogsTab.activity) loadActivity();
    if (value == DailyLogsTab.day) loadDay();
  }

  /// Changing the residence clears the resident, as the web does.
  /// Empty [id] is "All residences".
  void setResidence(String id) {
    residenceId.value = id;
    clientId.value = '';
    _openedResidence = null;
    clients.clear();
    page.value = 1;
    _loadClients();
    refreshAll();
  }

  void setClient(String id) {
    clientId.value = id;
    if (id.isEmpty) _openedResidence = null;
    page.value = 1;
    loadQueues();
    loadDay();
  }

  /// Empty [id] is "All staff". Only the operational logbook sends it.
  void setStaff(String id) {
    staffId.value = id;
    page.value = 1;
    loadActivity();
  }

  /// A `from` after `to` (or the reverse) collapses both to [value].
  void setFrom(String value) => _setRange(value, to.value, value);

  void setTo(String value) => _setRange(from.value, value, value);

  void _setRange(String nextFrom, String nextTo, String changed) {
    if (nextFrom.compareTo(nextTo) > 0) {
      nextFrom = changed;
      nextTo = changed;
    }
    from.value = nextFrom;
    to.value = nextTo;
    page.value = 1;
    loadQueues();
    if (tab.value == DailyLogsTab.activity) loadActivity();
  }

  void setLogDate(String value) {
    logDate.value = value;
    loadDay();
    loadShiftLogs();
  }

  /// "Open day" / "Write entry": the resident and date, on the day tab.
  void openDay(String client, String date, {String? name, String? residence}) {
    if (name != null && name.isNotEmpty) _openedClient = (client, name);
    if (residence != null && residence.isNotEmpty) _openedResidence = residence;
    clientId.value = client;
    logDate.value = date.length >= 10 ? date.substring(0, 10) : date;
    tab.value = DailyLogsTab.day;
    loadDay();
    loadShiftLogs();
  }

  void setPage(int value) {
    page.value = value;
    tab.value == DailyLogsTab.activity ? loadActivity() : loadQueues();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    tab.value == DailyLogsTab.activity ? loadActivity() : loadQueues();
  }

  Future<void> _loadClients() async {
    final serial = ++_clientSerial;
    final scope = residenceId.value.isEmpty ? null : residenceId.value;
    final result = await repository.clients(scope);
    if (serial != _clientSerial) return;
    result.when(success: clients.assignAll, failure: (_) => clients.clear());
  }

  String? get _dayResidence {
    if (hasResidence) return residenceId.value;
    final opened = _openedResidence;
    if (opened != null && opened.isNotEmpty) return opened;
    return clients.firstWhereOrNull((c) => c.id == clientId.value)?.residenceId;
  }

  String? get _client => clientId.value.isEmpty ? null : clientId.value;

  /// One residence uses the server page. "All residences" asks each home
  /// (the web does the same) and pages the merged list here.
  Future<void> loadQueues() async {
    final ids = hasResidence
        ? [residenceId.value]
        : [for (final home in residences) home.id];
    final serial = ++_queueSerial;
    if (ids.isEmpty) {
      review.value = const DailyLogPage(items: [], total: 0, totalPages: 0);
      missing.value = const DailyLogPage(items: [], total: 0, totalPages: 0);
      reviewError.value = null;
      missingError.value = null;
      return;
    }
    reviewLoading.value = true;
    missingLoading.value = true;
    final wide = ids.length > 1;
    final pageNo = wide ? 1 : page.value;
    final pageSize = wide ? 100 : limit.value;
    final reviewPages = await Future.wait([
      for (final id in ids)
        repository.reviewQueue(
          residenceId: id,
          clientId: _client,
          from: from.value,
          to: to.value,
          page: pageNo,
          limit: pageSize,
        ),
    ]);
    final missingPages = await Future.wait([
      for (final id in ids)
        repository.missing(
          residenceId: id,
          clientId: _client,
          from: from.value,
          to: to.value,
          page: pageNo,
          limit: pageSize,
        ),
    ]);
    if (serial != _queueSerial) return;
    _applyReview(ids, reviewPages, wide);
    _applyMissing(ids, missingPages, wide);
    reviewLoading.value = false;
    missingLoading.value = false;
  }

  void _applyReview(
    List<String> ids,
    List<Result<DailyLogPage<DailyLogReviewRow>>> pages,
    bool wide,
  ) {
    final items = <DailyLogReviewRow>[];
    String? error;
    var ok = false;
    for (var i = 0; i < pages.length; i++) {
      pages[i].when(
        success: (data) {
          ok = true;
          items.addAll([for (final row in data.items) row.atResidence(ids[i])]);
        },
        failure: (failure) => error = failure.message,
      );
    }
    if (!ok) {
      review.value = null;
      reviewError.value = error;
      return;
    }
    if (!wide) {
      final first = pages.first;
      first.when(
        success: (data) {
          review.value = DailyLogPage(
            items: [for (final row in data.items) row.atResidence(ids.first)],
            total: data.total,
            totalPages: data.totalPages,
          );
          reviewError.value = null;
        },
        failure: (_) {},
      );
      return;
    }
    items.sort((a, b) => b.logDate.compareTo(a.logDate));
    review.value = _slice(items);
    reviewError.value = null;
  }

  void _applyMissing(
    List<String> ids,
    List<Result<DailyLogPage<DailyLogMissingRow>>> pages,
    bool wide,
  ) {
    final items = <DailyLogMissingRow>[];
    String? error;
    var ok = false;
    for (var i = 0; i < pages.length; i++) {
      pages[i].when(
        success: (data) {
          ok = true;
          items.addAll([for (final row in data.items) row.atResidence(ids[i])]);
        },
        failure: (failure) => error = failure.message,
      );
    }
    if (!ok) {
      missing.value = null;
      missingError.value = error;
      return;
    }
    if (!wide) {
      pages.first.when(
        success: (data) {
          missing.value = DailyLogPage(
            items: [for (final row in data.items) row.atResidence(ids.first)],
            total: data.total,
            totalPages: data.totalPages,
          );
          missingError.value = null;
        },
        failure: (_) {},
      );
      return;
    }
    items.sort((a, b) => b.logDate.compareTo(a.logDate));
    missing.value = _slice(items);
    missingError.value = null;
  }

  DailyLogPage<T> _slice<T>(List<T> items) {
    final start = (page.value - 1) * limit.value;
    final slice = start >= items.length ? <T>[] : items.skip(start).take(limit.value).toList();
    final pages = items.isEmpty ? 0 : (items.length / limit.value).ceil();
    return DailyLogPage(items: slice, total: items.length, totalPages: pages);
  }

  Future<void> loadActivity() async {
    final serial = ++_activitySerial;
    activityLoading.value = true;
    final result = await repository.activity(
      residenceId: hasResidence ? residenceId.value : null,
      staffId: staffId.value.isEmpty ? null : staffId.value,
      from: from.value,
      to: to.value,
      page: page.value,
      limit: limit.value,
    );
    if (serial != _activitySerial) return;
    result.when(success: (data) => activity.value = data, failure: (_) => activity.value = null);
    activityLoading.value = false;
  }

  Future<void> loadDay() async {
    final residence = _dayResidence;
    if (residence == null || residence.isEmpty || clientId.value.isEmpty) {
      day.value = null;
      return;
    }
    final serial = ++_daySerial;
    dayLoading.value = true;
    final result = await repository.day(
      clientId: clientId.value,
      residenceId: residence,
      logDate: logDate.value,
    );
    if (serial != _daySerial) return;
    result.when(
      success: (data) {
        day.value = data;
        dayError.value = null;
      },
      failure: (error) {
        day.value = null;
        dayError.value = error.message;
      },
    );
    dayLoading.value = false;
  }

  Future<void> loadShiftLogs() async {
    final residence = _dayResidence;
    if (residence == null || residence.isEmpty) {
      shiftLogs.clear();
      return;
    }
    final serial = ++_shiftSerial;
    shiftLogsLoading.value = true;
    final result = await repository.shiftLogs(
      residenceId: residence,
      logDate: logDate.value,
    );
    if (serial != _shiftSerial) return;
    result.when(success: shiftLogs.assignAll, failure: (_) => shiftLogs.clear());
    shiftLogsLoading.value = false;
  }

  Future<void> loadFlags() async {
    if (!canReadFlags) return;
    final serial = ++_flagSerial;
    flagsLoading.value = true;
    final result = await repository.openFlags(hasResidence ? residenceId.value : null);
    if (serial != _flagSerial) return;
    result.when(
      success: (data) {
        flags.assignAll(data.items);
        flagsTotal.value = data.total;
        flagsError.value = null;
      },
      failure: (error) {
        flags.clear();
        flagsTotal.value = 0;
        flagsError.value = error.message;
      },
    );
    flagsLoading.value = false;
  }

  Future<void> _afterEntryChange() => Future.wait([loadDay(), loadQueues(), loadFlags()]);

  /// Throws the API message so the sheet can show it inline.
  Future<void> createEntry(Map<String, dynamic> body) async {
    final result = await repository.createEntry(body);
    if (result.isFailure) throw result.error!.message;
    AppSnackbar.show('Entry added', '');
    _afterEntryChange();
  }

  Future<void> amendEntry(DailyLogEntry entry, String body, String reason) async {
    final result = await repository.amendEntry(entry.id, body: body, reason: reason);
    if (result.isFailure) throw result.error!.message;
    AppSnackbar.show('Correction recorded', '');
    _afterEntryChange();
  }

  Future<void> deleteEntry(DailyLogEntry entry) async {
    final result = await repository.deleteEntry(entry.id);
    if (result.isFailure) {
      AppSnackbar.show(result.error!.message, '');
      return;
    }
    AppSnackbar.show('Entry deleted', '');
    _afterEntryChange();
  }

  Future<void> resolveFlag(CareFlag flag, String note) async {
    final trimmed = note.trim();
    final result = await repository.resolveFlag(flag.id, note: trimmed.isEmpty ? null : trimmed);
    if (result.isFailure) throw result.error!.message;
    AppSnackbar.show('Flag resolved', '');
    loadFlags();
  }

  Future<void> updateShiftLog(
    DailyLogShiftRow row,
    Map<String, dynamic> body,
    String success,
  ) async {
    busyShiftId.value = row.id;
    final result = await repository.updateShiftLog(row.id, body);
    busyShiftId.value = null;
    result.when(
      success: (_) {
        AppSnackbar.show(success, '');
        loadShiftLogs();
      },
      failure: (error) => AppSnackbar.show(error.message, ''),
    );
  }

  Future<DailyLogUpload> upload(String path, String fileName) async {
    final result = await repository.upload(path, fileName);
    if (result.isFailure) throw result.error!.message;
    return result.value!;
  }

  Future<Result<DailyLogEntry>> entry(String id) => repository.entry(id);
}
