import 'package:comprehensive_hr_and_ops/features/common/direct_deposit/data/direct_deposit_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('engineFrom treats runHere/internal as eligible', () {
    final internal = DirectDepositMapper.engineFrom({
      'data': {
        'engine': 'internal',
        'provider': 'quickbooks',
        'runHere': true,
      },
    });
    expect(internal.isInternal, isTrue);

    final qb = DirectDepositMapper.engineFrom({
      'data': {
        'engine': 'quickbooks',
        'provider': 'quickbooks',
        'runHere': false,
      },
    });
    expect(qb.isInternal, isFalse);
  });

  test('methodFrom maps available payout channels', () {
    final method = DirectDepositMapper.methodFrom({
      'data': {
        'method': 'stripe',
        'paypalEmail': null,
        'available': ['stripe'],
      },
    });
    expect(method.method, 'stripe');
    expect(method.available, ['stripe']);
  });

  test('accountFrom and status labels match web Direct deposit card', () {
    final account = DirectDepositMapper.accountFrom({
      'data': {
        'enabled': true,
        'connected': true,
        'status': 'active',
        'payoutsEnabled': true,
        'requirements': <dynamic>[],
        'disabledReason': null,
      },
    });
    expect(account.payoutsEnabled, isTrue);
    expect(DirectDepositMapper.statusLabel(account.status), 'Ready to be paid');
    expect(
      DirectDepositMapper.stripeActionLabel(account),
      'Update bank details on Stripe',
    );
    expect(
      DirectDepositMapper.stripeActionLabel(
        DirectDepositMapper.accountFrom({
          'data': {
            'connected': true,
            'payoutsEnabled': false,
            'status': 'pending',
          },
        }),
      ),
      'Finish setting up with Stripe',
    );
    expect(DirectDepositMapper.statusLabel('pending'), 'Not finished');
    expect(DirectDepositMapper.statusLabel('restricted'), 'Stripe needs more');
  });

  test('onboardingFrom requires url', () {
    final link = DirectDepositMapper.onboardingFrom({
      'data': {
        'url': 'https://connect.stripe.com/setup/e/test',
        'expiresAt': '2026-11-03T12:00:00.000Z',
      },
    });
    expect(link?.url, contains('connect.stripe.com'));
    expect(DirectDepositMapper.onboardingFrom({'data': {}}), isNull);
  });
}
