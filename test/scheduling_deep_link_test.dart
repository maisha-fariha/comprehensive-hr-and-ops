import 'package:comprehensive_hr_and_ops/core/deeplink/scheduling_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the shift email link, which has no action', () {
    final link = SchedulingDeepLink.tryParse(
      Uri.parse(
        'https://harmony-help.encoderittest.store/dashboard/scheduling'
        '?shiftId=2091eea5-8fbe-40ce-8d68-c499ac1b4a10',
      ),
    );
    expect(link, isNotNull);
    expect(link!.tenantSubdomain, 'harmony-help');
    expect(link.shiftId, '2091eea5-8fbe-40ce-8d68-c499ac1b4a10');
    expect(link.action, 'edit');
  });

  test('the public login host is not treated as a workspace', () {
    final link = SchedulingDeepLink.tryParse(
      Uri.parse(
        'https://app-hr.encoderittest.store/dashboard/scheduling?shiftId=abc',
      ),
    );
    expect(link, isNotNull);
    expect(link!.tenantSubdomain, isNull);
    expect(link.shiftId, 'abc');
  });

  test('parses HTTPS tenant scheduling link', () {
    final link = SchedulingDeepLink.tryParse(
      Uri.parse(
        'https://my-care.encoderittest.store/dashboard/scheduling'
        '?shiftId=abc-123&action=edit',
      ),
    );
    expect(link, isNotNull);
    expect(link!.tenantSubdomain, 'my-care');
    expect(link.shiftId, 'abc-123');
    expect(link.action, 'edit');
  });

  test('parses custom scheme hrcare://shifts/<id>', () {
    final link = SchedulingDeepLink.tryParse(
      Uri.parse('hrcare://shifts/shift-9?action=edit'),
    );
    expect(link, isNotNull);
    expect(link!.shiftId, 'shift-9');
    expect(link.tenantSubdomain, isNull);
  });

  test('rejects unrelated hosts and paths', () {
    expect(
      SchedulingDeepLink.tryParse(
        Uri.parse('https://example.com/dashboard/scheduling?shiftId=1'),
      ),
      isNull,
    );
    expect(
      SchedulingDeepLink.tryParse(
        Uri.parse(
          'https://demo.encoderittest.store/dashboard/attendance?shiftId=1',
        ),
      ),
      isNull,
    );
  });
}
