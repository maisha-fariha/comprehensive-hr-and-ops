import 'package:comprehensive_hr_and_ops/features/staff/medication/data/mappers/staff_medication_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Due Now matches web: due + upcoming only; overdue goes to Missed', () {
    final overview = StaffMedicationMapper.fromRound({
      'data': {
        'occurrences': [
          {
            'id': 'overdue-am',
            'state': 'overdue',
            'name': 'Metformin 500mg',
            'clientName': 'Client 002',
            'residenceName': 'Residence 001',
            'scheduledTime': '08:00',
            'dueAt': '2026-11-12T02:00:00.000Z',
            'scheduled': true,
          },
          {
            'id': 'due-eve',
            'state': 'due',
            'name': 'Paracetamol Daily',
            'clientName': 'Client 015',
            'residenceName': 'Residence 003',
            'scheduledTime': '18:00',
            'dueAt': '2026-11-12T12:00:00.000Z',
            'scheduled': true,
          },
          {
            'id': 'upcoming-eve',
            'state': 'upcoming',
            'name': 'Atorvastatin 20mg',
            'clientName': 'Client 012',
            'residenceName': 'Residence 003',
            'scheduledTime': '20:00',
            'dueAt': '2026-11-12T14:00:00.000Z',
            'scheduled': true,
          },
        ],
        'summary': {
          'scheduled': 3,
          'due': 1,
          'missed': 1,
          'overdue': 1,
        },
      },
    });

    expect(
      overview.dueNowDoses.map((d) => d.timeLabel).toList(),
      ['18:00', '20:00'],
    );
    expect(overview.laterTodayDoses, isEmpty);
    expect(overview.missedDoses.map((d) => d.id).toList(), ['overdue-am']);
  });
}
