import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_week.dart';
import '../../domain/entities/manual_entry_options.dart';
import '../../domain/repositories/attendance_repository.dart';

/// Web `/dashboard/attendance`: week, residence and status filters, KPI
/// cards, the paginated records table and its row actions.
class AttendanceController extends BaseController<AttendanceRecordPage> {
  final AttendanceRepository _repository;
  final UserSession _session;

  AttendanceController({
    required AttendanceRepository repository,
    required UserSession session,
  })  : _repository = repository,
        _session = session;

  static const int defaultLimit = 20;
  static const List<int> limitOptions = [10, 25, 50];

  final Rx<AttendanceWeek> week =
      AttendanceWeek.containing(DateTime.now()).obs;

  /// True once a week was picked; a pending-approval filter otherwise
  /// ignores dates so every open claim shows.
  final RxBool weekChosen = false.obs;
  final RxnString residenceId = RxnString();
  final Rxn<AttendanceStatusFilter> status = Rxn<AttendanceStatusFilter>();
  final RxInt page = 1.obs;
  final RxInt limit = defaultLimit.obs;

  final Rxn<AttendanceSummary> summary = Rxn<AttendanceSummary>();
  final RxList<ManualEntryResidenceOption> residences =
      <ManualEntryResidenceOption>[].obs;
  final Rxn<OpenAttendance> myOpenAttendance = Rxn<OpenAttendance>();
  final RxnString busyId = RxnString();

  int _requestSerial = 0;

  bool get canManage => _session.can('attendance:manage');
  bool get canWrite => _session.can('attendance:write');

  bool get appliesWeek =>
      status.value != AttendanceStatusFilter.pendingApproval ||
      weekChosen.value;

  @override
  void onInit() {
    super.onInit();
    _loadResidences();
    refresh();
  }

  @override
  Future<void> refresh() async {
    await Future.wait([
      loadRecords(),
      loadSummary(),
      if (canWrite) loadMyOpenAttendance(),
    ]);
  }

  Future<void> loadRecords() async {
    final serial = ++_requestSerial;
    setLoading(true);
    final result = await _repository.getRecords(
      page: page.value,
      limit: limit.value,
      residenceId: residenceId.value,
      status: status.value?.value,
      from: appliesWeek ? week.value.from : null,
      to: appliesWeek ? week.value.to : null,
      mine: !canManage,
    );
    if (serial != _requestSerial) return;
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<void> loadSummary() async {
    if (!canManage) return;
    final result = await _repository.getSummary(
      residenceId: residenceId.value,
      from: week.value.from,
      to: week.value.to,
    );
    result.when(
      success: (value) => summary.value = value,
      failure: (_) {},
    );
  }

  Future<void> loadMyOpenAttendance() async {
    final result = await _repository.getMyOpenAttendance();
    result.when(
      success: (value) => myOpenAttendance.value = value,
      failure: (_) {},
    );
  }

  Future<void> _loadResidences() async {
    final result = await _repository.getResidences();
    result.when(
      success: residences.assignAll,
      failure: (_) {},
    );
  }

  void selectWeek(DateTime day) {
    week.value = AttendanceWeek.containing(day);
    weekChosen.value = true;
    _reload();
  }

  void previousWeek() => selectWeek(week.value.previous.start);

  void nextWeek() => selectWeek(week.value.next.start);

  void setResidence(String? id) {
    residenceId.value = (id == null || id.isEmpty) ? null : id;
    _reload();
  }

  void setStatus(AttendanceStatusFilter? value) {
    status.value = value;
    page.value = 1;
    loadRecords();
  }

  /// KPI card tap toggles its status; the pending card also drops the week
  /// so claims typed at any time show.
  void toggleKpi(AttendanceStatusFilter value) {
    if (status.value == value) {
      setStatus(null);
      return;
    }
    if (value == AttendanceStatusFilter.pendingApproval && weekChosen.value) {
      weekChosen.value = false;
      week.value = AttendanceWeek.containing(DateTime.now());
      status.value = value;
      _reload();
      return;
    }
    setStatus(value);
  }

  void setPage(int value) {
    if (value < 1 || value == page.value) return;
    page.value = value;
    loadRecords();
  }

  void setLimit(int value) {
    if (value == limit.value) return;
    limit.value = value;
    page.value = 1;
    loadRecords();
  }

  void _reload() {
    page.value = 1;
    loadRecords();
    loadSummary();
  }

  Future<void> approve(AttendanceRecord record) => _decide(
        record,
        () => _repository.approveAttendance(record.id),
        'Attendance approved',
      );

  Future<void> reject(AttendanceRecord record) => _decide(
        record,
        () => _repository.rejectAttendance(record.id),
        'Attendance rejected',
      );

  Future<bool> delete(AttendanceRecord record) => _decide(
        record,
        () => _repository.deleteAttendance(record.id),
        'Attendance record deleted',
      );

  Future<bool> _decide(
    AttendanceRecord record,
    Future<Result<void>> Function() action,
    String successMessage,
  ) async {
    if (busyId.value != null) return false;
    busyId.value = record.id;
    try {
      final result = await action();
      var ok = false;
      result.when(
        success: (_) {
          ok = true;
          AppSnackbar.show('Attendance', successMessage);
        },
        failure: (error) => AppSnackbar.show('Attendance', error.message),
      );
      if (ok) await Future.wait([loadRecords(), loadSummary()]);
      return ok;
    } finally {
      busyId.value = null;
    }
  }
}
