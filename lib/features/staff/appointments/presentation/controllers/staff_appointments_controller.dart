import 'package:get/get.dart';
import 'package:gems_core/gems_core.dart';

import '../../domain/entities/staff_appointment.dart';
import '../../domain/repositories/staff_appointments_repository.dart';

class StaffAppointmentsController extends GetxController {
  final StaffAppointmentsRepository repository;

  StaffAppointmentsController({required this.repository});

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  final summary = const StaffAppointmentsSummary().obs;
  final appointments = <StaffAppointment>[].obs;
  final clients = <StaffAppointmentClientOption>[].obs;

  final selectedTab = StaffAppointmentTab.pending.obs;
  final searchQuery = ''.obs;

  final page = 1.obs;
  final pageSize = 20.obs;
  final total = 0.obs;
  final totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    await Future.wait([
      _loadSummary(),
      _loadAppointments(),
      _loadClients(),
    ]);
    isLoading.value = false;
  }

  Future<void> reload() async {
    isRefreshing.value = true;
    errorMessage.value = '';
    await Future.wait([
      _loadSummary(),
      _loadAppointments(),
    ]);
    isRefreshing.value = false;
  }

  Future<void> _loadSummary() async {
    final result = await repository.getSummary();
    result.when(
      success: (data) => summary.value = data,
      failure: (error) => errorMessage.value = error.message,
    );
  }

  Future<void> _loadAppointments() async {
    final tab = selectedTab.value;
    final result = await repository.listAppointments(
      page: page.value,
      limit: pageSize.value,
      search: searchQuery.value,
      status: _statusForTab(tab),
      type: _typeForTab(tab),
    );
    result.when(
      success: (data) {
        appointments.assignAll(data.items);
        total.value = data.total;
        totalPages.value = data.totalPages < 1 ? 1 : data.totalPages;
        page.value = data.page;
      },
      failure: (error) => errorMessage.value = error.message,
    );
  }

  Future<void> _loadClients() async {
    final result = await repository.listClients();
    result.when(
      success: (data) => clients.assignAll(data),
      failure: (_) {},
    );
  }

  String? _statusForTab(StaffAppointmentTab tab) {
    switch (tab) {
      case StaffAppointmentTab.pending:
        return 'pending';
      case StaffAppointmentTab.approved:
        return 'approved';
      case StaffAppointmentTab.rejected:
        return 'rejected';
      case StaffAppointmentTab.familyVisits:
      case StaffAppointmentTab.external:
      case StaffAppointmentTab.all:
        return null;
    }
  }

  String? _typeForTab(StaffAppointmentTab tab) {
    switch (tab) {
      case StaffAppointmentTab.familyVisits:
        return 'family_visit';
      case StaffAppointmentTab.external:
        return 'external';
      case StaffAppointmentTab.pending:
      case StaffAppointmentTab.approved:
      case StaffAppointmentTab.rejected:
      case StaffAppointmentTab.all:
        return null;
    }
  }

  void setTab(StaffAppointmentTab tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    page.value = 1;
    _loadAppointments();
  }

  void setSearch(String value) {
    searchQuery.value = value;
    page.value = 1;
    _loadAppointments();
  }

  void goToPage(int next) {
    if (next < 1 || next > totalPages.value) return;
    page.value = next;
    _loadAppointments();
  }

  Future<Result<void>> createAppointment(StaffCreateAppointmentInput input) async {
    final result = await repository.createAppointment(input);
    return result.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> approve(String id) async {
    final result = await repository.approve(id);
    return result.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> reject(String id, {String? reason}) async {
    final result = await repository.reject(id, reason: reason);
    return result.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> restore(String id) async {
    final result = await repository.restore(id);
    return result.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> cancel(String id, {String? reason}) async {
    final result = await repository.cancel(id, reason: reason);
    return result.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> delete(String id) async {
    final result = await repository.delete(id);
    return result.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> updateAppointment(
    String id,
    StaffUpdateAppointmentInput input,
  ) async {
    final result = await repository.updateAppointment(id, input);
    return result.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }
}
