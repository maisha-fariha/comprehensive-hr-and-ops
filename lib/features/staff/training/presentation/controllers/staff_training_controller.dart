import 'package:get/get.dart';

import '../../domain/entities/staff_training.dart';
import '../../domain/repositories/staff_training_repository.dart';

class StaffTrainingController extends GetxController {
  final StaffTrainingRepository repository;

  StaffTrainingController({required this.repository});

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  final summary = const StaffTrainingSummary().obs;
  final courses = <StaffTrainingCourse>[].obs;
  final includeArchived = false.obs;

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
    await Future.wait([_loadSummary(), _loadCourses()]);
    isLoading.value = false;
  }

  Future<void> reload() async {
    isRefreshing.value = true;
    errorMessage.value = '';
    await Future.wait([_loadSummary(), _loadCourses()]);
    isRefreshing.value = false;
  }

  Future<void> _loadSummary() async {
    final result = await repository.listAssignments(page: 1, limit: 1);
    result.when(
      success: (data) => summary.value = data.summary,
      failure: (error) => errorMessage.value = error.message,
    );
  }

  Future<void> _loadCourses() async {
    final result = await repository.listCourses(
      page: page.value,
      limit: pageSize.value,
      includeArchived: includeArchived.value,
    );
    result.when(
      success: (data) {
        courses.assignAll(data.items);
        total.value = data.total;
        totalPages.value = data.totalPages < 1 ? 1 : data.totalPages;
        page.value = data.page;
      },
      failure: (error) => errorMessage.value = error.message,
    );
  }

  void toggleArchived() {
    includeArchived.value = !includeArchived.value;
    page.value = 1;
    _loadCourses();
  }

  void goToPage(int next) {
    if (next < 1 || next > totalPages.value) return;
    page.value = next;
    _loadCourses();
  }
}
