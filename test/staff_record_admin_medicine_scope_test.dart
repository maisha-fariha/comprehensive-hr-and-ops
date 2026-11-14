import 'package:comprehensive_hr_and_ops/features/staff/medication/domain/entities/staff_client_medication_item.dart';
import 'package:flutter_test/flutter_test.dart';

StaffClientMedicationItem _med({
  required String id,
  required String name,
  String clientId = '',
  String residenceId = 'res-1',
  bool isPrn = false,
  bool isActive = true,
}) =>
    StaffClientMedicationItem(
      id: id,
      name: name,
      dose: '1',
      clientId: clientId,
      residenceId: residenceId,
      isPrn: isPrn,
      isActive: isActive,
    );

void main() {
  const clientId = 'client-002';
  const home = 'res-001';

  test('Record Admin medicine list is only this resident’s active PRNs', () {
    final scoped = StaffClientMedicationItem.scopedForRecordAdministration(
      clientId: clientId,
      residenceId: home,
      prescribed: [
        _med(id: 'met', name: 'Metformin', clientId: clientId, residenceId: home),
        _med(
          id: 'tears-sched',
          name: 'Artificial Tears',
          clientId: clientId,
          residenceId: home,
        ),
      ],
      prns: [
        _med(
          id: 'tears-prn',
          name: 'Artificial Tears',
          clientId: clientId,
          residenceId: home,
          isPrn: true,
        ),
        // Same-home house stock — not this resident's PRN.
        _med(
          id: 'house-prn',
          name: 'House Stock PRN',
          clientId: '',
          residenceId: home,
          isPrn: true,
        ),
        // Other resident PRN leaked by API — excluded.
        _med(
          id: 'para',
          name: 'Paracetamol',
          clientId: 'client-015',
          residenceId: home,
          isPrn: true,
        ),
        _med(
          id: 'inactive',
          name: 'Inactive PRN',
          clientId: clientId,
          residenceId: home,
          isPrn: true,
          isActive: false,
        ),
      ],
    );

    expect(scoped.map((m) => m.id), ['tears-prn']);
  });

  test('duplicate PRN ids are deduped', () {
    final tear = _med(
      id: 'tears',
      name: 'Artificial Tears',
      clientId: clientId,
      residenceId: home,
      isPrn: true,
    );
    final scoped = StaffClientMedicationItem.scopedForRecordAdministration(
      clientId: clientId,
      residenceId: home,
      prescribed: const [],
      prns: [tear, tear],
    );
    expect(scoped, hasLength(1));
  });
}
