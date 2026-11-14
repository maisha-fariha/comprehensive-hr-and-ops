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

  test('tasksAssignedTo keeps only rows for the signed-in staff', () {
    final mine = StaffTasksMessagesMapper.tasksAssignedTo(
      [
        {
          'id': 'mine',
          'title': 'My task',
          'status': 'open',
          'assignees': [
            {
              'staff': {'id': 'staff-1', 'firstName': 'A', 'lastName': 'B'},
            },
          ],
        },
        {
          'id': 'theirs',
          'title': 'Someone else',
          'status': 'open',
          'assignees': [
            {
              'staff': {'id': 'staff-2', 'firstName': 'C', 'lastName': 'D'},
            },
          ],
        },
        {
          'id': 'orphan',
          'title': 'Unassigned open task',
          'status': 'open',
        },
      ],
      staffId: 'staff-1',
      userId: 'user-1',
    );

    // Orphan (no assignees in payload) kept — trusts assignee=me when the
    // list omits assignee objects. Explicit other assignees are dropped.
    expect(mine.map((t) => t.id), ['mine', 'orphan']);
    final stats = StaffTasksMessagesMapper.statsFromTasks(mine);
    expect(stats.all, 2);
    expect(stats.dueToday, 2);
  });
}
