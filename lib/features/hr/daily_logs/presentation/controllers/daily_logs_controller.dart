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

  final Rx<DailyLogsTab> tab = DailyLogsTab.review.obs;

  final RxList<DailyLogOption> residences = <DailyLogOption>[].obs;
  final RxList<DailyLogOption> clients = <DailyLogOption>[].obs;
  final RxString residenceId = ''.obs;
  final RxString clientId = ''.obs;
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
  /// Falls back to the name from the queue row that opened the day, since
  /// residents outside the user's client scope aren't in [clients].
  String get clientName {
    final label = _labelOf(clients, clientId.value);
    if (label.isNotEmpty) return label;
    final known = _openedClient;
    return known != null && known.$1 == clientId.value ? known.$2 : '';
  }

  (String, String)? _openedClient;

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
    repository.residences().then((r) => r.when(success: residences.assignAll, failure: (_) {}));
    loadFlags();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadFlags(),
      if (hasResidence) ...[
        loadQueues(),
        loadShiftLogs(),
        if (tab.value == DailyLogsTab.activity) loadActivity(),
        if (tab.value == DailyLogsTab.day) loadDay(),
      ],
    ]);
  }

  void setTab(DailyLogsTab value) {
    if (tab.value == value) return;
    tab.value = value;
    if (value == DailyLogsTab.activity) loadActivity();
    if (value == DailyLogsTab.day) loadDay();
  }

  /// Changing the residence clears the resident, as the web does.
  void setResidence(String id) {
    residenceId.value = id;
    clientId.value = '';
    clients.clear();
    page.value = 1;
    _loadClients();
    refreshAll();
  }

  void setClient(String id) {
    clientId.value = id;
    page.value = 1;
    loadQueues();
    loadDay();
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
  void openDay(String client, String date, {String? name}) {
    if (name != null && name.isNotEmpty) _openedClient = (client, name);
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
    final result = await repository.clients(residenceId.value);
    if (serial != _clientSerial) return;
    result.when(success: clients.assignAll, failure: (_) => clients.clear());
  }

  String? get _client => clientId.value.isEmpty ? null : clientId.value;

  Future<void> loadQueues() async {
    if (!hasResidence) return;
    final serial = ++_queueSerial;
    reviewLoading.value = true;
    missingLoading.value = true;
    final results = await Future.wait([
      repository.reviewQueue(
        residenceId: residenceId.value,
        clientId: _client,
        from: from.value,
        to: to.value,
        page: page.value,
        limit: limit.value,
      ),
      repository.missing(
        residenceId: residenceId.value,
        clientId: _client,
        from: from.value,
        to: to.value,
        page: page.value,
        limit: limit.value,
      ),
    ]);
    if (serial != _queueSerial) return;
    (results[0] as Result<DailyLogPage<DailyLogReviewRow>>).when(
      success: (data) {
        review.value = data;
        reviewError.value = null;
      },
      failure: (error) {
        review.value = null;
        reviewError.value = error.message;
      },
    );
    (results[1] as Result<DailyLogPage<DailyLogMissingRow>>).when(
      success: (data) {
        missing.value = data;
        missingError.value = null;
      },
      failure: (error) {
        missing.value = null;
        missingError.value = error.message;
      },
    );
    reviewLoading.value = false;
    missingLoading.value = false;
  }

  Future<void> loadActivity() async {
    if (!hasResidence) return;
    final serial = ++_activitySerial;
    activityLoading.value = true;
    final result = await repository.activity(
      residenceId: residenceId.value,
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
    if (!hasResidence || clientId.value.isEmpty) {
      day.value = null;
      return;
    }
    final serial = ++_daySerial;
    dayLoading.value = true;
    final result = await repository.day(
      clientId: clientId.value,
      residenceId: residenceId.value,
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
    if (!hasResidence) return;
    final serial = ++_shiftSerial;
    shiftLogsLoading.value = true;
    final result = await repository.shiftLogs(
      residenceId: residenceId.value,
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
