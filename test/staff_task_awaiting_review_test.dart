import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/data/mappers/staff_tasks_messages_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/staff/tasks_messages/domain/entities/tasks_messages_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a signed task that still needs review is Awaiting review, not Done', () {
    final tasks = StaffTasksMessagesMapper.tasksFrom({
      'data': [
        {
          'id': 't1',
          'title': 'last (2)',
          'status': 'completed',
          'requiresReview': true,
          'requiresSignOff': false,
          'reviewedAt': null,
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
    expect(tasks[0].status, TaskStatus.done);
    expect(tasks[1].awaitingReview, isFalse);

    final doneOnly = StaffTasksMessagesMapper.filterTasks(
      tasks,
      TaskFilter.done,
    );
    expect(doneOnly.map((t) => t.id), ['t2']);

    final stats = StaffTasksMessagesMapper.statsFromTasks(tasks);
    expect(stats.done, 1);
  });
}
