import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';

/// Staff Daily Logs — web filters + To review / Missing / Day / House tabs.
class StaffDailyLogsController extends BaseController<StaffDailyLogsOverview> {
  final StaffDailyLogsRepository repository;
  final UserSession session;

  final Rx<StaffDailyLogsTab> selectedTab = StaffDailyLogsTab.toReview.obs;

  final RxList<({String id, String name})> residenceOptions =
      <({String id, String name})>[].obs;

  /// Required for API queues (web Residence *).
  final RxnString selectedResidenceId = RxnString();

  /// Optional resident filter / day-view subject.
  final RxnString selectedClientId = RxnString();

  final Rx<DateTime> fromDate =
      DateTime.now().subtract(const Duration(days: 6)).obs;
  final Rx<DateTime> toDate = DateTime.now().obs;

  StaffDailyLogsController({
    required this.repository,
    required this.session,
  }) {
    _bootstrap();
  }

  StaffDailyLogsOverview? get overview => state.value.data;

  List<({String id, String name})> get residentOptions =>
      overview?.residents ?? const [];

  Future<void> _bootstrap() async {
    await loadResidenceOptions();
    final sessionResidence = session.residenceId;
    if (sessionResidence != null &&
        sessionResidence.isNotEmpty &&
        residenceOptions.any((r) => r.id == sessionResidence)) {
      selectedResidenceId.value = sessionResidence;
    } else if (residenceOptions.isNotEmpty) {
      selectedResidenceId.value = residenceOptions.first.id;
    }
    await loadOverview();
  }

  void selectTab(StaffDailyLogsTab tab) => selectedTab.value = tab;

  Future<void> setResidence(String? residenceId) async {
    selectedResidenceId.value =
        (residenceId == null || residenceId.isEmpty) ? null : residenceId;
    selectedClientId.value = null;
    await loadOverview();
  }

  Future<void> setResident(String? clientId) async {
    selectedClientId.value =
        (clientId == null || clientId.isEmpty) ? null : clientId;
    await loadOverview();
  }

  Future<void> setFromDate(DateTime date) async {
    fromDate.value = DateTime(date.year, date.month, date.day);
    if (toDate.value.isBefore(fromDate.value)) {
      toDate.value = fromDate.value;
    }
    await loadOverview();
  }

  Future<void> setToDate(DateTime date) async {
    toDate.value = DateTime(date.year, date.month, date.day);
    if (fromDate.value.isAfter(toDate.value)) {
      fromDate.value = toDate.value;
    }
    await loadOverview();
  }

  String formatFilterDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  String get weekRangeLabel {
    final start = fromDate.value;
    final end = toDate.value;
    return IsoDateRange.formatWeekRange(start, end);
  }

  List<StaffClientLogEntry> get filteredToReview {
    final clientId = selectedClientId.value;
    final items = overview?.toReview ?? const <StaffClientLogEntry>[];
    if (clientId == null || clientId.isEmpty) return items;
    return items.where((e) => e.clientId == clientId).toList();
  }

  List<StaffClientLogEntry> get filteredMissing {
    final clientId = selectedClientId.value;
    final items = overview?.missing ?? const <StaffClientLogEntry>[];
    if (clientId == null || clientId.isEmpty) return items;
    return items.where((e) => e.clientId == clientId).toList();
  }

  Future<void> loadResidenceOptions() async {
    final result = await repository.getResidenceOptions();
    result.when(
      success: (options) => residenceOptions.assignAll(options),
      failure: (_) {},
    );
  }

  Future<void> loadOverview() async {
    final residenceId = selectedResidenceId.value;
    if (residenceId == null || residenceId.isEmpty) {
      setSuccess(StaffDailyLogsOverview.empty);
      return;
    }

    setLoading(true);
    final result = await repository.getOverview(
      residenceId: residenceId,
      from: fromDate.value,
      to: toDate.value,
      clientId: selectedClientId.value,
    );
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() async {
    await loadResidenceOptions();
    await loadOverview();
  }
}
