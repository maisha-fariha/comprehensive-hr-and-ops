import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/client_form.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/data/residence_geocoder.dart';
import 'package:comprehensive_hr_and_ops/features/hr/residences/domain/entities/residence_form.dart';
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

  test('residence form body includes email and geofence when set', () {
    final values = ResidenceFormValues(
      name: 'Map House',
      email: 'map@example.com',
      type: 'Assisted Living',
      streetAddress: '1 Main',
      city: 'Portland',
      state: 'OR',
      postalCode: '97035',
      country: 'United States',
      latitude: '45.515200',
      longitude: '-122.678400',
      geofenceRadius: '150',
      totalBeds: '4',
    );
    final body = values.toBody();
    expect(body['email'], 'map@example.com');
    expect(body['latitude'], 45.5152);
    expect(body['longitude'], -122.6784);
    expect(body['geofence'], {'radiusMeters': 150});
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
