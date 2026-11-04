import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/daily_logs_repository.dart';

/// Web `/dashboard/daily-logs` top tabs.
enum DailyLogsTab { today, review, activities }

/// Resident list chips on the Today board.
enum DailyLogsResidentFilter { all, owed, flagged }

/// Web `/dashboard/daily-logs`: Today board, Review, Activities, and the
/// resident-day drill-down (care note + feed + AI).
class DailyLogsController extends GetxController {
  final DailyLogsRepository repository;
  final UserSession session;

  DailyLogsController({required this.repository, required this.session});

  static const limitOptions = [10, 25, 50];

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final Rx<DailyLogsTab> tab = DailyLogsTab.today.obs;
  final Rx<DailyLogsResidentFilter> residentFilter = DailyLogsResidentFilter.all.obs;
  final RxString residentQuery = ''.obs;

  final RxList<DailyLogOption> residences = <DailyLogOption>[].obs;
  final RxList<DailyLogOption> clients = <DailyLogOption>[].obs;
  final RxList<DailyLogOption> staff = <DailyLogOption>[].obs;
  final RxString residenceId = ''.obs;
  final RxString clientId = ''.obs;
  final RxString staffId = ''.obs;
  final RxString from = dayKey(DateTime.now()).obs;
  final RxString to = dayKey(DateTime.now()).obs;
  final RxString logDate = dayKey(DateTime.now()).obs;

  final RxInt page = 1.obs;
  final RxInt limit = 20.obs;

  final Rxn<DailyLogBoard> board = Rxn();
  final RxBool boardLoading = false.obs;
  final RxnString boardError = RxnString();

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

  final Rxn<DailyActivityFeed> feed = Rxn();
  final RxBool feedLoading = false.obs;
  final RxnString feedError = RxnString();
  final RxString feedFilter = 'all'.obs;

  final RxList<DailyLogShiftRow> shiftLogs = <DailyLogShiftRow>[].obs;
  final RxBool shiftLogsLoading = false.obs;
  final RxnString busyShiftId = RxnString();

  final RxList<CareFlag> flags = <CareFlag>[].obs;
  final RxInt flagsTotal = 0.obs;
  final RxBool flagsLoading = false.obs;
  final RxnString flagsError = RxnString();

  int _queueSerial = 0;
  int _daySerial = 0;
  int _feedSerial = 0;
  int _activitySerial = 0;
  int _shiftSerial = 0;
  int _flagSerial = 0;
  int _clientSerial = 0;
  int _boardSerial = 0;

  /// Web Daily Logs role group (5 keys):
  /// - `daily-logs:read` — module access (nav / PermissionGate)
  /// - `daily-logs:write` — care notes, complete shift docs
  /// - `daily-logs:review` — Review tab + shift sign-off
  /// - `care-flags:read` — open flags list / Review badge
  /// - `care-flags:resolve` — Clear a flag
  bool get canWrite => session.can('daily-logs:write');
  bool get canReview => session.can('daily-logs:review');
  bool get canResolveFlags => session.can('care-flags:resolve');
  bool get canReadFlags => session.can('care-flags:read');
  bool get canRecordActivity => session.can('client-activities:write');
  bool get canReadActivities => session.can('client-activities:read');
  bool get hasResidence => residenceId.value.isNotEmpty;
  bool get viewingResidentDay => clientId.value.isNotEmpty;

  String? get dayResidenceId => _dayResidence;
  String get dayResidenceName {
    final id = dayResidenceId;
    if (id == null || id.isEmpty) return '';
    return _labelOf(residences, id);
  }

  bool get showAddEntry => viewingResidentDay && canWrite;

  bool get canOpenCareNote {
    final hasClient = clientId.value.isNotEmpty;
    final residence = dayResidenceId;
    return canWrite &&
        hasClient &&
        residence != null &&
        residence.isNotEmpty;
  }

  bool get showRecordActivity => canRecordActivity;

  String get residenceName => _labelOf(residences, residenceId.value);
  String get staffName => _labelOf(staff, staffId.value);
  String get clientName {
    final label = _labelOf(clients, clientId.value);
    if (label.isNotEmpty) return label;
    final known = _openedClient;
    if (known != null && known.$1 == clientId.value) return known.$2;
    final onBoard = board.value?.residents
        .firstWhereOrNull((r) => r.clientId == clientId.value);
    return onBoard?.name ?? '';
  }

  String? get clientRoom {
    final onBoard = board.value?.residents
        .firstWhereOrNull((r) => r.clientId == clientId.value);
    return onBoard?.room;
  }

  (String, String)? _openedClient;
  String? _openedResidence;

  static String _labelOf(List<DailyLogOption> options, String id) =>
      options.firstWhereOrNull((o) => o.id == id)?.label ?? '';

  int get entriesLogged =>
      review.value?.items.fold<int>(0, (sum, r) => sum + r.entriesCount) ?? 0;

  (int total, int totalPages) get paging => switch (tab.value) {
        DailyLogsTab.activities => (
            activity.value?.total ?? 0,
            activity.value?.totalPages ?? 0,
          ),
        DailyLogsTab.review => (
            review.value?.total ?? 0,
            review.value?.totalPages ?? 0,
          ),
        DailyLogsTab.today => (0, 0),
      };

  List<DailyLogBoardResident> get filteredResidents {
    final rows = board.value?.residents ?? const <DailyLogBoardResident>[];
    final q = residentQuery.value.trim().toLowerCase();
    return [
      for (final r in rows)
        if (_matchesResidentFilter(r) &&
            (q.isEmpty ||
                r.name.toLowerCase().contains(q) ||
                (r.room?.toLowerCase().contains(q) ?? false)))
          r,
    ];
  }

  bool _matchesResidentFilter(DailyLogBoardResident r) => switch (residentFilter.value) {
        DailyLogsResidentFilter.all => true,
        DailyLogsResidentFilter.owed => r.gaps.isNotEmpty || r.notes == 0,
        DailyLogsResidentFilter.flagged => r.flags.isNotEmpty,
      };

  int countFor(DailyLogsResidentFilter filter) {
    final rows = board.value?.residents ?? const <DailyLogBoardResident>[];
    return switch (filter) {
      DailyLogsResidentFilter.all => rows.length,
      DailyLogsResidentFilter.owed =>
        rows.where((r) => r.gaps.isNotEmpty || r.notes == 0).length,
      DailyLogsResidentFilter.flagged => rows.where((r) => r.flags.isNotEmpty).length,
    };
  }

  DailyLogBoardResident? get selectedBoardResident => board.value?.residents
      .firstWhereOrNull((r) => r.clientId == clientId.value);

  int get notesWrittenToday => day.value?.entries
          .where((e) => e.source != 'system' && e.logType != 'medication')
          .length ??
      0;

  int get dosesRecordedToday =>
      feed.value?.counts['mar'] ??
      day.value?.entries.where((e) => e.logType == 'medication').length ??
      0;

  int get checksDoneToday =>
      feed.value?.counts['recurringChecks'] ?? day.value?.checks.length ?? 0;

  int get openFlagsForResident => selectedBoardResident?.flags.length ?? 0;

  @override
  void onInit() {
    super.onInit();
    _boot();
  }

  Future<void> _boot() async {
    final homes = await repository.residences();
    homes.when(success: residences.assignAll, failure: (_) {});
    // Prefer a concrete home when only one is in scope (common for staff /
    // single-home tenants). Managers with several homes start unscoped until
    // they pick — matching the web "Choose a home" empty board.
    if (residenceId.value.isEmpty && residences.length == 1) {
      residenceId.value = residences.first.id;
    }
    await Future.wait([
      _loadClients(),
      _loadStaff(),
      loadFlags(),
      loadBoard(),
      loadQueues(),
    ]);
  }

  Future<void> _loadStaff() async {
    final result = await repository.staff();
    result.when(success: staff.assignAll, failure: (_) => staff.clear());
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadFlags(),
      loadBoard(),
      loadQueues(),
      if (tab.value == DailyLogsTab.activities) loadActivity(),
      if (hasResidence) loadShiftLogs(),
      if (viewingResidentDay) ...[loadDay(), loadFeed()],
    ]);
  }

  void setTab(DailyLogsTab value) {
    if (value == DailyLogsTab.review && !canReview) return;
    if (value == DailyLogsTab.activities && !canReadActivities) return;
    if (tab.value == value) return;
    tab.value = value;
    clientId.value = '';
    _openedClient = null;
    if (value == DailyLogsTab.activities) loadActivity();
    if (value == DailyLogsTab.today) loadBoard();
    if (value == DailyLogsTab.review) {
      // Web Review: sign-off queue is the last 7 days ending on the board date.
      _alignReviewRange();
      loadQueues();
      loadFlags();
      loadShiftLogs();
      loadBoard();
      loadActivity();
    }
  }

  /// Web `Waiting for sign-off` window: board date and the six days before it.
  void _alignReviewRange() {
    final end = DateTime.tryParse(logDate.value) ?? DateTime.now();
    final start = end.subtract(const Duration(days: 6));
    from.value = dayKey(start);
    to.value = dayKey(end);
  }

  void setResidence(String id) {
    residenceId.value = id;
    clientId.value = '';
    _openedResidence = null;
    clients.clear();
    page.value = 1;
    residentQuery.value = '';
    _loadClients();
    refreshAll();
  }

  void setClient(String id) {
    clientId.value = id;
    if (id.isEmpty) {
      _openedResidence = null;
      day.value = null;
      feed.value = null;
      return;
    }
    final home = clients.firstWhereOrNull((c) => c.id == id)?.residenceId;
    if (home != null && home.isNotEmpty) {
      _openedResidence = home;
      if (residenceId.value.isEmpty) residenceId.value = home;
    }
    page.value = 1;
    loadDay();
    loadFeed();
    loadShiftLogs();
  }

  void setStaff(String id) {
    staffId.value = id;
    page.value = 1;
    loadActivity();
  }

  /// Care-given staff filter on Review (same `/residence-activity` feed).
  Future<void> pickCareGivenStaff(String id) async {
    setStaff(id);
  }

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
    if (tab.value == DailyLogsTab.activities) loadActivity();
  }

  void setLogDate(String value) {
    logDate.value = value;
    from.value = value;
    to.value = value;
    loadBoard();
    loadDay();
    loadFeed();
    loadShiftLogs();
    loadQueues();
  }

  void shiftLogDate(int days) {
    final current = DateTime.tryParse(logDate.value) ?? DateTime.now();
    final next = current.add(Duration(days: days));
    setLogDate(dayKey(next));
  }

  void setResidentFilter(DailyLogsResidentFilter value) {
    residentFilter.value = value;
  }

  void setResidentQuery(String value) {
    residentQuery.value = value;
  }

  void setFeedFilter(String value) {
    feedFilter.value = value;
  }

  /// Open resident day from the Today board / Review rows.
  void openDay(String client, String date, {String? name, String? residence}) {
    if (name != null && name.isNotEmpty) _openedClient = (client, name);
    if (residence != null && residence.isNotEmpty) {
      _openedResidence = residence;
      if (residenceId.value.isEmpty) residenceId.value = residence;
    }
    clientId.value = client;
    logDate.value = date.length >= 10 ? date.substring(0, 10) : date;
    tab.value = DailyLogsTab.today;
    loadDay();
    loadFeed();
    loadShiftLogs();
    loadBoard();
  }

  void backToToday() {
    clientId.value = '';
    _openedClient = null;
    day.value = null;
    feed.value = null;
    feedFilter.value = 'all';
    loadBoard();
  }

  void setPage(int value) {
    page.value = value;
    tab.value == DailyLogsTab.activities ? loadActivity() : loadQueues();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    tab.value == DailyLogsTab.activities ? loadActivity() : loadQueues();
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

  Future<void> loadBoard() async {
    final residence = residenceId.value;
    if (residence.isEmpty) {
      board.value = null;
      boardError.value = null;
      return;
    }
    final serial = ++_boardSerial;
    boardLoading.value = true;
    final result = await repository.board(
      residenceId: residence,
      date: logDate.value,
    );
    if (serial != _boardSerial) return;
    result.when(
      success: (data) {
        board.value = data;
        boardError.value = null;
      },
      failure: (error) {
        board.value = null;
        boardError.value = error.message;
      },
    );
    boardLoading.value = false;
  }

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
          clientId: null,
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
          clientId: null,
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
    final slice =
        start >= items.length ? <T>[] : items.skip(start).take(limit.value).toList();
    final pages = items.isEmpty ? 0 : (items.length / limit.value).ceil();
    return DailyLogPage(items: slice, total: items.length, totalPages: pages);
  }

  Future<void> loadActivity() async {
    final serial = ++_activitySerial;
    activityLoading.value = true;
    // Review "Care given" is the selected board day only; Activities keeps
    // the filter range. Sign-off uses a 7-day `from`/`to` that must not widen
    // this feed.
    final dayScoped = tab.value == DailyLogsTab.review;
    final result = await repository.activity(
      residenceId: hasResidence ? residenceId.value : null,
      staffId: staffId.value.isEmpty ? null : staffId.value,
      from: dayScoped ? logDate.value : from.value,
      to: dayScoped ? logDate.value : to.value,
      page: page.value,
      limit: limit.value,
    );
    if (serial != _activitySerial) return;
    result.when(
      success: (data) => activity.value = data,
      failure: (_) => activity.value = null,
    );
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

  Future<void> loadFeed() async {
    if (clientId.value.isEmpty) {
      feed.value = null;
      return;
    }
    if (!canReadActivities && !canWrite) {
      // Feed is optional enrichment; day timeline still works.
      return;
    }
    final serial = ++_feedSerial;
    feedLoading.value = true;
    final result = await repository.activityFeed(
      clientId: clientId.value,
      date: logDate.value,
    );
    if (serial != _feedSerial) return;
    result.when(
      success: (data) {
        feed.value = data;
        feedError.value = null;
      },
      failure: (error) {
        feed.value = null;
        feedError.value = error.message;
      },
    );
    feedLoading.value = false;
  }

  Future<void> loadShiftLogs() async {
    final residence = _dayResidence ?? (hasResidence ? residenceId.value : null);
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
    final result =
        await repository.openFlags(hasResidence ? residenceId.value : null);
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

  Future<void> _afterEntryChange() => Future.wait([
        loadDay(),
        loadFeed(),
        loadBoard(),
        loadQueues(),
        loadFlags(),
      ]);

  Future<void> createEntry(Map<String, dynamic> body) async {
    final result = await repository.createEntry(body);
    if (result.isFailure) throw result.error!.message;
    AppSnackbar.show('Note saved', '');
    await _afterEntryChange();
  }

  Future<void> amendEntry(DailyLogEntry entry, String body, String reason) async {
    final result =
        await repository.amendEntry(entry.id, body: body, reason: reason);
    if (result.isFailure) throw result.error!.message;
    AppSnackbar.show('Correction recorded', '');
    await _afterEntryChange();
  }

  Future<void> deleteEntry(DailyLogEntry entry) async {
    final result = await repository.deleteEntry(entry.id);
    if (result.isFailure) {
      AppSnackbar.show(result.error!.message, '');
      return;
    }
    AppSnackbar.show('Entry deleted', '');
    await _afterEntryChange();
  }

  Future<void> resolveFlag(CareFlag flag, String note) async {
    final trimmed = note.trim();
    final result =
        await repository.resolveFlag(flag.id, note: trimmed.isEmpty ? null : trimmed);
    if (result.isFailure) throw result.error!.message;
    AppSnackbar.show('Flag resolved', '');
    await Future.wait([loadFlags(), loadBoard()]);
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
        loadQueues();
        loadBoard();
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
