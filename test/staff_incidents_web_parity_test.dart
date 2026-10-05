import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/incident_detail.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incident.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incident_options.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incidents_summary.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/repositories/staff_incidents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/controllers/incident_creation_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/controllers/staff_incidents_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/widgets/create_incident/create_incident_report_form_section.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/widgets/staff_incidents_metrics_row.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/widgets/staff_incidents_side_panels.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/widgets/staff_incidents_tab_bar.dart';
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
      Result.success(const []);

  @override
  Future<Result<List<StaffIncidentClientOption>>> getClients({
    String? search,
    String? residenceId,
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
    String? residenceId,
    String? clientId,
    int page = 1,
    int limit = 20,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<StaffIncidentsSummary>> getSummary() async => Result.success(
        const StaffIncidentsSummary(
          total: 1,
          open: 0,
          investigating: 1,
          closed: 0,
          serious: 0,
          awaitingInvestigation: 0,
          openInvestigations: 1,
          investigationQueue: [
            StaffIncidentQueueItem(
              id: 'i1',
              caseName: 'Brief unauthorised absence',
              stage: 'Open',
              investigator: 'Jamal Uddin',
            ),
          ],
        ),
      );

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
      Result.success(const []);

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

  tearDown(Get.reset);

  testWidgets('Incident Reports metrics + side panels match web', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeIncidentsRepo();
    final controller = StaffIncidentsController(repository: repo);
    Get.put(controller);
    await tester.pump(const Duration(milliseconds: 100));
    await controller.loadSummary();
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: ListView(
            children: [
              StaffIncidentsMetricsRow(summary: controller.summary.value),
              StaffIncidentsTabBar(
                selected: controller.selectedTab.value,
                onSelected: controller.selectTab,
              ),
              StaffIncidentsSidePanels(
                summary: controller.summary.value,
                onOpenIncident: (_) {},
                onViewQueue: controller.viewInvestigationQueue,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staff-incidents-metrics')), findsOneWidget);
    expect(find.text('Total Incidents'), findsOneWidget);
    expect(find.textContaining('High or Critical'), findsOneWidget);
    expect(find.text('All Incidents'), findsOneWidget);
    expect(find.text('Reported by Me'), findsOneWidget);
    expect(find.byKey(const Key('staff-incidents-watchlist')), findsOneWidget);
    expect(find.byKey(const Key('staff-incidents-queue')), findsOneWidget);
    expect(find.textContaining('Nothing serious is open'), findsOneWidget);
    expect(find.text('Not started'), findsOneWidget);
    expect(find.text('Open Investigations'), findsOneWidget);
    expect(find.textContaining('Brief unauthorised absence'), findsOneWidget);
  });

  testWidgets('Add Incident wizard steps and Save Draft control', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller =
        IncidentCreationController(repository: _FakeIncidentsRepo());
    Get.put(controller);

    expect(controller.wizardStep.value, 0);
    expect(IncidentCreationController.stepTitles.length, 5);
    controller.nextStep();
    expect(controller.wizardStep.value, 1);
    controller.nextStep();
    expect(controller.wizardStep.value, 2);
    controller.previousStep();
    expect(controller.wizardStep.value, 1);

    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: Column(
            children: [
              TextButton(
                key: const Key('staff-incident-save-draft'),
                onPressed: controller.saveDraft,
                child: const Text('Save Draft'),
              ),
              Expanded(
                child: CreateIncidentReportFormSection(controller: controller),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staff-incident-save-draft')), findsOneWidget);
    expect(find.byKey(const Key('staff-incident-report-form')), findsOneWidget);
  });
}
