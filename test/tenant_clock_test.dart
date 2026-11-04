import 'package:comprehensive_hr_and_ops/core/formatting/web_formats.dart';
import 'package:comprehensive_hr_and_ops/core/network/iso_date_range.dart';
import 'package:comprehensive_hr_and_ops/core/time/tenant_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => TenantClock.use(null));

  test('wallOf uses Settings → General timezone, not the device zone', () {
    TenantClock.use(
      'America/Vancouver',
      dateFmt: 'DD/MM/YYYY',
      timeFmt: '24h',
    );

    // 20:00 UTC → 12:00 Pacific (PST, UTC-8) in winter.
    final instant = DateTime.utc(2026, 1, 15, 20, 0);
    final wall = TenantClock.wallOf(instant);
    expect(wall.hour, 12);
    expect(wall.minute, 0);
    expect(TenantClock.formatDate(instant), '15/01/2026');
    expect(TenantClock.formatTime(instant), '12:00');
    expect(WebFormat.dateTime(instant), '15/01/2026 12:00');
    expect(IsoDateRange.rangeLabel(instant, instant.add(const Duration(hours: 2))),
        '12:00 – 14:00');
  });

  test('date and time formats follow Settings → General', () {
    TenantClock.use(
      'America/Vancouver',
      dateFmt: 'MM/DD/YYYY',
      timeFmt: '12h',
    );
    final instant = DateTime.utc(2026, 1, 15, 20, 0);
    expect(TenantClock.formatDate(instant), '01/15/2026');
    expect(TenantClock.formatTime(instant), '12:00 pm');
  });

  test('Europe/Zurich matches web schedule labels for a UTC shift', () {
    TenantClock.use('Europe/Zurich', dateFmt: 'DD/MM/YYYY', timeFmt: '12h');
    // Same instant as GET /shifts startsAt for Tue 3 Nov afternoon slot.
    final instant = DateTime.utc(2026, 11, 3, 19, 15);
    expect(TenantClock.formatTime(instant), '8:15 pm');
    expect(TenantClock.wallOf(instant).hour, 20);
  });

  test('12-hour / 24-hour aliases from Settings → General normalize', () {
    TenantClock.use('Asia/Dhaka', timeFmt: '12-hour');
    expect(TenantClock.timeFormat, '12h');
    expect(TenantClock.is24Hour, isFalse);
    expect(TenantClock.formatMinutes(13 * 60 + 5), '1:05 pm');

    TenantClock.use('Asia/Dhaka', timeFmt: '24-hour');
    expect(TenantClock.timeFormat, '24h');
    expect(TenantClock.is24Hour, isTrue);
    expect(TenantClock.formatMinutes(13 * 60 + 5), '13:05');
    expect(TenantClock.formatClock(hour: 7, minute: 0), '07:00');
  });
}
