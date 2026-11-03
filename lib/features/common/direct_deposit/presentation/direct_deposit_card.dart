import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/app_snackbar.dart';
import '../../../../core/roles/user_session.dart';
import '../../../hr/handovers/presentation/widgets/handover_common.dart';
import '../../../hr/presentation/widgets/hr_directory_widgets.dart';
import '../data/direct_deposit_mapper.dart';
import '../data/direct_deposit_repository.dart';
import '../domain/direct_deposit.dart';

/// Web "Direct deposit" card on My profile (Stripe / PayPal).
///
/// Shown only when the signed-in user has a staff record, payroll runs
/// internally, and `/payroll/me/payout-method` returns available methods.
class DirectDepositCard extends StatefulWidget {
  const DirectDepositCard({super.key});

  @override
  State<DirectDepositCard> createState() => _DirectDepositCardState();
}

class _DirectDepositCardState extends State<DirectDepositCard> {
  late final DirectDepositRepository _repo;
  bool _loading = true;
  bool _opening = false;
  bool _saving = false;
  String? _error;
  bool _visible = false;
  PayoutMethodInfo? _method;
  PayoutAccountInfo? _account;
  String? _selected;
  final _paypal = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = GetIt.instance<DirectDepositRepository>();
    _reload();
  }

  @override
  void dispose() {
    _paypal.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final session = Get.isRegistered<UserSession>()
        ? Get.find<UserSession>()
        : null;
    final staffId = session?.staffId;
    if (staffId == null || staffId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _visible = false;
      });
      return;
    }

    final engineResult = await _repo.loadEngine();
    final engineOk =
        engineResult.isSuccess && (engineResult.value?.isInternal ?? false);
    if (!engineOk) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _visible = false;
      });
      return;
    }

    final methodResult = await _repo.loadMyMethod();
    if (!methodResult.isSuccess) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _visible = false;
        _error = methodResult.error?.message;
      });
      return;
    }
    final method = methodResult.value!;
    if (method.available.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _visible = false;
      });
      return;
    }

    PayoutAccountInfo? account;
    if (method.available.contains('stripe')) {
      final accountResult = await _repo.loadMyAccount();
      if (accountResult.isSuccess) {
        account = accountResult.value;
      }
    }

    final selected = method.method ??
        (method.available.length == 1 ? method.available.first : null);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _visible = true;
      _method = method;
      _account = account;
      _selected = selected;
      _paypal.text = method.paypalEmail ?? '';
    });
  }

  Future<void> _choose(String method, {String? paypalEmail}) async {
    setState(() => _saving = true);
    final result = await _repo.setMyMethod(
      method: method,
      paypalEmail: paypalEmail,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!result.isSuccess) {
      AppSnackbar.show(
        result.error?.message ?? 'Could not save payout method',
        '',
        force: true,
      );
      return;
    }
    AppSnackbar.show(
      method == 'paypal'
          ? 'You will be paid to this PayPal'
          : 'You will be paid into your bank by Stripe',
      '',
      force: true,
    );
    await _reload();
  }

  Future<void> _openStripe() async {
    setState(() => _opening = true);
    final result = await _repo.startOnboarding();
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() => _opening = false);
      AppSnackbar.show(
        result.error?.message ?? 'Could not open Stripe',
        '',
        force: true,
      );
      return;
    }
    final uri = Uri.tryParse(result.value!.url);
    if (uri == null) {
      setState(() => _opening = false);
      AppSnackbar.show('Invalid Stripe link', '', force: true);
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!launched) {
      AppSnackbar.show('Could not open Stripe', '', force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!_visible) return const SizedBox.shrink();

    final available = _method?.available ?? const <String>[];
    final account = _account;
    final statusLabel = DirectDepositMapper.statusLabel(account?.status);
    final stripeHint = account == null
        ? null
        : account.payoutsEnabled
            ? 'Your pay is sent straight to your bank through Stripe.'
            : 'Set up a Stripe payout account. You give your bank details and ID to Stripe on their page — they are never stored here.';

    return HrSectionCard(
      title: 'Direct deposit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How you are paid when your employer pays a payroll run from here.',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: handoverText(context, 12.5, color: AppColors.criticalRed),
            ),
          ],
          if (available.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in available)
                  ChoiceChip(
                    label: Text(
                      m == 'stripe' ? 'Into my bank (Stripe)' : 'To my PayPal',
                    ),
                    selected: _selected == m,
                    onSelected: _saving
                        ? null
                        : (_) {
                            if (m == 'stripe') {
                              _choose('stripe');
                            } else if (_paypal.text.trim().isEmpty) {
                              AppSnackbar.show(
                                'Enter your PayPal email below, then choose PayPal',
                                '',
                                force: true,
                              );
                            } else {
                              _choose('paypal', paypalEmail: _paypal.text.trim());
                            }
                          },
                  ),
              ],
            ),
          ],
          if (_selected == 'stripe' ||
              (available.contains('stripe') && available.length == 1)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          stripeHint ?? '',
                          style: handoverText(
                            context,
                            12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (statusLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.activeGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: handoverText(
                              context,
                              11.5,
                              weight: FontWeight.w600,
                              color: AppColors.activeGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (account != null) ...[
                    const SizedBox(height: 10),
                    HandoverButton(
                      label: _opening
                          ? 'Opening Stripe…'
                          : DirectDepositMapper.stripeActionLabel(account),
                      filled: !account.payoutsEnabled,
                      compact: true,
                      onPressed: _opening ? null : _openStripe,
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (available.contains('paypal') &&
              (_selected == 'paypal' ||
                  (_selected != 'stripe' && available.contains('paypal')))) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _paypal,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'PayPal email',
                helperText:
                    'The email address of your PayPal account. Without a PayPal account there, PayPal holds the money for 30 days for you to claim it.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 8),
            HandoverButton(
              label: _saving ? 'Saving…' : 'Save PayPal email',
              filled: true,
              compact: true,
              onPressed: _saving || _paypal.text.trim().isEmpty
                  ? null
                  : () => _choose('paypal', paypalEmail: _paypal.text.trim()),
            ),
          ],
        ],
      ),
    );
  }
}
