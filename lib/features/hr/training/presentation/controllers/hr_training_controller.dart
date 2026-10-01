import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/hr_training.dart';
import '../../domain/entities/training_course_view.dart';
import '../../domain/entities/training_form.dart';
import '../../domain/repositories/hr_training_repository.dart';
import '../training_labels.dart';

/// Web `/dashboard/training`: KPI tiles, the course cards, the paged course
/// list with archive / delete, and the "Create New Training" wizard.
class HrTrainingController extends GetxController {
  final HrTrainingRepository repository;
  final UserSession session;

  HrTrainingController({required this.repository, required this.session});

  static const List<int> pageSizes = [10, 25, 50];
  static const int defaultLimit = 20;

  final RxList<TrainingCourse> courses = <TrainingCourse>[].obs;
  final RxInt total = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();
  final RxBool includeArchived = false.obs;
  final RxInt page = 1.obs;
  final RxInt limit = defaultLimit.obs;
  final Rx<TrainingSummary> summary = const TrainingSummary().obs;
  final RxList<TrainingAssignment> cardAssignments = <TrainingAssignment>[].obs;
  final RxnString busyId = RxnString();

  int _serial = 0;
  List<TrainingStaffOption>? _staff;

  bool get canManage => session.can('training:manage');

  List<TrainingCourseView> get courseViews => [
        for (final course in courses)
          TrainingCourseView.from(
            course,
            assignments: [
              for (final a in cardAssignments)
                if (a.courseId == course.id) a,
            ],
          ),
      ];

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() => Future.wait([load(), loadSummary(), loadCardAssignments()]);

  Future<void> load() async {
    final serial = ++_serial;
    loading.value = true;
    final result = await repository.courses(
      includeArchived: includeArchived.value,
      page: page.value,
      limit: limit.value,
    );
    if (serial != _serial) return;
    result.when(
      success: (data) {
        courses.assignAll(data.items);
        total.value = data.total;
        totalPages.value = data.totalPages < 1 ? 1 : data.totalPages;
        loadError.value = null;
      },
      failure: (error) {
        courses.clear();
        total.value = 0;
        totalPages.value = 1;
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  Future<void> loadSummary() async {
    final result = await repository.assignments(limit: 1);
    result.when(
      success: (data) => summary.value = data.summary ?? const TrainingSummary(),
      failure: (_) {},
    );
  }

  Future<void> loadCardAssignments() async {
    final result = await repository.assignments(limit: 100);
    result.when(
      success: (data) => cardAssignments.assignAll(data.items),
      failure: (_) {},
    );
  }

  void toggleArchived() {
    includeArchived.value = !includeArchived.value;
    page.value = 1;
    load();
  }

  void setPage(int value) {
    page.value = value;
    load();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    load();
  }

  /// The staff directory the assignment rules count reach against.
  Future<List<TrainingStaffOption>> staff() async {
    if (_staff != null) return _staff!;
    if (!session.can('staff:read')) return const [];
    final result = await repository.staff();
    return result.when(
      success: (list) => _staff = list,
      failure: (_) => const [],
    );
  }

  Future<void> setArchived(TrainingCourse course, bool archive) async {
    busyId.value = course.id;
    final result = await repository.updateCourse(course.id, {'isActive': !archive});
    busyId.value = null;
    result.when(
      success: (_) {
        AppSnackbar.show(archive ? 'Course archived' : 'Course restored', '');
        refreshAll();
      },
      failure: (error) => AppSnackbar.show(error.message, ''),
    );
  }

  /// Returns true once deleted; failures toast and keep the dialog open.
  Future<bool> deleteCourse(TrainingCourse course) async {
    final result = await repository.removeCourse(course.id);
    return result.when(
      success: (_) {
        AppSnackbar.show('Course deleted', '');
        refreshAll();
        return true;
      },
      failure: (error) {
        AppSnackbar.show(error.message, '');
        return false;
      },
    );
  }

  /// Web create `onSave`: upload, course, questions, then one assignment per
  /// person the rules reach. Returns the error message, or null on success.
  Future<String?> createCourse(TrainingFormValues values) async {
    String? uploaded;
    final file = values.materialFile;
    if (file != null) {
      final upload = await repository.uploadMaterial(file.path, file.name);
      final failed = upload.when(
        success: (url) {
          uploaded = url;
          return null;
        },
        failure: (error) => error.message,
      );
      if (failed != null) return failed;
    }

    final created = await repository.createCourse(
      values.toCourseBody(uploadedUrl: uploaded, create: true),
    );
    TrainingCourse? course;
    final createError = created.when(
      success: (c) {
        course = c;
        return null;
      },
      failure: (error) => error.message,
    );
    if (createError != null) return createError;

    if (values.quizEnabled && values.questions.isNotEmpty) {
      final quiz = await repository.setQuestions(course!.id, values.toQuestionsBody());
      final quizError = quiz.when(success: (_) => null, failure: (e) => e.message);
      if (quizError != null) return quizError;
    }

    final staffIds = values.resolveStaffIds(await staff());
    if (staffIds.isNotEmpty) {
      final due = values.dueDate;
      final assigned = await repository.assign(
        courseId: course!.id,
        staffIds: staffIds,
        mandatory: values.mandatory,
        dueAt: due == null ? null : TrainingLabels.dateOnlyIso(due),
      );
      final assignError = assigned.when(success: (_) => null, failure: (e) => e.message);
      if (assignError != null) return assignError;
    }

    final n = staffIds.length;
    AppSnackbar.show(
      n > 0
          ? 'Course created and assigned to $n ${n == 1 ? 'person' : 'people'}'
          : 'Course created',
      '',
    );
    refreshAll();
    return null;
  }
}
