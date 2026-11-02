import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/finance_mapper.dart';
import '../../domain/entities/finance.dart';
import '../controllers/finance_controller.dart';
import '../widgets/finance_common.dart';

class FinanceSinBankingView extends StatelessWidget {
  final FinanceController controller;

  const FinanceSinBankingView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.canReadPii) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "You don't have permission to view SIN & banking.",
              textAlign: TextAlign.center,
              style: handoverText(context, 14, color: AppColors.textMuted),
            ),
          ),
        );
      }

      final staff = controller.staffOptions.toList();
      final selectedId = controller.sensitiveStaffId.value;
      final info = controller.sensitive.value;
      final engine = controller.engine.value;

      FinancePersonOption? selected;
      for (final s in staff) {
        if (s.id == selectedId) {
          selected = s;
          break;
        }
      }

      return RefreshIndicator(
        color: AppColors.secondaryTeal,
        onRefresh: () async {
          if (selectedId.isNotEmpty) {
            await controller.loadSensitive(selectedId);
          } else {
            await controller.refreshAll();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            financeSectionTitle(
              context,
              'SIN & Banking',
              subtitle:
                  'Personal information under PIPEDA. Encrypted at rest; every reveal and change is recorded in the audit log.',
            ),
            const SizedBox(height: 14),
            Text('Employee', style: handoverText(context, 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                if (staff.isEmpty) return;
                final picked = await showFinancePicker<FinancePersonOption>(
                  context: context,
                  title: 'Employee',
                  options: staff,
                  labelOf: (s) => s.name,
                  selected: selected,
                );
                if (picked != null) await controller.loadSensitive(picked.id);
              },
              child: FinanceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selected?.name ?? 'Choose employee',
                        style: handoverText(context, 14, weight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (info == null && controller.isLoading.value)
              const Center(child: CircularProgressIndicator())
            else if (info != null) ...[
              FinanceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIN & Banking',
                      style: handoverText(context, 15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personal information under PIPEDA. Encrypted at rest; every reveal and change is recorded in the audit log.',
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _Field(
                          label: 'Social Insurance Number',
                          value: info.sinValue ??
                              info.sinMasked ??
                              (info.sinOnFile ? '•••' : 'Not on file'),
                          muted: !info.sinOnFile,
                        ),
                        _Field(
                          label: 'Institution',
                          value: info.institutionNumber ??
                              (info.bankingOnFile ? '•••' : 'Not on file'),
                          muted: !info.bankingOnFile,
                        ),
                        _Field(
                          label: 'Transit',
                          value: info.transitNumber ??
                              (info.bankingOnFile ? '•••••' : 'Not on file'),
                          muted: !info.bankingOnFile,
                        ),
                        _Field(
                          label: 'Account',
                          value: info.accountNumber ??
                              info.accountMasked ??
                              (info.bankingOnFile ? '••••' : 'Not on file'),
                          muted: !info.bankingOnFile,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (info.sinOnFile || info.bankingOnFile)
                          HandoverButton(
                            label: info.revealed || info.sinValue != null
                                ? 'Hide'
                                : 'Reveal',
                            compact: true,
                            onPressed: () async {
                              if (info.revealed || info.sinValue != null) {
                                await controller.loadSensitive(selectedId);
                                return;
                              }
                              final err = await controller.revealSensitive();
                              if (err != null) {
                                AppSnackbar.show(err, '', force: true);
                              }
                            },
                          ),
                        if (controller.canWritePii)
                          HandoverButton(
                            label: 'Edit',
                            compact: true,
                            onPressed: () => _edit(context, info),
                          ),
                        Text(
                          'Viewing the full numbers is logged.',
                          style: handoverText(context, 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (engine != null && !engine.runHere)
                Text(
                  'Direct deposit: ${engine.provider.isEmpty ? 'QuickBooks Online' : FinanceLabels.statusLabel(engine.provider)} runs this organisation\'s payroll — pay, deductions, payslips and paying staff happen there. This platform sends it the hours.',
                  style: handoverText(context, 12.5, color: AppColors.criticalRed),
                ),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _edit(BuildContext context, StaffSensitiveInfo info) async {
    final sin = TextEditingController();
    final institution = TextEditingController();
    final transit = TextEditingController();
    final account = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit SIN & Banking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sin,
                  decoration: InputDecoration(
                    labelText: 'New SIN',
                    hintText: info.sinOnFile
                        ? 'Leave blank to keep the one on file'
                        : '123 456 789',
                  ),
                ),
                TextField(
                  controller: institution,
                  decoration: const InputDecoration(labelText: 'Institution #'),
                ),
                TextField(
                  controller: transit,
                  decoration: const InputDecoration(labelText: 'Transit #'),
                ),
                TextField(
                  controller: account,
                  decoration: const InputDecoration(labelText: 'Account #'),
                ),
                if (error != null)
                  Text(error!, style: handoverText(ctx, 12.5, color: AppColors.criticalRed)),
              ],
            ),
          ),
          actions: [
            if (info.sinOnFile)
              TextButton(
                onPressed: () async {
                  final err = await controller.saveSensitive(clearSin: true);
                  if (err != null) {
                    setState(() => error = err);
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Remove SIN'),
              ),
            if (info.bankingOnFile)
              TextButton(
                onPressed: () async {
                  final err = await controller.saveSensitive(clearBanking: true);
                  if (err != null) {
                    setState(() => error = err);
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Remove banking'),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final bodySin = sin.text.trim();
                final inst = institution.text.trim();
                final tr = transit.text.trim();
                final ac = account.text.trim();
                final anyBank = [inst, tr, ac].any((e) => e.isNotEmpty);
                Map<String, String>? banking;
                if (anyBank) {
                  if (![inst, tr, ac].every((e) => e.isNotEmpty)) {
                    setState(() => error =
                        'Banking needs all three: institution, transit and account number.');
                    return;
                  }
                  banking = {
                    'institutionNumber': inst,
                    'transitNumber': tr,
                    'accountNumber': ac,
                  };
                }
                if (bodySin.isEmpty && banking == null) {
                  setState(() => error =
                      'Type a new SIN or new banking details — blank boxes keep what is on file.');
                  return;
                }
                final err = await controller.saveSensitive(
                  sin: bodySin.isEmpty ? null : bodySin,
                  banking: banking,
                );
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    sin.dispose();
    institution.dispose();
    transit.dispose();
    account.dispose();
    if (ok == true && context.mounted) {
      AppSnackbar.show('Saved', '', force: true);
    }
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;

  const _Field({
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: handoverText(context, 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: handoverText(
              context,
              13.5,
              weight: FontWeight.w600,
              color: muted ? AppColors.textMuted : AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}
