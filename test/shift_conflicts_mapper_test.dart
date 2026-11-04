import 'package:comprehensive_hr_and_ops/features/hr/scheduling/data/mappers/scheduling_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shiftConflictsFrom maps overlap, leave, rest and minimum hours', () {
    final result = SchedulingMapper.shiftConflictsFrom({
      'data': {
        'hasConflict': true,
        'conflicts': [
          {
            'staffId': 's1',
            'staffName': 'Sadia Noor',
            'shiftId': 'sh1',
            'label': 'Wed 4 Nov, 12:30–14:30 GMT+6',
            'residenceName': 'Cozzy Cottege',
          },
        ],
        'leave': [
          {
            'staffId': 's2',
            'staffName': 'Alex',
            'label': 'Thu 5 Nov',
            'type': 'annual',
          },
        ],
        'rest': [
          {
            'staffId': 's1',
            'staffName': 'Sadia Noor',
            'label': 'Wed 4 Nov, 19:30–19:45 GMT+6',
            'restHours': 4.5,
          },
        ],
        'minimumRestHours': 8,
      },
    });

    expect(result.hasConflict, isTrue);
    expect(result.blocksStaffing, isTrue);
    expect(result.conflicts.single.staffName, 'Sadia Noor');
    expect(result.leave.single.staffName, 'Alex');
    expect(result.rest.single.restHours, 4.5);
    expect(result.rest.single.restHoursLabel, '4.5');
    expect(result.minimumRestHours, 8);
  });

  test('rest alone does not block staffing', () {
    final result = SchedulingMapper.shiftConflictsFrom({
      'data': {
        'hasConflict': true,
        'conflicts': [],
        'leave': [],
        'rest': [
          {
            'staffId': 's1',
            'staffName': 'Sadia Noor',
            'label': 'Wed 4 Nov, 12:30–14:30 GMT+6',
            'restHours': 5,
          },
        ],
        'minimumRestHours': 8,
      },
    });
    expect(result.rest, hasLength(1));
    expect(result.blocksStaffing, isFalse);
    expect(result.rest.single.restHoursLabel, '5');
  });
}
