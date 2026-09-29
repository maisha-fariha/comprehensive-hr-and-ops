import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_daily_activity_option.dart';
import '../../domain/entities/staff_daily_activity_overview.dart';
import '../../domain/repositories/staff_daily_activity_repository.dart';
import '../widgets/staff_daily_activity_record_sheet.dart';

/// GetX controller for Daily Activity (web parity).
class StaffDailyActivityController
    extends BaseController<StaffDailyActivityOverview> {
  final StaffDailyActivityRepository repository;

  StaffDailyActivityController({required this.repository});

  final Rx<StaffDailyActivityTab> selectedTab =
      StaffDailyActivityTab.registry.obs;

  final RxString searchQuery = ''.obs;
  final RxnString clientId = RxnString();
  final RxnString staffId = RxnString();
  final RxnString activityType = RxnString();
  final RxnString status = RxnString();
  final Rxn<DateTime> dateFilter = Rxn<DateTime>();
  final RxInt page = 1.obs;
  final RxInt limit = 20.obs;

  final RxList<StaffDailyActivityPersonOption> clientOptions =
      <StaffDailyActivityPersonOption>[].obs;
  final RxList<StaffDailyActivityPersonOption> staffOptions =
      <StaffDailyActivityPersonOption>[].obs;

  Timer? _searchDebounce;

  StaffDailyActivityOverview? get overview => state.value.data;

  @override
  void onInit() {
    super.onInit();
    _loadOptions();
    loadOverview();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> loadOverview() async {
    if (selectedTab.value == StaffDailyActivityTab.residentHistory &&
        (clientId.value == null || clientId.value!.isEmpty)) {
      setSuccess(
        StaffDailyActivityOverview(
          metrics: overview?.metrics ?? StaffDailyActivityOverview.empty.metrics,
        ),
      );
      return;
    }

    setLoading(true);
    final result = await repository.getOverview(
      page: page.value,
      limit: limit.value,
      search: searchQuery.value,
      clientId: clientId.value,
      recordedByStaffId: staffId.value,
      activityType: activityType.value,
      status: status.value,
      date: dateFilter.value,
    );
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadOverview();

  Future<void> _loadOptions() async {
    final clients = await repository.getClientOptions();
    clients.when(
      success: (list) => clientOptions.assignAll(list),
      failure: (_) {},
    );
    final staff = await repository.getStaffOptions();
    staff.when(
      success: (list) => staffOptions.assignAll(list),
      failure: (_) {},
    );
  }

  void selectTab(StaffDailyActivityTab tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    page.value = 1;
    loadOverview();
  }

  void setSearch(String value) {
    searchQuery.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      page.value = 1;
      loadOverview();
    });
  }

  void setClientId(String? id) {
    clientId.value = (id == null || id.isEmpty || id == 'all') ? null : id;
    page.value = 1;
    loadOverview();
  }

  void setStaffId(String? id) {
    staffId.value = (id == null || id.isEmpty || id == 'all') ? null : id;
    page.value = 1;
    loadOverview();
  }

  void setActivityType(String? value) {
    activityType.value =
        (value == null || value.isEmpty || value == 'all') ? null : value;
    page.value = 1;
    loadOverview();
  }

  void setStatus(String? value) {
    status.value =
        (value == null || value.isEmpty || value == 'all') ? null : value;
    page.value = 1;
    loadOverview();
  }

  void setDate(DateTime? date) {
    dateFilter.value = date;
    page.value = 1;
    loadOverview();
  }

  void setPage(int next) {
    if (next < 1) return;
    page.value = next;
    loadOverview();
  }

  void setLimit(int next) {
    limit.value = next;
    page.value = 1;
    loadOverview();
  }

  Future<void> openRecordSheet() async {
    if (clientOptions.isEmpty) await _loadOptions();
    final context = Get.context;
    if (context == null || !context.mounted) return;

    final session = Get.find<UserSession>();
    final saved = await StaffDailyActivityRecordSheet.show(
      context,
      clients: clientOptions.toList(),
      staff: staffOptions.toList(),
      initialClientId: clientId.value,
      currentStaffId: session.staffId,
    );
    if (saved == true) {
      Get.snackbar(
        'Activity recorded',
        'Daily activity saved.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
      );
      await loadOverview();
    }
  }

  String formatFilterDate(DateTime? date) {
    if (date == null) return 'Any date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
