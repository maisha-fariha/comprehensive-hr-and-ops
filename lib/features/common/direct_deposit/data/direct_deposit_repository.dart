import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../domain/direct_deposit.dart';
import 'direct_deposit_mapper.dart';

/// Web profile Direct deposit APIs (`/payroll/me/…`, `/payroll/engine`).
class DirectDepositRepository {
  static const engine = '/payroll/engine';
  static const myMethod = '/payroll/me/payout-method';
  static const myAccount = '/payroll/me/payout-account';
  static const myOnboarding = '/payroll/me/payout-account/onboarding';

  final AppApiClient _api;

  DirectDepositRepository({required AppApiClient api}) : _api = api;

  Future<Result<PayrollEngineInfo>> loadEngine() async {
    final result = await _api.get(engine, silent: true);
    return result.when(
      success: (body) async =>
          Result.success(DirectDepositMapper.engineFrom(body)),
      failure: (e) async => Result.failure(e),
    );
  }

  Future<Result<PayoutMethodInfo>> loadMyMethod() async {
    final result = await _api.get(myMethod, silent: true);
    return result.when(
      success: (body) async =>
          Result.success(DirectDepositMapper.methodFrom(body)),
      failure: (e) async => Result.failure(e),
    );
  }

  Future<Result<PayoutAccountInfo>> loadMyAccount() async {
    final result = await _api.get(myAccount, silent: true);
    return result.when(
      success: (body) async =>
          Result.success(DirectDepositMapper.accountFrom(body)),
      failure: (e) async => Result.failure(e),
    );
  }

  Future<Result<PayoutMethodInfo>> setMyMethod({
    required String method,
    String? paypalEmail,
  }) async {
    final body = <String, dynamic>{
      'method': method,
      if (method == 'paypal' && paypalEmail != null) 'paypalEmail': paypalEmail,
    };
    final result = await _api.put(myMethod, data: body, allowQueue: false);
    return result.when(
      success: (body) async =>
          Result.success(DirectDepositMapper.methodFrom(body)),
      failure: (e) async => Result.failure(e),
    );
  }

  Future<Result<StripeOnboardingLink>> startOnboarding() async {
    final result = await _api.post(myOnboarding, data: const {}, allowQueue: false);
    return result.when(
      success: (body) async {
        final link = DirectDepositMapper.onboardingFrom(body);
        if (link == null) {
          return Result.failure(
            const ApiError(message: 'Stripe did not return an onboarding link'),
          );
        }
        return Result.success(link);
      },
      failure: (e) async => Result.failure(e),
    );
  }
}
