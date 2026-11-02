import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/finance_mapper.dart';
import '../../domain/entities/finance.dart';
import '../controllers/finance_controller.dart';
import '../widgets/finance_common.dart';

class FinanceRunsView extends StatelessWidget {
  final FinanceController controller;

  const FinanceRunsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final runs = controller.runs.toList();
      final loading = controller.isLoading.value;
      return RefreshIndicator(
        color: AppColors.secondaryTeal,
        onRefresh: controller.refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            financeSectionTitle(
              context,
              'Payroll runs',
              subtitle: 'Pay periods and staff totals for each run.',
              actions: [
                if (controller.canWritePayroll)
                  HandoverButton(
                    label: '+ New run',
                    filled: true,
                    compact: true,
                    onPressed: () => _newRun(context),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (loading && runs.isEmpty)
              const Center(child: CircularProgressIndicator()),
            if (!loading && runs.isEmpty)
              FinanceCard(
                child: Text(
                  'A run reads the attendance in its period and totals it per staff member.',
                  style: handoverText(context, 13, color: AppColors.textMuted),
                ),
              ),
            for (final run in runs) ...[
              _RunTile(
                run: run,
                onOpen: () async {
                  await controller.openRun(run.id);
                  if (!context.mounted) return;
                  final detail = controller.selectedRun.value ?? run;
                  await showAppBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _RunDetailSheet(
                      controller: controller,
                      run: detail,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            if (controller.runsTotal.value > 0) ...[
              const SizedBox(height: 8),
              AttendancePagination(
                page: controller.runsPage.value,
                limit: controller.runsLimit.value,
                total: controller.runsTotal.value,
                totalPages: controller.runsTotalPages.value,
                limitOptions: FinanceController.pageSizes,
                onPage: controller.setRunsPage,
                onLimit: controller.setRunsLimit,
              ),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _newRun(BuildContext context) async {
    String periodType = 'bi_weekly';
    final from = TextEditingController();
    final to = TextEditingController();
    String? error;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('New payroll run'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Every attendance record in the period is totalled per staff member and multiplied by their hourly rate.',
                      style: handoverText(ctx, 12.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: periodType,
                      decoration: const InputDecoration(labelText: 'Period type'),
                      items: [
                        for (final p in FinanceLabels.periodTypes)
                          DropdownMenuItem(value: p.$1, child: Text(p.$2)),
                      ],
                      onChanged: (v) => setState(() => periodType = v ?? periodType),
                    ),
                    TextField(
                      controller: from,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        hintText: 'YYYY-MM-DD',
                      ),
                    ),
                    TextField(
                      controller: to,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        hintText: 'YYYY-MM-DD',
                        helperText:
                            'Staff with no hourly rate on file are included with a gross of zero',
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          error!,
                          style: handoverText(ctx, 12.5, color: AppColors.criticalRed),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (from.text.trim().isEmpty || to.text.trim().isEmpty) {
                      setState(() => error = 'Both dates are required.');
                      return;
                    }
                    final err = await controller.createRun(
                      periodType: periodType,
                      periodStart: from.text.trim(),
                      periodEnd: to.text.trim(),
                    );
                    if (err != null) {
                      setState(() => error = err);
                      return;
                    }
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(controller.busy.value ? 'Computing…' : 'Create run'),
                ),
              ],
            );
          },
        );
      },
    );
    from.dispose();
    to.dispose();
    if (created == true && context.mounted) {
      AppSnackbar.show('Run created', '', force: true);
    }
  }
}

class _RunTile extends StatelessWidget {
  final PayrollRun run;
  final VoidCallback onOpen;

  const _RunTile({required this.run, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      FinanceLabels.periodLabel(run.periodStart, run.periodEnd),
                      style: handoverText(context, 14, weight: FontWeight.w700),
                    ),
                  ),
                  FinanceStatusPill(run.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                FinanceLabels.periodTypeLabel(run.periodType),
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('Staff ${run.staffCount}', style: handoverText(context, 12.5)),
                  Text('Claims ${run.claimsCount}', style: handoverText(context, 12.5)),
                  Text(
                    'Hours ${run.hoursTotal.toStringAsFixed(2)} h',
                    style: handoverText(context, 12.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunDetailSheet extends StatelessWidget {
  final FinanceController controller;
  final PayrollRun run;

  const _RunDetailSheet({required this.controller, required this.run});

  @override
  Widget build(BuildContext context) {
    final canFinalize =
        controller.canWritePayroll && run.status.toLowerCase() == 'draft';
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Payroll Run Summary',
                    style: handoverText(context, 16, weight: FontWeight.w700),
                  ),
                ),
                FinanceStatusPill(run.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${FinanceLabels.periodLabel(run.periodStart, run.periodEnd)} · '
                '${FinanceLabels.periodTypeLabel(run.periodType)} · '
                '${FinanceLabels.money(run.grossTotal)}',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            ),
          ),
          if (canFinalize)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: HandoverButton(
                  label: 'Finalize run',
                  filled: true,
                  compact: true,
                  onPressed: () async {
                    final err = await controller.finalizeRun(run.id);
                    if (!context.mounted) return;
                    if (err != null) {
                      AppSnackbar.show(err, '', force: true);
                    } else {
                      Navigator.pop(context);
                      AppSnackbar.show('Run finalized', '', force: true);
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: run.entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = run.entries[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.staffName,
                        style: handoverText(context, 14, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e.residenceName} · '
                        'Gross ${FinanceLabels.money(e.grossAmount)} · '
                        'Adj ${FinanceLabels.money(e.manualAdjustment)} · '
                        'Total ${FinanceLabels.money(e.totalPay)}',
                        style: handoverText(
                          context,
                          12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
