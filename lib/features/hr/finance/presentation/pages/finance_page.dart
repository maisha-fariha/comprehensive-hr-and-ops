import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../controllers/finance_controller.dart';
import '../views/finance_addons_view.dart';
import '../views/finance_claims_view.dart';
import '../views/finance_overview_view.dart';
import '../views/finance_pnl_view.dart';
import '../views/finance_runs_view.dart';
import '../views/finance_sin_banking_view.dart';

enum FinanceTab { overview, runs, pnl, claims, addons, sinBanking }

/// Web `/dashboard/finance` — Finance & Payroll (Billing tab omitted).
class FinancePage extends StatefulWidget {
  final FinanceTab initialTab;

  const FinancePage({super.key, this.initialTab = FinanceTab.overview});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late final UserSession _session;
  late final FinanceController _controller;
  late FinanceTab? _tab;

  List<(FinanceTab, String, bool Function())> get _defs => [
        (
          FinanceTab.overview,
          'Overview',
          () => _session.can('payroll:read'),
        ),
        (
          FinanceTab.runs,
          'Payroll runs',
          () => _session.can('payroll:read'),
        ),
        (
          FinanceTab.pnl,
          'Residence P&L',
          () => _session.can('finance:read'),
        ),
        (
          FinanceTab.claims,
          'Claims',
          () => _session.can('payroll:read'),
        ),
        (
          FinanceTab.addons,
          'Add-ons',
          () => _session.can('payroll:read') || _session.can('finance:read'),
        ),
        (
          FinanceTab.sinBanking,
          'SIN & Banking',
          () => _session.can('staff:pii:read'),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _session = Get.find<UserSession>();
    _controller = Get.put(GetIt.instance<FinanceController>());
    final allowed = [for (final d in _defs) if (d.$3()) d.$1];
    _tab = allowed.contains(widget.initialTab)
        ? widget.initialTab
        : (allowed.isEmpty ? null : allowed.first);
  }

  @override
  void dispose() {
    Get.delete<FinanceController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [for (final d in _defs) if (d.$3()) d];
    final tab = _tab;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textHeading,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Finance & Payroll',
                            style: handoverText(
                              context,
                              18,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: _controller.refreshAll,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                  ),
                  if (tabs.length > 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          for (final d in tabs) ...[
                            _TabChip(
                              label: d.$2,
                              selected: tab == d.$1,
                              onTap: () => setState(() => _tab = d.$1),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: tab == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "You don't have permission to view finance figures.",
                        textAlign: TextAlign.center,
                        style: handoverText(
                          context,
                          14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  )
                : switch (tab) {
                    FinanceTab.overview => FinanceOverviewView(
                        controller: _controller,
                        onOpenRuns: () => setState(() => _tab = FinanceTab.runs),
                        onOpenClaims: () =>
                            setState(() => _tab = FinanceTab.claims),
                      ),
                    FinanceTab.runs =>
                      FinanceRunsView(controller: _controller),
                    FinanceTab.pnl => FinancePnlView(controller: _controller),
                    FinanceTab.claims =>
                      FinanceClaimsView(controller: _controller),
                    FinanceTab.addons =>
                      FinanceAddonsView(controller: _controller),
                    FinanceTab.sinBanking =>
                      FinanceSinBankingView(controller: _controller),
                  },
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: handoverText(
              context,
              13,
              weight: FontWeight.w600,
              color: selected ? AppColors.surfaceWhite : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}
