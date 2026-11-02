import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/finance_mapper.dart';
import '../../domain/entities/finance.dart';
import '../controllers/finance_controller.dart';
import '../widgets/finance_common.dart';

class FinancePnlView extends StatelessWidget {
  final FinanceController controller;

  const FinancePnlView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final report = controller.report.value;
      final loading = controller.isLoading.value;
      final residences = controller.residenceOptions.toList();
      final entries = controller.ledgerEntries.toList();
      return RefreshIndicator(
        color: AppColors.secondaryTeal,
        onRefresh: () => controller.setPnlRange(
          from: controller.pnlFrom.value,
          to: controller.pnlTo.value,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            financeSectionTitle(
              context,
              'Residence P&L',
              subtitle:
                  'What each home earned and cost over a period, and whether it made money.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: controller.pnlFrom.value),
                    decoration: const InputDecoration(labelText: 'From'),
                    onSubmitted: (v) => controller.setPnlRange(
                      from: v.trim(),
                      to: controller.pnlTo.value,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: controller.pnlTo.value),
                    decoration: const InputDecoration(labelText: 'To'),
                    onSubmitted: (v) => controller.setPnlRange(
                      from: controller.pnlFrom.value,
                      to: v.trim(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final options = [
                  const FinancePersonOption(id: '', name: 'All residences'),
                  ...residences,
                ];
                final picked = await showFinancePicker<FinancePersonOption>(
                  context: context,
                  title: 'Residence',
                  options: options,
                  labelOf: (o) => o.name,
                  selected: options.firstWhere(
                    (o) => o.id == controller.pnlResidenceId.value,
                    orElse: () => options.first,
                  ),
                );
                if (picked != null) {
                  await controller.setPnlRange(
                    from: controller.pnlFrom.value,
                    to: controller.pnlTo.value,
                    residenceId: picked.id,
                  );
                }
              },
              child: FinanceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        () {
                          for (final r in residences) {
                            if (r.id == controller.pnlResidenceId.value) {
                              return r.name;
                            }
                          }
                          return 'All residences';
                        }(),
                        style: handoverText(context, 13.5),
                      ),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                HandoverButton(
                  label: 'Export CSV',
                  compact: true,
                  onPressed: () async {
                    final csv = controller.pnlCsv();
                    if (csv.isEmpty) {
                      AppSnackbar.show('Nothing to export', '', force: true);
                      return;
                    }
                    await copyFinanceText(csv, ok: 'P&L CSV copied');
                  },
                ),
                HandoverButton(
                  label: 'Client Cost Analysis',
                  compact: true,
                  onPressed: () => _clientCost(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (loading && report == null)
              const Center(child: CircularProgressIndicator()),
            if (report != null) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FinanceStatCard(
                    label: 'REVENUE',
                    value: FinanceLabels.money(report.revenueTotal),
                    note: '${FinanceLabels.money(report.revenueTotal)} from day rates',
                  ),
                  FinanceStatCard(
                    label: 'COSTS',
                    value: FinanceLabels.money(report.expenseTotal),
                    note: '${FinanceLabels.money(report.payrollTotal)} labor',
                  ),
                  FinanceStatCard(
                    label: 'NET',
                    value: FinanceLabels.money(report.netProfit),
                    note: report.margin == null
                        ? null
                        : '${report.margin!.toStringAsFixed(1)}% margin',
                    noteColor: report.netProfit < 0
                        ? AppColors.criticalRed
                        : AppColors.activeGreen,
                  ),
                  FinanceStatCard(
                    label: 'COST PER BED-NIGHT',
                    value: FinanceLabels.money(report.costPerBedNight ?? 0),
                    note: '${report.bedNights} bed-nights',
                  ),
                  FinanceStatCard(
                    label: 'COST PER RESIDENT',
                    value: FinanceLabels.money(report.costPerResident ?? 0),
                    note:
                        '${(report.averageResidents ?? 0).toStringAsFixed(1)} residents on average',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final r in report.residences) ...[
                FinanceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.residenceName,
                        style: handoverText(context, 14, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Occupancy ${r.occupancyPercent.toStringAsFixed(1)}% / ${r.occupiedBedNights} nights',
                        style: handoverText(context, 12.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Revenue ${FinanceLabels.money(r.revenueTotal)}'
                        '${r.revenueDetail == null ? '' : ' · ${r.revenueDetail}'}',
                      ),
                      Text(
                        'Labor ${FinanceLabels.money(r.payrollExpense)} · '
                        'Inventory ${FinanceLabels.money(r.inventoryExpense)} · '
                        'Other ${FinanceLabels.money(r.otherExpense)}',
                      ),
                      Text(
                        'Net ${FinanceLabels.money(r.netProfit)}'
                        '${r.margin == null ? '' : ' · ${r.margin!.toStringAsFixed(1)}% margin'}',
                        style: handoverText(
                          context,
                          13,
                          weight: FontWeight.w600,
                          color: r.netProfit < 0
                              ? AppColors.criticalRed
                              : AppColors.textHeading,
                        ),
                      ),
                      Text(
                        'Per bed-night ${FinanceLabels.money(r.costPerBedNight)} · '
                        'Per resident ${FinanceLabels.money(r.costPerResident)}',
                        style: handoverText(context, 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                'Figures combine day-rate fees, occupancy, unit costs, and labor costs from pay runs.',
                style: handoverText(context, 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              financeSectionTitle(
                context,
                'Revenue & overheads entered',
                subtitle:
                    'Funding, grants, rent, utilities, maintenance — what no other part of the app records.',
                actions: [
                  if (controller.canWriteFinance)
                    HandoverButton(
                      label: '+ Add entry',
                      compact: true,
                      onPressed: () => _addEntry(context),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (entries.isEmpty)
                FinanceCard(
                  child: Text(
                    'Nothing entered in this period.',
                    style: handoverText(context, 13, color: AppColors.textMuted),
                  ),
                )
              else
                for (final e in entries) ...[
                  FinanceCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${FinanceLabels.statusLabel(e.entryType)} · ${e.category}',
                                style: handoverText(context, 13.5, weight: FontWeight.w600),
                              ),
                              Text(
                                '${e.residenceName ?? 'Residence'} · ${FinanceLabels.money(e.amount)}'
                                '${e.description == null || e.description!.isEmpty ? '' : ' · ${e.description}'}',
                                style: handoverText(context, 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (controller.canWriteFinance)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.criticalRed),
                            onPressed: () async {
                              final err = await controller.deleteLedgerEntry(e.id);
                              if (err != null) {
                                AppSnackbar.show(err, '', force: true);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ],
        ),
      );
    });
  }

  Future<void> _clientCost(BuildContext context) async {
    final clients = controller.clientOptions.toList();
    if (clients.isEmpty) {
      AppSnackbar.show('No residents on the books', '', force: true);
      return;
    }
    final picked = await showFinancePicker<FinancePersonOption>(
      context: context,
      title: 'Resident',
      options: clients,
      labelOf: (c) => c.name,
    );
    if (picked == null || !context.mounted) return;
    final result = await controller.loadClientCost(picked.id);
    if (!context.mounted) return;
    if (result.error != null) {
      AppSnackbar.show(result.error!, '', force: true);
      return;
    }
    final c = result.value!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Client Cost Analysis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.clientName, style: handoverText(ctx, 15, weight: FontWeight.w700)),
            Text(c.residenceName ?? '', style: handoverText(ctx, 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 10),
            Text('Nights ${c.nights}'),
            Text('Cost ${FinanceLabels.money(c.costTotal)}'),
            Text('Revenue ${FinanceLabels.money(c.revenueTotal)}'),
            Text('Variance ${FinanceLabels.money(c.variance)}'),
            Text('Overhead share ${FinanceLabels.money(c.overheadShare)}'),
            if (c.fundingSource != null) Text('Funding ${c.fundingSource}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _addEntry(BuildContext context) async {
    String entryType = 'expense';
    String category = FinanceLabels.expenseCategories.first.$1;
    String? residenceId = controller.residenceOptions.isEmpty
        ? null
        : controller.residenceOptions.first.id;
    final amount = TextEditingController();
    final date = TextEditingController(text: controller.pnlTo.value);
    final description = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final cats = entryType == 'revenue'
                ? FinanceLabels.revenueCategories
                : FinanceLabels.expenseCategories;
            return AlertDialog(
              title: const Text('Add entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: entryType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'expense', child: Text('Expense')),
                        DropdownMenuItem(value: 'revenue', child: Text('Revenue')),
                      ],
                      onChanged: (v) => setState(() {
                        entryType = v ?? entryType;
                        category = (entryType == 'revenue'
                                ? FinanceLabels.revenueCategories
                                : FinanceLabels.expenseCategories)
                            .first
                            .$1;
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      value: cats.any((c) => c.$1 == category) ? category : cats.first.$1,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in cats)
                          DropdownMenuItem(value: c.$1, child: Text(c.$2)),
                      ],
                      onChanged: (v) => setState(() => category = v ?? category),
                    ),
                    DropdownButtonFormField<String>(
                      value: residenceId,
                      decoration: const InputDecoration(labelText: 'Residence'),
                      items: [
                        for (final r in controller.residenceOptions)
                          DropdownMenuItem(value: r.id, child: Text(r.name)),
                      ],
                      onChanged: (v) => setState(() => residenceId = v),
                    ),
                    TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    TextField(
                      controller: date,
                      decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                    ),
                    TextField(
                      controller: description,
                      decoration: const InputDecoration(labelText: 'Description (optional)'),
                    ),
                    if (error != null)
                      Text(error!, style: handoverText(ctx, 12.5, color: AppColors.criticalRed)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    final amt = double.tryParse(amount.text.trim());
                    if (residenceId == null || residenceId!.isEmpty) {
                      setState(() => error = 'Choose a residence');
                      return;
                    }
                    if (amt == null) {
                      setState(() => error = 'Enter an amount');
                      return;
                    }
                    final err = await controller.createLedgerEntry(
                      residenceId: residenceId!,
                      entryType: entryType,
                      category: category,
                      amount: amt,
                      occurredOn: date.text.trim(),
                      description: description.text.trim(),
                    );
                    if (err != null) {
                      setState(() => error = err);
                      return;
                    }
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: const Text('Save entry'),
                ),
              ],
            );
          },
        );
      },
    );
    amount.dispose();
    date.dispose();
    description.dispose();
    if (ok == true && context.mounted) {
      AppSnackbar.show('Entry saved', '', force: true);
    }
  }
}
