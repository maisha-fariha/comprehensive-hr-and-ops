import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../documents/presentation/pages/hr_documents_page.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../controllers/compliance_controller.dart';
import '../views/compliance_actions_view.dart';
import '../views/compliance_alerts_view.dart';
import '../views/compliance_audit_view.dart';
import '../views/compliance_checks_view.dart';
import '../views/compliance_findings_view.dart';
import '../views/compliance_overview_view.dart';
import '../views/compliance_requirements_view.dart';
import '../widgets/create_finding_sheet.dart';

/// Web `/dashboard/compliance` — Compliance & Audit.
class CompliancePage extends StatefulWidget {
  final ComplianceTab initialTab;

  const CompliancePage({super.key, this.initialTab = ComplianceTab.overview});

  @override
  State<CompliancePage> createState() => _CompliancePageState();
}

class _CompliancePageState extends State<CompliancePage> {
  late final ComplianceController _controller;
  late ComplianceTab _tab;

  static const _tabs = <(ComplianceTab, String)>[
    (ComplianceTab.overview, 'Overview'),
    (ComplianceTab.requirements, 'Requirements'),
    (ComplianceTab.checks, 'Checks'),
    (ComplianceTab.findings, 'Findings'),
    (ComplianceTab.actions, 'Corrective actions'),
    (ComplianceTab.alerts, 'What is pulling the score down'),
    (ComplianceTab.audit, 'Audit log'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(GetIt.instance<ComplianceController>());
    _tab = widget.initialTab;
  }

  @override
  void dispose() {
    Get.delete<ComplianceController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
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
                            'Compliance & Audit',
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Obx(() {
                      final at = _controller.overview.value?.computedAt;
                      return Text(
                        at == null
                            ? 'No standards set — add them in Settings'
                            : 'Live as of ${ComplianceMapper.when(at)} · '
                                'No standards set — add them in Settings',
                        style: handoverText(
                          context,
                          12,
                          color: AppColors.textMuted,
                        ),
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_controller.canUploadDocs)
                          HandoverButton(
                            label: 'Upload Document',
                            compact: true,
                            icon: Icons.upload_file_outlined,
                            onPressed: () => Get.to(() => const HrDocumentsPage()),
                          ),
                        if (_controller.canWrite)
                          HandoverButton(
                            label: '+ Add Issue',
                            filled: true,
                            compact: true,
                            onPressed: () => showCreateFindingSheet(
                              context,
                              controller: _controller,
                            ),
                          ),
                        if (_controller.canExport)
                          HandoverButton(
                            label: 'Export Report',
                            compact: true,
                            icon: Icons.download_outlined,
                            onPressed: () async {
                              final err = await _controller.exportReport();
                              if (!context.mounted) return;
                              if (err != null) {
                                AppSnackbar.show(err, '', force: true);
                              } else {
                                AppSnackbar.show(
                                  'Export queued — it appears under Reports & Exports when ready',
                                  '',
                                  force: true,
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        for (final t in _tabs) ...[
                          _TabChip(
                            label: t.$2,
                            selected: _tab == t.$1,
                            onTap: () => setState(() => _tab = t.$1),
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
            child: switch (_tab) {
              ComplianceTab.overview => ComplianceOverviewView(
                  controller: _controller,
                  onOpenFindings: () =>
                      setState(() => _tab = ComplianceTab.findings),
                  onOpenActions: () =>
                      setState(() => _tab = ComplianceTab.actions),
                  onOpenAudit: () => setState(() => _tab = ComplianceTab.audit),
                  onOpenChecks: () =>
                      setState(() => _tab = ComplianceTab.checks),
                  onAddIssue: () => showCreateFindingSheet(
                    context,
                    controller: _controller,
                  ),
                ),
              ComplianceTab.requirements =>
                ComplianceRequirementsView(controller: _controller),
              ComplianceTab.checks =>
                ComplianceChecksView(controller: _controller),
              ComplianceTab.findings => ComplianceFindingsView(
                  controller: _controller,
                  onAddIssue: () => showCreateFindingSheet(
                    context,
                    controller: _controller,
                  ),
                ),
              ComplianceTab.actions =>
                ComplianceActionsView(controller: _controller),
              ComplianceTab.alerts =>
                ComplianceAlertsView(controller: _controller),
              ComplianceTab.audit =>
                ComplianceAuditView(controller: _controller),
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
