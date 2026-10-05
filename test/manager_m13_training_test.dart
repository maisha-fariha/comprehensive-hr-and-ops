import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/presentation/widgets/handover_common.dart';
import 'package:comprehensive_hr_and_ops/features/hr/training/data/mappers/hr_training_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/training/domain/entities/hr_training.dart';
import 'package:comprehensive_hr_and_ops/features/hr/training/domain/entities/training_course_view.dart';
import 'package:comprehensive_hr_and_ops/features/hr/training/domain/entities/training_form.dart';
import 'package:comprehensive_hr_and_ops/features/hr/training/domain/repositories/hr_training_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/training/presentation/controllers/hr_training_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/training/presentation/pages/hr_training_course_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/training/presentation/pages/hr_training_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

Future<void> _loadOutfitFont() async {
  final data = await rootBundle.load('assets/fonts/outfit/Outfit-Variable.ttf');
  final loader = FontLoader('Outfit')..addFont(Future.value(data));
  await loader.load();
}

Widget _app(Widget home) => ScreenUtilInit(
      designSize: const Size(
        ResponsiveHelper.baseWidth,
        ResponsiveHelper.baseHeight,
      ),
      minTextAdapt: true,
      builder: (_, _) => GetMaterialApp(
        home: home,
        theme: ThemeData(
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
      ),
    );

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) => _tap(tester, find.byKey(ValueKey(key)));

Future<void> _tapStrip(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  final strip = find
      .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right)
      .first;
  await tester.dragUntilVisible(target, strip, const Offset(-120, 0));
  await _tap(tester, target);
}

Finder _inKey(String key, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: matching);

Future<void> _closeTopSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

class _Session extends UserSession {
  final Set<String> denied;

  _Session({this.denied = const {}});

  @override
  bool can(String permission) => !denied.contains(permission);
}

const _ruma = TrainingStaffRef(
  id: 's1',
  firstName: 'Ruma',
  lastName: 'Begum',
  categoryName: 'Carer',
  residenceName: 'Elm House',
);
const _karim = TrainingStaffRef(id: 's2', firstName: 'Karim', lastName: 'Uddin', residenceName: 'Oak Lodge');
const _nadia = TrainingStaffRef(id: 's3', firstName: 'Nadia', lastName: 'Islam', residenceName: 'Elm House');

const _c1 = 'c1aaaaaa-0000-0000-0000-000000000001';

final _assignments = [
  TrainingAssignment(
    id: 'a1',
    courseId: _c1,
    staffId: 's1',
    staff: _ruma,
    dueAt: DateTime(2020, 1, 1),
    mandatory: true,
  ),
  const TrainingAssignment(id: 'a2', courseId: _c1, staffId: 's2', staff: _karim, status: 'in_progress'),
  TrainingAssignment(
    id: 'a3',
    courseId: _c1,
    staffId: 's3',
    staff: _nadia,
    status: 'completed',
    completedAt: DateTime(2026, 9, 3),
  ),
  const TrainingAssignment(id: 'a4', courseId: 'c3', staffId: 's1', staff: _ruma),
];

final _medication = TrainingCourse(
  id: _c1,
  title: 'Medication Basics',
  description: 'Read the MAR policy.',
  materialUrl: 'https://files.example/mar.pdf',
  materialType: 'document',
  category: 'Medication MAR',
  validityMonths: 12,
  passingScore: 80,
  attemptsAllowed: 3,
  isActive: true,
  createdAt: DateTime(2026, 8, 1),
);

const _archived = TrainingCourse(id: 'c2', title: 'Old Fire Drill', isActive: false);

const _firstAid = TrainingCourse(
  id: 'c3',
  title: 'First Aid',
  category: 'Health & Safety',
  certificateRequired: true,
  isActive: true,
);

const _staffOptions = [
  TrainingStaffOption(id: 's1', name: 'Ruma Begum', categoryId: 'cat-carer', residenceIds: ['elm']),
  TrainingStaffOption(id: 's2', name: 'Karim Uddin', categoryId: 'cat-nurse', residenceIds: ['oak']),
  TrainingStaffOption(id: 's3', name: 'Nadia Islam', categoryId: 'cat-carer', residenceIds: ['elm']),
  TrainingStaffOption(id: 's4', name: 'Tariq Hasan', categoryName: 'Nurse', firstResidenceName: 'Oak Lodge'),
];

const _quizBody = {
  'questions': [
    {
      'prompt': 'What is 1 + 2?',
      'type': 'single_choice',
      'options': ['One', 'Two', 'Three'],
      'correct': [2],
      'position': 0,
    },
  ],
};

const _question = TrainingQuestion(
  id: 'q1',
  prompt: 'What is 1 + 2?',
  type: 'single_choice',
  options: ['One', 'Two', 'Three'],
);

class _FakeTrainingRepo implements HrTrainingRepository {
  final List<(String, Object?)> calls = [];
  List<TrainingCourse> courseList = [_medication, _archived];
  bool failCourses = false;

  String _key(String id) => id.startsWith('c1') ? 'c1' : id;

  TrainingCourse _byId(String id) =>
      [_medication, _archived, _firstAid].firstWhere((c) => c.id == id);

  @override
  Future<Result<TrainingPage<TrainingCourse>>> courses({
    required bool includeArchived,
    required int page,
    required int limit,
  }) async {
    calls.add(('courses', includeArchived));
    if (failCourses) return Result.failure(const ApiError(message: 'offline'));
    final rows = includeArchived ? courseList : courseList.where((c) => !c.isArchived).toList();
    return Result.success(TrainingPage(items: rows, total: rows.length, totalPages: 1));
  }

  @override
  Future<Result<TrainingCourse>> course(String id) async => Result.success(_byId(id));

  @override
  Future<Result<TrainingCourse>> createCourse(Map<String, dynamic> body) async {
    calls.add(('createCourse', body));
    return Result.success(TrainingCourse(id: 'new-course', title: body['title'] as String));
  }

  @override
  Future<Result<void>> updateCourse(String id, Map<String, dynamic> body) async {
    calls.add(('updateCourse', [id, body]));
    return Result.success(null);
  }

  @override
  Future<Result<void>> removeCourse(String id) async {
    calls.add(('removeCourse', id));
    return Result.success(null);
  }

  @override
  Future<Result<TrainingQuiz>> quiz(String courseId) async => Result.success(
        TrainingQuiz(
          courseId: courseId,
          passingScore: _key(courseId) == 'c1' ? 80 : null,
          attemptsAllowed: 3,
          questions: _key(courseId) == 'c1' ? const [_question] : const [],
        ),
      );

  @override
  Future<Result<List<TrainingQuestion>>> authoredQuestions(String courseId) async {
    calls.add(('authoredQuestions', courseId));
    return Result.success(
      _key(courseId) == 'c1'
          ? HrTrainingMapper.questionsFrom({
              'questions': [
                {
                  'id': 'q1',
                  'prompt': 'What is 1 + 2?',
                  'type': 'single_choice',
                  'options': ['One', 'Two', 'Three'],
                  'correct': ['Three'],
                  'position': 0,
                },
              ],
            })
          : const [],
    );
  }

  @override
  Future<Result<void>> setQuestions(String courseId, Map<String, dynamic> body) async {
    calls.add(('setQuestions', [courseId, body]));
    return Result.success(null);
  }

  @override
  Future<Result<TrainingPage<TrainingAssignment>>> assignments({
    String? courseId,
    int? page,
    required int limit,
  }) async {
    final rows = courseId == null
        ? _assignments
        : _assignments.where((a) => a.courseId == courseId).toList();
    return Result.success(
      TrainingPage(
        items: rows,
        total: rows.length,
        summary: const TrainingSummary(
          assignments: 12,
          completed: 5,
          outstanding: 7,
          overdue: 2,
          mandatoryOutstanding: 3,
        ),
      ),
    );
  }

  @override
  Future<Result<List<TrainingAssignment>>> assign({
    required String courseId,
    required List<String> staffIds,
    required bool mandatory,
    String? dueAt,
  }) async {
    calls.add(('assign', {'courseId': courseId, 'staffIds': staffIds, 'mandatory': mandatory, 'dueAt': dueAt}));
    return Result.success([
      for (final id in staffIds) TrainingAssignment(id: 'n-$id', courseId: courseId, staffId: id),
    ]);
  }

  @override
  Future<Result<void>> updateAssignment(String id, Map<String, dynamic> body) async {
    calls.add(('updateAssignment', [id, body]));
    return Result.success(null);
  }

  @override
  Future<Result<void>> submitCertificate(String assignmentId, Map<String, dynamic> body) async {
    calls.add(('submitCertificate', [assignmentId, body]));
    return Result.success(null);
  }

  @override
  Future<Result<TrainingPage<TrainingAttempt>>> attempts({
    required String courseId,
    required int page,
    required int limit,
  }) async {
    final rows = _key(courseId) == 'c1'
        ? [
            TrainingAttempt(
              id: 't1',
              courseId: courseId,
              staffId: 's2',
              score: 67,
              passed: false,
              attemptNo: 1,
              submittedAt: DateTime(2026, 9, 2, 14, 5),
            ),
          ]
        : <TrainingAttempt>[];
    return Result.success(TrainingPage(items: rows, total: rows.length));
  }

  @override
  Future<Result<TrainingAttemptResult>> submitAttempt(
    String courseId, {
    required String staffId,
    required List<Map<String, dynamic>> answers,
  }) async {
    calls.add(('submitAttempt', {'courseId': courseId, 'staffId': staffId, 'answers': answers}));
    return Result.success(
      TrainingAttemptResult(
        attempt: TrainingAttempt(id: 't2', courseId: courseId, staffId: staffId, score: 100, passed: true),
        certificateIssued: true,
      ),
    );
  }

  @override
  Future<Result<TrainingPage<TrainingCertificate>>> certificates({
    required String courseId,
    required int page,
    required int limit,
  }) async {
    final rows = _key(courseId) == 'c1'
        ? [
            TrainingCertificate(
              id: 'cert1',
              courseId: courseId,
              staffId: 's1',
              staffFirstName: 'Ruma',
              staffLastName: 'Begum',
              issuedAt: DateTime(2026, 9, 1),
              reviewStatus: 'submitted',
              expiryStatus: 'valid',
              certificateNumber: 'FA-2026-8891',
              provider: 'St John Ambulance',
            ),
          ]
        : <TrainingCertificate>[];
    return Result.success(TrainingPage(items: rows, total: rows.length));
  }

  @override
  Future<Result<void>> reviewCertificate(String certificateId, Map<String, dynamic> body) async {
    calls.add(('reviewCertificate', [certificateId, body]));
    return Result.success(null);
  }

  @override
  Future<Result<List<TrainingAuditEntry>>> auditLogs(String courseId) async {
    calls.add(('auditLogs', courseId));
    return Result.success([
      TrainingAuditEntry(
        id: 'log1',
        action: 'training.course.create',
        outcome: 'success',
        actorName: 'Rafi Ahmed',
        createdAt: DateTime(2026, 8, 1, 9, 30),
      ),
    ]);
  }

  @override
  Future<Result<List<TrainingStaffOption>>> staff() async => Result.success(_staffOptions);

  @override
  Future<Result<List<TrainingOption>>> staffCategories() async =>
      Result.success(const [TrainingOption(id: 'cat-carer', label: 'Carer')]);

  @override
  Future<Result<List<TrainingOption>>> residences() async =>
      Result.success(const [TrainingOption(id: 'elm', label: 'Elm House')]);

  @override
  Future<Result<String>> uploadMaterial(String path, String fileName) async {
    calls.add(('uploadMaterial', fileName));
    return Result.success('https://files.example/$fileName');
  }

  Iterable<Object?> argsOf(String method) => calls.where((c) => c.$1 == method).map((c) => c.$2);
}

Future<TrainingMaterialFile?> _fakePick() async =>
    const TrainingMaterialFile(path: '/tmp/handbook.pdf', name: 'handbook.pdf', size: 1024);

_FakeTrainingRepo _register({_FakeTrainingRepo? repo, Set<String> denied = const {}}) {
  final fake = repo ?? _FakeTrainingRepo();
  final session = Get.put<UserSession>(_Session(denied: denied));
  GetIt.I.registerSingleton<HrTrainingRepository>(fake);
  GetIt.I.registerFactory<HrTrainingController>(
    () => HrTrainingController(repository: fake, session: session),
  );
  return fake;
}

Future<_FakeTrainingRepo> _pumpList(
  WidgetTester tester, {
  _FakeTrainingRepo? repo,
  Set<String> denied = const {},
}) async {
  _tallView(tester);
  final fake = _register(repo: repo, denied: denied);
  await tester.pumpWidget(_app(const HrTrainingPage(pickFile: _fakePick)));
  await tester.pumpAndSettle();
  return fake;
}

Future<_FakeTrainingRepo> _pumpCourse(
  WidgetTester tester, {
  String courseId = 'c1aaaaaa-0000-0000-0000-000000000001',
  String tab = 'overview',
  Set<String> denied = const {},
}) async {
  _tallView(tester);
  final fake = _register(denied: denied);
  await tester.pumpWidget(
    _app(HrTrainingCoursePage(courseId: courseId, initialTab: tab, pickFile: _fakePick)),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('M13 training mapper (live payload shapes)', () {
    test('courses page and assignment summary', () {
      final courses = HrTrainingMapper.coursesFrom({
        'data': [
          {
            'id': '97221ad9-1b1f-4b7f-9bb1-45987f3d4fc9',
            'title': 'Safeguarding Adults',
            'materialType': 'video',
            'isActive': true,
            'validityMonths': 24,
            'passingScore': 70,
            'certificateRequired': false,
            'createdAt': '2026-07-10T08:00:00.000Z',
          },
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 41, 'totalPages': 3},
      });
      expect(courses.items.single.title, 'Safeguarding Adults');
      expect(courses.items.single.isArchived, isFalse);
      expect(courses.total, 41);
      expect(courses.totalPages, 3);

      final page = HrTrainingMapper.assignmentsFrom({
        'data': [
          {
            'id': 'a1',
            'courseId': 'c1',
            'staffId': 's1',
            'status': 'assigned',
            'mandatory': true,
            'staff': {
              'id': 's1',
              'firstName': 'Ruma',
              'lastName': 'Begum',
              'category': {'name': 'Carer'},
              'staffResidences': [
                {
                  'residence': {'name': 'Elm House'},
                },
              ],
            },
          },
        ],
        'meta': {
          'total': 1,
          'totalPages': 1,
          'summary': {
            'assignments': 12,
            'completed': 5,
            'outstanding': 7,
            'overdue': 2,
            'mandatoryOutstanding': 3,
          },
        },
      });
      expect(page.summary?.assignments, 12);
      expect(page.summary?.mandatoryOutstanding, 3);
      expect(page.items.single.staff?.name, 'Ruma Begum');
      expect(page.items.single.staff?.categoryName, 'Carer');
      expect(page.items.single.staff?.residenceName, 'Elm House');
    });

    test('authored questions give the answer key as option text', () {
      final questions = HrTrainingMapper.questionsFrom({
        'questions': [
          {
            'id': 'q1',
            'prompt': 'What is 1 + 2?',
            'type': 'single_choice',
            'options': ['One', 'Two', 'Three'],
            'correct': ['Three'],
          },
          {
            'id': 'q2',
            'prompt': 'Pick evens',
            'type': 'multi_choice',
            'optionsJson': ['1', '2', '4'],
            'correctJson': [1, 2],
          },
        ],
      });
      expect(questions[0].correct, [2]);
      expect(questions[1].options, ['1', '2', '4']);
      expect(questions[1].correct, [1, 2]);
    });

    test('staff directory and attempt result', () {
      final staff = HrTrainingMapper.staffFrom({
        'data': [
          {
            'id': 's1',
            'firstName': 'Ruma',
            'lastName': 'Begum',
            'categoryId': 'cat-carer',
            'category': {'name': 'Carer'},
            'residences': [
              {'id': 'elm', 'name': 'Elm House', 'isPrimary': true},
            ],
          },
        ],
      });
      expect(staff.single.name, 'Ruma Begum');
      expect(staff.single.residenceIds, ['elm']);
      expect(staff.single.role, 'Carer · Elm House');

      final result = HrTrainingMapper.attemptResultFrom({
        'data': {
          'attempt': {'id': 't', 'courseId': 'c', 'staffId': 's1', 'score': 100, 'passed': true},
          'certificate': {'id': 'cert'},
        },
      });
      expect(result?.attempt.passed, isTrue);
      expect(result?.certificateIssued, isTrue);
    });
  });

  group('M13 training form model', () {
    test('create strips nulls, edit sends them', () {
      final values = TrainingFormValues(title: '  Moving & Handling ', category: 'Clinical')
        ..expiryPeriod = 'No Expiry'
        ..quizEnabled = false;
      final create = values.toCourseBody(create: true);
      expect(create, {
        'title': 'Moving & Handling',
        'category': 'Clinical',
        'materialType': 'link',
        'certificateRequired': false,
      });
      final edit = values.toCourseBody();
      expect(edit.containsKey('description'), isTrue);
      expect(edit['validityMonths'], isNull);
      expect(edit['passingScore'], isNull);

      values
        ..expiryPeriod = 'Custom'
        ..customDurationValue = 2
        ..customDurationUnit = 'Years'
        ..type = 'Video';
      expect(values.toCourseBody(uploadedUrl: 'https://u', create: true), containsPair('validityMonths', 24));
      expect(values.toCourseBody(uploadedUrl: 'https://u')['materialUrl'], 'https://u');
      expect(values.materialType, 'video');
    });

    test('questions body, reach and validation use the web rules', () {
      final values = TrainingFormValues(
        questions: [
          TrainingFormQuestion(id: 'x', question: 'Sky?', options: ['Blue', 'Green'], correctAnswer: 'Green'),
          TrainingFormQuestion(id: 'y', question: 'Hot?', type: 'True / False', options: ['True', 'False']),
        ],
      );
      expect(values.toQuestionsBody()['questions'], [
        {'prompt': 'Sky?', 'type': 'single_choice', 'options': ['Blue', 'Green'], 'correct': [1], 'position': 0},
        {'prompt': 'Hot?', 'type': 'true_false', 'options': ['True', 'False'], 'correct': [0], 'position': 1},
      ]);

      expect((values..assignTo = 'All Staff').resolveStaffIds(_staffOptions), hasLength(4));
      expect(
        (values
              ..assignTo = 'Specific Roles'
              ..roles = ['cat-carer'])
            .resolveStaffIds(_staffOptions),
        ['s1', 's3'],
      );
      expect(
        (values
              ..assignTo = 'Specific Residence'
              ..residences = ['oak'])
            .resolveStaffIds(_staffOptions),
        ['s2'],
      );

      final errors = TrainingFormValues(expiryPeriod: 'Custom').validate();
      expect(errors, {
        'title': 'Training title is required',
        'category': 'Category is required',
        'customDurationValue': 'Say how long it stays valid',
        'staffIds': 'Pick at least one person',
      });
    });

    test('quiz drafts validate in the web order', () {
      String? check(TrainingQuizDraft d) => TrainingQuizDraft.validate([d]);
      expect(check(TrainingQuizDraft()), 'Question 1 has no prompt.');
      expect(check(TrainingQuizDraft(prompt: 'Q', options: ['A', ' '])), 'Question 1 needs at least two options.');
      expect(check(TrainingQuizDraft(prompt: 'Q', options: ['A', 'B'])), 'Question 1 has no correct answer marked.');
      expect(
        check(TrainingQuizDraft(prompt: 'Q', options: ['A', 'B'], correct: [0, 1])),
        'Question 1 allows only one correct answer — change its type or unmark one.',
      );
      expect(check(TrainingQuizDraft(prompt: 'Q', type: 'multi_choice', options: ['A', 'B'], correct: [0, 1])),
          isNull);
    });

    test('course view derives stats, progress and the card badge', () {
      final view = TrainingCourseView.from(
        _medication,
        assignments: _assignments.where((a) => a.courseId == _c1).toList(),
        attempts: const [TrainingAttempt(id: 't', courseId: _c1, staffId: 's2', score: 67, passed: false)],
        certificates: const [
          TrainingCertificate(id: 'x', courseId: _c1, staffId: 's3', reviewStatus: 'approved'),
        ],
      );
      expect(view.code, 'TRN-C1AAAAAA');
      expect(view.expiryPeriod, '1 Year');
      expect(view.type, 'Document');
      expect(view.content.single.type, 'PDF');
      expect(view.stats.assigned, 3);
      expect(view.stats.completed, 1);
      expect(view.stats.inProgress, 1);
      expect(view.stats.overdue, 1);
      expect(view.stats.certificatesIssued, 1);
      expect(view.stats.percentComplete, 33);
      expect(view.cardBadge, 'Overdue');
      expect(view.mandatory, isTrue);
      expect([for (final p in view.staffProgress) p.status], ['Overdue', 'In Progress', 'Completed']);
      expect(view.staffProgress[1].quizScore, 67);
      expect(view.staffProgress[2].certificateIssued, isTrue);
    });
  });

  group('M13 training list page', () {
    testWidgets('shows KPIs, course cards and rows with manage actions', (tester) async {
      await _pumpList(tester);

      expect(find.text('Training'), findsOneWidget);
      expect(_inKey('training-kpi-assignments', find.text('12')), findsOneWidget);
      expect(_inKey('training-kpi-completed', find.text('5')), findsOneWidget);
      expect(_inKey('training-kpi-overdue', find.text('2')), findsOneWidget);
      expect(_inKey('training-kpi-mandatory', find.text('3')), findsOneWidget);
      expect(find.text('MANDATORY OUTSTANDING'), findsOneWidget);

      expect(find.text('Training Courses'), findsOneWidget);
      expect(find.text('1 courses'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Pass at 80% · 3 attempts'), findsOneWidget);
      expect(find.text('Valid 12 months'), findsOneWidget);

      expect(find.byKey(const ValueKey('training-new-course')), findsOneWidget);
      expect(find.byKey(ValueKey('training-archive-${_medication.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('training-delete-${_medication.id}')), findsOneWidget);
    });

    testWidgets('training:read alone hides every write action', (tester) async {
      await _pumpList(tester, denied: {'training:manage'});

      expect(find.byKey(const ValueKey('training-new-course')), findsNothing);
      expect(find.byKey(ValueKey('training-archive-${_medication.id}')), findsNothing);
      expect(find.byKey(ValueKey('training-delete-${_medication.id}')), findsNothing);
      expect(find.byKey(ValueKey('training-open-${_medication.id}')), findsOneWidget);
    });

    testWidgets('show archived, archive, restore and delete', (tester) async {
      final fake = await _pumpList(tester);

      await _tapKey(tester, 'training-archive-${_medication.id}');
      expect(fake.argsOf('updateCourse').last, [_medication.id, {'isActive': false}]);
      expect(find.text('Course archived'), findsOneWidget);

      await _tapKey(tester, 'training-show-archived');
      expect(fake.argsOf('courses').last, isTrue);
      expect(find.text('Archived shown'), findsOneWidget);
      await _tapKey(tester, 'training-restore-c2');
      expect(fake.argsOf('updateCourse').last, ['c2', {'isActive': true}]);
      expect(find.text('Course restored'), findsOneWidget);

      await _tapKey(tester, 'training-delete-c2');
      expect(find.text('Delete this course?'), findsOneWidget);
      await _tapKey(tester, 'training-confirm');
      expect(fake.argsOf('removeCourse').single, 'c2');
      expect(find.text('Delete this course?'), findsNothing);
      expect(find.text('Course deleted'), findsOneWidget);
    });

    testWidgets('a failed load shows the error state', (tester) async {
      await _pumpList(tester, repo: _FakeTrainingRepo()..failCourses = true);
      expect(find.text('Training could not be loaded'), findsOneWidget);
      expect(find.text('offline'), findsOneWidget);
    });
  });

  group('M13 create training wizard', () {
    testWidgets('walks the five steps and publishes course, quiz and assignment', (tester) async {
      final fake = await _pumpList(tester);
      await _tapKey(tester, 'training-new-course');
      expect(find.text('Create New Training'), findsOneWidget);
      expect(find.text('Setup Progress · Step 1 of 5'), findsOneWidget);

      await _tapKey(tester, 'training-form-next');
      expect(find.text('Training title is required'), findsOneWidget);
      expect(find.text('Category is required'), findsOneWidget);

      await tester.enterText(_inKey('training-form-title', find.byType(TextField)), 'Fire Safety 2026');
      await _tapKey(tester, 'training-form-category');
      await _tap(tester, find.text('Compliance').last);
      await _tapKey(tester, 'training-form-next');
      expect(find.text('Setup Progress · Step 2 of 5'), findsOneWidget);

      await _tapKey(tester, 'training-form-upload');
      expect(find.text('handbook.pdf'), findsOneWidget);
      await _tapKey(tester, 'training-form-next');

      await _tapKey(tester, 'training-form-add-question');
      await tester.enterText(find.widgetWithText(TextField, 'Enter the question'), 'Exit route?');
      await tester.enterText(find.widgetWithText(TextField, 'Option A'), 'Lift');
      await tester.enterText(find.widgetWithText(TextField, 'Option B'), 'Stairs');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Select correct answer'));
      await _tap(tester, find.text('Stairs').last);
      await _tapKey(tester, 'training-form-next');

      await _tap(tester, find.byKey(const ValueKey('training-staff-search')));
      await _tapKey(tester, 'training-staff-option-s4');
      expect(find.text('Estimated reach: 1 staff members'), findsOneWidget);
      await _tapKey(tester, 'training-form-next');

      expect(find.text('Review & Publish'), findsOneWidget);
      expect(find.text('Publish Training'), findsOneWidget);
      await _tapKey(tester, 'training-form-publish');

      expect(fake.argsOf('uploadMaterial').single, 'handbook.pdf');
      expect(fake.argsOf('createCourse').single, {
        'title': 'Fire Safety 2026',
        'category': 'Compliance',
        'materialType': 'link',
        'materialUrl': 'https://files.example/handbook.pdf',
        'certificateRequired': false,
        'passingScore': 80,
        'attemptsAllowed': 3,
        'validityMonths': 12,
      });
      expect(fake.argsOf('setQuestions').single, [
        'new-course',
        {
          'questions': [
            {'prompt': 'Exit route?', 'type': 'single_choice', 'options': ['Lift', 'Stairs'], 'correct': [1], 'position': 0},
          ],
        },
      ]);
      expect(fake.argsOf('assign').single, {
        'courseId': 'new-course',
        'staffIds': ['s4'],
        'mandatory': true,
        'dueAt': null,
      });
      expect(find.text('Create New Training'), findsNothing);
      expect(find.text('Course created and assigned to 1 person'), findsOneWidget);
    });

    testWidgets('publishing with a hidden-step error jumps back to that step', (tester) async {
      final fake = await _pumpList(tester);
      await _tapKey(tester, 'training-new-course');
      await _tapStrip(tester, 'training-step-tab-reviewPublish');
      await _tapKey(tester, 'training-form-publish');

      expect(find.text('Setup Progress · Step 1 of 5'), findsOneWidget);
      expect(find.text('Training title is required'), findsOneWidget);
      expect(fake.argsOf('createCourse'), isEmpty);
    });
  });

  group('M13 course detail page', () {
    testWidgets('header, KPIs and tabs for a manager', (tester) async {
      final fake = await _pumpCourse(tester);

      expect(find.text('Back to Training'), findsOneWidget);
      expect(find.text('Medication Basics'), findsOneWidget);
      expect(find.text('TRN-C1AAAAAA'), findsOneWidget);
      expect(find.text('Mandatory'), findsOneWidget);
      expect(find.text('Created on: 01/08/2026'), findsOneWidget);
      expect(_inKey('training-course-kpi-assigned', find.text('3')), findsOneWidget);
      expect(_inKey('training-course-kpi-overdue', find.text('1')), findsOneWidget);
      expect(_inKey('training-course-kpi-certificates', find.text('0')), findsOneWidget);
      expect(find.text('About this course'), findsOneWidget);
      expect(find.text('Marked complete directly, or by passing the quiz'), findsOneWidget);
      expect(find.byKey(const ValueKey('training-assign-training')), findsOneWidget);
      expect(find.byKey(const ValueKey('training-edit-training')), findsOneWidget);
      expect(fake.argsOf('authoredQuestions'), hasLength(1));

      await _tapStrip(tester, 'training-tab-content');
      expect(find.text('Medication Basics'), findsWidgets);
      expect(_inKey('training-content-material', find.text('Change material')), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);

      await _tapStrip(tester, 'training-tab-history');
      expect(find.text('Activity History'), findsOneWidget);

      await _tapKey(tester, 'training-assign-training');
      expect(find.byKey(const ValueKey('training-assign-staff')), findsOneWidget);
    });

    testWidgets('training:read alone sees the course without any action', (tester) async {
      final fake = await _pumpCourse(tester, tab: 'assignments', denied: {'training:manage'});

      expect(find.byKey(const ValueKey('training-assign-training')), findsNothing);
      expect(find.byKey(const ValueKey('training-edit-training')), findsNothing);
      expect(find.byKey(const ValueKey('training-assign-staff')), findsNothing);
      expect(find.byKey(const ValueKey('training-advance-a1')), findsNothing);
      expect(find.byKey(const ValueKey('training-assignment-a1')), findsOneWidget);
      expect(fake.argsOf('authoredQuestions'), isEmpty);

      await _tapStrip(tester, 'training-tab-quiz');
      expect(find.byKey(const ValueKey('training-quiz-write')), findsNothing);
      await _tapStrip(tester, 'training-tab-sittings');
      expect(find.byKey(const ValueKey('training-record-sitting')), findsNothing);
      await _tapStrip(tester, 'training-tab-certificates');
      expect(find.byKey(const ValueKey('training-certificate-approve-cert1')), findsNothing);
    });

    testWidgets('assign staff validates, then writes one call for the group', (tester) async {
      final fake = await _pumpCourse(tester, tab: 'assignments');

      expect(_inKey('training-assignment-a1', find.text('Ruma Begum')), findsOneWidget);
      expect(_inKey('training-assignment-a1', find.text('01/01/2020 · overdue')), findsOneWidget);

      await _tapKey(tester, 'training-assign-staff');
      await _tapKey(tester, 'training-assign-submit');
      expect(_inKey('training-assign-error', find.text('Choose at least one person.')), findsOneWidget);
      expect(fake.argsOf('assign'), isEmpty);

      await _tapKey(tester, 'training-picker-Staff');
      await _tap(tester, find.text('Tariq Hasan').last);
      await _closeTopSheet(tester);
      await _tapKey(tester, 'training-assign-submit');

      expect(fake.argsOf('assign').single, {
        'courseId': _medication.id,
        'staffIds': ['s4'],
        'mandatory': true,
        'dueAt': null,
      });
      expect(find.byKey(const ValueKey('training-assign-submit')), findsNothing);
      expect(find.text('1 assignment written'), findsOneWidget);
    });

    testWidgets('start and mark complete advance an assignment', (tester) async {
      final fake = await _pumpCourse(tester, tab: 'assignments');

      expect(_inKey('training-advance-a1', find.text('Start')), findsOneWidget);
      expect(_inKey('training-advance-a2', find.text('Mark complete')), findsOneWidget);
      expect(find.byKey(const ValueKey('training-advance-a3')), findsNothing);

      await _tapKey(tester, 'training-advance-a1');
      expect(fake.argsOf('updateAssignment').last, ['a1', {'status': 'in_progress'}]);
      expect(find.text('Started'), findsOneWidget);

      await _tapKey(tester, 'training-advance-a2');
      final call = fake.argsOf('updateAssignment').last! as List;
      final body = call[1] as Map<String, dynamic>;
      expect(call[0], 'a2');
      expect(body['status'], 'completed');
      expect(DateTime.tryParse(body['completedAt'] as String), isNotNull);
      expect(find.text('Marked complete'), findsOneWidget);
    });

    testWidgets('a certificate-required course submits the certificate instead', (tester) async {
      final fake = await _pumpCourse(tester, courseId: 'c3', tab: 'assignments');

      expect(find.byKey(const ValueKey('training-advance-a4')), findsNothing);
      await _tapKey(tester, 'training-submit-certificate-a4');
      expect(find.text('Submit the certificate'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'FA-2026-8891'), ' FA-1 ');
      await tester.enterText(find.widgetWithText(TextField, 'St John Ambulance'), 'Red Cross');
      await _tapKey(tester, 'training-certificate-send');

      expect(fake.argsOf('submitCertificate').single, ['a4', {'certificateNumber': 'FA-1', 'provider': 'Red Cross'}]);
      expect(find.text('Sent for review'), findsOneWidget);
    });

    testWidgets('certificates are approved or sent back with a reason', (tester) async {
      final fake = await _pumpCourse(tester, tab: 'certificates');

      expect(_inKey('training-certificate-cert1', find.text('Waiting')), findsOneWidget);
      expect(_inKey('training-certificate-cert1', find.text('FA-2026-8891')), findsOneWidget);

      await _tapKey(tester, 'training-certificate-approve-cert1');
      expect(fake.argsOf('reviewCertificate').last, ['cert1', {'decision': 'approve'}]);
      expect(find.text('Certificate approved'), findsOneWidget);

      await _tapKey(tester, 'training-certificate-reject-cert1');
      final submit = find.byKey(const ValueKey('training-send-back-submit'));
      expect(tester.widget<HandoverButton>(submit).onPressed, isNull);
      await tester.enterText(
        _inKey('training-send-back-notes', find.byType(TextField)),
        ' Re-scan showing the expiry date. ',
      );
      await tester.pumpAndSettle();
      await _tap(tester, submit);

      expect(
        fake.argsOf('reviewCertificate').last,
        ['cert1', {'decision': 'reject', 'reviewNotes': 'Re-scan showing the expiry date.'}],
      );
      expect(find.text('Sent back'), findsWidgets);
    });

    testWidgets('quiz rewrite needs every answer re-marked before it saves', (tester) async {
      final fake = await _pumpCourse(tester, tab: 'quiz');

      expect(find.text('1 question · pass at 80%'), findsOneWidget);
      expect(find.text('1. What is 1 + 2?'), findsOneWidget);
      await _tapKey(tester, 'training-quiz-write');
      expect(find.textContaining('Saving replaces the whole quiz.'), findsOneWidget);

      await _tapKey(tester, 'training-quiz-save');
      expect(_inKey('training-quiz-error', find.text('Question 1 has no correct answer marked.')), findsOneWidget);
      expect(fake.argsOf('setQuestions'), isEmpty);

      await _tapKey(tester, 'training-quiz-correct-1-2');
      await _tapKey(tester, 'training-quiz-save');
      expect(fake.argsOf('setQuestions').single, [_medication.id, _quizBody]);
      expect(find.text('Quiz saved'), findsOneWidget);
      expect(find.byKey(const ValueKey('training-quiz-save')), findsNothing);
    });

    testWidgets('record a sitting is marked by the API', (tester) async {
      final fake = await _pumpCourse(tester, tab: 'sittings');

      expect(_inKey('training-sitting-t1', find.text('Karim Uddin')), findsOneWidget);
      expect(_inKey('training-sitting-t1', find.text('1 of 3')), findsOneWidget);
      expect(_inKey('training-sitting-t1', find.text('02/09/2026 14:05')), findsOneWidget);

      await _tapKey(tester, 'training-record-sitting');
      await _tapKey(tester, 'training-sitting-submit');
      expect(_inKey('training-sitting-error', find.text('Choose who sat the quiz.')), findsOneWidget);

      await _tapKey(tester, 'training-sitting-staff');
      await _tap(tester, find.text('Ruma Begum').last);
      await _tapKey(tester, 'training-sitting-answer-q1-2');
      await _tapKey(tester, 'training-sitting-submit');

      expect(fake.argsOf('submitAttempt').single, {
        'courseId': _medication.id,
        'staffId': 's1',
        'answers': [
          {
            'questionId': 'q1',
            'selected': [2],
          },
        ],
      });
      expect(find.text('Passed with 100% — certificate issued'), findsOneWidget);
    });

    testWidgets('sittings are disabled when the course has no quiz', (tester) async {
      await _pumpCourse(tester, courseId: 'c3', tab: 'sittings');
      expect(find.text('This course has no quiz to sit — it needs questions and a pass mark.'), findsOneWidget);
      await _tapKey(tester, 'training-record-sitting');
      expect(find.byKey(const ValueKey('training-sitting-submit')), findsNothing);
    });

    testWidgets('completions show progress and filter by status', (tester) async {
      await _pumpCourse(tester, tab: 'completions');

      expect(find.text('1 of 3 staff have completed this training'), findsOneWidget);
      expect(find.text('33% complete'), findsOneWidget);
      expect(find.byKey(const ValueKey('training-progress-a1')), findsOneWidget);
      expect(_inKey('training-progress-a2', find.text('67%')), findsOneWidget);

      await _tapKey(tester, 'training-completions-filters');
      expect(find.text('FILTER BY'), findsOneWidget);
      await _tapKey(tester, 'training-filter-Status');
      await _tap(tester, find.text('Completed').last);
      expect(_inKey('training-filter-Status', find.text('Completed')), findsOneWidget);
      await _tapKey(tester, 'training-filters-done');

      expect(find.byKey(const ValueKey('training-progress-a3')), findsOneWidget);
      expect(find.byKey(const ValueKey('training-progress-a1')), findsNothing);

      await _tap(tester, find.text('Clear filters'));
      expect(find.byKey(const ValueKey('training-progress-a1')), findsOneWidget);
    });

    testWidgets('history reads the audit trail only with compliance:read', (tester) async {
      final fake = await _pumpCourse(tester, tab: 'history');
      expect(find.text('Training course create'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(fake.argsOf('auditLogs'), hasLength(1));
    });

    testWidgets('history without compliance:read shows the empty trail', (tester) async {
      final fake = await _pumpCourse(tester, tab: 'history', denied: {'compliance:read'});
      expect(find.text('Nothing has changed on this course since the audit trail began.'), findsOneWidget);
      expect(fake.argsOf('auditLogs'), isEmpty);
    });

    testWidgets('edit training keeps the authored quiz and saves the full body', (tester) async {
      final fake = await _pumpCourse(tester);

      await _tapKey(tester, 'training-edit-training');
      expect(find.text('Edit Training'), findsOneWidget);
      expect(find.text('EDITING · TRN-C1AAAAAA'), findsOneWidget);
      await _tapStrip(tester, 'training-step-tab-reviewPublish');
      expect(find.text('Save Changes'), findsOneWidget);
      await _tapKey(tester, 'training-form-publish');

      expect(find.text('Pick at least one person'), findsOneWidget);
      expect(find.text('Setup Progress · Step 4 of 5'), findsOneWidget);
      expect(fake.argsOf('updateCourse'), isEmpty);
      await _tapKey(tester, 'training-choice-All Staff');
      await _tapStrip(tester, 'training-step-tab-reviewPublish');
      await _tapKey(tester, 'training-form-publish');

      expect(fake.argsOf('assign'), isEmpty);
      final call = fake.argsOf('updateCourse').single! as List;
      expect(call[0], _medication.id);
      expect(call[1], {
        'title': 'Medication Basics',
        'description': 'Read the MAR policy.',
        'category': 'Medication MAR',
        'materialType': 'document',
        'materialUrl': 'https://files.example/mar.pdf',
        'certificateRequired': false,
        'passingScore': 80,
        'attemptsAllowed': 3,
        'validityMonths': 12,
      });
      expect(fake.argsOf('setQuestions').single, [_medication.id, _quizBody]);
      expect(find.text('Course updated'), findsOneWidget);
    });
  });
}
