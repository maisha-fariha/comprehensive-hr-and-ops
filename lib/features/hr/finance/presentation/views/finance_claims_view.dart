import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/finance_mapper.dart';
import '../../domain/entities/finance.dart';
import '../controllers/finance_controller.dart';
import '../widgets/finance_common.dart';

class FinanceClaimsView extends StatelessWidget {
  final FinanceController controller;

  const FinanceClaimsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expenses = controller.expenseClaims.toList();
      final mileage = controller.mileageClaims.toList();
      final rates = controller.mileageRates.toList();
      final loading = controller.isLoading.value;
      return RefreshIndicator(
        color: AppColors.secondaryTeal,
        onRefresh: controller.refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            financeSectionTitle(
              context,
              'Mileage rates',
              actions: [
                if (controller.canWritePayroll)
                  HandoverButton(
                    label: '+ Set a rate',
                    compact: true,
                    onPressed: () => _setRate(context),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (rates.isEmpty)
              const FinanceInfoBanner(
                'No active rate. Mileage claims are refused until one exists for the unit being claimed.',
                tone: AppColors.urgentAmber,
              )
            else
              for (final rate in rates) ...[
                FinanceCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${FinanceLabels.money(rate.rateAmount)} per ${rate.unit}'
                          '${rate.effectiveFrom == null ? '' : ' · from ${FinanceLabels.ymd(rate.effectiveFrom!)}'}',
                          style: handoverText(context, 13),
                        ),
                      ),
                      if (controller.canWritePayroll && rate.isActive)
                        TextButton(
                          onPressed: () async {
                            final err = await controller.endMileageRate(rate.id);
                            if (err != null) {
                              AppSnackbar.show(err, '', force: true);
                            } else {
                              AppSnackbar.show('Rate ended', '', force: true);
                            }
                          },
                          child: const Text('End it'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 16),
            financeSectionTitle(
              context,
              'Mileage claims',
              actions: [
                if (controller.canWritePayroll)
                  HandoverButton(
                    label: '+ New mileage claim',
                    filled: true,
                    compact: true,
                    onPressed: () => _fileClaim(context, mileage: true),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (loading && mileage.isEmpty && expenses.isEmpty)
              const Center(child: CircularProgressIndicator()),
            if (mileage.isEmpty)
              FinanceCard(
                child: Column(
                  children: [
                    const Icon(Icons.directions_car_outlined, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'No mileage claims. Claims are priced from the active rate when they are filed.',
                      textAlign: TextAlign.center,
                      style: handoverText(context, 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              for (final claim in mileage) ...[
                _ClaimTile(controller: controller, claim: claim),
                const SizedBox(height: 8),
              ],
            if (controller.mileageTotal.value >= 0) ...[
              const SizedBox(height: 8),
              AttendancePagination(
                page: controller.mileagePage.value,
                limit: controller.mileageLimit.value,
                total: controller.mileageTotal.value,
                totalPages: controller.mileageTotalPages.value,
                limitOptions: FinanceController.pageSizes,
                onPage: controller.setMileagePage,
                onLimit: controller.setMileageLimit,
              ),
            ],
            const SizedBox(height: 20),
            financeSectionTitle(
              context,
              'Expense claims',
              actions: [
                if (controller.canWritePayroll)
                  HandoverButton(
                    label: '+ New expense claim',
                    filled: true,
                    compact: true,
                    onPressed: () => _fileClaim(context, mileage: false),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (expenses.isEmpty)
              FinanceCard(
                child: Column(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'No expense claims. Out-of-pocket costs staff have paid and are owed back.',
                      textAlign: TextAlign.center,
                      style: handoverText(context, 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              for (final claim in expenses) ...[
                _ClaimTile(controller: controller, claim: claim),
                const SizedBox(height: 8),
              ],
            if (controller.expenseTotal.value >= 0) ...[
              const SizedBox(height: 8),
              AttendancePagination(
                page: controller.expensePage.value,
                limit: controller.expenseLimit.value,
                total: controller.expenseTotal.value,
                totalPages: controller.expenseTotalPages.value,
                limitOptions: FinanceController.pageSizes,
                onPage: controller.setExpensePage,
                onLimit: controller.setExpenseLimit,
              ),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _setRate(BuildContext context) async {
    String unit = 'km';
    final amount = TextEditingController();
    final from = TextEditingController(text: FinanceLabels.ymd(DateTime.now()));
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Set a rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: const [
                  DropdownMenuItem(value: 'km', child: Text('Kilometres')),
                  DropdownMenuItem(value: 'mile', child: Text('Miles')),
                ],
                onChanged: (v) => setState(() => unit = v ?? unit),
              ),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Rate per $unit'),
              ),
              TextField(
                controller: from,
                decoration: const InputDecoration(labelText: 'Effective from (YYYY-MM-DD)'),
              ),
              if (error != null)
                Text(error!, style: handoverText(ctx, 12.5, color: AppColors.criticalRed)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final rate = double.tryParse(amount.text.trim());
                if (rate == null || rate <= 0) {
                  setState(() => error = 'What is the rate per $unit?');
                  return;
                }
                final err = await controller.setMileageRate(
                  unit: unit,
                  rateAmount: rate,
                  effectiveFrom: from.text.trim(),
                );
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Set rate'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    from.dispose();
    if (ok == true && context.mounted) {
      AppSnackbar.show('Rate set', '', force: true);
    }
  }

  Future<void> _fileClaim(BuildContext context, {required bool mileage}) async {
    final residences = controller.residenceOptions
        .where((r) => mileage ? r.mileageEnabled : r.outOfPocketEnabled)
        .toList();
    final staff = controller.staffOptions.toList();
    String? staffId;
    String? residenceId = residences.isEmpty ? null : residences.first.id;
    String unit = 'km';
    final amountOrDistance = TextEditingController();
    final description = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(mileage ? 'New mileage claim' : 'New expense claim'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  mileage
                      ? 'The amount is priced by the API from the active rate — mileage must be enabled on the residence.'
                      : 'What the staff member paid out of pocket.',
                  style: handoverText(ctx, 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: staffId,
                  decoration: const InputDecoration(labelText: 'Staff *'),
                  hint: const Text('Who is claiming'),
                  items: [
                    for (final s in staff)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => staffId = v),
                ),
                if (residences.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: FinanceInfoBanner(
                      mileage
                          ? 'No residence has mileage enabled — turn it on under the residence\'s payroll settings first.'
                          : 'No residence has out-of-pocket expenses enabled — turn it on under the residence\'s payroll settings first.',
                      tone: AppColors.urgentAmber,
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: residenceId,
                    decoration: const InputDecoration(labelText: 'Residence *'),
                    items: [
                      for (final r in residences)
                        DropdownMenuItem(value: r.id, child: Text(r.name)),
                    ],
                    onChanged: (v) => setState(() => residenceId = v),
                  ),
                if (mileage) ...[
                  TextField(
                    controller: amountOrDistance,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Distance *'),
                  ),
                  DropdownButtonFormField<String>(
                    value: unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      helperText: 'A unit with no active rate is refused',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'km', child: Text('Kilometres')),
                      DropdownMenuItem(value: 'mile', child: Text('Miles')),
                    ],
                    onChanged: (v) => setState(() => unit = v ?? unit),
                  ),
                ] else ...[
                  TextField(
                    controller: amountOrDistance,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount *'),
                  ),
                  TextField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'What for'),
                  ),
                ],
                if (error != null)
                  Text(error!, style: handoverText(ctx, 12.5, color: AppColors.criticalRed)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: residences.isEmpty
                  ? null
                  : () async {
                      if (staffId == null || residenceId == null) {
                        setState(() => error = 'Staff and residence are required');
                        return;
                      }
                      final n = double.tryParse(amountOrDistance.text.trim());
                      if (n == null || n <= 0) {
                        setState(() => error = mileage ? 'Enter distance' : 'Enter amount');
                        return;
                      }
                      final err = mileage
                          ? await controller.fileMileageClaim(
                              staffId: staffId!,
                              residenceId: residenceId!,
                              distance: n,
                              unit: unit,
                            )
                          : await controller.fileExpenseClaim(
                              staffId: staffId!,
                              residenceId: residenceId!,
                              amount: n,
                              description: description.text.trim(),
                            );
                      if (err != null) {
                        setState(() => error = err);
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
              child: const Text('File claim'),
            ),
          ],
        ),
      ),
    );
    amountOrDistance.dispose();
    description.dispose();
    if (ok == true && context.mounted) {
      AppSnackbar.show('Claim filed', '', force: true);
    }
  }
}

class _ClaimTile extends StatelessWidget {
  final FinanceController controller;
  final PayrollClaim claim;

  const _ClaimTile({required this.controller, required this.claim});

  @override
  Widget build(BuildContext context) {
    final pending = claim.status.toLowerCase() == 'pending';
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  claim.staffName,
                  style: handoverText(context, 14, weight: FontWeight.w700),
                ),
              ),
              FinanceStatusPill(claim.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              FinanceLabels.money(claim.amount),
              if (claim.category != null) claim.category!,
              if (claim.distance != null)
                '${claim.distance} ${claim.distanceUnit ?? ''}'.trim(),
              if (claim.description != null && claim.description!.isNotEmpty)
                claim.description!,
              if (claim.payrollRunLabel != null) 'Run ${claim.payrollRunLabel}',
            ].join(' · '),
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          if (pending && controller.canWritePayroll) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                HandoverButton(
                  label: 'Approve',
                  filled: true,
                  compact: true,
                  onPressed: () async {
                    final error = await controller.decideClaim(
                      claim: claim,
                      status: 'approved',
                    );
                    if (error != null) {
                      AppSnackbar.show(error, '', force: true);
                    }
                  },
                ),
                const SizedBox(width: 8),
                HandoverButton(
                  label: 'Reject',
                  compact: true,
                  foreground: AppColors.criticalRed,
                  onPressed: () async {
                    final error = await controller.decideClaim(
                      claim: claim,
                      status: 'rejected',
                    );
                    if (error != null) {
                      AppSnackbar.show(error, '', force: true);
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
