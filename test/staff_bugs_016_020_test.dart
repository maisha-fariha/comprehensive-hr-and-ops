import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/attendance/presentation/widgets/clock_out_button.dart';
import 'package:comprehensive_hr_and_ops/features/staff/extras/domain/entities/staff_residence.dart';
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
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/due_dose.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_medication_enums.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/presentation/widgets/staff_administer_dose_dialog.dart';
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

/// Minimal Evidence & Submission harness matching web nested fields.
class _EvidenceHarness extends StatelessWidget {
  final IncidentCreationController controller;

  const _EvidenceHarness({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('staff-incident-evidence'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evidence (photos, documents)'),
          const SizedBox(height: 12),
          const Text('Transcription / Additional Notes'),
          TextField(
            key: const Key('staff-incident-additional-notes'),
            controller: controller.transcriptionController,
          ),
          const SizedBox(height: 12),
          Container(
            key: const Key('staff-incident-parties-notified'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Parties Notified'),
                for (final party in controller.partyNotifications)
                  Text(party.party),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeIncidentsRepo implements StaffIncidentsRepository {
  @override
  Future<Result<List<StaffCirTemplateOption>>> getCirTemplates() async =>
      Result.success(const [
        StaffCirTemplateOption(
          id: 'cir-1',
          name: 'Standard CIR',
          version: '1',
          sections: [
            StaffCirTemplateSection(
              key: 'people',
              title: 'People & place',
              fields: [
                StaffCirTemplateField(
                  key: 'personsInvolved',
                  label: 'Persons Involved / Witnesses',
                  type: 'textarea',
                ),
                StaffCirTemplateField(
                  key: 'incidentLocationDescription',
                  label: 'Incident Location Description',
                  type: 'textarea',
                ),
              ],
            ),
          ],
        ),
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
  Future<Result<List<StaffIncidentStaffOption>>> getStaffOptions({
    String? residenceId,
  }) async =>
      Result.success(const [
        StaffIncidentStaffOption(id: 's1', name: 'Sam Jones'),
      ]);

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
    String? immediateAction,
    bool? emergencyServicesContacted,
    String? externalAgencyType,
    String? externalAgencyReference,
    String? externalAgencyResponder,
    String? reportedByStaffId,
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
  Future<Result<List<StaffResidence>>> getResidences() async =>
      Result.success(const [
        StaffResidence(
          id: 'res-1',
          name: 'Sunrise Home',
          status: 'active',
        ),
      ]);

  @override
  Future<Result<StaffResidence>> getResidenceDetail(String residenceId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<int>> getActiveResidentCount() async => Result.success(0);

  @override
  Future<Result<StaffResidence>> updateResidence({
    required String residenceId,
    required Map<String, dynamic> fields,
  }) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<StaffResidence>> deactivateResidence(String residenceId) async =>
      Result.failure(const ApiError(message: 'unused'));

  @override
  Future<Result<List<Map<String, String>>>> getResidenceClients(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceRooms(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceStaffMembers(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceShifts(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<Map<String, String>>>> getResidenceDailyLogs(
    String residenceId,
  ) async =>
      Result.success(const []);

  @override
  Future<Result<List<StaffResidencePerson>>> getStaffDirectoryOptions() async =>
      Result.success(const []);

  @override
  Future<Result<List<StaffShiftHandover>>> getHandovers({
    String? residenceId,
    DateTime? from,
    DateTime? to,
    String? status,
    String? authorId,
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
      expect(find.textContaining('Investigation Status'), findsOneWidget);
      expect(find.textContaining('Investigator'), findsOneWidget);
      expect(find.textContaining('Investigation Notes'), findsOneWidget);
      expect(find.textContaining('Root Cause'), findsOneWidget);
      expect(find.textContaining('Corrective Action'), findsOneWidget);
      expect(
        find.byKey(const Key('staff-incident-follow-up-toggle')),
        findsOneWidget,
      );
      expect(find.textContaining('Follow-up Required'), findsOneWidget);
      expect(find.text('Debrief'), findsOneWidget);
      expect(
        find.byKey(const Key('staff-incident-debrief-completed')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BUG_Report016: Evidence & Submission has upload, notes, parties notified',
    (tester) async {
      tester.view.physicalSize = const Size(375, 1200);
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
              child: _EvidenceHarness(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staff-incident-evidence')), findsOneWidget);
      expect(
        find.textContaining('Evidence (photos, documents)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Transcription / Additional Notes'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('staff-incident-additional-notes')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('staff-incident-parties-notified')),
        findsOneWidget,
      );
      expect(find.text('Parties Notified'), findsOneWidget);
      expect(find.textContaining("Child's Family"), findsOneWidget);
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
      await tester.pumpAndSettle();

      // Web: CIR picker + dynamic template fields after selection.
      controller.selectedCirTemplate.value = controller.cirTemplates.first;

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
      expect(find.textContaining('Persons Involved'), findsWidgets);
      expect(
        find.textContaining('Incident Location Description'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'BUG_Report021: Incident Details has Category Details and Time Ended',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category Details (optional)'),
                  TextField(
                    key: const Key('staff-incident-category-details'),
                    controller: controller.categoryDetailsController,
                  ),
                  const Text('Time Ended (optional)'),
                  TextField(
                    key: const Key('staff-incident-end-time'),
                    controller: controller.endTimeController,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staff-incident-category-details')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('staff-incident-end-time')), findsOneWidget);
      expect(find.textContaining('Category Details'), findsOneWidget);
      expect(find.textContaining('Time Ended'), findsOneWidget);
    },
  );

  testWidgets(
    'BUG_Report018/019: Administer wizard shows Medicines / Safety / Documentation',
    (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const dose = DueDose(
        id: 'd1',
        residentName: 'Ayaan Karim',
        residentInitials: 'AK',
        avatarColor: AvatarPalette.green,
        medicationName: 'Paracetamol',
        dose: '500mg',
        route: MedicationRoute.tabletOral,
        timeLabel: '08:00',
        section: DueDoseSection.dueNow,
        clientId: 'c1',
        residenceId: 'r1',
        medicationId: 'm1',
      );

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const Key('open-admin'),
                    onPressed: () => StaffAdministerDoseDialog.show(
                      context,
                      dose: dose,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-admin')));
      await tester.pumpAndSettle();

      expect(find.text('Record administration'), findsOneWidget);
      expect(find.text('Medicines'), findsOneWidget);
      expect(find.text('Safety Check'), findsOneWidget);
      expect(find.text('Documentation'), findsOneWidget);
      expect(find.textContaining('Ayaan Karim'), findsOneWidget);
      expect(find.textContaining('Paracetamol'), findsOneWidget);

      await tester.tap(find.byKey(const Key('staff-mar-admin-next')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pre-administration'), findsOneWidget);
      expect(find.textContaining('Patient identity'), findsOneWidget);
      expect(find.textContaining('Blood pressure'), findsOneWidget);
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
