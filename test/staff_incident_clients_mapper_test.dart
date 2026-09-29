import 'package:comprehensive_hr_and_ops/features/staff/incidents/data/mappers/staff_incidents_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clientsFrom builds names from firstName/lastName like live API', () {
    final clients = StaffIncidentsMapper.clientsFrom({
      'data': [
        {
          'id': 'c1',
          'firstName': 'Encoderit',
          'lastName': 'Naeem',
          'residenceId': 'r1',
          'residence': {'id': 'r1', 'name': 'Mala Box '},
          'roomNumber': '12',
        },
        {
          'id': 'c2',
          'firstName': 'Puchan',
          'lastName': 'Indha',
          'residenceId': 'r1',
          'residence': {'id': 'r1', 'name': 'Mala Box'},
        },
        {
          'id': 'c3',
          'name': 'Already Named',
        },
      ],
    });

    expect(clients, hasLength(3));
    expect(clients[0].name, 'Encoderit Naeem');
    expect(clients[0].subtitle, 'Client · Mala Box');
    expect(clients[0].initials, 'EN');
    expect(clients[1].name, 'Puchan Indha');
    expect(clients[1].initials, 'PI');
    expect(clients[2].name, 'Already Named');
  });
}
