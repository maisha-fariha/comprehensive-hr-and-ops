import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/client_form.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/data/residence_geocoder.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/presentation/residences_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('residence timeZones match web IANA list (UTC + Asia/Dhaka + US/EU)', () {
    final ids = ResidencesLabels.timeZones.map((e) => e.$1).toList();
    expect(ids.first, 'UTC');
    expect(ids, contains('Asia/Dhaka'));
    expect(ids, contains('America/New_York'));
    expect(ids, contains('Europe/London'));
    expect(ids, contains('Pacific/Auckland'));
    expect(ids.length, greaterThanOrEqualTo(50));
  });

  test('composeAddress joins non-empty parts for geocode', () {
    final q = ResidenceGeocoder.composeAddress(
      street: '123 Ovoy Dash Lane',
      city: 'Dhaka',
      state: 'Dhaka North',
      postalCode: '1205',
      country: 'Bangladesh',
    );
    expect(q, '123 Ovoy Dash Lane, Dhaka, Dhaka North, 1205, Bangladesh');
  });

  test('medications portal visibility copy matches web', () {
    final med = portalVisibilityGroups
        .expand((g) => g.items)
        .firstWhere((i) => i.key == 'medications');
    expect(med.title, 'Current Medications');
    expect(med.description, 'What is prescribed and when it is given.');
    expect(
      med.note,
      'Individual dose administration status (given/refused) is hidden from family.',
    );
  });
}
