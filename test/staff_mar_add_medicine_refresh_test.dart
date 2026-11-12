import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/domain/entities/mar_medication_stock.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/data/mappers/staff_medication_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/administered_dose.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_client_medication_item.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_med_options.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_medication_enums.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_medication_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/repositories/staff_medication_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/presentation/controllers/staff_medication_controller.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/presentation/widgets/staff_add_medicine_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

class _Repo implements StaffMedicationRepository {
  final overviewCalls = <String?>[];
  var overviewVersion = 0;
  final prnRows = <Map<String, dynamic>>[];
  final medRows = <Map<String, dynamic>>[];
  final occurrences = <Map<String, dynamic>>[
    {
      'id': 'occ-old',
      'state': 'due',
      'name': 'Metformin',
      'scheduledTime': '08:00',
      'scheduled': true,
      'clientId': 'c1',
      'residenceId': 'r1',
    },
  ];

  @override
  Future<Result<StaffMedicationOverview>> getOverview({
    String? residenceId,
  }) async {
    overviewCalls.add(residenceId);
    // Simulate a slow in-flight load that started before create.
    if (overviewVersion == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    final rows = [
      for (final o in occurrences)
        if (residenceId == null || o['residenceId'] == residenceId) o,
    ];
    return Result.success(
      StaffMedicationMapper.fromRound({
        'data': {
          'occurrences': rows,
          'summary': {
            'scheduled': rows.where((o) => o['scheduled'] == true).length,
            'administered': 0,
            'unscheduled': 0,
          },
        },
      }),
    );
  }

  @override
  Future<Result<List<StaffClientMedicationItem>>> listPrnMedications({
    String? residenceId,
  }) async =>
      Result.success(
        StaffMedicationMapper.clientMedicationsFrom(prnRows, isPrn: true),
      );

  @override
  Future<Result<List<StaffClientMedicationItem>>> listMedications({
    String? residenceId,
    String? clientId,
    String? type,
  }) async =>
      Result.success(
        StaffMedicationMapper.clientMedicationsFrom(medRows, isPrn: false),
      );

  @override
  Future<Result<List<StaffMedResidenceOption>>> getResidences() async =>
      Result.success(const [
        StaffMedResidenceOption(id: 'r1', name: 'Residence 001'),
      ]);

  @override
  Future<Result<List<StaffMedClientOption>>> getClients({
    String? residenceId,
    String? search,
  }) async =>
      Result.success(const [
        StaffMedClientOption(id: 'c1', name: 'Client 002', residenceId: 'r1'),
      ]);

  @override
  Future<Result<MarAdministrationsList>> listAdministrations({
    String? residenceId,
    int page = 1,
    int limit = 50,
  }) async =>
      Result.success(const MarAdministrationsList(items: [], total: 0));

  @override
  Future<Result<List<MarMedicationStock>>> listMedicationStock({
    String? residenceId,
  }) async =>
      Result.success(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(Get.reset);

  test('post-create refresh is latest-wins and lands on the PRN tab', () async {
    final repo = _Repo();
    final session = UserSession()
      ..signIn(role: UserRole.staff, displayName: 'Tester')
      ..applyPermissions(const ['mar:read', 'mar:write']);
    final controller = StaffMedicationController(
      repository: repo,
      session: session,
    );
    Get.put(controller);

    // First overview is still in flight (slow).
    expect(repo.overviewCalls, isNotEmpty);

    // Simulate a successful PRN create that appears on the next overview.
    repo.overviewVersion = 1;
    repo.prnRows.add({
      'id': 'prn-new',
      'clientId': 'c1',
      'residenceId': 'r1',
      'name': 'Artificial Tears',
      'dose': '1-2 drops',
      'isActive': true,
    });

    await controller.refreshAfterMedicineSave(
      const StaffAddMedicineResult(
        isPrn: true,
        residenceId: 'r1',
        clientId: 'c1',
        name: 'Artificial Tears',
      ),
    );

    expect(controller.selectedTab.value, StaffMedicationTab.prn);
    expect(
      controller.prnItems.any((p) => p.name == 'Artificial Tears'),
      isTrue,
    );
    // MAR count still only scheduled non-PRN rows.
    expect(controller.marTabCount, 1);
    expect(controller.prnTabCount, 1);
  });

  test('scheduled add stays on MAR and does not inflate with PRN rows', () async {
    final repo = _Repo();
    final session = UserSession()
      ..signIn(role: UserRole.staff, displayName: 'Tester')
      ..applyPermissions(const ['mar:read', 'mar:write']);
    final controller = StaffMedicationController(
      repository: repo,
      session: session,
    );
    Get.put(controller);
    await controller.loadOverview();

    repo.overviewVersion = 1;
    repo.occurrences.add({
      'id': 'occ-new',
      'state': 'upcoming',
      'name': 'Calpol',
      'dose': '5ml',
      'scheduledTime': '08:00',
      'scheduled': true,
      'clientId': 'c1',
      'residenceId': 'r1',
    });
    // Off-round PRN must still be excluded from MAR count.
    repo.occurrences.add({
      'id': 'prn-given',
      'state': 'given',
      'name': 'PRN Drop',
      'scheduled': false,
      'isPrn': true,
      'source': 'prn',
      'prnMedicationId': 'prn-1',
      'administrationId': 'adm-1',
      'clientId': 'c1',
      'residenceId': 'r1',
    });

    await controller.refreshAfterMedicineSave(
      const StaffAddMedicineResult(
        isPrn: false,
        residenceId: 'r1',
        clientId: 'c1',
        name: 'Calpol',
      ),
    );

    expect(controller.selectedTab.value, StaffMedicationTab.mar);
    expect(
      controller.allScheduledDoses.any((d) => d.medicationName == 'Calpol'),
      isTrue,
    );
    expect(controller.marTabCount, 2);
    expect(
      controller.allScheduledDoses.any((d) => d.medicationName == 'PRN Drop'),
      isFalse,
    );
  });
}
