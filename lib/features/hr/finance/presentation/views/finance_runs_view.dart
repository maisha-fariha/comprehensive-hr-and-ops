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
                  child: Text(
                    controller.busyAction.value == 'createRun'
                        ? 'Computing…'
                        : 'Create run',
                  ),
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

class _RunDetailSheet extends StatefulWidget {
  final FinanceController controller;
  final PayrollRun run;

  const _RunDetailSheet({required this.controller, required this.run});

  @override
  State<_RunDetailSheet> createState() => _RunDetailSheetState();
}

enum _RunDetailTab { entries, claims, residences }

class _RunDetailSheetState extends State<_RunDetailSheet> {
  _RunDetailTab _tab = _RunDetailTab.entries;
  QuickBooksRunStatus? _qbStatus;
  bool _qbLoading = false;

  PayrollRun get run => widget.controller.selectedRun.value ?? widget.run;
  FinanceController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _loadQb();
  }

  Future<void> _loadQb() async {
    final engine = controller.engine.value;
    if (engine == null || engine.runHere) return;
    if (engine.provider.toLowerCase() != 'quickbooks') return;
    if (run.status.toLowerCase() != 'finalized') return;
    setState(() => _qbLoading = true);
    final result = await controller.loadQuickBooksRunStatus(run.id);
    if (!mounted) return;
    setState(() {
      _qbLoading = false;
      _qbStatus = result.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine.value;
    final status = run.status.toLowerCase();
    final canFinalize = controller.canWritePayroll && status == 'draft';
    final runHere = engine?.runHere ?? false;
    final isQb = (engine?.provider ?? '').toLowerCase() == 'quickbooks';
    final showQbCard = !runHere && isQb && status == 'finalized';
    final claims = run.attachedClaims;
    final residences = run.laborByResidence;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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
                '${FinanceLabels.money(run.grossTotal)} · '
                '${run.staffCount} staff · ${run.claimsCount} claims',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            ),
          ),
          if (!runHere && engine != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: FinanceInfoBanner(
                status == 'draft'
                    ? 'Draft timesheet — check the hours, fix any in Attendance, '
                        'then finalize to hand them to ${FinanceLabels.statusLabel(engine.provider)}.'
                    : 'Finalized — the hours are locked. '
                        '${FinanceLabels.statusLabel(engine.provider)} works out the pay, '
                        'tax and deductions.',
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
                      AppSnackbar.show('Run finalized', '', force: true);
                      setState(() {});
                      _loadQb();
                    }
                  },
                ),
              ),
            ),
          if (showQbCard)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: FinanceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QuickBooks Integration',
                      style: handoverText(context, 13.5, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send this finalized run\'s hours straight to QuickBooks Payroll '
                      'as daily TimeActivities without manual retyping.',
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    if (_qbLoading)
                      Text(
                        'Checking send status…',
                        style: handoverText(context, 12, color: AppColors.textMuted),
                      )
                    else if (_qbStatus?.sent == true)
                      Text(
                        'Hours already sent'
                        '${_qbStatus?.finishedAt == null ? '' : ' · ${FinanceLabels.ymd(_qbStatus!.finishedAt!)}'}',
                        style: handoverText(
                          context,
                          12.5,
                          color: AppColors.activeGreen,
                          weight: FontWeight.w600,
                        ),
                      )
                    else if (controller.quickBooks.value?.connected != true)
                      Text(
                        controller.quickBooks.value?.status == 'needs_reconnect'
                            ? 'Authorization has expired. Reconnect in the Add-ons tab before sending this run.'
                            : 'Connect your QuickBooks company in the Add-ons tab to push this run\'s timesheets.',
                        style: handoverText(context, 12.5, color: AppColors.urgentAmber),
                      )
                    else if (controller.canWritePayroll)
                      HandoverButton(
                        label: controller.busyAction.value == 'sendQb'
                            ? 'Sending…'
                            : 'Send Run to QuickBooks',
                        filled: true,
                        compact: true,
                        onPressed: controller.busy.value
                            ? null
                            : () async {
                                final err = await controller.sendRunToQuickBooks(run.id);
                                if (!context.mounted) return;
                                if (err != null) {
                                  AppSnackbar.show(err, '', force: true);
                                } else {
                                  AppSnackbar.show('Run sent to QuickBooks', '', force: true);
                                  await _loadQb();
                                }
                              },
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _DetailTab(
                  label: 'Staff (${run.entries.length})',
                  selected: _tab == _RunDetailTab.entries,
                  onTap: () => setState(() => _tab = _RunDetailTab.entries),
                ),
                const SizedBox(width: 8),
                _DetailTab(
                  label: 'Attached Claims (${claims.length})',
                  selected: _tab == _RunDetailTab.claims,
                  onTap: () => setState(() => _tab = _RunDetailTab.claims),
                ),
                const SizedBox(width: 8),
                _DetailTab(
                  label: 'Cost by Residence',
                  selected: _tab == _RunDetailTab.residences,
                  onTap: () => setState(() => _tab = _RunDetailTab.residences),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_tab) {
              _RunDetailTab.entries => ListView.separated(
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.staffName,
                                  style: handoverText(
                                    context,
                                    14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              FinanceStatusPill(e.paymentStatus),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${e.residenceName} · '
                            '${e.hours.toStringAsFixed(2)} hrs · '
                            'Gross ${FinanceLabels.money(e.grossAmount)} · '
                            'Adj ${FinanceLabels.money(e.manualAdjustment)} · '
                            'Total ${FinanceLabels.money(e.totalPay)}',
                            style: handoverText(
                              context,
                              12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (e.allocations.length > 1) ...[
                            const SizedBox(height: 6),
                            Text(
                              [
                                for (final a in e.allocations)
                                  '${a.residenceName} ${a.percent.toStringAsFixed(0)}%',
                              ].join(' · '),
                              style: handoverText(
                                context,
                                11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                          if (runHere &&
                              status == 'finalized' &&
                              controller.canWritePayroll) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (e.paymentStatus != 'paid')
                                  HandoverButton(
                                    label: 'Mark paid',
                                    compact: true,
                                    onPressed: () async {
                                      final err = await controller.setEntryPayment(
                                        entryId: e.id,
                                        status: 'paid',
                                      );
                                      if (!context.mounted) return;
                                      if (err != null) {
                                        AppSnackbar.show(err, '', force: true);
                                      } else {
                                        setState(() {});
                                      }
                                    },
                                  ),
                                if (e.paymentStatus != 'failed')
                                  HandoverButton(
                                    label: 'Mark failed',
                                    compact: true,
                                    foreground: AppColors.criticalRed,
                                    onPressed: () async {
                                      final err = await controller.setEntryPayment(
                                        entryId: e.id,
                                        status: 'failed',
                                      );
                                      if (!context.mounted) return;
                                      if (err != null) {
                                        AppSnackbar.show(err, '', force: true);
                                      } else {
                                        setState(() {});
                                      }
                                    },
                                  ),
                                if (e.paymentStatus != 'pending')
                                  HandoverButton(
                                    label: 'Back to awaiting payment',
                                    compact: true,
                                    onPressed: () async {
                                      final err = await controller.setEntryPayment(
                                        entryId: e.id,
                                        status: 'pending',
                                      );
                                      if (!context.mounted) return;
                                      if (err != null) {
                                        AppSnackbar.show(err, '', force: true);
                                      } else {
                                        setState(() {});
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              _RunDetailTab.claims => claims.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        FinanceCard(
                          child: Text(
                            'No claims attached to this run',
                            style: handoverText(
                              context,
                              13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: claims.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = claims[i];
                        return FinanceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.staffName,
                                      style: handoverText(
                                        context,
                                        14,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  FinanceStatusPill(c.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  c.kind == 'mileage' ? 'Mileage' : 'Expense',
                                  FinanceLabels.money(c.amount),
                                  if (c.description != null &&
                                      c.description!.isNotEmpty)
                                    c.description!,
                                ].join(' · '),
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
              _RunDetailTab.residences => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(
                      'Ranked by Labor Cost',
                      style: handoverText(context, 13.5, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Distribution of this run\'s gross wages based on attendance '
                      'hours worked at each care home.',
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    if (residences.isEmpty)
                      FinanceCard(
                        child: Text(
                          'Staff in this run do not have residence-allocated '
                          'attendance hours yet.',
                          style: handoverText(
                            context,
                            13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      for (final row in residences) ...[
                        FinanceCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row.name,
                                      style: handoverText(
                                        context,
                                        13.5,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${row.hours.toStringAsFixed(1)} hrs',
                                      style: handoverText(
                                        context,
                                        12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                FinanceLabels.money(row.laborCost),
                                style: handoverText(
                                  context,
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _DetailTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DetailTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.secondaryTeal : AppColors.filterButtonBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: handoverText(
              context,
              12.5,
              weight: FontWeight.w600,
              color: selected ? AppColors.surfaceWhite : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}
