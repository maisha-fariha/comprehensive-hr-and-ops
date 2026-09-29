import 'dart:async';

import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/network/iso_date_range.dart';
import '../../domain/entities/staff_incident.dart';
import '../../domain/entities/staff_incident_options.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import '../../domain/entities/staff_incidents_summary.dart';
import '../../domain/repositories/staff_incidents_repository.dart';

/// GetX controller for the Staff Incidents list screen (both tabs).
class StaffIncidentsController extends BaseController<List<StaffIncident>> {
  final StaffIncidentsRepository repository;

  StaffIncidentsController({required this.repository}) {
    loadFilterOptions();
    loadIncidents();
    loadSummary();
  }

  final Rx<StaffIncidentsTab> selectedTab = StaffIncidentsTab.allIncidents.obs;
  final RxString searchQuery = ''.obs;
  final Rxn<IncidentSeverity> severityFilter = Rxn<IncidentSeverity>();
  final Rxn<IncidentStatus> statusFilter = Rxn<IncidentStatus>();
  final Rxn<DateTime> fromDate = Rxn<DateTime>();
  final Rxn<DateTime> toDate = Rxn<DateTime>();
  final RxnString residenceFilterId = RxnString();
  final RxnString clientFilterId = RxnString();
  final RxList<StaffIncidentResidenceOption> residences =
      <StaffIncidentResidenceOption>[].obs;
  final RxList<StaffIncidentClientOption> clients =
      <StaffIncidentClientOption>[].obs;
  final Rx<StaffIncidentsSummary> summary = StaffIncidentsSummary.empty.obs;
  final RxInt myIncidentsCount = 0.obs;
  final RxInt allIncidentsCount = 0.obs;

  Timer? _searchDebounce;

  List<StaffIncident> get incidents => state.value.data ?? const [];

  /// Server-filtered list for the active tab (search/filters applied in API).
  List<StaffIncident> get visibleIncidents => incidents;

  int get headerCount => summary.value.total;

  String? get residenceFilterLabel {
    final id = residenceFilterId.value;
    if (id == null) return null;
    for (final residence in residences) {
      if (residence.id == id) return residence.name;
    }
    return null;
  }

  String? get clientFilterLabel {
    final id = clientFilterId.value;
    if (id == null) return null;
    for (final client in clients) {
      if (client.id == id) return client.name;
    }
    return null;
  }

  void selectTab(StaffIncidentsTab tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    loadIncidents();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), loadIncidents);
  }

  void setSeverityFilter(IncidentSeverity? value) {
    severityFilter.value = value;
    loadIncidents();
  }

  void setStatusFilter(IncidentStatus? value) {
    statusFilter.value = value;
    loadIncidents();
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    fromDate.value = from;
    toDate.value = to;
    loadIncidents();
  }

  Future<void> setResidenceFilter(String? residenceId) async {
    final next =
        (residenceId == null || residenceId.isEmpty) ? null : residenceId;
    residenceFilterId.value = next;
    clientFilterId.value = null;
    await loadClients(residenceId: next);
    loadIncidents();
  }

  void setClientFilter(String? clientId) {
    clientFilterId.value =
        (clientId == null || clientId.isEmpty) ? null : clientId;
    loadIncidents();
  }

  void clearFilters() {
    severityFilter.value = null;
    statusFilter.value = null;
    fromDate.value = null;
    toDate.value = null;
    residenceFilterId.value = null;
    clientFilterId.value = null;
    loadClients();
    loadIncidents();
  }

  /// Web "View Queue" — filter list to investigating status.
  void viewInvestigationQueue() {
    statusFilter.value = IncidentStatus.inReview;
    loadIncidents();
  }

  Future<void> loadFilterOptions() async {
    await Future.wait([loadResidences(), loadClients()]);
  }

  Future<void> loadResidences() async {
    final result = await repository.getResidences();
    result.when(
      success: (list) => residences.assignAll(list),
      failure: (_) {},
    );
  }

  Future<void> loadClients({String? residenceId}) async {
    final result = await repository.getClients(
      assignedToMe: false,
      residenceId: residenceId ?? residenceFilterId.value,
    );
    result.when(
      success: (list) => clients.assignAll(list),
      failure: (_) {},
    );
  }

  Future<void> loadSummary() async {
    final result = await repository.getSummary();
    result.when(
      success: (value) => summary.value = value,
      failure: (_) {},
    );
  }

  Future<void> loadIncidents() async {
    setLoading(true);
    final from = fromDate.value;
    final to = toDate.value;
    final result = await repository.getIncidents(
      mine: selectedTab.value == StaffIncidentsTab.myIncidents,
      search: searchQuery.value,
      severity: severityFilter.value?.name,
      status: statusFilter.value?.apiValue,
      from: from == null
          ? null
          : IsoDateRange.startOfLocalDay(from).toUtc().toIso8601String(),
      to: to == null
          ? null
          : IsoDateRange.startOfLocalDay(to)
              .add(const Duration(days: 1))
              .toUtc()
              .toIso8601String(),
      residenceId: residenceFilterId.value,
      clientId: clientFilterId.value,
    );
    result.when(
      success: (list) {
        setSuccess(list);
        if (selectedTab.value == StaffIncidentsTab.myIncidents) {
          myIncidentsCount.value = list.length;
        } else {
          allIncidentsCount.value = list.length;
        }
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() async {
    await Future.wait([
      loadFilterOptions(),
      loadIncidents(),
      loadSummary(),
    ]);
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
