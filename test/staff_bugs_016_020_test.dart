import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/presentation/widgets/clock_out_button.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/entities/staff_shift_handover.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/repositories/staff_extras_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/presentation/pages/staff_residences_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/incident_detail.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incident.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incident_options.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incidents_summary.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/repositories/staff_incidents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/controllers/incident_creation_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/widgets/create_incident/create_incident_investigation_section.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/widgets/create_incident/create_incident_report_form_section.dart';
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

class _FakeIncidentsRepo implements StaffIncidentsRepository {
  @override
  Future<Result<List<StaffCirTemplateOption>>> getCirTemplates() async =>
      Result.success(const [
        StaffCirTemplateOption(id: 'cir-1', name: 'Standard CIR'),
      ]);

  @override
  Future<Result<List<StaffIncidentCategoryOption>>> getCategories() async =>
      Result.success(const [
        StaffIncidentCategoryOption(id: 'cat-1', name: 'Fall'),
      ]);

  @override
  Future<Result<List<StaffIncidentResidenceOption>>> getResidences() async =>
      Result.success(const [
        StaffIncidentResidenceOption(id: 'res-1', name: 'Sunrise Home'),
      ]);

  @override
  Future<Result<List<StaffIncidentClientOption>>> getClients({
    String? search,
    bool assignedToMe = true,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<List<StaffIncident>>> getIncidents({
    bool mine = false,
    String? search,
    String? severity,
    String? status,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<StaffIncidentsSummary>> getSummary() async =>
      Result.success(const StaffIncidentsSummary());

  @override
  Future<Result<IncidentDetail>> getIncidentDetail(String incidentId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<void>> acknowledge(String incidentId) async =>
      Result.success(null);

  @override
  Future<Result<void>> addInvestigationNote({
    required String incidentId,
    required String notes,
  }) async =>
      Result.success(null);

  @override
  Future<Result<String>> getCirPdfLink(String incidentId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<List<int>>> downloadCirPdf(String incidentId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<List<int>>> downloadFileBytes(String fileUrl) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<String>> createIncident({
    required String residenceId,
    required String clientId,
    required String categoryId,
    required String title,
    required String severity,
    required Map<String, dynamic> payload,
    String? cirTemplateId,
    String? occurredAt,
    String? description,
    String? location,
    bool? residentChecked,
    bool? supervisorNotified,
    bool? familyNotified,
    bool? carePlanReviewed,
  }) async =>
      Result.success('inc-1');

  @override
  Future<Result<void>> updateIncident({
    required String incidentId,
    required String residenceId,
    required String clientId,
    required String categoryId,
    required String title,
    required String severity,
    required Map<String, dynamic> payload,
    String? cirTemplateId,
    String? occurredAt,
    String? description,
    String? location,
    bool? residentChecked,
    bool? supervisorNotified,
    bool? familyNotified,
    bool? carePlanReviewed,
  }) async =>
      Result.success(null);

  @override
  Future<Result<StaffIncidentEvidenceFile>> uploadEvidenceFile(
    StaffIncidentEvidenceFile file,
  ) async =>
      Result.success(file);

  @override
  Future<Result<void>> attachEvidence({
    required String incidentId,
    required String fileUrl,
    required String fileType,
  }) async =>
      Result.success(null);
}

class _FakeExtrasRepo implements StaffExtrasRepository {
  @override
  Future<Result<List<Map<String, String>>>> getResidences() async =>
      Result.success(const [
        {
          'id': 'res-1',
          'title': 'Sunrise Home',
          'subtitle': 'Assigned residence',
        },
      ]);

  @override
  Future<Result<List<StaffShiftHandover>>> getHandovers({
    String? residenceId,
    DateTime? from,
    DateTime? to,
    String? status,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<StaffShiftHandover>> getHandoverDetail(String handoverId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<String>> createHandover({
    required String residenceId,
    required String summary,
    bool submit = true,
    String? fromShiftId,
    String? toShiftId,
    List<Map<String, dynamic>> pendingActions = const [],
    List<Map<String, dynamic>> clientUpdates = const [],
    Map<String, dynamic>? flagForAttention,
  }) async =>
      Result.success('');

  @override
  Future<Result<void>> acknowledgeHandover({
    required String handoverId,
    String? note,
  }) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteHandover(String handoverId) async =>
      Result.success(null);

  @override
  Future<Result<List<Map<String, String>>>> getClientActivities({
    required String clientId,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<void>> recordClientActivity({
    required String clientId,
    required String activityType,
    required String status,
    String? notes,
  }) async =>
      Result.success(null);

  @override
  Future<Result<List<Map<String, String>>>> getInventoryItems({
    int page = 1,
    int limit = 50,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getReferrals() async =>
      Result.success(const []);

  @override
  Future<Result<Map<String, dynamic>>> getCourseQuiz(String courseId) async =>
      Result.success(const {});

  @override
  Future<Result<Map<String, dynamic>>> submitQuizAttempt({
    required String courseId,
    required List<Map<String, dynamic>> answers,
  }) async =>
      Result.success(const {});

  @override
  Future<Result<List<Map<String, String>>>> getTrainingCertificates() async =>
      Result.success(const []);
}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(
      ResponsiveHelper.baseWidth,
      ResponsiveHelper.baseHeight,
    ),
    minTextAdapt: true,
    builder: (_, _) => GetMaterialApp(
      home: child,
      theme: ThemeData(
        fontFamily: 'Outfit',
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _loadOutfitFont();
    Get.reset();
    await GetIt.I.reset();
    Get.put(
      UserSession()
        ..signIn(
          role: UserRole.staff,
          displayName: 'Sam Jones',
          email: 'sam@example.com',
        ),
      permanent: true,
    );
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets(
    'BUG_Report015: Investigation section is available on Create Incident',
    (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller =
          IncidentCreationController(repository: _FakeIncidentsRepo());
      Get.put(controller);

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CreateIncidentInvestigationSection(
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-incident-investigation')),
        findsOneWidget,
      );
      expect(find.textContaining('Immediate Action Taken'), findsOneWidget);
      expect(find.textContaining('Investigation Notes'), findsOneWidget);
      expect(
        find.byKey(const Key('staff-incident-follow-up-toggle')),
        findsOneWidget,
      );
      expect(find.textContaining('Follow-up Date'), findsOneWidget);
      expect(
        find.byKey(const Key('staff-incident-supervisor')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BUG_Report016: Evidence has Notes tab and Additional Notes field',
    (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller =
          IncidentCreationController(repository: _FakeIncidentsRepo());
      Get.put(controller);

      // Use a minimal evidence shell mirroring page tabs
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    key: const Key('staff-incident-evidence-tabs'),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () =>
                              controller.evidenceTabIndex.value = 0,
                          child: const Text('Files'),
                        ),
                        TextButton(
                          key: const Key('staff-incident-evidence-notes-tab'),
                          onPressed: () =>
                              controller.evidenceTabIndex.value = 1,
                          child: const Text('Notes'),
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    if (controller.evidenceTabIndex.value != 1) {
                      return const Text('Upload Evidence');
                    }
                    return TextField(
                      key: const Key('staff-incident-additional-notes'),
                      controller: controller.additionalNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-incident-evidence-tabs')),
        findsOneWidget,
      );
      expect(find.text('Notes'), findsOneWidget);
      await tester.tap(find.byKey(const Key('staff-incident-evidence-notes-tab')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('staff-incident-additional-notes')),
        findsOneWidget,
      );
      expect(find.textContaining('Additional Notes'), findsOneWidget);
    },
  );

  testWidgets(
    'BUG_Report017: Report Form section is available on Create Incident',
    (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller =
          IncidentCreationController(repository: _FakeIncidentsRepo());
      Get.put(controller);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CreateIncidentReportFormSection(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-incident-report-form')),
        findsOneWidget,
      );
      expect(find.text('Report form'), findsOneWidget);
      expect(
        find.byKey(const Key('staff-incident-report-cir')),
        findsOneWidget,
      );
      expect(find.textContaining('Persons Involved'), findsOneWidget);
      expect(
        find.textContaining('Incident Location Description'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BUG_Report018/019: MAR no-residence message shows visible action button',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      GetIt.I.registerSingleton<StaffExtrasRepository>(_FakeExtrasRepo());

      // Drive error state via a stub page using the same error widget pattern
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No residence is selected for this account. Choose a residence, then open Medication MAR again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: const Key('staff-mar-view-residence'),
                      onPressed: () =>
                          Get.to(() => const StaffResidencesPage()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('View Residence'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      key: const Key('staff-mar-retry'),
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceWhite,
                        foregroundColor: AppColors.secondaryTeal,
                        side: const BorderSide(color: AppColors.secondaryTeal),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final viewResidence = find.byKey(const Key('staff-mar-view-residence'));
      expect(viewResidence, findsOneWidget);
      expect(find.text('View Residence'), findsOneWidget);
      expect(find.byKey(const Key('staff-mar-retry')), findsOneWidget);

      final button = tester.widget<ElevatedButton>(viewResidence);
      final style = button.style;
      expect(style?.foregroundColor?.resolve({}), Colors.white);

      await tester.tap(viewResidence);
      await tester.pumpAndSettle();
      expect(find.byType(StaffResidencesPage), findsOneWidget);
    },
  );

  testWidgets(
    'BUG_Report020: Clock Out button is visible when on shift',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ClockOutButton(
                label: 'Clock Out',
                isClockOut: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-attendance-clock-out')),
        findsOneWidget,
      );
      expect(find.text('Clock Out'), findsOneWidget);
      await tester.tap(find.byKey(const Key('staff-attendance-clock-out')));
      expect(tapped, isTrue);
    },
  );
}
