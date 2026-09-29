import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/recurring_check.dart';
import '../../domain/repositories/recurring_checks_repository.dart';

enum RecurringChecksTab { schedules, due, checks }

/// Web `/dashboard/recurring-checks`: the Schedules table, the Due
/// occurrences and the recorded Checks, with their row actions.
class RecurringChecksController extends GetxController {
  final RecurringChecksRepository repository;
  final UserSession session;

  RecurringChecksController({required this.repository, required this.session});

  static const limitOptions = [10, 25, 50];

  final Rx<RecurringChecksTab> tab = RecurringChecksTab.schedules.obs;

  final RxList<CheckSchedule> schedules = <CheckSchedule>[].obs;
  final RxBool schedulesLoading = true.obs;
  final RxnString schedulesError = RxnString();
  final RxInt page = 1.obs;
  final RxInt limit = 20.obs;
  final RxInt total = 0.obs;
  final RxInt totalPages = 1.obs;

  final RxList<CheckInstance> instances = <CheckInstance>[].obs;
  final RxList<CheckEntry> entries = <CheckEntry>[].obs;
  final RxBool listLoading = false.obs;
  final RxnString listError = RxnString();

  final RxnString residenceId = RxnString();
  final Rx<DateTime> day = DateTime.now().obs;
  final RxnString status = RxnString();
  final RxBool mine = false.obs;

  /// Moment "Late" is judged against; refreshed after each record / skip.
  final Rx<DateTime> now = DateTime.now().obs;

  final RxList<CheckOption> residences = <CheckOption>[].obs;
  final RxList<CheckOption> staff = <CheckOption>[].obs;
  final RxList<CheckOption> allClients = <CheckOption>[].obs;
  final RxnString busyId = RxnString();

  int _scheduleSerial = 0;
  int _listSerial = 0;

  bool get canWrite => session.can('recurring-checks:write');
  bool get canComplete => session.can('recurring-checks:complete');
  bool get canManage => session.can('recurring-checks:manage');
  bool get canRecordProgress => canComplete || canWrite;
  bool get canSeeColleagues =>
      session.can('staff:directory') || session.can('staff:read');
  String? get myStaffId => session.staffId;

  /// Assigned to somebody else and the caller cannot take it over.
  bool lockedFor(CheckInstance i) =>
      !canManage &&
      i.assignedStaffId != null &&
      myStaffId != null &&
      i.assignedStaffId != myStaffId;

  bool isLate(CheckInstance i) => i.open && i.dueAt.isBefore(now.value);

  @override
  void onInit() {
    super.onInit();
    _loadOptions();
    loadSchedules();
  }

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadOptions() async {
    final results = await Future.wait([
      repository.residences(),
      repository.staff(),
      repository.clients(),
    ]);
    results[0].when(success: residences.assignAll, failure: (_) {});
    results[1].when(success: staff.assignAll, failure: (_) {});
    results[2].when(success: allClients.assignAll, failure: (_) {});
  }

  void setTab(RecurringChecksTab value) {
    if (tab.value == value) return;
    tab.value = value;
    if (value == RecurringChecksTab.schedules) {
      loadSchedules();
    } else {
      loadList();
    }
  }

  Future<void> refreshCurrent() =>
      tab.value == RecurringChecksTab.schedules ? loadSchedules() : loadList();

  Future<void> loadSchedules() async {
    final serial = ++_scheduleSerial;
    schedulesLoading.value = true;
    final result = await repository.schedules(page: page.value, limit: limit.value);
    if (serial != _scheduleSerial) return;
    result.when(
      success: (data) {
        schedules.assignAll(data.items);
        total.value = data.total;
        totalPages.value = data.totalPages < 1 ? 1 : data.totalPages;
        schedulesError.value = null;
      },
      failure: (error) {
        schedules.clear();
        schedulesError.value = error.message;
      },
    );
    schedulesLoading.value = false;
  }

  void setPage(int value) {
    page.value = value;
    loadSchedules();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    loadSchedules();
  }

  Future<void> loadList() async {
    final serial = ++_listSerial;
    listLoading.value = true;
    final key = dayKey(day.value);
    if (tab.value == RecurringChecksTab.checks) {
      final result = await repository.entries(
        day: key,
        residenceId: residenceId.value,
        outcome: status.value,
        mine: mine.value,
      );
      if (serial != _listSerial) return;
      result.when(
        success: (items) {
          entries.assignAll(items);
          listError.value = null;
        },
        failure: (error) {
          entries.clear();
          listError.value = error.message;
        },
      );
    } else {
      final result = await repository.instances(
        day: key,
        residenceId: residenceId.value,
        status: status.value,
        mine: mine.value,
      );
      if (serial != _listSerial) return;
      result.when(
        success: (items) {
          instances.assignAll(items);
          listError.value = null;
        },
        failure: (error) {
          instances.clear();
          listError.value = error.message;
        },
      );
    }
    listLoading.value = false;
  }

  void setResidence(String? value) {
    residenceId.value = value;
    loadList();
  }

  void setDay(DateTime value) {
    day.value = value;
    loadList();
  }

  void setStatus(String? value) {
    status.value = value;
    loadList();
  }

  void setMine(bool value) {
    mine.value = value;
    loadList();
  }

  Future<bool> _run(
    String id,
    Future<Result<void>> Function() action,
    String? success, {
    required Future<void> Function() reload,
  }) async {
    busyId.value = id;
    final result = await action();
    busyId.value = null;
    return result.when(
      success: (_) {
        if (success != null) AppSnackbar.show(success, '');
        reload();
        return true;
      },
      failure: (error) {
        AppSnackbar.show('Something went wrong', error.message);
        return false;
      },
    );
  }

  Future<bool> toggleSchedule(CheckSchedule s) => _run(
        s.id,
        () => repository.updateSchedule(s.id, {'isActive': !s.isActive}),
        null,
        reload: loadSchedules,
      );

  Future<bool> assignSchedule(CheckSchedule s, CheckOption? person) {
    final name = s.name ?? 'This check';
    return _run(
      s.id,
      () => repository.updateSchedule(s.id, {'assignedStaffId': person?.id}),
      person == null
          ? '$name is no longer assigned to anybody'
          : '$name assigned to ${person.label}',
      reload: loadSchedules,
    );
  }

  Future<bool> deleteSchedule(CheckSchedule s) => _run(
        s.id,
        () => repository.deleteSchedule(s.id),
        'Check deleted',
        reload: loadSchedules,
      );

  /// Throws the API message so the form can show it inline, as the web does.
  Future<void> saveSchedule(Map<String, dynamic> body, {String? id}) async {
    final result = id == null
        ? await repository.createSchedule(body)
        : await repository.updateSchedule(id, body);
    if (result.isFailure) throw result.error!.message;
    AppSnackbar.show(id == null ? 'Recurring check created' : 'Check updated', '');
    loadSchedules();
  }

  Future<bool> assignInstance(
    CheckInstance i,
    CheckAvailableStaff person, {
    required bool applyToSchedule,
  }) {
    final name = i.checkName ?? 'Check';
    return _run(
      i.id,
      () => repository.updateInstance(i.id, {
        'assignedStaffId': person.staffId,
        if (applyToSchedule) 'applyToSchedule': true,
      }),
      applyToSchedule
          ? '$name assigned to ${person.name}, and to future checks'
          : '$name assigned to ${person.name}',
      reload: loadList,
    );
  }

  Future<void> skipInstance(CheckInstance i, String note) async {
    final result = await repository
        .updateInstance(i.id, {'status': 'skipped', 'statusNote': note});
    if (result.isFailure) throw result.error!.message;
    now.value = DateTime.now();
    AppSnackbar.show('Check skipped', '');
    loadList();
  }

  Future<void> recordEntry(Map<String, dynamic> body, {required String outcome}) async {
    final result = await repository.recordEntry(body);
    if (result.isFailure) throw result.error!.message;
    now.value = DateTime.now();
    AppSnackbar.show(
      outcome == 'normal' ? 'Check recorded' : 'Recorded — sent for review',
      '',
    );
    if (tab.value != RecurringChecksTab.schedules) loadList();
  }
}
