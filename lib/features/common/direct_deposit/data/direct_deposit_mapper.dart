import '../../../../core/network/json_codec.dart';
import '../domain/direct_deposit.dart';

abstract final class DirectDepositMapper {
  static PayrollEngineInfo engineFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    return PayrollEngineInfo(
      engine: JsonCodec.stringOr(json['engine'], ''),
      provider: JsonCodec.string(json['provider']),
      runHere: JsonCodec.boolean(json['runHere']) ?? false,
    );
  }

  static PayoutMethodInfo methodFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final available = <String>[
      for (final row in JsonCodec.listAt(json, 'available'))
        if (JsonCodec.string(row) case final s?) s,
    ];
    return PayoutMethodInfo(
      method: JsonCodec.string(json['method']),
      paypalEmail: JsonCodec.string(json['paypalEmail']),
      available: available,
    );
  }

  static PayoutAccountInfo accountFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final requirements = <String>[
      for (final row in JsonCodec.listAt(json, 'requirements'))
        if (JsonCodec.string(row) case final s?) s,
    ];
    return PayoutAccountInfo(
      enabled: JsonCodec.boolean(json['enabled']) ?? false,
      connected: JsonCodec.boolean(json['connected']) ?? false,
      status: JsonCodec.string(json['status']),
      payoutsEnabled: JsonCodec.boolean(json['payoutsEnabled']) ?? false,
      requirements: requirements,
      disabledReason: JsonCodec.string(json['disabledReason']),
    );
  }

  static StripeOnboardingLink? onboardingFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final url = JsonCodec.string(json['url']);
    if (url == null || url.isEmpty) return null;
    return StripeOnboardingLink(
      url: url,
      expiresAt: JsonCodec.dateTime(json['expiresAt']),
    );
  }

  /// Web status pills on the Direct deposit card.
  static String? statusLabel(String? status) {
    return switch (status) {
      'active' => 'Ready to be paid',
      'pending' => 'Not finished',
      'restricted' => 'Stripe needs more',
      _ => null,
    };
  }

  static String stripeActionLabel(PayoutAccountInfo account) {
    if (account.payoutsEnabled) return 'Update bank details on Stripe';
    if (account.connected) return 'Finish setting up with Stripe';
    return 'Set up with Stripe';
  }
}
