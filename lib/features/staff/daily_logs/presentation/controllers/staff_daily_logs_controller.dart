import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';

/// GetX controller for the Staff "Daily Logs" screen and its three
/// segmented tabs (My Clients / In Progress / Submitted).
class StaffDailyLogsController extends BaseController<StaffDailyLogsOverview> {
  final StaffDailyLogsRepository repository;

  final Rx<StaffDailyLogsTab> selectedTab = StaffDailyLogsTab.myClients.obs;

  /// BUG_Report003 — client search query (My Clients tab).
  final RxString searchQuery = ''.obs;

  /// BUG_Report003 — residence filter (`null` / empty = All residences).
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

  Future<void> createClient({
    required String name,
    required String residenceId,
    String? room,
  }) async {
    final result = await repository.createClient(
      name: name,
      residenceId: residenceId,
      room: room,
    );
    result.when(
      success: (_) {
        AppSnackbar.show('Client added', 'The new client is now available.');
        loadOverview();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not add client',
      ),
    );
  }

  Future<void> showAddClientDialog() async {
    await loadResidenceOptions();
    final nameController = TextEditingController();
    final roomController = TextEditingController();
    var residenceId = selectedResidenceId.value ??
        Get.find<UserSession>().residenceId ??
        (residenceOptions.isNotEmpty ? residenceOptions.first.id : null);

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Add Client'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('staff-add-client-name'),
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Client name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('staff-add-client-residence'),
                  initialValue: residenceId,
                  decoration: const InputDecoration(labelText: 'Residence'),
                  items: [
                    for (final option in residenceOptions)
                      DropdownMenuItem(
                        value: option.id,
                        child: Text(option.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => residenceId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room (optional)',
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('staff-add-client-submit'),
            onPressed: () => Get.back(result: true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final name = nameController.text.trim();
    final room = roomController.text.trim();
    nameController.dispose();
    roomController.dispose();
    if (confirmed != true || name.isEmpty || residenceId == null) return;
    await createClient(name: name, residenceId: residenceId!, room: room);
  }

  @override
  Future<void> refresh() => loadOverview();
}
