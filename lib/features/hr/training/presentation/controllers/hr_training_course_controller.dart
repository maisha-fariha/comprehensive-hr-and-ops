import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/hr_training.dart';
import '../../domain/entities/training_course_view.dart';
import '../../domain/entities/training_form.dart';
import '../../domain/repositories/hr_training_repository.dart';
import '../training_labels.dart';

/// A paged table on one of the course tabs (Assignments, Sittings,
/// Certificates); each keeps its own page like the web `useListParams`.
class TrainingPagedList<T> {
  final RxList<T> rows = <T>[].obs;
  final RxInt total = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxInt page = 1.obs;
  final RxInt limit = HrTrainingCourseController.defaultLimit.obs;
  final RxBool loading = true.obs;
  final RxnString error = RxnString();

  void apply(Result<TrainingPage<T>> result) {
    result.when(
      success: (data) {
        rows.assignAll(data.items);
        total.value = data.total;
        totalPages.value = data.totalPages < 1 ? 1 : data.totalPages;
        error.value = null;
      },
      failure: (e) {
        rows.clear();
        total.value = 0;
        totalPages.value = 1;
        error.value = e.message;
      },
    );
    loading.value = false;
  }
}

/// Web `/dashboard/training/[trainingId]`: header, five KPI tiles and the
/// eight tabs with every action `training:manage` unlocks.
class HrTrainingCourseController extends GetxController {
  final HrTrainingRepository repository;
  final UserSession session;
  final String courseId;

  HrTrainingCourseController({
    required this.repository,
    required this.session,
    required this.courseId,
    String initialTab = 'overview',
  }) : tab = initialTab.obs;

  static const List<int> pageSizes = [10, 25, 50];
  static const int defaultLimit = 20;
  static const int _maxLimit = 100;

  final RxString tab;
  final Rxn<TrainingCourse> course = Rxn<TrainingCourse>();
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();
  final Rxn<TrainingQuiz> quiz = Rxn<TrainingQuiz>();
  final RxList<TrainingQuestion> questions = <TrainingQuestion>[].obs;
  final Rxn<List<TrainingAssignment>> allAssignments = Rxn<List<TrainingAssignment>>();
  final RxList<TrainingAttempt> allAttempts = <TrainingAttempt>[].obs;
  final RxList<TrainingCertificate> allCertificates = <TrainingCertificate>[].obs;
  final RxList<TrainingAuditEntry> audit = <TrainingAuditEntry>[].obs;
  final RxBool auditLoading = true.obs;
  final RxList<TrainingStaffOption> staffOptions = <TrainingStaffOption>[].obs;
  final RxnString busyId = RxnString();

  final TrainingPagedList<TrainingAssignment> assignmentsTab = TrainingPagedList();
  final TrainingPagedList<TrainingAttempt> sittingsTab = TrainingPagedList();
  final TrainingPagedList<TrainingCertificate> certificatesTab = TrainingPagedList();

  bool get canManage => session.can('training:manage');
  bool get canReadAudit => session.can('compliance:read');

  TrainingCourseView? get view {
    final c = course.value;
    if (c == null) return null;
    return TrainingCourseView.from(
      c,
      assignments: allAssignments.value ?? c.assignments,
      attempts: allAttempts,
      certificates: allCertificates,
      questions: questions,
      history: TrainingCourseView.historyFrom(audit),
    );
  }

  /// The staff picker label for [staffId]; the web says "Outside your access"
  /// when the directory does not include that person.
  String staffName(String staffId) =>
      staffOptions.firstWhereOrNull((s) => s.id == staffId)?.name ??
      'Outside your access';

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() => Future.wait([
        loadCourse(),
        loadQuiz(),
        loadQuestions(),
        loadAllAssignments(),
        loadAllAttempts(),
        loadAllCertificates(),
        loadAudit(),
        loadStaff(),
        loadAssignmentsTab(),
        loadSittingsTab(),
        loadCertificatesTab(),
      ]);

  Future<void> loadCourse() async {
    final result = await repository.course(courseId);
    result.when(
      success: (c) {
        course.value = c;
        loadError.value = null;
      },
      failure: (e) => loadError.value = e.message,
    );
    loading.value = false;
  }

  Future<void> loadQuiz() async {
    final result = await repository.quiz(courseId);
    result.when(success: (q) => quiz.value = q, failure: (_) {});
  }

  Future<void> loadQuestions() async {
    if (!canManage) return;
    final result = await repository.authoredQuestions(courseId);
    result.when(success: questions.assignAll, failure: (_) {});
  }

  Future<void> loadAllAssignments() async {
    final result = await repository.assignments(courseId: courseId, limit: _maxLimit);
    result.when(success: (p) => allAssignments.value = p.items, failure: (_) {});
  }

  Future<void> loadAllAttempts() async {
    final result =
        await repository.attempts(courseId: courseId, page: 1, limit: _maxLimit);
    result.when(success: (p) => allAttempts.assignAll(p.items), failure: (_) {});
  }

  Future<void> loadAllCertificates() async {
    final result =
        await repository.certificates(courseId: courseId, page: 1, limit: _maxLimit);
    result.when(success: (p) => allCertificates.assignAll(p.items), failure: (_) {});
  }

  Future<void> loadAudit() async {
    if (!canReadAudit) {
      auditLoading.value = false;
      return;
    }
    final result = await repository.auditLogs(courseId);
    result.when(success: audit.assignAll, failure: (_) {});
    auditLoading.value = false;
  }

  Future<void> loadStaff() async {
    if (!session.can('staff:read')) return;
    final result = await repository.staff();
    result.when(success: staffOptions.assignAll, failure: (_) {});
  }

  Future<void> loadAssignmentsTab() async {
    final list = assignmentsTab..loading.value = true;
    list.apply(await repository.assignments(
      courseId: courseId,
      page: list.page.value,
      limit: list.limit.value,
    ));
  }

  Future<void> loadSittingsTab() async {
    final list = sittingsTab..loading.value = true;
    list.apply(await repository.attempts(
      courseId: courseId,
      page: list.page.value,
      limit: list.limit.value,
    ));
  }

  Future<void> loadCertificatesTab() async {
    final list = certificatesTab..loading.value = true;
    list.apply(await repository.certificates(
      courseId: courseId,
      page: list.page.value,
      limit: list.limit.value,
    ));
  }

  void setTabPage(TrainingPagedList list, int page) {
    list.page.value = page;
    _reloadTab(list);
  }

  void setTabLimit(TrainingPagedList list, int limit) {
    list.limit.value = limit;
    list.page.value = 1;
    _reloadTab(list);
  }

  void _reloadTab(TrainingPagedList list) {
    if (identical(list, assignmentsTab)) loadAssignmentsTab();
    if (identical(list, sittingsTab)) loadSittingsTab();
    if (identical(list, certificatesTab)) loadCertificatesTab();
  }

  String? _error(Result<dynamic> result) =>
      result.when(success: (_) => null, failure: (e) => e.message);

  /// "Assign staff" dialog. Returns the error to show inline, or null.
  Future<String?> assign({
    required List<String> staffIds,
    required bool mandatory,
    DateTime? dueAt,
  }) async {
    if (staffIds.isEmpty) return 'Choose at least one person.';
    final result = await repository.assign(
      courseId: courseId,
      staffIds: staffIds,
      mandatory: mandatory,
      dueAt: dueAt?.toUtc().toIso8601String(),
    );
    return result.when(
      success: (rows) {
        final n = rows.length;
        AppSnackbar.show('$n assignment${n == 1 ? '' : 's'} written', '');
        refreshAll();
        return null;
      },
      failure: (e) => e.message,
    );
  }

  /// Row action "Start" / "Mark complete".
  Future<void> advance(TrainingAssignment assignment) async {
    final next = assignment.status == 'assigned' ? 'in_progress' : 'completed';
    busyId.value = assignment.id;
    final result = await repository.updateAssignment(assignment.id, {
      'status': next,
      if (next == 'completed')
        'completedAt': DateTime.now().toUtc().toIso8601String(),
    });
    busyId.value = null;
    result.when(
      success: (_) {
        AppSnackbar.show(next == 'completed' ? 'Marked complete' : 'Started', '');
        refreshAll();
      },
      failure: (e) => AppSnackbar.show(e.message, ''),
    );
  }

  /// "Submit the certificate" dialog. Returns the error, or null.
  Future<String?> submitCertificate(
    String assignmentId, {
    String? certificateNumber,
    String? provider,
    String? fileUrl,
    DateTime? completedOn,
  }) async {
    final number = certificateNumber?.trim() ?? '';
    final issuer = provider?.trim() ?? '';
    final scan = fileUrl?.trim() ?? '';
    final result = await repository.submitCertificate(assignmentId, {
      if (number.isNotEmpty) 'certificateNumber': number,
      if (issuer.isNotEmpty) 'provider': issuer,
      if (scan.isNotEmpty) 'fileUrl': scan,
      if (completedOn != null) 'completedAt': TrainingLabels.dateOnlyIso(completedOn),
    });
    final error = _error(result);
    if (error == null) {
      AppSnackbar.show('Sent for review', '');
      refreshAll();
    }
    return error;
  }

  Future<void> approveCertificate(TrainingCertificate certificate) async {
    busyId.value = certificate.id;
    final result =
        await repository.reviewCertificate(certificate.id, {'decision': 'approve'});
    busyId.value = null;
    result.when(
      success: (_) {
        AppSnackbar.show('Certificate approved', '');
        refreshAll();
      },
      failure: (e) => AppSnackbar.show(e.message, ''),
    );
  }

  /// "Send the certificate back" dialog. Returns the error, or null.
  Future<String?> rejectCertificate(String certificateId, String notes) async {
    final result = await repository.reviewCertificate(certificateId, {
      'decision': 'reject',
      'reviewNotes': notes.trim(),
    });
    final error = _error(result);
    if (error == null) {
      AppSnackbar.show('Sent back', '');
      refreshAll();
    }
    return error;
  }

  /// Quiz tab "Save quiz". Returns the error, or null.
  Future<String?> saveQuiz(List<TrainingQuizDraft> drafts) async {
    final invalid = TrainingQuizDraft.validate(drafts);
    if (invalid != null) return invalid;
    final error = _error(
      await repository.setQuestions(courseId, TrainingQuizDraft.body(drafts)),
    );
    if (error == null) {
      AppSnackbar.show('Quiz saved', '');
      refreshAll();
    }
    return error;
  }

  /// "Record a sitting". Returns the error, or null.
  Future<String?> submitAttempt({
    required String? staffId,
    required Map<String, List<int>> selected,
  }) async {
    if (staffId == null || staffId.isEmpty) return 'Choose who sat the quiz.';
    final result = await repository.submitAttempt(
      courseId,
      staffId: staffId,
      answers: [
        for (final q in quiz.value?.questions ?? const <TrainingQuestion>[])
          {'questionId': q.id, 'selected': selected[q.id] ?? const <int>[]},
      ],
    );
    return result.when(
      success: (r) {
        final score = r.attempt.score;
        AppSnackbar.show(
          r.attempt.passed
              ? 'Passed with $score%${r.certificateIssued ? ' — certificate issued' : ''}'
              : 'Failed with $score%',
          '',
        );
        refreshAll();
        return null;
      },
      failure: (e) => e.message,
    );
  }

  /// "Edit Training" `onSave`. Returns the error, or null.
  Future<String?> saveEdit(TrainingFormValues values) async {
    String? uploaded;
    final file = values.materialFile;
    if (file != null) {
      final upload = await repository.uploadMaterial(file.path, file.name);
      final failed = upload.when(
        success: (url) {
          uploaded = url;
          return null;
        },
        failure: (e) => e.message,
      );
      if (failed != null) return failed;
    }
    final updateError = _error(
      await repository.updateCourse(courseId, values.toCourseBody(uploadedUrl: uploaded)),
    );
    if (updateError != null) return updateError;
    if (values.quizEnabled) {
      final quizError = _error(
        await repository.setQuestions(courseId, values.toQuestionsBody()),
      );
      if (quizError != null) return quizError;
    }
    AppSnackbar.show('Course updated', '');
    refreshAll();
    return null;
  }
}
