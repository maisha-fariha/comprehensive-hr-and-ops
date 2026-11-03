import 'package:flutter/foundation.dart';

/// Web `/dashboard/profile` Direct deposit card — Stripe / PayPal payouts.
@immutable
class PayrollEngineInfo {
  final String engine;
  final String? provider;
  final bool runHere;

  const PayrollEngineInfo({
    required this.engine,
    required this.runHere,
    this.provider,
  });

  /// Web: Direct deposit only loads when engine is `"internal"`.
  bool get isInternal => engine == 'internal' || runHere;
}

@immutable
class PayoutMethodInfo {
  final String? method;
  final String? paypalEmail;
  final List<String> available;

  const PayoutMethodInfo({
    this.method,
    this.paypalEmail,
    this.available = const [],
  });
}

@immutable
class PayoutAccountInfo {
  final bool enabled;
  final bool connected;
  final String? status;
  final bool payoutsEnabled;
  final List<String> requirements;
  final String? disabledReason;

  const PayoutAccountInfo({
    this.enabled = false,
    this.connected = false,
    this.status,
    this.payoutsEnabled = false,
    this.requirements = const [],
    this.disabledReason,
  });
}

@immutable
class StripeOnboardingLink {
  final String url;
  final DateTime? expiresAt;

  const StripeOnboardingLink({required this.url, this.expiresAt});
}
