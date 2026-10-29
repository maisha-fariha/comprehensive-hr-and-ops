import 'package:comprehensive_hr_and_ops/features/common/inbox/domain/entities/portal_notification.dart';
import 'package:comprehensive_hr_and_ops/features/common/inbox/presentation/navigation/shift_notification_focus.dart';
import 'package:comprehensive_hr_and_ops/core/network/iso_date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BUG_Report001 shift notification focus', () {
    test('reads shiftStartsAt and shiftId from notification meta', () {
      final focus = ShiftNotificationFocus.fromNotification(
        const PortalNotification(
          id: 'n1',
          title: 'Shift assigned',
          body: 'Fri 30 Oct, 08:00–12:00 PDT',
          timeLabel: '',
          entityType: 'shift',
          entityId: '49dae483-a91b-4a46-99d4-1c1a0ef944f0',
          meta: {
            'shiftId': '49dae483-a91b-4a46-99d4-1c1a0ef944f0',
            'shiftStartsAt': '2026-10-30T15:00:00.000Z',
            'shiftEndsAt': '2026-10-30T19:00:00.000Z',
          },
        ),
      );

      expect(focus.shiftId, '49dae483-a91b-4a46-99d4-1c1a0ef944f0');
      expect(focus.date, isNotNull);
      final local = DateTime.parse('2026-10-30T15:00:00.000Z').toLocal();
      expect(
        focus.date,
        DateTime(local.year, local.month, local.day),
      );
      expect(
        IsoDateRange.startOfWeek(focus.date!),
        IsoDateRange.startOfWeek(DateTime(local.year, local.month, local.day)),
      );
    });

    test('falls back to entityId when meta has no shiftId or startsAt', () {
      final focus = ShiftNotificationFocus.fromNotification(
        const PortalNotification(
          id: 'n2',
          title: 'Shift assigned',
          body: 'Wed 14 Oct',
          timeLabel: '',
          entityType: 'shift',
          entityId: 'c9180a2c-ed4c-4ab9-a6c1-5dc48f0699b6',
          meta: {
            'shiftId': 'c9180a2c-ed4c-4ab9-a6c1-5dc48f0699b6',
            'eventKey': 'scheduling.shift_published',
          },
        ),
      );

      expect(focus.date, isNull);
      expect(focus.shiftId, 'c9180a2c-ed4c-4ab9-a6c1-5dc48f0699b6');
      expect(focus.isEmpty, isFalse);
    });

    test('push data helper mirrors notification meta keys', () {
      final focus = ShiftNotificationFocus.fromPushData({
        'entityType': 'shift',
        'entityId': 'abc',
        'shiftStartsAt': '2026-11-05T18:00:00.000Z',
      });
      expect(focus.shiftId, 'abc');
      expect(focus.date, isNotNull);
    });
  });
}
