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

class FinanceOverviewView extends StatelessWidget {
  final FinanceController controller;
  final VoidCallback onOpenRuns;
  final VoidCallback onOpenClaims;
  final VoidCallback? onOpenReports;

  const FinanceOverviewView({
    super.key,
    required this.controller,
    required this.onOpenRuns,
    required this.onOpenClaims,
    this.onOpenReports,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.overview.value;
      final engine = controller.engine.value;
      final loading = controller.isLoading.value;
      final error = controller.loadError.value;
      final run = controller.activeRun;
      final entries = controller.overviewEntries;
      final trend = controller.payrollTrend;
      final export = controller.lastPayrollExport.value;

      return RefreshIndicator(
        color: AppColors.secondaryTeal,
        onRefresh: controller.refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            financeSectionTitle(
              context,
              'Payroll Overview',
              subtitle: 'Current pay period summary and claims attribution',
            ),
            if (engine != null && !engine.runHere) ...[
              const SizedBox(height: 12),
              FinanceInfoBanner(
                '${FinanceLabels.statusLabel(engine.provider)} runs your payroll. '
                'The amounts below are estimates from hours and the rates on file here — '
                '${FinanceLabels.statusLabel(engine.provider)} works out the actual pay, '
                'tax and deductions, and issues the payslips.',
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error, style: handoverText(context, 13, color: AppColors.criticalRed)),
            ],
            if (loading && stats == null)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (stats != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FinanceStatCard(
                    label: 'Total Payroll This Period',
                    value: FinanceLabels.money(stats.totalPayroll),
                    note: stats.payPeriodLabel,
                  ),
                  FinanceStatCard(
                    label: 'Staff Hours',
                    value: stats.staffHours.toStringAsFixed(
                      stats.staffHours == stats.staffHours.roundToDouble() ? 0 : 1,
                    ),
                    note: '${stats.staffOnRun} people on this run',
                  ),
                  FinanceStatCard(
                    label: 'Overtime Cost',
                    value: FinanceLabels.money(stats.overtimeCost),
                    note:
                        '${stats.overtimeHours.toStringAsFixed(0)} overtime hours',
                  ),
                  FinanceStatCard(
                    label: 'Pending Approvals',
                    value: '${stats.pendingApprovals}',
                    note: 'Requires review',
                    noteColor: AppColors.criticalRed,
                    onTap: stats.pendingApprovals > 0 ? onOpenClaims : null,
                  ),
                  FinanceStatCard(
                    label: 'Reimbursements',
                    value: FinanceLabels.money(stats.reimbursements),
                    note: '${stats.reimbursementClaims} claims in this run',
                  ),
                  FinanceStatCard(
                    label: 'Cost per Client',
                    value: FinanceLabels.money(stats.costPerClient),
                    note: stats.residentCount == 0
                        ? 'No residents on the books'
                        : '${stats.residentCount} residents',
                  ),
                  FinanceStatCard(
                    label: 'Finalized',
                    value: stats.runStatus.isEmpty
                        ? '—'
                        : FinanceLabels.statusLabel(
                            stats.runStatus == 'finalized'
                                ? 'Processing'
                                : stats.runStatus,
                          ),
                    note: 'Payroll Status',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              financeSectionTitle(
                context,
                'Payroll Summary',
                subtitle: run == null
                    ? null
                    : 'Pay period ${FinanceLabels.periodLabel(run.periodStart, run.periodEnd)} · ${run.entries.length} staff',
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (v) => controller.overviewSearch.value = v,
                decoration: InputDecoration(
                  hintText: 'Search staff or residence...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surfaceWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                FinanceCard(
                  child: Text(
                    'No staff lines on the current run.',
                    style: handoverText(context, 13, color: AppColors.textMuted),
                  ),
                )
              else
                for (final e in entries) ...[
                  _EntryRow(
                    entry: e,
                    periodType: run?.periodType ?? '',
                    onView: () => _openEntry(context, e, run),
                  ),
                  const SizedBox(height: 8),
                ],
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Showing 1 to ${entries.length} of ${entries.length} entries',
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 20),
              _TrendCard(
                trend: trend,
                thisPeriod: stats.totalPayroll,
                runsCount: controller.runsTotal.value,
                onAnalytics: onOpenRuns,
              ),
              const SizedBox(height: 12),
              if (run != null) _RunSummaryCard(run: run, onOpen: onOpenRuns),
              const SizedBox(height: 12),
              _PayPeriodCalendar(run: run),
              const SizedBox(height: 12),
              FinanceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Breakdown',
                      style: handoverText(context, 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Claims, by where they stand',
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      FinanceLabels.money(stats.reimbursements),
                      style: handoverText(context, 20, weight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: onOpenClaims,
                      child: const Text('View Expense Report'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FinanceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Upcoming Approvals & Exceptions',
                            style: handoverText(context, 14, weight: FontWeight.w700),
                          ),
                        ),
                        TextButton(
                          onPressed: onOpenClaims,
                          child: const Text('View all approvals'),
                        ),
                      ],
                    ),
                    Text(
                      stats.pendingApprovals == 0
                          ? 'Nothing waiting for a decision.'
                          : '${stats.pendingApprovals} claim(s) need review.',
                      style: handoverText(context, 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FinanceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: handoverText(context, 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _QuickAction(
                          label: 'Approve Timesheets',
                          color: AppColors.activeGreen,
                          onTap: onOpenClaims,
                        ),
                        _QuickAction(
                          label: 'Export Payroll',
                          color: AppColors.secondaryTeal,
                          onTap: () => _export(context),
                        ),
                        _QuickAction(
                          label: 'Add Adjustment',
                          color: AppColors.urgentAmber,
                          onTap: () {
                            if (entries.isEmpty) {
                              AppSnackbar.show(
                                'No staff line to adjust on the current run.',
                                '',
                                force: true,
                              );
                              return;
                            }
                            _openEntry(context, entries.first, run);
                          },
                        ),
                        _QuickAction(
                          label: 'View Reports',
                          color: const Color(0xFF7656D6),
                          onTap: onOpenReports ?? onOpenRuns,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FinanceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Payroll Data',
                      style: handoverText(context, 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'One row per pay line. The file is written in the background.',
                      style: handoverText(context, 12.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    HandoverButton(
                      label: controller.busy.value
                          ? 'Queueing…'
                          : 'Export payroll entries (CSV)',
                      filled: true,
                      onPressed: controller.busy.value
                          ? null
                          : () => _export(context),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Last export: ${export == null ? 'Never exported' : FinanceLabels.statusLabel(export.status)}',
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _export(BuildContext context) async {
    final error = await controller.exportPayrollCsv();
    if (error != null) {
      AppSnackbar.show(error, '', force: true);
    } else {
      AppSnackbar.show('Payroll export queued', '', force: true);
    }
  }

  Future<void> _openEntry(
    BuildContext context,
    PayrollEntry entry,
    PayrollRun? run,
  ) async {
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntryDetailSheet(
        controller: controller,
        entry: entry,
        run: run,
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final PayrollEntry entry;
  final String periodType;
  final VoidCallback onView;

  const _EntryRow({
    required this.entry,
    required this.periodType,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return FinanceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceAvatar(entry.staffName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.staffName,
                  style: handoverText(context, 14, weight: FontWeight.w700),
                ),
                if (entry.staffRole != null)
                  Text(
                    entry.staffRole!,
                    style: handoverText(context, 11.5, color: AppColors.infoBlue),
                  ),
                const SizedBox(height: 6),
                Text(
                  '${entry.residenceName} · '
                  '${entry.hours.toStringAsFixed(2)} hrs · '
                  '${FinanceLabels.periodTypeLabel(periodType)}',
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rate ${FinanceLabels.money(entry.hourlyRate ?? 0)} · '
                  'Gross ${FinanceLabels.money(entry.grossAmount)} · '
                  'Adj ${FinanceLabels.money(entry.manualAdjustment)} · '
                  'Total ${FinanceLabels.money(entry.totalPay)}',
                  style: handoverText(context, 12.5),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'view') onView();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'view', child: Text('View Details')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryDetailSheet extends StatefulWidget {
  final FinanceController controller;
  final PayrollEntry entry;
  final PayrollRun? run;

  const _EntryDetailSheet({
    required this.controller,
    required this.entry,
    required this.run,
  });

  @override
  State<_EntryDetailSheet> createState() => _EntryDetailSheetState();
}

class _EntryDetailSheetState extends State<_EntryDetailSheet> {
  late final TextEditingController _adj;
  late final TextEditingController _reason;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adj = TextEditingController(
      text: widget.entry.manualAdjustment.toStringAsFixed(2),
    );
    _reason = TextEditingController();
  }

  @override
  void dispose() {
    _adj.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final canAdjust = widget.controller.canWritePayroll &&
        (widget.run?.status.toLowerCase() == 'draft' ||
            (widget.controller.engine.value?.runHere ?? false));
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ListView(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('View Details', style: handoverText(context, 16, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(e.staffName, style: handoverText(context, 15, weight: FontWeight.w600)),
          Text(
            '${e.residenceName} · ${FinanceLabels.money(e.totalPay)}',
            style: handoverText(context, 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Text('Hours ${e.hours.toStringAsFixed(2)} · OT ${e.overtimeHours.toStringAsFixed(2)}'),
          Text('Gross ${FinanceLabels.money(e.grossAmount)}'),
          Text('Adjustment ${FinanceLabels.money(e.manualAdjustment)}'),
          Text('Net ${FinanceLabels.money(e.netAmount)}'),
          Text('Payment ${FinanceLabels.statusLabel(e.paymentStatus)}'),
          if (canAdjust) ...[
            const SizedBox(height: 16),
            Text('Add Adjustment', style: handoverText(context, 14, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _adj,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Manual adjustment'),
            ),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                helperText: 'Required when the amount changes',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: handoverText(context, 12.5, color: AppColors.criticalRed)),
              ),
            const SizedBox(height: 12),
            HandoverButton(
              label: 'Save adjustment',
              filled: true,
              onPressed: () async {
                final amount = double.tryParse(_adj.text.trim());
                if (amount == null) {
                  setState(() => _error = 'Enter a valid amount');
                  return;
                }
                final changed = (amount - e.manualAdjustment).abs() > 0.001;
                if (changed && _reason.text.trim().length < 3) {
                  setState(() => _error = 'Say what kind of adjustment this is and why');
                  return;
                }
                final err = await widget.controller.adjustEntry(
                  entryId: e.id,
                  manualAdjustment: amount,
                  adjustmentType: changed ? 'manual' : null,
                  reason: changed ? _reason.text.trim() : null,
                );
                if (!mounted) return;
                if (err != null) {
                  setState(() => _error = err);
                } else {
                  Navigator.pop(context);
                  AppSnackbar.show('Entry updated', '', force: true);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<({String month, double total})> trend;
  final double thisPeriod;
  final int runsCount;
  final VoidCallback onAnalytics;

  const _TrendCard({
    required this.trend,
    required this.thisPeriod,
    required this.runsCount,
    required this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final max = trend.fold<double>(0, (s, e) => e.total > s ? e.total : s);
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payroll Cost Trend', style: handoverText(context, 14, weight: FontWeight.w700)),
          Text(
            'Gross payroll - last 6 months',
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            '${FinanceLabels.money(thisPeriod)} this period',
            style: handoverText(context, 16, weight: FontWeight.w700),
          ),
          Text(
            '▲ $runsCount runs',
            style: handoverText(context, 12, color: AppColors.activeGreen),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in trend) ...[
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: max <= 0 ? 4 : (4 + (point.total / max) * 60),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTeal.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(onPressed: onAnalytics, child: const Text('View full analytics')),
        ],
      ),
    );
  }
}

class _RunSummaryCard extends StatelessWidget {
  final PayrollRun run;
  final VoidCallback onOpen;

  const _RunSummaryCard({required this.run, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payroll Run Summary', style: handoverText(context, 14, weight: FontWeight.w700)),
          Text(
            'Current processing run',
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          _kv(context, 'Pay Period', FinanceLabels.periodLabel(run.periodStart, run.periodEnd)),
          _kv(context, 'Processing Started', FinanceLabels.periodLabel(run.createdAt, null)),
          _kv(context, 'Total Staff', '${run.staffCount}'),
          _kv(context, 'Total Hours', run.hoursTotal.toStringAsFixed(0)),
          _kv(context, 'Gross Payroll', run.grossTotal.toStringAsFixed(2)),
          _kv(context, 'Adjustments', run.adjustmentsTotal.toStringAsFixed(2)),
          _kv(context, 'Attached Claims', run.claimsCount == 0 ? 'None' : '${run.claimsCount}'),
          _kv(
            context,
            'Total to pay',
            run.grossTotal.toStringAsFixed(2),
            valueColor: AppColors.secondaryTeal,
          ),
          const SizedBox(height: 8),
          HandoverButton(label: 'View Payroll Report', filled: true, onPressed: onOpen),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: handoverText(context, 12.5, color: AppColors.textMuted))),
          Text(
            v,
            style: handoverText(
              context,
              12.5,
              weight: FontWeight.w600,
              color: valueColor ?? AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayPeriodCalendar extends StatelessWidget {
  final PayrollRun? run;
  const _PayPeriodCalendar({required this.run});

  @override
  Widget build(BuildContext context) {
    final start = run?.periodStart;
    final end = run?.periodEnd;
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pay Period Calendar', style: handoverText(context, 14, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (start == null || end == null)
            Text('No active pay period', style: handoverText(context, 13, color: AppColors.textMuted))
          else ...[
            Text(
              '${_month(start)} - ${_month(end)} ${end.year}',
              style: handoverText(context, 13, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _dot(context, AppColors.secondaryTeal, 'Pay Period Start · ${start.day}'),
            _dot(context, AppColors.urgentAmber, 'Pay Period End · ${end.day}'),
            _dot(context, AppColors.activeGreen, 'Pay Date · ${end.day}'),
          ],
        ],
      ),
    );
  }

  String _month(DateTime d) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[d.month - 1];
  }

  Widget _dot(BuildContext context, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: handoverText(context, 12.5)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.bolt, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: handoverText(context, 12, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
