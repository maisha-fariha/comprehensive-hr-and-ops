import 'package:comprehensive_hr_and_ops/features/hr/tasks_compliance/data/mappers/tasks_compliance_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clientsFrom builds names from firstName/lastName like live /clients', () {
    final clients = TasksComplianceMapper.clientsFrom({
      'data': [
        {
          'id': 'c1',
          'name': null,
          'firstName': 'Client',
          'lastName': 'One',
          'residenceId': 'r1',
          'residence': {'id': 'r1', 'name': 'Cozzy Cottege'},
          'roomNumber': '101',
        },
        {
          'id': 'c2',
          'name': 'Already Named',
        },
        {
          'id': 'c3',
          'firstName': '',
          'lastName': '',
        },
      ],
    });

    expect(clients, hasLength(2));
    expect(clients[0].name, 'Client One');
    expect(clients[0].subtitle, '101 · Cozzy Cottege');
    expect(clients[1].name, 'Already Named');
  });

  test('a signed task that still needs review is Awaiting review, not Completed', () {
    final tasks = TasksComplianceMapper.tasksFrom({
      'data': [
        {
          'id': 't1',
          'title': 'HK Task',
          'status': 'completed',
          'requiresReview': true,
          'requiresSignOff': true,
          'reviewedAt': null,
          'taskType': 'housekeeping',
        },
        {
          'id': 't2',
          'title': 'Already reviewed',
          'status': 'completed',
          'requiresReview': true,
          'reviewedAt': '2026-10-23T10:11:49.145Z',
        },
      ],
    });

    expect(tasks, hasLength(2));
    expect(tasks[0].awaitingReview, isTrue);
    expect(tasks[1].awaitingReview, isFalse);
  });
}
