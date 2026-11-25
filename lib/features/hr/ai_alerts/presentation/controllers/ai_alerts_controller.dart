import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../domain/entities/ai_report.dart';
import '../../domain/repositories/ai_alerts_repository.dart';

class AiAlertsController extends GetxController {
  final AiAlertsRepository repository;

  AiAlertsController({required this.repository});

  final selectedTab = AiAlertsTab.reports.obs;
  final featureGate = const AiFeatureGate().obs;
  final gateLoading = true.obs;

  final reportsPage = const AiReportsPage().obs;
  final reportsLoading = false.obs;
  final reportsError = RxnString();

  final automationsPage = const AiReportAutomationsPage().obs;
  final automationsLoading = false.obs;
  final automationsError = RxnString();

  final selectedReportId = RxnString();
  final detail = Rxn<AiReportDetail>();
  final detailLoading = false.obs;
  final detailError = RxnString();

  final searchQuery = ''.obs;
  final kindFilter = RxnString();
  final severityFilter = RxnString();
  final homeFilter = RxnString();
  final unreadOnly = false.obs;

  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();

  late final TextEditingController searchController;
  Timer? _searchDebounce;
  int _reportsGeneration = 0;
  int _detailGeneration = 0;

  List<AiReportKindOption> get kindOptions => reportsPage.value.kinds;
  List<AiReportHomeOption> get homeOptions => reportsPage.value.homes;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    _bootstrap();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    await loadFeatureGate();
    await Future.wait([loadReports(), loadAutomations()]);
  }

  Future<void> loadFeatureGate() async {
    gateLoading.value = true;
    final result = await repository.getFeatureGate();
    result.when(
      success: (gate) => featureGate.value = gate,
      failure: (_) => featureGate.value = const AiFeatureGate(),
    );
    gateLoading.value = false;
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadReports(),
      if (selectedTab.value == AiAlertsTab.automations) loadAutomations(),
      if (selectedReportId.value != null) loadDetail(selectedReportId.value!),
    ]);
  }

  void selectTab(AiAlertsTab tab) {
    selectedTab.value = tab;
    if (tab == AiAlertsTab.automations && automationsPage.value.items.isEmpty) {
      loadAutomations();
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), loadReports);
  }

  void setKindFilter(String? kind) {
    kindFilter.value = kind;
    loadReports();
  }

  void setSeverityFilter(String? severity) {
    severityFilter.value = severity;
    loadReports();
  }

  void setHomeFilter(String? residenceId) {
    homeFilter.value = residenceId;
    loadReports();
  }

  void toggleUnreadOnly(bool value) {
    unreadOnly.value = value;
    loadReports();
  }

  Future<void> pickDateRange(BuildContext context) async {
    final now = TenantClock.now();
    final initialStart = fromDate.value ?? now.subtract(const Duration(days: 30));
    final initialEnd = toDate.value ?? now;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked == null) return;
    fromDate.value = picked.start;
    toDate.value = picked.end;
    loadReports();
  }

  void clearFilters() {
    searchController.clear();
    searchQuery.value = '';
    kindFilter.value = null;
    severityFilter.value = null;
    homeFilter.value = null;
    unreadOnly.value = false;
    fromDate.value = null;
    toDate.value = null;
    loadReports();
  }

  bool get hasActiveFilters =>
      searchQuery.value.trim().isNotEmpty ||
      kindFilter.value != null ||
      severityFilter.value != null ||
      homeFilter.value != null ||
      unreadOnly.value ||
      fromDate.value != null ||
      toDate.value != null;

  String? get _fromIso {
    final from = fromDate.value;
    if (from == null) return null;
    return TenantClock.at(IsoDateRange.startOfLocalDay(from), 0)
        .toUtc()
        .toIso8601String();
  }

  String? get _toIso {
    final to = toDate.value;
    if (to == null) return null;
    final end = IsoDateRange.startOfLocalDay(to).add(const Duration(days: 1));
    return TenantClock.at(end, 0).toUtc().toIso8601String();
  }

  Future<void> loadReports() async {
    final generation = ++_reportsGeneration;
    reportsLoading.value = true;
    reportsError.value = null;
    final result = await repository.getReports(
      page: 1,
      limit: 50,
      q: searchQuery.value,
      kind: kindFilter.value,
      severity: severityFilter.value,
      residenceId: homeFilter.value,
      from: _fromIso,
      to: _toIso,
      unreadOnly: unreadOnly.value,
    );
    if (generation != _reportsGeneration) return;
    result.when(
      success: (page) {
        reportsPage.value = page;
        final selected = selectedReportId.value;
        if (selected != null && page.items.every((i) => i.id != selected)) {
          selectedReportId.value = null;
          detail.value = null;
        }
      },
      failure: (error) => reportsError.value = error.message,
    );
    reportsLoading.value = false;
  }

  Future<void> selectReport(String id, {bool wide = false}) async {
    selectedReportId.value = id;
    await loadDetail(id);
    _markReadLocally(id);
  }

  void _markReadLocally(String id) {
    final page = reportsPage.value;
    final next = page.items
        .map((item) => item.id == id ? item.markRead() : item)
        .toList();
    var unread = page.unread;
    final wasUnread = page.items.any((i) => i.id == id && !i.read);
    if (wasUnread && unread > 0) unread--;
    reportsPage.value = AiReportsPage(
      items: next,
      total: page.total,
      unread: unread,
      page: page.page,
      limit: page.limit,
      kinds: page.kinds,
      homes: page.homes,
    );
  }

  Future<void> loadDetail(String id) async {
    final generation = ++_detailGeneration;
    detailLoading.value = true;
    detailError.value = null;
    final result = await repository.getReportDetail(id);
    if (generation != _detailGeneration) return;
    result.when(
      success: (value) => detail.value = value,
      failure: (error) => detailError.value = error.message,
    );
    detailLoading.value = false;
  }

  Future<void> loadAutomations() async {
    automationsLoading.value = true;
    automationsError.value = null;
    final result = await repository.getAutomations();
    result.when(
      success: (page) => automationsPage.value = page,
      failure: (error) => automationsError.value = error.message,
    );
    automationsLoading.value = false;
  }
}
