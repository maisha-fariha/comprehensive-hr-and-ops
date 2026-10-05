import 'dart:async';
import 'dart:io';

import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_activity.dart';
import '../../domain/repositories/daily_activity_repository.dart';
import '../daily_activity_labels.dart';

enum DailyActivityTab { registry, history }

/// Web `/dashboard/daily-activity`: KPI tiles, the filtered registry,
/// the resident month history and record / edit / review / delete.
class DailyActivityController extends GetxController {
  final DailyActivityRepository repository;
  final UserSession session;
  final DateTime Function() _now;

  DailyActivityController({
    required this.repository,
    UserSession? session,
    DateTime Function()? now,
  })  : session = session ?? Get.find<UserSession>(),
        _now = now ?? DateTime.now;

  static const List<int> pageSizes = [10, 25, 50];
  static const int historyLimit = 100;

  final Rx<DailyActivityTab> tab = DailyActivityTab.registry.obs;

  final RxString search = ''.obs;
  final RxnString clientId = RxnString();
  final RxnString staffId = RxnString();
  final RxnString activityType = RxnString();
  final RxnString range = RxnString();
  final RxnString status = RxnString();
  final RxInt page = 1.obs;
  final RxInt limit = pageSizes.first.obs;

  final RxList<DailyActivity> items = <DailyActivity>[].obs;
  final RxInt total = 0.obs;
  final RxInt totalPages = 0.obs;
  final Rx<DailyActivityStats> stats = const DailyActivityStats().obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();

  final RxList<DailyActivityOption> clients = <DailyActivityOption>[].obs;
  final RxList<DailyActivityOption> staff = <DailyActivityOption>[].obs;

  final RxnString historyClientId = RxnString();
  late final RxString historyMonth = DailyActivityLabels.month(_now()).obs;
  final RxList<DailyActivity> historyItems = <DailyActivity>[].obs;
  final RxBool historyLoading = false.obs;
  final Rxn<DailyActivityMonthSummary> monthSummary = Rxn<DailyActivityMonthSummary>();
  final RxnString monthSummaryError = RxnString();
  final RxInt historyPage = 1.obs;
  final RxInt historyPageSize = pageSizes.first.obs;

  final RxBool busy = false.obs;

  Timer? _debounce;
  int _serial = 0;
  int _historySerial = 0;

  bool get canWrite => session.can('client-activities:write');

  DailyActivityOption? get historyClient =>
      clients.firstWhereOrNull((c) => c.id == historyClientId.value);

  @override
  void onInit() {
    super.onInit();
    loadOptions();
    load();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> refreshAll() => Future.wait([load(), loadHistory()]);

  Future<void> loadOptions() async {
    final results = await Future.wait([repository.clients(), repository.staff()]);
    results[0].when(success: clients.assignAll, failure: (_) {});
    results[1].when(success: staff.assignAll, failure: (_) {});
  }

  Future<void> load() async {
    final serial = ++_serial;
    loading.value = true;
    final (from, to) = DailyActivityLabels.range(range.value, _now());
    final result = await repository.list(
      page: page.value,
      limit: limit.value,
      search: search.value,
      clientId: clientId.value,
      recordedByStaffId: staffId.value,
      activityType: activityType.value,
      status: status.value,
      from: from,
      to: to,
    );
    if (serial != _serial) return;
    result.when(
      success: (data) {
        items.assignAll(data.items);
        total.value = data.total;
        totalPages.value = data.totalPages;
        stats.value = data.stats;
        loadError.value = null;
      },
      failure: (error) {
        items.clear();
        total.value = 0;
        totalPages.value = 0;
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  void selectTab(DailyActivityTab value) => tab.value = value;

  void setSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (search.value == value) return;
      search.value = value;
      page.value = 1;
      load();
    });
  }

  void _filter(RxnString target, String? value) {
    target.value = value == null || value.isEmpty ? null : value;
    page.value = 1;
    load();
  }

  void setClient(String? value) => _filter(clientId, value);
  void setStaff(String? value) => _filter(staffId, value);
  void setType(String? value) => _filter(activityType, value);
  void setRange(String? value) => _filter(range, value);
  void setStatus(String? value) => _filter(status, value);

  void setPage(int value) {
    page.value = value;
    load();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    load();
  }

  Future<void> loadHistory() async {
    final client = historyClientId.value;
    final serial = ++_historySerial;
    if (client == null) {
      historyItems.clear();
      monthSummary.value = null;
      monthSummaryError.value = null;
      historyLoading.value = false;
      return;
    }
    historyLoading.value = true;
    final month = historyMonth.value;
    final (from, to) = DailyActivityLabels.monthBounds(month);
    final results = await Future.wait([
      repository.list(page: 1, limit: historyLimit, clientId: client, from: from, to: to),
      repository.monthSummary(clientId: client, month: month),
    ]);
    if (serial != _historySerial) return;
    (results[0] as Result<DailyActivityListResult>).when(
      success: (data) => historyItems.assignAll(data.items),
      failure: (_) => historyItems.clear(),
    );
    (results[1] as Result<DailyActivityMonthSummary>).when(
      success: (data) {
        monthSummary.value = data;
        monthSummaryError.value = null;
      },
      failure: (error) {
        monthSummary.value = null;
        monthSummaryError.value = error.message;
      },
    );
    historyLoading.value = false;
  }

  void setHistoryClient(String? value) {
    historyClientId.value = value == null || value.isEmpty ? null : value;
    historyPage.value = 1;
    loadHistory();
  }

  void setHistoryMonth(String value) {
    historyMonth.value = value;
    historyPage.value = 1;
    loadHistory();
  }

  void setHistoryPage(int value) => historyPage.value = value;

  void setHistoryPageSize(int value) {
    historyPageSize.value = value;
    historyPage.value = 1;
  }

  /// Uploads [file] first, keeps existing attachments on edit, then saves.
  /// Returns the message the form shows, or null on success.
  Future<String?> save(
    DailyActivityDraft draft, {
    DailyActivityLocalFile? file,
    DailyActivity? editing,
  }) async {
    final uploaded = <DailyActivityAttachment>[];
    if (file != null) {
      final result = await repository.upload(file);
      final error = result.when(
        success: (url) {
          uploaded.add(DailyActivityAttachment(fileUrl: url, fileType: file.name));
          return null;
        },
        failure: (e) => _message(e),
      );
      if (error != null) return error;
    }
    final body = draft.withAttachments([
      ...?editing?.attachments,
      ...uploaded,
    ]);
    final result = editing == null
        ? await repository.create(body)
        : await repository.update(editing.id, body);
    return result.when(
      success: (_) {
        AppSnackbar.show(editing == null ? 'Activity recorded' : 'Activity updated', '');
        refreshAll();
        return null;
      },
      failure: _message,
    );
  }

  Future<void> delete(DailyActivity activity) async {
    final result = await repository.delete(activity.id);
    result.when(
      success: (_) {
        AppSnackbar.show('Activity record deleted', '');
        refreshAll();
      },
      failure: (error) => AppSnackbar.show(_message(error), ''),
    );
  }

  Future<bool> markReviewed(DailyActivity activity) async {
    busy.value = true;
    final result = await repository.markReviewed(activity.id);
    busy.value = false;
    return result.when(
      success: (_) {
        AppSnackbar.show('Marked reviewed', '');
        refreshAll();
        return true;
      },
      failure: (error) {
        AppSnackbar.show(_message(error), '');
        return false;
      },
    );
  }

  Future<void> openAttachment(DailyActivityAttachment file) async {
    final result = await repository.download(file.fileUrl);
    final bytes = result.when(
      success: (data) => data,
      failure: (error) {
        AppSnackbar.show('Could not open file', error.message);
        return null;
      },
    );
    if (bytes == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final name = Uri.tryParse(file.fileUrl)?.pathSegments.lastOrNull ?? 'attachment';
      final target = File('${dir.path}/${file.fileType ?? name}');
      await target.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(target.path);
    } catch (_) {
      AppSnackbar.show('Could not open file', file.name);
    }
  }

  static String _message(AppError error) =>
      error.message.trim().isEmpty ? 'This activity was not saved' : error.message;
}
