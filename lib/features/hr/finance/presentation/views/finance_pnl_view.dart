import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
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
      final canExport = report != null && report.residences.isNotEmpty;
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
                  child: _DateField(
                    label: 'From',
                    value: controller.pnlFrom.value,
                    onPicked: (ymd) => controller.setPnlRange(
                      from: ymd,
                      to: controller.pnlTo.value,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateField(
                    label: 'To',
                    value: controller.pnlTo.value,
                    onPicked: (ymd) => controller.setPnlRange(
                      from: controller.pnlFrom.value,
                      to: ymd,
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
                  icon: Icons.download_rounded,
                  onPressed: canExport ? () => _exportCsv(context) : null,
                ),
                HandoverButton(
                  label: 'Client Cost Analysis',
                  compact: true,
                  icon: Icons.person_outline_rounded,
                  onPressed: () => _openClientCost(context),
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
                    note:
                        '${FinanceLabels.money(report.revenueTotal)} from day rates',
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

  Future<void> _exportCsv(BuildContext context) async {
    final csv = controller.pnlCsv();
    if (csv.isEmpty) {
      AppSnackbar.show('Nothing to export', '', force: true);
      return;
    }
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final saved = await MediaStoreDownload.saveFileAndOpen(
      fileName: controller.pnlExportFileName(),
      bytes: bytes,
      mimeType: 'text/csv',
      chooserTitle: 'Open P&L export',
    );
    if (!context.mounted) return;
    if (saved.success) {
      AppSnackbar.show(
        saved.locationLabel == null
            ? 'P&L CSV exported'
            : 'P&L CSV saved to ${saved.locationLabel}',
        '',
        force: true,
      );
    } else {
      AppSnackbar.show(
        saved.error ?? 'Could not save the export.',
        '',
        force: true,
      );
    }
  }

  Future<void> _openClientCost(BuildContext context) async {
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientCostSheet(controller: controller),
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
                      initialValue: entryType,
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
                      initialValue:
                          cats.any((c) => c.$1 == category) ? category : cats.first.$1,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in cats)
                          DropdownMenuItem(value: c.$1, child: Text(c.$2)),
                      ],
                      onChanged: (v) => setState(() => category = v ?? category),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: residenceId,
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

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onPicked;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final parts = value.split('-');
        var initial = DateTime.now();
        if (parts.length == 3) {
          initial = DateTime(
            int.tryParse(parts[0]) ?? initial.year,
            int.tryParse(parts[1]) ?? initial.month,
            int.tryParse(parts[2]) ?? initial.day,
          );
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPicked(FinanceLabels.ymd(picked));
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value, style: handoverText(context, 13.5)),
      ),
    );
  }
}

class _ClientCostSheet extends StatefulWidget {
  final FinanceController controller;

  const _ClientCostSheet({required this.controller});

  @override
  State<_ClientCostSheet> createState() => _ClientCostSheetState();
}

class _ClientCostSheetState extends State<_ClientCostSheet> {
  List<FinancePersonOption> _clients = const [];
  FinancePersonOption? _selected;
  ClientCostSummary? _summary;
  String? _error;
  var _loadingClients = true;
  var _loadingCost = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final clients = await widget.controller.clientsForCostAnalysis();
    if (!mounted) return;
    setState(() {
      _clients = clients;
      _loadingClients = false;
    });
  }

  Future<void> _pickResident() async {
    if (_clients.isEmpty) return;
    final picked = await showFinancePicker<FinancePersonOption>(
      context: context,
      title: 'Resident',
      options: _clients,
      labelOf: (c) => c.name,
      selected: _selected,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selected = picked;
      _summary = null;
      _error = null;
      _loadingCost = true;
    });
    final result = await widget.controller.loadClientCost(picked.id);
    if (!mounted) return;
    setState(() {
      _loadingCost = false;
      if (result.error != null) {
        _error = result.error;
        _summary = null;
      } else {
        _summary = result.value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.secondaryTeal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Cost Analysis',
                        style: handoverText(context, 16, weight: FontWeight.w700),
                      ),
                      Text(
                        "One resident's cost of care against their funding, for this period.",
                        style: handoverText(context, 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Text(
                  'Period ${widget.controller.pnlFrom.value} → ${widget.controller.pnlTo.value}',
                  style: handoverText(context, 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Text('Resident', style: handoverText(context, 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _loadingClients ? null : _pickResident,
                  borderRadius: BorderRadius.circular(10),
                  child: FinanceCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _loadingClients
                                ? 'Loading residents…'
                                : (_selected?.name ?? 'Choose a resident'),
                            style: handoverText(
                              context,
                              14,
                              weight: FontWeight.w600,
                              color: _selected == null
                                  ? AppColors.textMuted
                                  : AppColors.textHeading,
                            ),
                          ),
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selected == null)
                  Text(
                    widget.controller.canReadFinance
                        ? 'Choose a resident to see their cost of care.'
                        : "You don't have permission to view finance figures.",
                    textAlign: TextAlign.center,
                    style: handoverText(context, 13, color: AppColors.textMuted),
                  )
                else if (_loadingCost)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  FinanceCard(
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          "Couldn't load this resident's cost",
                          style: handoverText(context, 13.5, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: handoverText(context, 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                else if (_summary != null)
                  _ClientCostResult(summary: _summary!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCostResult extends StatelessWidget {
  final ClientCostSummary summary;

  const _ClientCostResult({required this.summary});

  @override
  Widget build(BuildContext context) {
    final overheadLabel = summary.overheadResidenceNames.length > 1
        ? 'Share of home overhead (${summary.overheadResidenceNames.join(', ')})'
        : 'Share of home overhead';
    final notes = <String>[
      if (summary.unpricedDoses > 0)
        '${summary.unpricedDoses} of ${summary.dosesGiven} doses given are of medicines with no cost per dose, so they aren\'t in direct supplies.',
      if (summary.unpricedOneToOneHours > 0)
        '${summary.unpricedOneToOneHours} one-to-one hours were worked by salaried staff or staff with no rate on file; their pay stays in the home\'s overhead.',
    ];
    final billBits = [
      if (summary.billToName != null) summary.billToName!,
      if (summary.fundingSource != null) summary.fundingSource!,
      if (summary.beneficiary != null) 'for ${summary.beneficiary}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          summary.clientName,
          style: handoverText(context, 15, weight: FontWeight.w700),
        ),
        if (summary.residenceName != null)
          Text(
            summary.residenceName!,
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
        const SizedBox(height: 12),
        FinanceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cost of care · ${summary.nights} night${summary.nights == 1 ? '' : 's'}',
                style: handoverText(context, 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              _row(
                context,
                'Direct supplies (${summary.dosesGiven} dose${summary.dosesGiven == 1 ? '' : 's'} given)',
                FinanceLabels.money(summary.directSupplies),
              ),
              _row(
                context,
                '1:1 care (${summary.oneToOneHours} h)',
                FinanceLabels.money(summary.oneToOneCare),
              ),
              _row(context, overheadLabel, FinanceLabels.money(summary.overheadShare)),
              _row(
                context,
                'Total cost',
                FinanceLabels.money(summary.costTotal),
                bold: true,
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final note in notes)
                  Text(note, style: handoverText(context, 12, color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        FinanceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Funding received',
                style: handoverText(context, 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              _row(
                context,
                'Day rate',
                summary.dailyRate == null
                    ? 'Not set'
                    : FinanceLabels.money(summary.dailyRate),
              ),
              _row(
                context,
                'Accrued day-rate fees',
                FinanceLabels.money(summary.accruedFees),
              ),
              if (billBits.isNotEmpty)
                _row(context, 'Bill to', billBits.join(' · ')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (summary.fundingKnown)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: (summary.costExceedsFunding == true
                      ? AppColors.criticalRed
                      : AppColors.secondaryTeal)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summary.costExceedsFunding == true
                        ? 'Shortfall — costing more than funding covers'
                        : 'Surplus — within funding',
                    style: handoverText(
                      context,
                      13,
                      weight: FontWeight.w600,
                      color: summary.costExceedsFunding == true
                          ? AppColors.criticalRed
                          : AppColors.secondaryTeal,
                    ),
                  ),
                ),
                Text(
                  FinanceLabels.money(summary.variance.abs()),
                  style: handoverText(
                    context,
                    14,
                    weight: FontWeight.w700,
                    color: summary.costExceedsFunding == true
                        ? AppColors.criticalRed
                        : AppColors.secondaryTeal,
                  ),
                ),
              ],
            ),
          )
        else
          FinanceCard(
            child: Text(
              "No day rate is recorded for this resident, so their cost can't be compared with their funding. Set one on the resident's profile.",
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: handoverText(context, 12.5, color: AppColors.textMuted)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: handoverText(
              context,
              13,
              weight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
