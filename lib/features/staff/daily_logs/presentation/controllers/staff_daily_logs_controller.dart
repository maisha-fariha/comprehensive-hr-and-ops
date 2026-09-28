import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';

/// GetX controller for the Staff "Daily Logs" screen and its three
/// segmented tabs (My Clients / In Progress / Submitted).
class StaffDailyLogsController extends BaseController<StaffDailyLogsOverview> {
  final StaffDailyLogsRepository repository;

  final Rx<StaffDailyLogsTab> selectedTab = StaffDailyLogsTab.myClients.obs;

  /// Client search query (My Clients tab).
  final RxString searchQuery = ''.obs;

  /// Residence filter (`null` / empty = All residences).
  final RxnString selectedResidenceId = RxnString();

  final RxList<({String id, String name})> residenceOptions =
      <({String id, String name})>[].obs;

  StaffDailyLogsController({required this.repository}) {
    loadOverview();
    loadResidenceOptions();
  }

  StaffDailyLogsOverview? get overview => state.value.data;

  void selectTab(StaffDailyLogsTab tab) => selectedTab.value = tab;

  void setSearchQuery(String value) => searchQuery.value = value.trim();

  void setResidenceFilter(String? residenceId) {
    selectedResidenceId.value =
        (residenceId == null || residenceId.isEmpty) ? null : residenceId;
  }

  List<StaffClientLogEntry> get filteredMyClients {
    final all = overview?.myClients ?? const <StaffClientLogEntry>[];
    return _filterClients(all);
  }

  List<StaffClientLogEntry> get filteredInProgressClients {
    final all = overview?.inProgressClients ?? const <StaffClientLogEntry>[];
    return _filterClients(all);
  }

  List<StaffClientLogEntry> get filteredSubmittedClients {
    final all = overview?.submittedClients ?? const <StaffClientLogEntry>[];
    return _filterClients(all);
  }

  List<StaffClientLogEntry> _filterClients(List<StaffClientLogEntry> source) {
    final query = searchQuery.value.toLowerCase();
    final residenceId = selectedResidenceId.value;
    return source.where((entry) {
      if (residenceId != null &&
          residenceId.isNotEmpty &&
          (entry.residenceId ?? '') != residenceId) {
        return false;
      }
      if (query.isEmpty) return true;
      return entry.clientName.toLowerCase().contains(query) ||
          entry.roomLabel.toLowerCase().contains(query) ||
          entry.initials.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> loadResidenceOptions() async {
    final result = await repository.getResidenceOptions();
    result.when(
      success: (options) => residenceOptions.assignAll(options),
      failure: (_) {},
    );
  }

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadOverview();
}
