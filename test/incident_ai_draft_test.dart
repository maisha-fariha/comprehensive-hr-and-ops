import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/data/mappers/incidents_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_ai_draft.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_category_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_cir_template_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_client_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_residence_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incident_staff_option.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/entities/incidents_enums.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/domain/repositories/incidents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/presentation/controllers/incident_creation_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/incidents/presentation/widgets/steps/step1_details_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

Future<void> _loadOutfitFont() async {
  final data = await rootBundle.load('assets/fonts/outfit/Outfit-Variable.ttf');
  final loader = FontLoader('Outfit')..addFont(Future.value(data));
  await loader.load();
}

class _Session extends UserSession {
  @override
  String get displayName => 'Rifat Islam';

  @override
  String? get residenceId => 'res-1';

  @override
  String? get residenceName => 'Elm House';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepo implements IncidentsRepository {
  IncidentAiDraft? draft;
  bool aiEnabled;

  _FakeRepo({this.draft, this.aiEnabled = true});

  @override
  Future<Result<bool>> isAiDraftingEnabled() async => Result.success(aiEnabled);

  @override
  Future<Result<IncidentAiDraft>> draftIncidentFromNotes({
    required String notes,
    String? residenceId,
    String? clientId,
    String? categoryId,
    List<String>? detectedDuringOptions,
    List<String>? notificationParties,
  }) async {
    final value = draft;
    if (value == null) {
      return Result.failure(const ApiError(message: 'no draft'));
    }
    return Result.success(value);
  }

  @override
  Future<Result<List<IncidentCategoryOption>>> getCategories() async =>
      Result.success(const [
        IncidentCategoryOption(
          id: '3fdd589c-7dc2-43ba-b014-2579cf2b6d9b',
          name: 'Fall',
        ),
      ]);

  @override
  Future<Result<List<IncidentCirTemplateOption>>> getCirTemplates() async =>
      Result.success(const []);

  @override
  Future<Result<List<IncidentResidenceOption>>> getResidences() async =>
      Result.success(const [
        IncidentResidenceOption(id: 'res-1', name: 'Elm House'),
      ]);

  @override
  Future<Result<List<IncidentStaffOption>>> getStaff() async =>
      Result.success(const [
        IncidentStaffOption(
          id: '3dd5350e-4a96-4e63-aae6-fde487b1d9d9',
          name: 'Rifat Islam',
        ),
      ]);

  @override
  Future<Result<List<IncidentClientOption>>> searchClients(String search) async =>
      Result.success(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget home) => ScreenUtilInit(
      designSize: const Size(
        ResponsiveHelper.baseWidth,
        ResponsiveHelper.baseHeight,
      ),
      minTextAdapt: true,
      builder: (_, _) => GetMaterialApp(home: home),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
  });

  tearDown(Get.reset);

  test('IncidentsMapper.aiDraftFrom maps web POST /ai/incidents/draft', () {
    final draft = IncidentsMapper.aiDraftFrom({
      'data': {
        'date': '2026-11-02',
        'time': '14:20',
        'endTime': null,
        'categoryId': '3fdd589c-7dc2-43ba-b014-2579cf2b6d9b',
        'clientId': null,
        'residenceId': null,
        'detectedDuring': null,
        'witnesses': ['Priya'],
        'externalAgency': null,
        'notifications': [
          {'party': "Child's Family", 'contactName': null, 'date': null},
        ],
        'title': 'Mary slipped in the lounge',
        'description': 'At around 14:20, Mary slipped in the lounge.',
        'immediateAction': "Mary's son was called.",
        'severity': 'low',
        'emergencyServicesContacted': null,
        'familyNotified': true,
        'categoryDetail': 'slipped in the lounge',
        'reportedBy': {
          'id': '3dd5350e-4a96-4e63-aae6-fde487b1d9d9',
          'name': 'Rifat Islam',
        },
        'supervisor': null,
        'child': {
          'idNumber': null,
          'cfsStatus': [],
          'cipName': null,
          'cipOffice': null,
          'informedOfRights': null,
        },
        'followUp': {'required': null, 'dueDate': null},
        'debrief': {'completed': null, 'details': null},
        'missing': ['Confirm which resident'],
        'cirAnswers': {},
        'model': 'claude-opus-5-5',
      },
    });

    expect(draft.title, 'Mary slipped in the lounge');
    expect(draft.time, '14:20');
    expect(draft.severity, 'low');
    expect(draft.familyNotified, isTrue);
    expect(draft.witnesses, ['Priya']);
    expect(draft.notifications.single.party, "Child's Family");
    expect(draft.missing, ['Confirm which resident']);
    expect(draft.reportedBy?.name, 'Rifat Islam');
  });

  test('applyAiDraft fills step 1 fields from AI draft', () {
    final controller = IncidentCreationController(
      repository: _FakeRepo(),
      session: _Session(),
    );
    controller.categories.assignAll(const [
      IncidentCategoryOption(
        id: '3fdd589c-7dc2-43ba-b014-2579cf2b6d9b',
        name: 'Fall',
      ),
    ]);

    controller.applyAiDraft(
      const IncidentAiDraft(
        date: '2026-11-02',
        time: '14:20',
        categoryId: '3fdd589c-7dc2-43ba-b014-2579cf2b6d9b',
        title: 'Mary slipped in the lounge',
        description: 'At around 14:20, Mary slipped in the lounge.',
        immediateAction: "Mary's son was called.",
        severity: 'low',
        familyNotified: true,
        categoryDetail: 'slipped in the lounge',
        witnesses: ['Priya'],
        reportedBy: IncidentAiPerson(
          id: '3dd5350e-4a96-4e63-aae6-fde487b1d9d9',
          name: 'Rifat Islam',
        ),
      ),
    );

    expect(controller.incidentTitleController.text, 'Mary slipped in the lounge');
    expect(
      controller.descriptionController.text,
      'At around 14:20, Mary slipped in the lounge.',
    );
    expect(controller.incidentTimeController.text, '14:20');
    expect(controller.incidentDateController.text, '11/02/2026');
    expect(controller.severity.value, IncidentSeverity.low);
    expect(controller.selectedCategory.value?.name, 'Fall');
    expect(controller.immediateActionController.text, "Mary's son was called.");
    expect(controller.familyGuardianNotified.value, isTrue);
    expect(controller.witnesses, ['Priya']);
    expect(controller.categoryDetailController.text, 'slipped in the lounge');
  });

  testWidgets('Step 1 shows Draft from my notes when AI is enabled',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = Get.put(
      IncidentCreationController(
        repository: _FakeRepo(aiEnabled: true),
        session: _Session(),
      ),
    );
    controller.aiDraftingEnabled.value = true;

    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SingleChildScrollView(
            child: Step1DetailsForm(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Draft from my notes'), findsOneWidget);
    expect(find.byKey(const Key('incident-draft-from-notes')), findsOneWidget);
  });

  testWidgets('Step 1 hides Draft from my notes when AI is disabled',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = Get.put(
      IncidentCreationController(
        repository: _FakeRepo(aiEnabled: false),
        session: _Session(),
      ),
    );
    controller.aiDraftingEnabled.value = false;

    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SingleChildScrollView(
            child: Step1DetailsForm(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Draft from my notes'), findsNothing);
  });
}
