import 'package:gems_core/gems_core.dart';

import '../entities/staff_training.dart';

abstract class StaffTrainingRepository {
  Future<Result<StaffTrainingAssignmentsPage>> listAssignments({
    int page = 1,
    int limit = 20,
    String? courseId,
    String? staffId,
  });

  Future<Result<StaffTrainingCoursesPage>> listCourses({
    int page = 1,
    int limit = 20,
    bool includeArchived = false,
  });

  Future<Result<StaffTrainingCourse>> getCourse(String id);

  Future<Result<StaffTrainingCertificatesPageResult>> listCertificates({
    int page = 1,
    int limit = 50,
    String? courseId,
  });
}
