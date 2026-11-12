import 'package:comprehensive_hr_and_ops/core/roles/user_role.dart';
import 'package:comprehensive_hr_and_ops/core/roles/user_session.dart';
import 'package:comprehensive_hr_and_ops/features/hr/medication/domain/entities/mar_medication_stock.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/data/mappers/staff_medication_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/administered_dose.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_client_medication_item.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_med_options.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_medication_overview.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/repositories/staff_medication_repository.dart';
import 'package:comprehensive_hr_and_ops/features/staff/medication/presentation/controllers/staff_medication_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

class _Repo implements StaffMedicationRepository {
  _Repo(this.overview);

  final StaffMedicationOverview overview;

  @override
  Future<Result<StaffMedicationOverview>> getOverview({String? residenceId}) async =>
      Result.success(overview);

  @override
  Future<Result<List<StaffClientMedicationItem>>> listPrnMedications({
    String? residenceId,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<List<StaffClientMedicationItem>>> listMedications({
    String? residenceId,
    String? clientId,
    String? type,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<List<StaffMedResidenceOption>>> getResidences() async =>
      Result.success(const []);

  @override
  Future<Result<MarAdministrationsList>> listAdministrations({
    String? residenceId,
    int page = 1,
    int limit = 50,
  }) async =>
      Result.success(const MarAdministrationsList(items: [], total: 0));

  @override
  Future<Result<List<StaffMedClientOption>>> getClients({
    String? residenceId,
    String? search,
  }) async =>
      Result.success(const []);

  @override
  Future<Result<List<MarMedicationStock>>> listMedicationStock({
    String? residenceId,
  }) async =>
      Result.success(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StaffMedicationOverview _overview(List<Map<String, dynamic>> occurrences) {
  return StaffMedicationMapper.fromRound({
    'data': {
      'occurrences': occurrences,
      'summary': {
        'scheduled': occurrences.where((o) => o['scheduled'] == true).length,
        'administered': 1,
        'unscheduled': 1,
      },
    },
  });
}

void main() {
  tearDown(Get.reset);

  test('MAR tab count ignores off-round PRN administrations', () async {
    final overview = _overview([
      {
        'id': 'sched-1',
        'state': 'overdue',
        'name': 'Metformin',
        'scheduledTime': '08:00',
        'scheduled': true,
        'clientName': 'Client 002',
        'residenceName': 'Residence 001',
      },
      {
        'id': 'prn-given-1',
        'state': 'given',
        'name': 'Artificial Tears',
        'scheduled': false,
        'isPrn': true,
        'source': 'prn',
        'prnMedicationId': 'prn-1',
        'administrationId': 'adm-prn',
        'administeredAt': '2026-11-12T10:00:00.000Z',
        'clientName': 'Client 002',
        'residenceName': 'Residence 001',
      },
      {
        'id': 'off-round-2',
        'state': 'given',
        'name': 'Paracetamol PRN',
        'scheduled': false,
        'administrationId': 'adm-2',
        'administeredAt': '2026-11-12T11:00:00.000Z',
        'clientName': 'Client 015',
        'residenceName': 'Residence 003',
      },
    ]);

    final session = UserSession()
      ..signIn(role: UserRole.staff, displayName: 'Tester');
    final controller = StaffMedicationController(
      repository: _Repo(overview),
      session: session,
    );
    Get.put(controller);
    await controller.loadOverview();

    expect(overview.registryDoses, hasLength(3));
    expect(overview.registryDoses.where((d) => d.scheduled), hasLength(1));
    expect(controller.marTabCount, 1);
    expect(controller.filteredScheduledDoses.single.id, 'sched-1');
  });

  test('PRN occurrence without scheduled flag stays off the MAR tab', () async {
    final overview = _overview([
      {
        'id': 'sched-1',
        'state': 'due',
        'name': 'Metformin',
        'scheduledTime': '08:00',
        'scheduled': true,
      },
      {
        'id': 'prn-omitted-flag',
        'state': 'given',
        'name': 'Artificial Tears',
        'source': 'prn',
        'prnMedicationId': 'prn-1',
        'administrationId': 'adm-prn',
      },
    ]);

    final session = UserSession()
      ..signIn(role: UserRole.staff, displayName: 'Tester');
    final controller = StaffMedicationController(
      repository: _Repo(overview),
      session: session,
    );
    Get.put(controller);
    await controller.loadOverview();

    expect(controller.marTabCount, 1);
    expect(
      overview.registryDoses
          .firstWhere((d) => d.id == 'prn-omitted-flag')
          .scheduled,
      isFalse,
    );
  });
}
