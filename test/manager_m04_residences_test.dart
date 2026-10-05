import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/handovers/presentation/widgets/handover_common.dart';
import 'package:comprehensive_hr_and_ops/features/hr/presentation/widgets/hr_directory_widgets.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/data/mappers/residences_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/domain/entities/residence_detail_tabs.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/domain/entities/residence_form.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/domain/entities/residence_summary.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/domain/repositories/residences_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/presentation/controllers/residences_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/presentation/pages/residence_detail_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/presentation/pages/residence_form_page.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/presentation/pages/residences_page.dart';
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
      designSize: const Size(ResponsiveHelper.baseWidth, ResponsiveHelper.baseHeight),
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

Finder _key(String key) => find.byKey(ValueKey(key));

class _Session extends UserSession {
  final Set<String> denied;

  _Session({this.denied = const {}});

  @override
  bool can(String permission) => !denied.contains(permission);
}

final _elm = ResidenceSummary(
  id: 'r1',
  name: 'Elm House',
  status: 'active',
  bedCapacity: 4,
  residents: 3,
  availableBeds: 1,
  residenceType: 'Group Home',
  address: '12 Elm Road, Portland, Oregon, 97035',
  addressLine1: '12 Elm Road',
  city: 'Portland',
  stateProvince: 'Oregon',
  postalCode: '97035',
  country: 'United States',
  phone: '+1 503 555 0100',
  timezone: 'America/Los_Angeles',
  gpsRadiusMeters: 150,
  serviceType: 'Residential Care',
  careLevelMix: const {'level_2': 2},
  primaryManager: const ResidencePerson(id: 's1', name: 'Rafi Ahmed', role: 'primary_manager'),
  careTeam: const [ResidencePerson(id: 's2', name: 'Nadia Khan', role: 'care_team')],
  assignedStaff: const [ResidencePerson(id: 's3', name: 'Omar Faruk', role: 'staff')],
  outOfPocketEnabled: false,
  mileageEnabled: false,
  updatedAt: DateTime(2026, 9, 30, 10),
);

const _oak = ResidenceSummary(
  id: 'r2',
  name: 'Oak Lodge',
  status: 'inactive',
  bedCapacity: 6,
  residents: 0,
  residenceType: 'Assisted Living',
);

const _kpis = ResidencesKpis(
  residences: 2,
  active: 1,
  residents: 3,
  beds: 10,
  bedsFree: 7,
  atCapacity: 0,
);

class _Repo implements ResidencesRepository, ResidenceAdminRepository {
  List<ResidenceSummary> rows;
  ResidenceTenantContext tenant;
  String? createError;

  final listQueries = <Map<String, Object?>>[];
  Map<String, dynamic>? createdBody;
  List<ResidenceAssignment>? createdAssignments;
  Map<String, dynamic>? updatedBody;
  List<ResidenceAssignment>? updatedAssignments;
  bool updated = false;
  (String, String)? statusCall;
  String? deletedId;
  (bool, bool)? payroll;
  String? archivedRoom;
  Map<String, Object?>? createdRoom;

  _Repo({List<ResidenceSummary>? rows, this.tenant = const ResidenceTenantContext()})
      : rows = rows ?? [_elm, _oak];

  ResidenceSummary _find(String id) => rows.firstWhere((r) => r.id == id, orElse: () => _elm);

  @override
  Future<Result<List<ResidenceSummary>>> getResidences() async => Result.success(rows);

  @override
  Future<Result<List<ResidenceRoom>>> getRooms(String residenceId) async =>
      Result.success((await getRoomBoard(residenceId)).value!.rooms);

  @override
  Future<Result<ResidencesPageData>> listResidences({
    required int page,
    required int limit,
    String? search,
    String? status,
    String? residenceType,
  }) async {
    listQueries.add({'page': page, 'limit': limit, 'search': search, 'status': status, 'type': residenceType});
    final q = (search ?? '').toLowerCase();
    final items = rows
        .where((r) => q.isEmpty || r.name.toLowerCase().contains(q))
        .where((r) => status == null || r.status == status)
        .where((r) => residenceType == null || r.residenceType == residenceType)
        .toList();
    return Result.success(
      ResidencesPageData(
        items: items,
        total: items.length,
        totalPages: 1,
        summary: rows.isEmpty ? const ResidencesKpis() : _kpis,
      ),
    );
  }

  @override
  Future<Result<ResidenceSummary>> getResidence(String residenceId) async => Result.success(_find(residenceId));

  @override
  Future<Result<ResidenceSummary>> createResidence(
    Map<String, dynamic> body,
    List<ResidenceAssignment> assignments,
  ) async {
    createdBody = body;
    createdAssignments = assignments;
    if (createError != null) return Result.failure(ApiError(message: createError!));
    return Result.success(_oak);
  }

  @override
  Future<Result<ResidenceSummary>> updateResidence(
    String residenceId,
    Map<String, dynamic> body, {
    List<ResidenceAssignment>? assignments,
  }) async {
    updated = true;
    updatedBody = body;
    updatedAssignments = assignments;
    return Result.success(_find(residenceId));
  }

  @override
  Future<Result<void>> setStatus(String residenceId, String status) async {
    statusCall = (residenceId, status);
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteResidence(String residenceId) async {
    deletedId = residenceId;
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePayrollSettings(
    String residenceId, {
    required bool outOfPocketEnabled,
    required bool mileageEnabled,
  }) async {
    payroll = (outOfPocketEnabled, mileageEnabled);
    return Result.success(null);
  }

  @override
  Future<Result<ResidenceRoomBoard>> getRoomBoard(String residenceId, {bool includeArchived = false}) async =>
      Result.success(
        const ResidenceRoomBoard(
          rooms: [
            ResidenceRoom(
              id: 'room101',
              name: '101',
              capacity: 2,
              occupied: 1,
              isActive: true,
              residentNames: ['Ava Stone'],
              floor: 'Ground',
              roomType: 'double',
            ),
            ResidenceRoom(id: 'room102', name: '102', capacity: 1, occupied: 0, isActive: true, residentNames: []),
          ],
          roomCount: 2,
          beds: 3,
          occupied: 1,
          available: 2,
        ),
      );

  @override
  Future<Result<void>> createRoom(
    String residenceId, {
    required String name,
    required int capacity,
    String? floor,
    String? wing,
    String? roomType,
  }) async {
    createdRoom = {'name': name, 'capacity': capacity, 'floor': floor, 'roomType': roomType};
    return Result.success(null);
  }

  @override
  Future<Result<void>> reactivateRoom(String residenceId, String roomId) async => Result.success(null);

  @override
  Future<Result<void>> archiveRoom(String residenceId, String roomId) async {
    archivedRoom = roomId;
    return Result.success(null);
  }

  @override
  Future<Result<ResidenceTabPage<ResidenceResident, ResidentsSummary>>> getResidents(
    String residenceId, {
    required int page,
    required int limit,
  }) async =>
      Result.success(
        const ResidenceTabPage(
          items: [
            ResidenceResident(
              id: 'c1',
              name: 'Ava Stone',
              initials: 'AS',
              statusLabel: 'Active',
              level: 'Level 2',
              roomNumber: '101',
            ),
          ],
          total: 12,
          summary: ResidentsSummary(clients: 12, active: 11, onLeave: 1),
        ),
      );

  @override
  Future<Result<ResidenceTabPage<ResidenceStaffMember, StaffSummary>>> getStaff(
    String residenceId, {
    required int page,
    required int limit,
  }) async {
    ResidenceStaffMember member(String id, String name) => ResidenceStaffMember(
          id: id,
          name: name,
          initials: name[0],
          employeeCode: 'EMP-$id',
          category: 'Support Worker',
          employmentType: 'Full time',
          medAdminCertified: id == 's1',
          statusLabel: 'Active',
        );
    return Result.success(
      ResidenceTabPage(
        items: [member('s9', 'Zed Walker'), member('s3', 'Omar Faruk'), member('s1', 'Rafi Ahmed')],
        total: 3,
        summary: const StaffSummary(staff: 3, active: 3, medAdminCertified: 1),
      ),
    );
  }

  @override
  Future<Result<List<ResidenceShift>>> getShifts(
    String residenceId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 8);
    final shift = ResidenceShift(
      id: 'sh1',
      title: 'Early shift',
      status: 'scheduled',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 8)),
      assignedCount: 1,
      requiredStaffCount: 2,
      requiredCategoryName: 'Support Worker',
    );
    final inWeek = !start.isBefore(from) && !start.isAfter(to);
    return Result.success(inWeek ? [shift] : const []);
  }

  @override
  Future<Result<ResidenceTabPage<ResidenceLogDay, void>>> getReviewQueue(
    String residenceId, {
    required int page,
    required int limit,
  }) async =>
      Result.success(
        ResidenceTabPage(
          items: [ResidenceLogDay(clientName: 'Ava Stone', logDate: DateTime(2026, 9, 29), entriesCount: 3)],
          total: 1,
        ),
      );

  @override
  Future<Result<ResidenceTabPage<ResidenceLogDay, void>>> getMissingLogs(
    String residenceId, {
    required int page,
    required int limit,
  }) async =>
      Result.success(
        ResidenceTabPage(items: [ResidenceLogDay(clientName: 'Ben Cole', logDate: DateTime(2026, 9, 28))], total: 1),
      );

  @override
  Future<Result<List<ResidenceStaffOption>>> getStaffOptions() async => Result.success(const [
        ResidenceStaffOption(id: 's1', label: 'Rafi Ahmed'),
        ResidenceStaffOption(id: 's2', label: 'Nadia Khan'),
        ResidenceStaffOption(id: 's3', label: 'Omar Faruk'),
      ]);

  @override
  Future<Result<ResidenceTenantContext>> getTenantContext() async => Result.success(tenant);

  @override
  Future<Result<List<int>>> exportRoster() async => Result.success(const [1, 2, 3]);
}

class _Saved {
  List<int>? bytes;
  String? name;
}

ResidencesController _put(_Repo repo, {Set<String> denied = const {}, _Saved? saved}) {
  return Get.put(
    ResidencesController(
      repository: repo,
      admin: repo,
      session: _Session(denied: denied),
      saveExport: (bytes, name) async {
        saved?.bytes = bytes;
        saved?.name = name;
        return null;
      },
    ),
  );
}

Future<void> _openList(WidgetTester tester) async {
  _tallView(tester);
  await tester.pumpWidget(_app(const ResidencesPage()));
  await tester.pumpAndSettle();
}

Future<void> _openDetail(WidgetTester tester) async {
  _tallView(tester);
  await tester.pumpWidget(_app(ResidenceDetailPage(residence: _elm)));
  await tester.pumpAndSettle();
}

Future<void> _menu(WidgetTester tester, String id, String item) async {
  await _tap(tester, _key('residence-actions-$id'));
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadOutfitFont);

  setUp(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  group('M04 residences list', () {
    testWidgets('header actions, KPI tiles and rows from the list summary', (tester) async {
      _put(_Repo());
      await _openList(tester);

      expect(find.text('Residences Management'), findsOneWidget);
      expect(find.text('Add Residence'), findsOneWidget);
      expect(find.text('Export List'), findsOneWidget);
      expect(find.text('1 active'), findsOneWidget);
      expect(find.text('Living in them today'), findsOneWidget);
      expect(find.text('Of 10 licensed'), findsOneWidget);
      expect(find.text('Homes that cannot take anyone'), findsOneWidget);
      expect(_key('residence-r1'), findsOneWidget);
      expect(_key('residence-r2'), findsOneWidget);
      expect(find.text('3 / 4 Beds'), findsOneWidget);
      expect(find.text('3 Members'), findsOneWidget);
    });

    testWidgets('permissions hide Add / Export and the edit / delete row actions', (tester) async {
      _put(_Repo(), denied: {'residences:create', 'residences:export', 'residences:update'});
      await _openList(tester);

      expect(find.text('Add Residence'), findsNothing);
      expect(find.text('Export List'), findsNothing);
      await _tap(tester, _key('residence-actions-r1'));
      expect(find.text('View'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Take out of service'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('delete needs residences:delete on top of update', (tester) async {
      _put(_Repo(), denied: {'residences:delete'});
      await _openList(tester);

      await _tap(tester, _key('residence-actions-r1'));
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Take out of service'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('plan limit turns Add Residence into a disabled Limit Exceeded', (tester) async {
      _put(_Repo(tenant: const ResidenceTenantContext(residenceLimit: 2)));
      await _openList(tester);

      expect(find.text('Limit Exceeded'), findsOneWidget);
      expect(tester.widget<HandoverButton>(_key('residence-add')).onPressed, isNull);
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(of: _key('residence-add'), matching: find.byType(Tooltip)).first,
      );
      expect(tooltip.message, 'Plan limit reached (2/2 residences). Upgrade your plan to add more.');
    });

    testWidgets('Export List saves the residence roster CSV', (tester) async {
      final saved = _Saved();
      _put(_Repo(), saved: saved);
      await _openList(tester);

      await _tap(tester, _key('residence-export'));
      expect(saved.bytes, [1, 2, 3]);
      expect(saved.name, 'residence_roster.csv');
      expect(find.text('Export ready'), findsOneWidget);
    });

    testWidgets('Take out of service / Activate call the status endpoint', (tester) async {
      final repo = _Repo();
      _put(repo);
      await _openList(tester);

      await _menu(tester, 'r1', 'Take out of service');
      expect(repo.statusCall, ('r1', 'inactive'));
      expect(find.text('Elm House is out of service and hidden from staff'), findsOneWidget);

      await _menu(tester, 'r2', 'Activate');
      expect(repo.statusCall, ('r2', 'active'));
      expect(find.text('Oak Lodge is now active'), findsOneWidget);
    });

    testWidgets('Delete asks for confirmation first', (tester) async {
      final repo = _Repo();
      _put(repo);
      await _openList(tester);

      await _menu(tester, 'r1', 'Delete');
      expect(find.text('Delete this home?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.deletedId, isNull);

      await _menu(tester, 'r1', 'Delete');
      await _tap(tester, _key('residence-delete-confirm'));
      expect(repo.deletedId, 'r1');
      expect(find.text('Residence deleted'), findsOneWidget);
    });

    testWidgets('empty list shows the web empty state', (tester) async {
      _put(_Repo(rows: []));
      await _openList(tester);

      expect(find.text('No residences found'), findsOneWidget);
      expect(find.text('Residences you add will appear here.'), findsOneWidget);
    });

    testWidgets('search and status filter go to the server', (tester) async {
      final repo = _Repo();
      _put(repo);
      await _openList(tester);

      await tester.enterText(find.descendant(of: find.byType(HrSearchField), matching: find.byType(TextField)), 'zzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(repo.listQueries.last['search'], 'zzz');
      expect(find.text('No residence matches these filters.'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);

      await _tap(tester, find.text('Clear filters'));
      expect(repo.listQueries.last['search'], '');
      expect(_key('residence-r1'), findsOneWidget);

      await _tap(tester, _key('residence-status-filter'));
      await tester.tap(find.text('Archived').last);
      await tester.pumpAndSettle();
      expect(repo.listQueries.last['status'], 'archived');
    });
  });

  group('M04 residence wizard', () {
    testWidgets('create walks the five steps and posts body + assignments', (tester) async {
      final repo = _Repo();
      _put(repo);
      await _openList(tester);

      await _tap(tester, _key('residence-add'));
      expect(find.text('Add New Residence'), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsWidgets);

      await _tap(tester, _key('residence-form-next'));
      expect(find.text('Residence name is required'), findsOneWidget);
      expect(find.text('Select a residence type'), findsOneWidget);

      await tester.enterText(_key('residence-field-name'), 'Birch Court');
      await _tap(tester, _key('residence-type-Group Home'));
      await _tap(tester, _key('residence-form-next'));

      expect(find.text('GPS Coordinates & Geofence'), findsOneWidget);
      await _tap(tester, _key('residence-form-next'));
      expect(find.text('Street address is required'), findsOneWidget);
      await tester.enterText(_key('residence-field-streetAddress'), '1 Birch Way');
      await tester.enterText(_key('residence-field-city'), 'Portland');
      await tester.enterText(_key('residence-field-state'), 'Oregon');
      await tester.enterText(_key('residence-field-postalCode'), '97035');
      await _tap(tester, _key('residence-form-next'));

      expect(find.text('Bed Capacity'), findsOneWidget);
      await tester.enterText(_key('residence-field-totalBeds'), '8');
      await tester.pump();
      expect(find.descendant(of: _key('residence-available-beds'), matching: find.text('8')), findsOneWidget);
      await _tap(tester, _key('residence-form-next'));

      expect(find.text('Assigned Staff & Care Team'), findsOneWidget);
      await _tap(tester, _key('residence-field-primaryManager'));
      await tester.tap(find.text('Rafi Ahmed').last);
      await tester.pumpAndSettle();
      await _tap(tester, _key('residence-form-next'));

      expect(find.text('Review before creating'), findsOneWidget);
      expect(find.text('Create Residence'), findsOneWidget);
      await _tap(tester, _key('residence-form-submit'));

      final body = repo.createdBody!;
      expect(body['name'], 'Birch Court');
      expect(body['residenceType'], 'Group Home');
      expect(body['status'], 'pending');
      expect(body['addressLine1'], '1 Birch Way');
      expect(body['bedCapacity'], 8);
      expect(body['timezone'], 'America/Los_Angeles');
      expect(body['geofence'], {'radiusMeters': 150});
      expect(repo.createdAssignments, [(staffId: 's1', role: 'primary_manager')]);
      expect(find.text('Residence added'), findsOneWidget);
      expect(find.text('Residences Management'), findsOneWidget);
    });

    testWidgets('Save as Draft skips validation and shows the server error', (tester) async {
      final repo = _Repo()..createError = 'residenceType must be provided';
      _put(repo);
      await _openList(tester);

      await _tap(tester, _key('residence-add'));
      await tester.enterText(_key('residence-field-name'), 'Draft Home');
      await _tap(tester, _key('residence-form-save'));

      expect(repo.createdBody!['name'], 'Draft Home');
      expect(repo.createdBody!['status'], 'pending');
      expect(find.descendant(of: _key('residence-form-error'), matching: find.text('residenceType must be provided')),
          findsOneWidget);
      expect(find.text('Add New Residence'), findsOneWidget);
    });

    testWidgets('edit from the list sends assignments only when they changed', (tester) async {
      final repo = _Repo();
      _put(repo);
      await _openList(tester);

      await _menu(tester, 'r1', 'Edit');
      expect(find.text('Edit Residence'), findsOneWidget);
      expect(find.text('Residence Setup · #R1'), findsOneWidget);
      expect(find.text('Elm House'), findsWidgets);

      await tester.enterText(_key('residence-field-name'), 'Elm House North');
      await _tap(tester, _key('residence-form-save'));

      expect(repo.updated, isTrue);
      expect(repo.updatedBody!['name'], 'Elm House North');
      expect(repo.updatedBody!['status'], 'active');
      expect(repo.updatedAssignments, isNull);
      expect(find.text('Residence updated'), findsOneWidget);
    });
  });

  group('M04 residence detail', () {
    testWidgets('header and overview match the web drawer', (tester) async {
      _put(_Repo());
      await _openDetail(tester);

      expect(find.text('Manage residence operations, clients, staff, schedules and daily activities.'), findsOneWidget);
      expect(find.text('#r1'), findsOneWidget);
      expect(find.text('3 / 4'), findsOneWidget);
      expect(find.text('1 bed free'), findsOneWidget);
      expect(find.text('2 of 3 beds free'), findsOneWidget);
      expect(find.text('Managed by Rafi Ahmed'), findsOneWidget);
      expect(find.text('150m'), findsOneWidget);
      expect(find.text('Around this address'), findsOneWidget);
      expect(find.text('Level 2 · 2'), findsOneWidget);
      expect(find.text('Nadia Khan'), findsOneWidget);
      expect(find.text('Updated 30/09/2026'), findsOneWidget);
      expect(_key('residence-detail-edit'), findsOneWidget);
    });

    testWidgets('claims toggles save payroll settings', (tester) async {
      final repo = _Repo();
      _put(repo);
      await _openDetail(tester);

      await _tap(tester, _key('residence-claim-outOfPocket'));
      expect(repo.payroll, (true, false));
      expect(find.text('Claim settings saved'), findsOneWidget);
    });

    testWidgets('without residences:update claims are locked and edit is hidden', (tester) async {
      _put(_Repo(), denied: {'residences:update', 'scheduling:write'});
      await _openDetail(tester);

      expect(find.text('Ask an administrator to change these.'), findsOneWidget);
      expect(tester.widget<Switch>(_key('residence-claim-mileage')).onChanged, isNull);
      expect(_key('residence-detail-edit'), findsNothing);

      await _tap(tester, _key('residence-tab-schedule'));
      expect(_key('residence-create-schedule'), findsNothing);
    });

    testWidgets('clients tab lists residents with the summary', (tester) async {
      _put(_Repo());
      await _openDetail(tester);

      await _tap(tester, _key('residence-tab-clients'));
      expect(find.text('Ava Stone'), findsOneWidget);
      expect(find.text('Care level not set'), findsOneWidget);
      expect(find.text('Showing 1 of 12. The full list is on the Clients page.'), findsOneWidget);
      expect(_key('residence-detail-edit'), findsOneWidget);
    });

    testWidgets('rooms tab: mismatch warning, close and add room', (tester) async {
      final repo = _Repo();
      _put(repo);
      await _openDetail(tester);

      await _tap(tester, _key('residence-tab-rooms'));
      expect(
        find.text('This home is licensed for 4 beds, but its rooms add up to 3. '
            'Admission is measured against the licensed count.'),
        findsOneWidget,
      );
      expect(_key('residence-detail-edit'), findsNothing);
      expect(tester.widget<TextButton>(_key('residence-room-close-room101')).onPressed, isNull);

      await _tap(tester, _key('residence-room-close-room102'));
      expect(repo.archivedRoom, 'room102');

      await _tap(tester, _key('residence-room-add'));
      await tester.enterText(_key('residence-field-roomName'), '204');
      await _tap(tester, _key('residence-field-roomType'));
      await tester.tap(find.text('Double').last);
      await tester.pumpAndSettle();
      await _tap(tester, _key('residence-room-save'));
      expect(repo.createdRoom, {'name': '204', 'capacity': 2, 'floor': null, 'roomType': 'double'});
    });

    testWidgets('staff tab shows the role here, sorted like the web (unassigned first)', (tester) async {
      _put(_Repo());
      await _openDetail(tester);

      await _tap(tester, _key('residence-tab-staff'));
      expect(find.text('Primary manager'), findsOneWidget);
      expect(find.text('Not assigned'), findsOneWidget);
      expect(find.text('Certified'), findsOneWidget);
      final rafi = tester.getTopLeft(_key('residence-staff-s1')).dy;
      final omar = tester.getTopLeft(_key('residence-staff-s3')).dy;
      final zed = tester.getTopLeft(_key('residence-staff-s9')).dy;
      expect(zed < rafi && rafi < omar, isTrue);
    });

    testWidgets('schedule tab shows the week and Create Schedule', (tester) async {
      _put(_Repo());
      await _openDetail(tester);

      await _tap(tester, _key('residence-tab-schedule'));
      expect(find.text('Early shift'), findsOneWidget);
      expect(find.text('1 of 2 assigned · Support Worker'), findsOneWidget);
      expect(_key('residence-create-schedule'), findsOneWidget);

      await _tap(tester, _key('residence-week-next'));
      expect(find.text('Nothing rostered this week'), findsOneWidget);
      expect(_key('residence-week-this'), findsOneWidget);
    });

    testWidgets('daily logs tab shows review and missing days', (tester) async {
      _put(_Repo());
      await _openDetail(tester);

      await _tap(tester, _key('residence-tab-dailyLogs'));
      expect(find.text('ENTRIES WRITTEN'), findsOneWidget);
      expect(find.text('NOTHING WRITTEN'), findsOneWidget);
      expect(find.text('Ben Cole'), findsOneWidget);
      expect(find.text('Ava Stone'), findsOneWidget);
      expect(_key('residence-add-daily-log'), findsOneWidget);
    });

    testWidgets('Edit Residence from the drawer always sends assignments', (tester) async {
      final repo = _Repo();
      _put(repo);
      await _openDetail(tester);

      await _tap(tester, _key('residence-detail-edit'));
      expect(find.byType(ResidenceFormPage), findsOneWidget);
      await _tap(tester, _key('residence-form-save'));

      expect(repo.updatedAssignments, [
        (staffId: 's1', role: 'primary_manager'),
        (staffId: 's2', role: 'care_team'),
        (staffId: 's3', role: 'staff'),
      ]);
    });
  });

  group('M04 mapper and form', () {
    test('pageFrom reads rows, totals and the KPI summary', () {
      final page = ResidencesMapper.pageFrom({
        'data': [
          {
            'id': 'r1',
            'name': 'Elm House',
            'status': 'ACTIVE',
            'bedCapacity': 4,
            'occupiedBeds': 3,
            'geofence': {'radiusMeters': 120},
            'payrollSettings': {'outOfPocketEnabled': true},
            'primaryManager': {'id': 's1', 'name': 'Rafi Ahmed'},
            'careLevelMix': {'level_1': 2},
            'addressLine1': '12 Elm Road',
            'city': 'Portland',
          },
        ],
        'meta': {
          'total': 12,
          'totalPages': 2,
          'summary': {'residences': 12, 'active': 9, 'residents': 30, 'beds': 48, 'bedsFree': 18, 'atCapacity': 1},
        },
      });
      expect(page.total, 12);
      expect(page.totalPages, 2);
      expect(page.summary!.bedsFree, 18);
      expect(page.summary!.atCapacity, 1);
      final r = page.items.single;
      expect(r.status, 'active');
      expect(r.gpsRadiusMeters, 120);
      expect(r.outOfPocketEnabled, isTrue);
      expect(r.mileageEnabled, isFalse);
      expect(r.primaryManager!.name, 'Rafi Ahmed');
      expect(r.careLevelMix, {'level_1': 2});
      expect(r.address, '12 Elm Road, Portland');
    });

    test('roomBoardFrom and tenantContextFrom', () {
      final board = ResidencesMapper.roomBoardFrom({
        'data': [
          {
            'id': 'a',
            'name': '101',
            'capacity': 2,
            'occupied': 1,
            'isActive': true,
            'residents': [
              {'id': 'c1', 'fullName': 'Ava Stone'},
            ],
          },
        ],
        'meta': {
          'summary': {'rooms': 1, 'beds': 2, 'occupied': 1, 'available': 1},
        },
      });
      expect(board.rooms.single.residentNames, ['Ava Stone']);
      expect(board.beds, 2);
      expect(board.available, 1);

      final tenant = ResidencesMapper.tenantContextFrom({
        'data': {
          'tenant': {
            'limits': {'residences': 5},
            'enabledResidenceTypes': ['Group Home'],
          },
        },
      });
      expect(tenant.residenceLimit, 5);
      expect(tenant.enabledResidenceTypes, ['Group Home']);
    });

    test('form values round-trip the residence like the web form', () {
      final values = ResidenceFormValues.fromResidence(_elm);
      expect(values.lifecycleStatus, 'Active');
      expect(values.primaryManager, 's1');
      expect(values.careTeam, ['s2']);
      expect(values.assignedStaff, ['s3']);
      expect(values.geofenceRadius, '150');

      final body = values.toBody();
      expect(body['status'], 'active');
      expect(body['bedCapacity'], 4);
      expect(body['geofence'], {'radiusMeters': 150});
      expect(body.containsKey('latitude'), isFalse);

      values
        ..careTeam = ['s1', 's2']
        ..assignedStaff = ['s2', 's3'];
      expect(values.toAssignments(), [
        (staffId: 's1', role: 'primary_manager'),
        (staffId: 's2', role: 'care_team'),
        (staffId: 's3', role: 'staff'),
      ]);
      expect(
        ResidenceFormValues.sameAssignments(
          [(staffId: 'a', role: 'staff'), (staffId: 'b', role: 'care_team')],
          [(staffId: 'b', role: 'care_team'), (staffId: 'a', role: 'staff')],
        ),
        isTrue,
      );
    });

    test('validation uses the web messages', () {
      final values = ResidenceFormValues()
        ..timeZone = ''
        ..phone = 'abc'
        ..managementEmail = 'nope';
      final errors = values.validate();
      expect(errors['name'], 'Residence name is required');
      expect(errors['type'], 'Select a residence type');
      expect(errors['streetAddress'], 'Street address is required');
      expect(errors['totalBeds'], 'Total capacity is required');
      expect(errors['phone'], 'Enter a valid phone number');
      expect(errors['managementEmail'], 'Enter a valid email');
      expect(values.validateStep(ResidenceFormStep.capacity).keys, ['totalBeds']);
      expect(values.toBody()['timezone'], 'UTC');
    });
  });
}
