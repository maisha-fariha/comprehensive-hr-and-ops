import 'package:get/get.dart';

import '../../domain/entities/staff_training.dart';
import '../../domain/repositories/staff_training_repository.dart';

class StaffTrainingCourseController extends GetxController {
  final StaffTrainingRepository repository;

  StaffTrainingCourseController({required this.repository});

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final course = Rxn<StaffTrainingCourse>();
  final certificates = <StaffTrainingCertificate>[].obs;
  final metrics = const StaffTrainingCourseMetrics().obs;
  final selectedTab = 0.obs;

  String? _courseId;

  Future<void> load(String courseId) async {
    _courseId = courseId;
    isLoading.value = true;
    errorMessage.value = '';
    await Future.wait([
      _loadCourse(courseId),
      _loadCertificates(courseId),
    ]);
    _recomputeMetrics();
    isLoading.value = false;
  }

  Future<void> reload() async {
    final id = _courseId;
    if (id == null || id.isEmpty) return;
    await load(id);
  }

  Future<void> _loadCourse(String courseId) async {
    final result = await repository.getCourse(courseId);
    result.when(
      success: (data) => course.value = data,
      failure: (error) => errorMessage.value = error.message,
    );
  }

  Future<void> _loadCertificates(String courseId) async {
    final result = await repository.listCertificates(
      courseId: courseId,
      page: 1,
      limit: 100,
    );
    result.when(
      success: (data) => certificates.assignAll(data.items),
      failure: (_) {},
    );
  }

  void _recomputeMetrics() {
    final c = course.value;
    if (c == null) {
      metrics.value = StaffTrainingCourseMetrics(
        certificatesIssued: certificates.length,
      );
      return;
    }
    metrics.value = c.metrics.copyWith(
      certificatesIssued: certificates.length,
    );
  }

  void selectTab(int index) {
    selectedTab.value = index;
  }

  List<StaffTrainingAssignment> get completions {
    final c = course.value;
    if (c == null) return const [];
    return c.assignments.where((a) => a.isCompleted).toList();
  }
}
