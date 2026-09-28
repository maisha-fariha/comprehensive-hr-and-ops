import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/incident_detail.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incident.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incident_options.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/entities/staff_incidents_summary.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/domain/repositories/staff_incidents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/controllers/incident_creation_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/incidents/presentation/widgets/create_incident/create_incident_people_location_section.dart';
import 'package:comprehensive_hr_and_ops/features/staff/presentation/pages/staff_more_menu_page.dart';
import 'package:comprehensive_hr_and_ops/features/staff/presentation/widgets/staff_bottom_nav_bar.dart';
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
  Future<Result<List<StaffIncidentResidenceOption>>> getResidences() async =>
      Result.success(const [
        StaffIncidentResidenceOption(id: 'res-1', name: 'Sunrise Home'),
        StaffIncidentResidenceOption(id: 'res-2', name: 'Harbor House'),
      ]);

  @override
  Future<Result<List<StaffIncidentClientOption>>> getClients({
    String? search,
    bool assignedToMe = true,
  }) async {
    final all = const [
      StaffIncidentClientOption(
        id: 'c1',
        name: 'Alex Client',
        residenceId: 'res-1',
        residenceName: 'Sunrise Home',
        roomLabel: 'Room 2',
      ),
      StaffIncidentClientOption(
        id: 'c2',
        name: 'Blake Client',
        residenceId: 'res-2',
        residenceName: 'Harbor House',
      ),
    ];
    if (search == null || search.trim().isEmpty) {
      return Result.success(all);
    }
    final q = search.toLowerCase();
    return Result.success(
      all.where((c) => c.name.toLowerCase().contains(q)).toList(),
    );
  }

  @override
  Future<Result<List<StaffIncidentCategoryOption>>> getCategories() async =>
      Result.success(const [
        StaffIncidentCategoryOption(id: 'cat-1', name: 'Fall'),
      ]);

  @override
  Future<Result<List<StaffCirTemplateOption>>> getCirTemplates() async =>
      Result.success(const [
        StaffCirTemplateOption(id: 'cir-1', name: 'Standard CIR'),
      ]);

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
        )
        ..applyStaffContext(
          staffId: 'staff-1',
          residenceId: 'res-1',
          residenceName: 'Sunrise Home',
        ),
      permanent: true,
    );
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets(
    'BUG_Report010: Daily Logs nav and Clients module both appear',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: const Center(child: Text('Daily Logs')),
            bottomNavigationBar: StaffBottomNavBar(
              currentIndex: 2,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(StaffBottomNavBar),
          matching: find.text('Daily Logs'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(StaffBottomNavBar),
          matching: find.text('Clients'),
        ),
        findsNothing,
      );
      expect(StaffBottomNavBar.items[2].label, 'Daily Logs');
    },
  );

  testWidgets(
    'BUG_Report010: More menu exposes Clients and Daily Activity like web',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Get.find<UserSession>().applyPermissions(const [
        'clients:read',
        'client-activities:read',
        'client-activities:write',
        'daily-logs:read',
      ]);

      await tester.pumpWidget(_wrap(const StaffMoreMenuPage()));
      await tester.pumpAndSettle();

      expect(find.text('Clients'), findsOneWidget);
      expect(find.text('Daily Activity'), findsOneWidget);
      expect(find.text('Client activities'), findsNothing);
    },
  );

  testWidgets(
    'BUG_Report011–014: People & Location has residence, client search, CFS, toggles',
    (tester) async {
      tester.view.physicalSize = const Size(375, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeIncidentsRepo();
      final controller = IncidentCreationController(repository: repo);
      Get.put(controller);

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CreateIncidentPeopleLocationSection(
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // BUG_Report011 — Residence
      expect(find.byKey(const Key('staff-incident-residence')), findsOneWidget);
      expect(find.textContaining('Residence'), findsWidgets);

      // BUG_Report012 — Client Search
      expect(
        find.byKey(const Key('staff-incident-client-search')),
        findsOneWidget,
      );
      expect(find.textContaining('Client Search'), findsOneWidget);
      expect(find.text('Search client...'), findsOneWidget);

      // BUG_Report013 — CFS Details
      expect(
        find.byKey(const Key('staff-incident-cfs-details')),
        findsOneWidget,
      );
      expect(find.text('CFS Details'), findsOneWidget);
      expect(find.byKey(const Key('staff-incident-cfs-status')), findsOneWidget);
      expect(find.textContaining('Child Last Name'), findsOneWidget);
      expect(find.textContaining('Child First Name'), findsOneWidget);

      // BUG_Report014 — required fields + toggles
      expect(find.textContaining('Location'), findsWidgets);
      expect(find.textContaining('Staff Involved'), findsOneWidget);
      expect(find.textContaining('Witness Information'), findsOneWidget);
      expect(
        find.byKey(const Key('staff-incident-add-witness')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('staff-incident-cfs-notified')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('staff-incident-police-notified')),
        findsOneWidget,
      );

      // Residence can be selected via picker
      await tester.tap(find.byKey(const Key('staff-incident-residence')));
      await tester.pumpAndSettle();
      expect(find.text('Harbor House'), findsOneWidget);
      await tester.tap(find.text('Harbor House'));
      await tester.pumpAndSettle();
      expect(controller.selectedResidence.value?.name, 'Harbor House');

      // Client search filters suggestions (Blake is at Harbor House)
      await tester.enterText(
        find.byKey(const Key('staff-incident-client-search')),
        'Blake',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Blake Client'), findsOneWidget);
      await tester.tap(find.text('Blake Client'));
      await tester.pumpAndSettle();
      expect(controller.selectedClient.value?.name, 'Blake Client');

      // Toggles are present and flip state
      expect(
        find.byKey(const Key('staff-incident-cfs-notified')),
        findsOneWidget,
      );
      controller.cfsNotified.value = true;
      expect(controller.cfsNotified.value, isTrue);
      controller.policeNotified.value = true;
      expect(controller.policeNotified.value, isTrue);
    },
  );
}
