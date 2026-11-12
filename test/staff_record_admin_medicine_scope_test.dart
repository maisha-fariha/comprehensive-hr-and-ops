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

  test('Record Admin medicine list matches web resident + house-stock scope', () {
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
        // Other resident — must never appear.
        _med(
          id: 'other-med',
          name: 'Other Med',
          clientId: 'client-015',
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
        // Same-home house stock — web includes these.
        _med(
          id: 'house-prn',
          name: 'House Stock PRN',
          clientId: '',
          residenceId: home,
          isPrn: true,
        ),
        // Other home house stock — excluded on web.
        _med(
          id: 'other-house',
          name: 'Other House PRN',
          clientId: '',
          residenceId: 'res-003',
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

    expect(
      scoped.map((m) => m.id),
      ['met', 'tears-sched', 'tears-prn', 'house-prn'],
    );
  });

  test('duplicate id+isPrn rows are deduped', () {
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
