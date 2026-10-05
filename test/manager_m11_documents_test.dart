import 'package:comprehensive_hr_and_ops/core/constants/app_colors.dart';
import 'package:comprehensive_hr_and_ops/core/network/app_api_client.dart';
import 'package:comprehensive_hr_and_ops/core/network/tenant_store.dart';
import 'package:comprehensive_hr_and_ops/core/network/token_store.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/documents/data/hr_documents_endpoints.dart';
import 'package:comprehensive_hr_and_ops/features/hr/documents/data/mappers/hr_documents_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/documents/data/repositories/hr_documents_repository_impl.dart';
import 'package:comprehensive_hr_and_ops/features/hr/documents/domain/entities/hr_document.dart';
import 'package:comprehensive_hr_and_ops/features/hr/documents/domain/entities/hr_document_draft.dart';
import 'package:comprehensive_hr_and_ops/features/hr/documents/domain/entities/hr_document_row.dart';
import 'package:comprehensive_hr_and_ops/features/hr/documents/domain/repositories/hr_documents_repository.dart';
import 'package:comprehensive_hr_and_ops/features/hr/documents/presentation/controllers/hr_documents_controller.dart';
import 'package:comprehensive_hr_and_ops/features/hr/documents/presentation/pages/hr_documents_page.dart';
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
  tester.view.physicalSize = const Size(390, 3200);
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

Finder _inKey(String key, Finder matching) =>
    find.descendant(of: _key(key), matching: matching);

Future<void> _menu(WidgetTester tester, String id, String item) async {
  await _tap(tester, _key('document-actions-$id'));
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<void> _pick(WidgetTester tester, String key, String option) async {
  await _tap(tester, _key(key));
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  final field = find.descendant(of: _key(key), matching: find.byType(TextField));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

class _Session extends UserSession {
  final Set<String> denied;

  _Session({this.denied = const {}});

  @override
  bool can(String permission) => !denied.contains(permission);
}

final _now = DateTime(2026, 10, 1, 12);

final _carePlan = HrDocument(
  id: 'd1',
  name: 'Care plan — Ayaan',
  fileUrl: '/api/v1/files/t1/care-plans/plan.pdf',
  ownerType: 'client',
  ownerId: 'c1',
  status: 'valid',
  visibility: 'staff_only',
  uploadedBy: 'u1',
  createdAt: DateTime.parse('2026-09-09T12:00:00.000Z'),
);

final _nursing = HrDocument(
  id: 'd2',
  name: 'Nursing registration',
  documentTypeId: 'first-aid',
  fileUrl: '/api/v1/files/t1/staff-documents/reg.pdf',
  ownerType: 'staff',
  ownerId: 's1',
  expiresAt: DateTime.parse('2026-09-16T12:00:00.000Z'),
  status: 'expired',
  visibility: 'management_only',
  createdAt: DateTime.parse('2026-08-27T12:00:00.000Z'),
  source: 'staff_document',
);

final _policy = HrDocument(
  id: 'd3',
  name: 'Fire policy',
  documentTypeId: 'retired',
  fileUrl: '/api/v1/files/t1/documents/policy.docx',
  ownerType: 'tenant',
  expiresAt: DateTime.parse('2026-10-20T12:00:00.000Z'),
  visibility: 'all',
  notes: 'Reviewed yearly',
  createdAt: DateTime.parse('2026-09-20T12:00:00.000Z'),
);

final _withdrawn = HrDocument(
  id: 'd4',
  name: 'Old consent',
  fileUrl: '/api/v1/files/t1/documents/consent.xlsx',
  ownerType: 'client',
  ownerId: 'c9',
  visibility: 'family',
  deletedAt: DateTime.parse('2026-09-25T12:00:00.000Z'),
  createdAt: DateTime.parse('2026-08-01T12:00:00.000Z'),
);

const _activeTypes = [
  HrDocumentType(id: 'first-aid', name: 'First Aid Certificate', appliesTo: 'staff', isMandatory: true),
  HrDocumentType(id: 'consent', name: 'Care Consent Form', appliesTo: 'client', isMandatory: true),
  HrDocumentType(id: 'policy', name: 'Policy', appliesTo: 'general'),
];

const _archived = HrDocumentType(id: 'temp', name: 'Mobile Temp Type', appliesTo: 'staff', isActive: false);

const _summary = HrDocumentsSummary(
  documents: 9,
  expiringSoon: 1,
  expired: 4,
  restricted: 9,
  addedLast30Days: 8,
  missingMandatory: 94,
  missingByType: [
    HrMissingGap(documentTypeId: 'cpr', name: 'CPR Certificate', appliesTo: 'staff', owners: 23, filed: 0, missing: 23),
    HrMissingGap(documentTypeId: 'consent', name: 'Care Consent Form', appliesTo: 'client', owners: 3, filed: 0, missing: 3),
  ],
  byType: [
    HrCategorySlice(name: 'Uncategorised', count: 8),
    HrCategorySlice(documentTypeId: 'first-aid', name: 'First Aid Certificate', count: 1),
  ],
);

class _FakeRepo implements HrDocumentsRepository {
  List<HrDocument> rows = [_carePlan, _nursing, _policy, _withdrawn];
  HrDocumentsSummary? summaryData = _summary;
  bool failList = false;
  final List<(HrDocumentFilters, int, int)> listQueries = [];
  final List<HrDocumentFilters> summaryQueries = [];
  final List<String> calls = [];
  final List<Map<String, dynamic>> created = [];
  final List<(String, Map<String, dynamic>)> updated = [];
  final List<HrPickedFile> uploads = [];
  List<HrDocumentType> allTypes = [..._activeTypes, _archived];

  @override
  Future<Result<HrDocumentPage>> list({
    required HrDocumentFilters filters,
    required int page,
    required int limit,
  }) async {
    listQueries.add((filters, page, limit));
    if (failList) return Result.failure(const ApiError(message: 'Cannot reach the server.'));
    return Result.success(HrDocumentPage(items: rows, total: rows.length, totalPages: 1));
  }

  @override
  Future<Result<HrDocumentsSummary>> summary(HrDocumentFilters filters) async {
    summaryQueries.add(filters);
    final data = summaryData;
    return data == null
        ? Result.failure(const ApiError(message: 'no summary'))
        : Result.success(data);
  }

  @override
  Future<Result<List<HrDocumentType>>> types({bool includeArchived = false}) async =>
      Result.success(includeArchived ? allTypes : allTypes.where((t) => t.isActive).toList());

  @override
  Future<Result<HrDocumentType>> createType({required String name, required String appliesTo}) async {
    calls.add('createType $name $appliesTo');
    final type = HrDocumentType(id: 'new', name: name, appliesTo: appliesTo);
    allTypes = [...allTypes, type];
    return Result.success(type);
  }

  @override
  Future<Result<void>> archiveType(String id) async {
    calls.add('archiveType $id');
    return Result.success(null);
  }

  @override
  Future<Result<void>> restoreType(String id) async {
    calls.add('restoreType $id');
    return Result.success(null);
  }

  @override
  Future<Result<String>> uploadFile(HrPickedFile file) async {
    uploads.add(file);
    return Result.success('/api/v1/files/t1/documents/uploaded.pdf');
  }

  @override
  Future<Result<HrDocument>> create(Map<String, dynamic> body) async {
    created.add(body);
    return Result.success(
      HrDocument(id: 'new', name: body['name'] as String, fileUrl: body['fileUrl'] as String),
    );
  }

  @override
  Future<Result<HrDocument>> update(String id, Map<String, dynamic> body) async {
    updated.add((id, body));
    return Result.success(HrDocument(id: id, name: body['name'] as String));
  }

  @override
  Future<Result<void>> withdraw(String id) async {
    calls.add('withdraw $id');
    return Result.success(null);
  }

  @override
  Future<Result<void>> restore(String id) async {
    calls.add('restore $id');
    return Result.success(null);
  }

  @override
  Future<Result<void>> exportReport() async {
    calls.add('export');
    return Result.success(null);
  }

  @override
  Future<Result<HrDocumentFile>> download(String fileUrl, String fallbackName) async {
    calls.add('download $fileUrl');
    return Result.success(HrDocumentFile(bytes: const [1, 2, 3], fileName: '$fallbackName.pdf'));
  }

  @override
  Future<Result<List<HrDocumentOwner>>> owners(String ownerType) async {
    calls.add('owners $ownerType');
    return Result.success(switch (ownerType) {
      'client' => const [HrDocumentOwner(id: 'c1', name: 'Ayaan Karim')],
      'staff' => const [HrDocumentOwner(id: 's1', name: 'Priya Das')],
      _ => const [HrDocumentOwner(id: 'r1', name: 'Elm House')],
    });
  }
}

class _Harness {
  final _FakeRepo repo;
  final List<HrDocumentFile> opened;
  HrPickedFile? nextFile;

  _Harness(this.repo, this.opened);
}

Future<_Harness> _open(
  WidgetTester tester, {
  _FakeRepo? repo,
  Set<String> denied = const {},
}) async {
  _tallView(tester);
  final fake = repo ?? _FakeRepo();
  final harness = _Harness(fake, []);
  final session = Get.put<UserSession>(_Session(denied: denied));
  GetIt.I.registerFactory<HrDocumentsController>(
    () => HrDocumentsController(
      repository: fake,
      session: session,
      now: () => _now,
      pickFile: () async => harness.nextFile,
      openFile: (file) async => harness.opened.add(file),
    ),
  );
  await tester.pumpWidget(_app(const HrDocumentsPage()));
  await tester.pumpAndSettle();
  return harness;
}

class _FakeApi implements AppApiClient {
  final List<(String, String, Object?, Map<String, dynamic>?)> requests = [];
  dynamic response = const {'data': <dynamic>[]};

  Future<Result<dynamic>> _record(String method, String path, Object? data, Map<String, dynamic>? query) async {
    requests.add((method, path, data, query));
    return Result.success(response);
  }

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowTokenRefresh = true,
  }) =>
      _record('GET', path, null, query);

  @override
  Future<Result<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool includeTenant = true,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) =>
      _record('POST', path, data, query);

  @override
  Future<Result<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) =>
      _record('PATCH', path, data, query);

  @override
  Future<Result<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    bool silent = false,
    bool allowQueue = true,
    bool allowTokenRefresh = true,
  }) =>
      _record('DELETE', path, data, query);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoTokens implements TokenStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoTenant implements TenantStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HrDocumentRow _row(HrDocument d) => HrDocumentRow.from(
      d,
      directories: const {
        'client': {'c1': 'Ayaan Karim'},
        'staff': {'s1': 'Priya Das'},
      },
      typeNames: const {'first-aid': 'First Aid Certificate'},
      now: _now,
    );

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

  group('M11 Documents data', () {
    test('mapper reads the live list, summary, types and owner payloads', () {
      final page = HrDocumentsMapper.pageFrom({
        'success': true,
        'data': [
          {
            'id': '817746d8',
            'documentTypeId': 'd210c462',
            'name': 'Nursing registration',
            'fileUrl': '/files/documents/demo-nursing-reg.pdf',
            'ownerType': 'staff',
            'ownerId': 'be5a1299',
            'expiresAt': '2026-09-16T00:00:00.000Z',
            'status': 'expired',
            'visibility': 'management_only',
            'checklistKey': null,
            'notes': null,
            'uploadedBy': null,
            'createdAt': '2026-08-27T09:33:09.173Z',
            'deletedAt': null,
            'source': 'staff_document',
          },
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 12, 'totalPages': 1},
      });
      expect((page.total, page.totalPages), (12, 1));
      final d = page.items.single;
      expect(d.source, 'staff_document');
      expect(d.ownerType, 'staff');
      expect(d.expiresAt, DateTime.parse('2026-09-16T00:00:00.000Z'));
      expect(d.deletedAt, isNull);

      final summary = HrDocumentsMapper.summaryFrom({
        'data': {
          'documents': 9,
          'expiringSoon': 1,
          'expired': 4,
          'restricted': 9,
          'addedLast30Days': 8,
          'missingMandatory': 94,
          'missingByType': [
            {'documentTypeId': 'cea', 'name': 'Care Consent Form', 'appliesTo': 'client', 'owners': 3, 'filed': 0, 'missing': 3},
          ],
          'byType': [
            {'documentTypeId': null, 'name': 'Uncategorised', 'count': 8},
          ],
          'computedAt': '2026-10-01T04:52:32.667Z',
        },
      });
      expect(
        (summary.documents, summary.expiringSoon, summary.expired, summary.restricted,
            summary.addedLast30Days, summary.missingMandatory),
        (9, 1, 4, 9, 8, 94),
      );
      expect(summary.missingByType.single.appliesTo, 'client');
      expect(summary.byType.single.documentTypeId, isNull);

      final types = HrDocumentsMapper.typesFrom({
        'data': [
          {'id': 'a', 'name': 'CPR Certificate', 'appliesTo': 'staff', 'isMandatory': true, 'isActive': true},
          {'id': 'b', 'name': 'Mobile Temp Type', 'appliesTo': 'staff', 'isMandatory': false, 'isActive': false},
        ],
      });
      expect([for (final t in types) (t.name, t.isMandatory, t.isActive)], [
        ('CPR Certificate', true, true),
        ('Mobile Temp Type', false, false),
      ]);

      expect(
        HrDocumentsMapper.ownersFrom({
          'data': [
            {'id': 'c1', 'firstName': 'Encoderit', 'lastName': 'Naeem'},
          ],
        }, 'client').single.name,
        'Encoderit Naeem',
      );
      expect(
        HrDocumentsMapper.ownersFrom({
          'data': [
            {'id': 'r1', 'name': 'Elm House'},
          ],
        }, 'residence').single.name,
        'Elm House',
      );
    });

    test('rows derive the web owner, category, expiry, visibility and status labels', () {
      final care = _row(_carePlan);
      expect(
        (care.fileKind, care.ownerTypeLabel, care.ownerName, care.category, care.expiryDate,
            care.visibilityLabel, care.uploadedDate, care.statusLabel, care.statusTone),
        (HrFileKind.pdf, 'Resident', 'Ayaan Karim', 'Unclassified', null, 'Staff only',
            '09/09/2026', 'No expiry', HrDocTone.success),
      );

      final nursing = _row(_nursing);
      expect(
        (nursing.ownerName, nursing.category, nursing.expiryDate, nursing.expiryTone,
            nursing.statusLabel, nursing.statusTone, nursing.isStaffCertificate),
        ('Priya Das', 'First Aid Certificate', '16/09/2026', HrExpiryTone.critical, 'Expired',
            HrDocTone.danger, true),
      );
      expect(nursing.canEdit(true), isFalse);

      final policy = _row(_policy);
      expect(
        (policy.fileKind, policy.ownerTypeLabel, policy.ownerName, policy.category,
            policy.expiryTone, policy.statusLabel, policy.visibilityLabel, policy.restricted),
        (HrFileKind.doc, 'Organisation', 'Whole organisation', 'Retired type',
            HrExpiryTone.warning, 'Expiring', 'Everyone', false),
      );
      expect((policy.canEdit(true), policy.canEdit(false)), (true, false));

      final old = _row(_withdrawn);
      expect(
        (old.fileKind, old.ownerName, old.statusLabel, old.statusTone, old.visibilityLabel),
        (HrFileKind.sheet, 'Outside your access', 'Withdrawn', HrDocTone.neutral, 'Family'),
      );
      expect((old.canRestore(true), old.canWithdraw(true)), (true, false));

      final valid = _row(HrDocument(
        id: 'v',
        name: 'v',
        fileUrl: 'https://x/a.PNG?sig=1',
        expiresAt: DateTime(2027, 1, 1),
      ));
      expect((valid.statusLabel, valid.fileKind, valid.ownerTypeLabel), ('Valid', HrFileKind.image, '—'));
    });

    test('category percentages use the largest remainder and alerts follow the summary', () {
      expect(
        [for (final s in HrCategoryShare.from(_summary.byType)) (s.label, s.count, s.percent)],
        [('Uncategorised', 8, '89%'), ('First Aid Certificate', 1, '11%')],
      );
      expect(
        [for (final s in HrCategoryShare.from(const [
          HrCategorySlice(name: 'a', count: 1),
          HrCategorySlice(name: 'b', count: 1),
          HrCategorySlice(name: 'c', count: 1),
        ])) s.percent],
        ['34%', '33%', '33%'],
      );
      final alerts = HrComplianceAlert.from(_summary);
      expect([for (final a in alerts) (a.id, a.title, a.actionLabel, a.filter)], [
        ('expired', 'expired documents', 'Review', (status: 'expired', visibility: '')),
        ('missing', 'missing required documents', 'See gaps', null),
        ('expiring', 'expiring within 30 days', 'Review', (status: 'expiring', visibility: '')),
        ('restricted', 'restricted files', 'View', (status: '', visibility: 'management_only')),
      ]);
      expect(HrComplianceAlert.from(const HrDocumentsSummary(expired: 1)).single.title,
          'expired document');
      expect(HrComplianceAlert.from(const HrDocumentsSummary()), isEmpty);
    });

    test('form drafts validate and build the web create / update bodies', () {
      expect(const HrDocumentDraft().validate(), {
        'name': 'Give the document a name',
        'ownerId': 'Choose who this document belongs to',
        'files': 'Attach the file being filed',
      });
      const tenant = HrDocumentDraft(
        name: ' Fire policy ',
        ownerType: 'tenant',
        file: HrPickedFile(path: '/tmp/p.pdf', name: 'p.pdf'),
        expiryTrackingEnabled: true,
      );
      expect(tenant.validate(), {
        'expiryDate': 'Set the date it expires, or turn expiry tracking off',
      });
      expect(tenant.copyWith(expiryDate: '2026-12-01').createBody('/api/v1/files/x.pdf'), {
        'name': 'Fire policy',
        'ownerType': 'tenant',
        'expiresAt': '2026-12-01',
        'visibility': 'staff_only',
        'fileUrl': '/api/v1/files/x.pdf',
      });
      const staff = HrDocumentDraft(
        name: 'DBS',
        ownerType: 'staff',
        ownerId: 's1',
        documentTypeId: 'first-aid',
        visibility: 'management_only',
        notes: ' renew ',
      );
      expect(staff.createBody('/f'), {
        'name': 'DBS',
        'ownerType': 'staff',
        'ownerId': 's1',
        'documentTypeId': 'first-aid',
        'visibility': 'management_only',
        'notes': 'renew',
        'fileUrl': '/f',
      });

      final edit = HrDocumentDraft.edit(_row(_policy));
      expect(
        (edit.editing, edit.ownerType, edit.expiryTrackingEnabled, edit.expiryDate),
        (true, 'tenant', true, '2026-10-20'),
      );
      expect(edit.validate(), isEmpty);
      expect(edit.updateBody(), {
        'name': 'Fire policy',
        'documentTypeId': 'retired',
        'expiresAt': '2026-10-20',
        'visibility': 'all',
        'notes': 'Reviewed yearly',
      });
      expect(HrDocumentDraft.edit(_row(_carePlan)).updateBody(), {
        'name': 'Care plan — Ayaan',
        'documentTypeId': null,
        'expiresAt': null,
        'visibility': 'staff_only',
        'notes': null,
      });
      expect(
        HrDocumentDraft.edit(_row(const HrDocument(id: 'r', name: 'r', ownerType: 'referral', ownerId: 'x')))
            .ownerType,
        'tenant',
      );
    });

    test('stored file paths resolve like the web toApiFilePath', () {
      expect(HrDocumentsEndpoints.apiFilePath('/api/v1/files/t/care-plans/a.pdf'), '/files/t/care-plans/a.pdf');
      expect(
        HrDocumentsEndpoints.apiFilePath('https://hr.example/api/v1/files/t/a.pdf'),
        '/files/t/a.pdf',
      );
      expect(HrDocumentsEndpoints.apiFilePath('/files/documents/demo-nursing-reg.pdf'), isNull);
      expect(HrDocumentsEndpoints.apiFilePath(null), isNull);
    });

    test('the repository calls the verified endpoints with the web params and bodies', () async {
      final api = _FakeApi();
      final repo = HrDocumentsRepositoryImpl(api: api, tokens: _NoTokens(), tenant: _NoTenant());
      const filters = HrDocumentFilters(
        search: 'care',
        ownerType: 'client',
        status: 'expired',
        includeDeleted: true,
      );
      await repo.list(filters: filters, page: 2, limit: 20);
      await repo.summary(filters);
      await repo.types();
      await repo.types(includeArchived: true);
      await repo.owners('client');
      await repo.owners('staff');
      await repo.owners('residence');
      api.response = {'data': {'id': 't', 'name': 'DBS'}};
      await repo.createType(name: 'DBS', appliesTo: 'staff');
      await repo.archiveType('t');
      await repo.restoreType('t');
      api.response = {'data': {'id': 'd', 'name': 'Doc'}};
      await repo.create({'name': 'Doc'});
      await repo.update('d', {'name': 'Doc'});
      await repo.withdraw('d');
      await repo.restore('d');
      await repo.exportReport();

      expect([for (final r in api.requests) [r.$1, r.$2, r.$3, r.$4]], [
        ['GET', '/documents', null, {
          'page': 2, 'limit': 20, 'ownerType': 'client', 'status': 'expired', 'search': 'care',
          'includeDeleted': true,
        }],
        ['GET', '/documents/summary', null, {
          'ownerType': 'client', 'status': 'expired', 'search': 'care', 'includeDeleted': true,
        }],
        ['GET', '/document-types', null, {'includeArchived': false}],
        ['GET', '/document-types', null, {'includeArchived': true}],
        ['GET', '/clients', null, {'page': 1, 'limit': 100}],
        ['GET', '/staff', null, {'page': 1, 'limit': 100}],
        ['GET', '/residences', null, {'page': 1, 'limit': 100}],
        ['POST', '/document-types', {'name': 'DBS', 'appliesTo': 'staff'}, null],
        ['POST', '/document-types/t/archive', null, null],
        ['POST', '/document-types/t/restore', null, null],
        ['POST', '/documents', {'name': 'Doc'}, null],
        ['PATCH', '/documents/d', {'name': 'Doc'}, null],
        ['DELETE', '/documents/d', null, null],
        ['POST', '/documents/d/restore', null, null],
        ['POST', '/reports/exports', {'reportKey': 'document_expiry', 'format': 'csv'}, null],
      ]);

      final download = await repo.download('/files/documents/demo-nursing-reg.pdf', 'Nursing');
      expect(download.error!.message, 'This file is no longer available.');
    });
  });

  group('M11 Documents page', () {
    testWidgets('a writer sees the header actions, KPIs, registry rows, categories and alerts',
        (tester) async {
      final h = await _open(tester, denied: {'documents:export'});

      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Every certificate, care plan and policy on file, and what is missing'),
          findsOneWidget);
      expect(find.text('Show withdrawn'), findsOneWidget);
      expect(_key('documents-types'), findsOneWidget);
      expect(_key('documents-upload'), findsOneWidget);
      expect(_key('documents-export'), findsNothing);

      expect(h.repo.listQueries.single, (const HrDocumentFilters(), 1, 20));
      expect(h.repo.summaryQueries.single, const HrDocumentFilters());
      expect(h.repo.calls, containsAll(['owners client', 'owners staff', 'owners residence']));

      for (final (key, texts) in [
        ('documents-kpi-total', ['9', 'TOTAL DOCUMENTS', '+8 in the last 30 days']),
        ('documents-kpi-missing', ['94', 'MISSING REQUIRED DOCUMENTS', 'Review required']),
        ('documents-kpi-expiring', ['1', 'EXPIRING SOON', 'Within 30 days']),
        ('documents-kpi-restricted', ['9', 'RESTRICTED FILES', 'Access banded']),
      ]) {
        for (final text in texts) {
          expect(_inKey(key, find.text(text)), findsOneWidget, reason: '$key $text');
        }
      }

      expect(find.text('Document Registry'), findsOneWidget);
      expect(find.text('4 documents matching these filters'), findsOneWidget);
      expect(find.text('Search documents...'), findsOneWidget);
      for (final label in ['All owners', 'All categories', 'Any status', 'Any visibility', 'Clear filters']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      for (final text in ['Care plan — Ayaan', 'Resident', 'Ayaan Karim', 'Unclassified',
          'Staff only', '09/09/2026']) {
        expect(_inKey('document-d1', find.text(text)), findsOneWidget, reason: text);
      }
      expect(_inKey('document-d1', find.text('No expiry')), findsNWidgets(2));
      for (final text in ['Expired', 'Priya Das', 'First Aid Certificate', '16/09/2026', 'Management only']) {
        expect(_inKey('document-d2', find.text(text)), findsOneWidget, reason: text);
      }
      for (final text in ['Organisation', 'Whole organisation', 'Retired type', 'Expiring', 'Everyone']) {
        expect(_inKey('document-d3', find.text(text)), findsOneWidget, reason: text);
      }
      for (final text in ['Withdrawn', 'Outside your access', 'Family']) {
        expect(_inKey('document-d4', find.text(text)), findsOneWidget, reason: text);
      }
      expect(find.text('Showing 1 to 4 of 4 entries'), findsOneWidget);

      expect(find.text('Document Categories'), findsOneWidget);
      expect(_inKey('documents-categories', find.text('DOCUMENTS')), findsOneWidget);
      expect(find.text('8 (89%)', findRichText: true), findsOneWidget);
      expect(find.text('1 (11%)', findRichText: true), findsOneWidget);
      expect(find.text('View All Categories'), findsOneWidget);

      expect(find.text('Compliance Alerts'), findsOneWidget);
      for (final text in ['4 expired documents', 'Past their expiry date and still on file',
          '94 missing required documents', 'Mandatory types nobody has filed for these people',
          '1 expiring within 30 days', 'Renew before they lapse', '9 restricted files',
          'Held in a band narrower than everyone', 'See gaps', 'View']) {
        expect(_inKey('documents-alerts', find.text(text)), findsWidgets, reason: text);
      }
    });

    testWidgets('row menus follow documents:write and the document source', (tester) async {
      await _open(tester);
      Future<List<String>> items(String id) async {
        await _tap(tester, _key('document-actions-$id'));
        final labels = [
          for (final label in ['View', 'Download', 'Edit', 'Restore', 'Withdraw'])
            if (find.text(label).hitTestable().evaluate().isNotEmpty) label,
        ];
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        return labels;
      }

      expect(await items('d1'), ['View', 'Download', 'Edit', 'Withdraw']);
      expect(await items('d2'), ['View', 'Download']);
      expect(await items('d4'), ['View', 'Download', 'Restore']);
    });

    testWidgets('a reader without documents:write only views and downloads', (tester) async {
      await _open(tester, denied: {'documents:write', 'documents:export'});
      expect(_key('documents-upload'), findsNothing);
      expect(_key('documents-types'), findsNothing);
      expect(find.text('View All Categories'), findsNothing);

      await _tap(tester, _key('document-actions-d1'));
      expect(find.text('View').hitTestable(), findsOneWidget);
      expect(find.text('Download').hitTestable(), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Withdraw'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Fire policy'));
      expect(_key('document-detail'), findsOneWidget);
      expect(_key('document-detail-edit'), findsNothing);
      expect(_key('document-detail-download'), findsOneWidget);
    });

    testWidgets('Export Report needs documents:export and queues the expiry CSV', (tester) async {
      final h = await _open(tester);
      await _tap(tester, _key('documents-export'));
      expect(h.repo.calls, contains('export'));
      expect(find.text('Export queued — it appears under Reports & Exports when ready'), findsOneWidget);
    });

    testWidgets('filters, search, withdrawn toggle and clear reload the list and summary together',
        (tester) async {
      final h = await _open(tester);

      await _pick(tester, 'documents-filter-owner', 'Staff');
      expect(h.repo.listQueries.last.$1.ownerType, 'staff');
      expect(h.repo.summaryQueries.last.ownerType, 'staff');
      expect(_inKey('documents-filter-owner', find.text('Staff')), findsOneWidget);

      await _pick(tester, 'documents-filter-category', 'First Aid Certificate');
      await _pick(tester, 'documents-filter-status', 'Expiring soon');
      await _pick(tester, 'documents-filter-visibility', 'Management only');
      expect(
        h.repo.listQueries.last.$1.toQuery(),
        {'ownerType': 'staff', 'documentTypeId': 'first-aid', 'status': 'expiring', 'visibility': 'management_only'},
      );

      await tester.enterText(_key('documents-search'), 'care');
      await tester.pump(const Duration(milliseconds: 100));
      expect(h.repo.listQueries.last.$1.search, '');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(h.repo.listQueries.last.$1.search, 'care');
      expect(h.repo.summaryQueries.last.search, 'care');

      await _tap(tester, _key('documents-toggle-withdrawn'));
      expect(find.text('Withdrawn shown'), findsOneWidget);
      expect(h.repo.listQueries.last.$1.includeDeleted, isTrue);
      expect(h.repo.summaryQueries.last.includeDeleted, isTrue);

      await _tap(tester, _key('documents-clear-filters'));
      expect(h.repo.listQueries.last.$1, const HrDocumentFilters());
      expect(find.text('Show withdrawn'), findsOneWidget);
      final search = tester.widget<TextField>(_key('documents-search'));
      expect(search.controller!.text, isEmpty);
    });

    testWidgets('page size changes reload from page one', (tester) async {
      final h = await _open(tester);
      await _tap(tester, _key('attendance-page-size'));
      await tester.tap(find.text('50').last);
      await tester.pumpAndSettle();
      expect(h.repo.listQueries.last, (const HrDocumentFilters(), 1, 50));
    });

    testWidgets('compliance alerts filter the registry or open the missing gaps', (tester) async {
      final h = await _open(tester);
      await _tap(tester, _key('documents-alert-action-expired'));
      expect(h.repo.listQueries.last.$1.status, 'expired');
      expect(_inKey('documents-filter-status', find.text('Expired')), findsOneWidget);

      await _tap(tester, _key('documents-alert-action-restricted'));
      expect(h.repo.listQueries.last.$1.toQuery(), {'visibility': 'management_only'});

      await _tap(tester, _key('documents-alert-action-missing'));
      for (final text in ['Missing required documents',
          'Mandatory document types, and how many people have yet to file one.', 'CPR Certificate',
          '0 of 23 staff have filed one', '23 missing', 'Care Consent Form',
          '0 of 3 residents have filed one', '3 missing']) {
        expect(_inKey('documents-missing', find.text(text)), findsOneWidget, reason: text);
      }
      await _tap(tester, _key('documents-missing-done'));
      expect(_key('documents-missing'), findsNothing);
    });

    testWidgets('detail: details, filing and expiry, the certificate note and Download', (tester) async {
      final h = await _open(tester);
      await _menu(tester, 'd2', 'View');

      for (final text in ['Nursing registration', 'Filed against Priya Das', 'Document Details',
          'OWNER', 'Priya Das · Staff', 'CATEGORY', 'First Aid Certificate', 'VISIBLE TO',
          'Management only', 'HELD AS', 'Staff certificate', 'Filing & Expiry', 'FILED', '27/08/2026',
          'EXPIRY DATE', '16/09/2026', 'STATUS', 'Expired',
          'Certificates are held on the staff record and are edited there, not in the registry.']) {
        expect(_inKey('document-detail', find.text(text)), findsWidgets, reason: text);
      }
      expect(_key('document-detail-edit'), findsNothing);

      await _tap(tester, _key('document-detail-download'));
      expect(h.repo.calls, contains('download /api/v1/files/t1/staff-documents/reg.pdf'));
      expect(h.opened.single.fileName, 'Nursing registration.pdf');

      await _tap(tester, _key('document-detail-close'));
      await _menu(tester, 'd1', 'View');
      expect(_inKey('document-detail', find.text('Not tracked')), findsOneWidget);
      expect(_inKey('document-detail', find.text('Document')), findsOneWidget);
      expect(_key('document-detail-edit'), findsOneWidget);
    });

    testWidgets('upload: validation, owner-filtered categories, file, saved view and File Another',
        (tester) async {
      final h = await _open(tester);
      await _tap(tester, _key('documents-upload'));

      for (final text in ['Add New Document',
          'Upload a file, file it against its owner, and set who may read it.', 'Resident',
          'Select an owner', 'Unclassified', 'Document types are managed from the registry',
          'PDF, Word, Excel, CSV or an image · up to 15MB', 'PDF', 'DOCX', 'XLSX', 'CSV', 'JPG', 'PNG',
          'Everyone', 'Staff only', 'Management only', 'Family', 'Expiry Tracking',
          'Counts towards the expiring and expired figures', 'Document Preview', 'Live preview',
          'Not named yet', 'Not tracked', 'Upload Tips',
          'Name the document as a reader would search for it', 'Upload Document', 'Cancel']) {
        expect(_inKey('document-form', find.text(text)), findsWidgets, reason: text);
      }

      await _tap(tester, _key('document-form-submit'));
      expect(find.text('3 fields need attention'), findsOneWidget);
      expect(find.text('Complete the required fields below before filing this document.'), findsOneWidget);
      for (final text in ['Give the document a name', 'Choose who this document belongs to',
          'Attach the file being filed']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(h.repo.uploads, isEmpty);

      await _type(tester, 'document-form-name', 'DBS — Priya');
      await _pick(tester, 'document-form-owner-type', 'Staff');
      await _pick(tester, 'document-form-owner', 'Priya Das');
      await _tap(tester, _key('document-form-category'));
      expect(find.text('First Aid Certificate').hitTestable(), findsOneWidget);
      expect(find.text('Policy').hitTestable(), findsOneWidget);
      expect(find.text('Care Consent Form').hitTestable(), findsNothing);
      await tester.tap(find.text('First Aid Certificate').last);
      await tester.pumpAndSettle();

      h.nextFile = const HrPickedFile(path: '/tmp/big.pdf', name: 'big.pdf', size: 16 * 1024 * 1024);
      await _tap(tester, _key('document-form-file'));
      expect(find.text('"big.pdf" exceeds the 15MB limit'), findsOneWidget);
      h.nextFile = const HrPickedFile(path: '/tmp/dbs.pdf', name: 'dbs.pdf', size: 2048);
      await _tap(tester, _key('document-form-file'));
      expect(find.text('"big.pdf" exceeds the 15MB limit'), findsNothing);

      await _tap(tester, _key('document-form-expiry-toggle'));
      await _tap(tester, _key('document-form-submit'));
      expect(find.text('1 field need attention'), findsOneWidget);
      expect(find.text('Set the date it expires, or turn expiry tracking off'), findsOneWidget);
      await _tap(tester, _key('document-form-expiry-toggle'));
      await _tap(tester, _key('document-form-visibility-all'));
      await _type(tester, 'document-form-notes', 'Renew yearly');

      for (final (label, value) in [('File', 'dbs.pdf'), ('Owner', 'Priya Das'),
          ('Category', 'First Aid Certificate'), ('Visible to', 'Everyone'), ('Expiry', 'Not tracked')]) {
        expect(_inKey('document-form-preview', find.text(label)), findsOneWidget, reason: label);
        expect(_inKey('document-form-preview', find.text(value)), findsWidgets, reason: value);
      }

      await _tap(tester, _key('document-form-submit'));
      expect(h.repo.uploads.single.name, 'dbs.pdf');
      expect(h.repo.created.single, {
        'name': 'DBS — Priya',
        'ownerType': 'staff',
        'ownerId': 's1',
        'documentTypeId': 'first-aid',
        'visibility': 'all',
        'notes': 'Renew yearly',
        'fileUrl': '/api/v1/files/t1/documents/uploaded.pdf',
      });
      expect(find.text('Document filed'), findsOneWidget);
      for (final text in ['Document Filed', 'Saved',
          '"DBS — Priya" is on file against Priya Das and readable by everyone.', 'Download',
          'File Another', 'Done']) {
        expect(_inKey('document-form-saved', find.text(text)), findsWidgets, reason: text);
      }

      await _tap(tester, _key('document-file-another'));
      expect(_inKey('document-form', find.text('Staff')), findsOneWidget);
      expect(_inKey('document-form', find.text('Not named yet')), findsOneWidget);
      await _tap(tester, _key('document-form-cancel'));
      expect(_key('document-form'), findsNothing);
    });

    testWidgets('an organisation document needs no owner record', (tester) async {
      final h = await _open(tester);
      await _tap(tester, _key('documents-upload'));
      await _pick(tester, 'document-form-owner-type', 'Organisation');
      expect(find.text('Held by the organisation itself — no record to choose.'), findsOneWidget);
      await _type(tester, 'document-form-name', 'Fire policy');
      h.nextFile = const HrPickedFile(path: '/tmp/p.pdf', name: 'p.pdf', size: 10);
      await _tap(tester, _key('document-form-file'));
      await _tap(tester, _key('document-form-submit'));
      expect(h.repo.created.single, {
        'name': 'Fire policy',
        'ownerType': 'tenant',
        'visibility': 'staff_only',
        'fileUrl': '/api/v1/files/t1/documents/uploaded.pdf',
      });
      expect(
        find.text('"Fire policy" is on file against the organisation and readable by staff only.'),
        findsOneWidget,
      );
    });

    testWidgets('edit: owner fixed, file already filed, PATCH body and Document Updated', (tester) async {
      final h = await _open(tester);
      await _menu(tester, 'd3', 'View');
      await _tap(tester, _key('document-detail-edit'));

      for (final text in ['Edit Document', 'The owner is fixed once filed — file it again to move it.',
          'Organisation', 'Fixed once the document is filed', 'the organisation', 'Already filed',
          '2026-10-20', 'Save Changes']) {
        expect(_inKey('document-form', find.text(text)), findsWidgets, reason: text);
      }
      expect(_key('document-form-file'), findsNothing);

      await _type(tester, 'document-form-name', 'Fire policy v2');
      await _tap(tester, _key('document-form-submit'));
      expect(h.repo.updated.single.$1, 'd3');
      expect(h.repo.updated.single.$2, {
        'name': 'Fire policy v2',
        'documentTypeId': 'retired',
        'expiresAt': '2026-10-20',
        'visibility': 'all',
        'notes': 'Reviewed yearly',
      });
      expect(h.repo.uploads, isEmpty);
      expect(find.text('Document updated'), findsOneWidget);
      expect(_inKey('document-form-saved', find.text('Document Updated')), findsOneWidget);
      expect(_key('document-file-another'), findsNothing);
      await _tap(tester, _key('document-saved-done'));
      expect(_key('document-form-saved'), findsNothing);
    });

    testWidgets('withdraw asks first; restore brings a withdrawn document back', (tester) async {
      final h = await _open(tester);
      await _menu(tester, 'd1', 'Withdraw');
      expect(find.text('Withdraw this document?'), findsOneWidget);
      expect(
        find.text('"Care plan — Ayaan" leaves the registry but is kept — a filed document is '
            'evidence of what was held, so it can be restored.'),
        findsOneWidget,
      );
      await _tap(tester, _key('document-withdraw-confirm'));
      expect(h.repo.calls, contains('withdraw d1'));
      expect(find.text('Document withdrawn'), findsOneWidget);

      await _menu(tester, 'd4', 'Restore');
      expect(h.repo.calls, contains('restore d4'));
      expect(find.text('Document restored'), findsOneWidget);
    });

    testWidgets('document types: add with validation, archive and restore', (tester) async {
      final h = await _open(tester);
      await _tap(tester, _key('documents-types'));

      for (final text in ['Document types',
          'What a document can be filed as. Retired types are archived, never deleted.', 'New type',
          'Applies to', 'Anything', 'Add type', 'First Aid Certificate', 'Staff · Required',
          'Residents · Required', 'Policy', 'Mobile Temp Type', 'Staff · Archived', 'Archive', 'Restore']) {
        expect(_inKey('document-types', find.text(text)), findsWidgets, reason: text);
      }

      await _tap(tester, _key('document-type-add'));
      expect(find.text('Give the type a name.'), findsOneWidget);

      await _type(tester, 'document-type-name', 'DBS certificate');
      await _pick(tester, 'document-type-applies-to', 'Residents');
      await _tap(tester, _key('document-type-add'));
      expect(h.repo.calls, contains('createType DBS certificate client'));
      expect(find.text('Document type added'), findsOneWidget);
      expect(find.text('Give the type a name.'), findsNothing);
      expect(_inKey('document-types', find.text('DBS certificate')), findsOneWidget);

      await _tap(tester, _key('document-type-toggle-first-aid'));
      expect(h.repo.calls, contains('archiveType first-aid'));
      expect(find.text('Type archived'), findsOneWidget);

      await _tap(tester, _key('document-type-toggle-temp'));
      expect(h.repo.calls, contains('restoreType temp'));
      expect(find.text('Type restored'), findsOneWidget);

      await _tap(tester, _key('document-types-done'));
      await _tap(tester, _key('documents-view-all-categories'));
      expect(_key('document-types'), findsOneWidget);
    });

    testWidgets('empty and failed registries use the web empty states', (tester) async {
      final repo = _FakeRepo()
        ..rows = []
        ..summaryData = const HrDocumentsSummary();
      await _open(tester, repo: repo);
      expect(find.text('No documents match'), findsOneWidget);
      expect(find.text('Certificates, care plans and policies you upload are filed here.'), findsOneWidget);
      expect(find.text('0 documents matching these filters'), findsOneWidget);
      expect(find.textContaining('Showing'), findsNothing);
      expect(find.text('None filed in 30 days'), findsOneWidget);
      expect(find.text('All mandatory types filed'), findsOneWidget);
      expect(find.text('Nothing expiring, expired or missing. The registry is up to date.'), findsOneWidget);

      repo.failList = true;
      repo.summaryData = null;
      await Get.find<HrDocumentsController>().refreshAll();
      await tester.pumpAndSettle();
      expect(find.text('Documents could not be loaded'), findsOneWidget);
      expect(find.text('Cannot reach the server.'), findsOneWidget);
      expect(_key('documents-kpi-total'), findsNothing);
    });
  });
}
