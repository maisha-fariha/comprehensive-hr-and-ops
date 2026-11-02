import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/finance_mapper.dart';
import '../../domain/entities/finance.dart';
import '../controllers/finance_controller.dart';
import '../widgets/finance_common.dart';

class FinanceAddonsView extends StatelessWidget {
  final FinanceController controller;

  const FinanceAddonsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final addons = controller.addons.toList();
      final selectedKey = controller.selectedAddonKey.value;
      BillingAddon? selected;
      for (final a in addons) {
        if (a.key == selectedKey) {
          selected = a;
          break;
        }
      }
      selected ??= addons.isEmpty ? null : addons.first;
      final qb = controller.quickBooks.value;
      final engine = controller.engine.value;

      return RefreshIndicator(
        color: AppColors.secondaryTeal,
        onRefresh: controller.refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            financeSectionTitle(
              context,
              'Add-ons',
              subtitle: 'Payroll providers and included plan extras.',
            ),
            const SizedBox(height: 14),
            if (addons.isEmpty && controller.isLoading.value)
              const Center(child: CircularProgressIndicator()),
            for (final addon in addons) ...[
              Material(
                color: addon.key == selected?.key
                    ? AppColors.secondaryTeal.withValues(alpha: 0.12)
                    : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => controller.selectedAddonKey.value = addon.key,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: addon.key == selected?.key
                            ? AppColors.secondaryTeal
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                addon.name,
                                style: handoverText(
                                  context,
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                FinanceLabels.addonBadge(addon),
                                style: handoverText(
                                  context,
                                  12,
                                  color: AppColors.activeGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (addon.price != null)
                          Text(
                            '${FinanceLabels.money(addon.price)} per year',
                            style: handoverText(context, 12.5),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (selected != null) ...[
              const SizedBox(height: 8),
              FinanceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected.name,
                            style: handoverText(context, 16, weight: FontWeight.w700),
                          ),
                        ),
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
                            FinanceLabels.addonBadge(selected),
                            style: handoverText(
                              context,
                              11,
                              weight: FontWeight.w600,
                              color: AppColors.activeGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selected.description,
                      style: handoverText(context, 13, color: AppColors.textMuted),
                    ),
                    if (selected.key == 'quickbooks') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Connection',
                              style: handoverText(context, 14, weight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            qb?.connected == true ? 'Connected' : 'Not connected',
                            style: handoverText(
                              context,
                              12.5,
                              color: qb?.connected == true
                                  ? AppColors.activeGreen
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (qb?.connected != true) ...[
                        HandoverButton(
                          label: 'Connect QuickBooks',
                          filled: true,
                          onPressed: () async {
                            final result = await controller.connectQuickBooks();
                            if (result.error != null) {
                              AppSnackbar.show(result.error!, '', force: true);
                              return;
                            }
                            await copyFinanceText(
                              result.value!,
                              ok: 'Authorize URL copied — open it in a browser to connect',
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Payroll still runs through QuickBooks, but no hours reach it while it is not connected. Connect it, or run payroll here instead.',
                          style: handoverText(context, 12.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 10),
                        if (controller.canWritePayroll && engine?.runHere != true)
                          HandoverButton(
                            label: 'Run payroll here instead',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Stop running payroll through QuickBooks?'),
                                  content: const Text(
                                    'Staff will be paid from this platform instead: pay, payslips and payouts by Stripe or PayPal. Hours will no longer be sent to QuickBooks. Your QuickBooks add-on stays on your bill until you cancel it.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Yes, run payroll here'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              final err =
                                  await controller.setPayrollEngine(runHere: true);
                              if (err != null) {
                                AppSnackbar.show(err, '', force: true);
                              } else {
                                AppSnackbar.show(
                                  'Payroll now runs here',
                                  '',
                                  force: true,
                                );
                              }
                            },
                          ),
                      ] else ...[
                        if (qb?.companyName != null)
                          Text('Company: ${qb!.companyName}'),
                        if (controller.canWritePayroll && engine?.runHere == true)
                          HandoverButton(
                            label: 'Run payroll through QuickBooks again',
                            onPressed: () async {
                              final err =
                                  await controller.setPayrollEngine(runHere: false);
                              if (err != null) {
                                AppSnackbar.show(err, '', force: true);
                              }
                            },
                          ),
                      ],
                    ],
                    if (selected.key == 'adp') ...[
                      const SizedBox(height: 12),
                      Text(
                        selected.canBuy
                            ? 'Available to add — checkout stays on web billing.'
                            : FinanceLabels.addonBadge(selected),
                        style: handoverText(context, 12.5, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
