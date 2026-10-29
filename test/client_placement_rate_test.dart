import 'package:comprehensive_hr_and_ops/features/hr/clients/data/mappers/clients_mapper.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/client_form.dart';
import 'package:comprehensive_hr_and_ops/features/hr/clients/presentation/clients_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Client placement rate (web parity)', () {
    test('Charged options are daily / weekly / monthly', () {
      expect(
        ClientsLabels.rateFrequencies.map((e) => e.$1).toList(),
        ['daily', 'weekly', 'monthly'],
      );
      expect(ClientsLabels.rateFrequencyLabel('monthly'), 'Per month');
      expect(ClientsLabels.rateFrequencyLabel('weekly'), 'Per week');
      expect(ClientsLabels.rateFrequencyLabel('daily'), 'Per day');
    });

    test('create body sends rateAmount + rateFrequency', () {
      final form = ClientForm()
        ..firstName.text = 'Ada'
        ..lastName.text = 'Lovelace'
        ..currentResidence = 'res-1'
        ..admissionDate = '2026-09-27'
        ..fundingSource = 'Private Pay'
        ..rateAmount.text = '1200.00'
        ..rateFrequency = 'monthly';
      final body = form.toCreateBody();
      expect(body['rateAmount'], 1200.0);
      expect(body['rateFrequency'], 'monthly');
      form.dispose();
    });

    test('create body omits rateFrequency when amount empty', () {
      final form = ClientForm()
        ..firstName.text = 'Ada'
        ..lastName.text = 'Lovelace'
        ..currentResidence = 'res-1';
      final body = form.toCreateBody();
      expect(body.containsKey('rateAmount'), isFalse);
      expect(body.containsKey('rateFrequency'), isFalse);
      form.dispose();
    });

    test('mapper reads rateAmount and rateFrequency from API', () {
      final c = ClientsMapper.clientFrom({
        'id': 'c1',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'status': 'Active',
        'rateAmount': 850.5,
        'rateFrequency': 'weekly',
        'fundingSource': 'Medicaid',
      })!;
      expect(c.rateAmount, 850.5);
      expect(c.rateFrequency, 'weekly');
      final form = ClientForm.fromClient(c);
      expect(form.rateAmount.text, '850.50');
      expect(form.rateFrequency, 'weekly');
      form.dispose();
    });
  });
}
