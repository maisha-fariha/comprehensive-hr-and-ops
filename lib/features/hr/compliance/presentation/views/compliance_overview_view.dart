import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../controllers/compliance_controller.dart';
import '../widgets/compliance_common.dart';

class ComplianceOverviewView extends StatelessWidget {
  final ComplianceController controller;
  final VoidCallback onOpenFindings;
  final VoidCallback onOpenActions;
  final VoidCallback onOpenAudit;
  final VoidCallback onOpenChecks;
  final VoidCallback onAddIssue;

  const ComplianceOverviewView({
    super.key,
    required this.controller,
    required this.onOpenFindings,
    required this.onOpenActions,
    required this.onOpenAudit,
    required this.onOpenChecks,
    required this.onAddIssue,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final o = controller.overview.value;
      final loading = controller.isLoading.value;
      if (loading && o == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (o == null) {
        return Center(
          child: Text(
            controller.loadError.value ?? 'Could not load compliance overview.',
            style: handoverText(context, 13, color: AppColors.textMuted),
          ),
        );
      }
      final b = o.breakdown;
      num n(String key) => b[key] ?? 0;
      final weekOpened = o.trend.isEmpty ? 0 : o.trend.last.opened;

      return RefreshIndicator(
        color: AppColors.secondaryTeal,
        onRefresh: controller.refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: onOpenChecks,
                  child: const Text('View Audit Checklist'),
                ),
                TextButton(
                  onPressed: onOpenFindings,
                  child: const Text('View All Issues'),
                ),
                TextButton(
                  onPressed: onOpenAudit,
                  child: const Text('View Full Report'),
                ),
                if (controller.canWrite)
                  TextButton(
                    onPressed: onAddIssue,
                    child: const Text('+ Add Issue'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ComplianceStatChip(
                  label: 'Audit Readiness',
                  value: '${o.score.toStringAsFixed(0)}%',
                  note: ComplianceMapper.readinessTone(o.score),
                  accent: AppColors.activeGreen,
                ),
                ComplianceStatChip(
                  label: 'Expired Documents',
                  value: '${n('expiredDocuments')}',
                  note: n('expiredDocuments') == 0 ? 'Clear' : 'Action',
                ),
                ComplianceStatChip(
                  label: 'Certificates Expiring',
                  value: '${n('expiringCertificates')}',
                  note: n('expiringCertificates') == 0 ? 'Clear' : 'Due soon',
                  accent: AppColors.urgentAmber,
                ),
                ComplianceStatChip(
                  label: 'Refills Needed',
                  value: '${n('medicationRefillNeeded')}',
                  note: n('medicationRefillNeeded') == 0 ? 'Clear' : 'Action',
                ),
                ComplianceStatChip(
                  label: 'Open Corrective Actions',
                  value: '${n('openCorrectiveActions')}',
                  note: n('openCorrectiveActions') == 0 ? 'Clear' : 'Open',
                ),
                ComplianceStatChip(
                  label: 'Overdue Checks',
                  value: '${n('overdueChecks')}',
                  note: n('overdueChecks') == 0 ? 'Clear' : 'Overdue',
                  accent: AppColors.criticalRed,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ComplianceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit Readiness Summary',
                    style: handoverText(context, 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${o.score.toStringAsFixed(0)}% Ready',
                    style: handoverText(context, 22, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  for (final d in o.domains) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            d.domain,
                            style: handoverText(context, 12.5),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (d.percent / 100).clamp(0, 1),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(99),
                            color: AppColors.secondaryTeal,
                            backgroundColor: AppColors.filterButtonBackground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${d.percent.toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton(
                    onPressed: onOpenChecks,
                    child: const Text('View Audit Checklist'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ComplianceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compliance Source Breakdown',
                    style: handoverText(context, 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${o.sources.fold<int>(0, (s, e) => s + e.count)} Total Issues',
                    style: handoverText(context, 16, weight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: onOpenFindings,
                    child: const Text('View All Issues'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ComplianceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Trend (Over Time)',
                    style: handoverText(context, 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$weekOpened raised this week',
                    style: handoverText(context, 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Findings raised each week, over the last six',
                    style: handoverText(context, 12, color: AppColors.textMuted),
                  ),
                  for (final p in o.trend)
                    Text(
                      '${p.weekStart == null ? '—' : ComplianceMapper.ymd(p.weekStart!)} · ${p.opened}',
                      style: handoverText(context, 12.5),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DomainCard(
                  title: 'Staff Compliance',
                  lines: [
                    'Certificates expiring within a month: ${n('expiringCertificates')}',
                    'Training not finished: ${n('incompleteTraining')}',
                  ],
                ),
                _DomainCard(
                  title: 'Client File Completeness',
                  lines: [
                    'Residents on the books: ${o.clientFiles.residents}',
                    'No care plan on file: ${o.clientFiles.missingCarePlan}',
                    'Not placed in a room: ${o.clientFiles.missingRoom}',
                  ],
                ),
                _DomainCard(
                  title: 'Incident Follow-up',
                  lines: [
                    'Open incidents: ${n('openIncidents')}',
                    'Nobody investigating: ${n('incidentsWithoutInvestigation')}',
                    'Corrective actions overdue: ${n('overdueCorrectiveActions')}',
                  ],
                ),
                _DomainCard(
                  title: 'Medication Compliance',
                  lines: [
                    'Doses missed this week: ${o.medication.missed}',
                    'Refused this week: ${o.medication.refused}',
                    'Medications needing a refill: ${n('medicationRefillNeeded')}',
                  ],
                ),
                _DomainCard(
                  title: 'Policy & Document Compliance',
                  lines: [
                    'Expired documents: ${n('expiredDocuments')}',
                    'Expiring within a month: ${n('expiringDocuments')}',
                    'Checks overdue: ${n('overdueChecks')}',
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            complianceSectionTitle(
              context,
              'Compliance Issues Queue',
              actions: [
                TextButton(
                  onPressed: onOpenFindings,
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controller.findings.isEmpty)
              const ComplianceEmpty(message: 'No results found')
            else
              for (final f in controller.findings.take(5)) ...[
                ComplianceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: handoverText(context, 14, weight: FontWeight.w700),
                      ),
                      Text(
                        '${f.residenceName ?? '—'} · ${ComplianceMapper.label(f.severity ?? '')}',
                        style: handoverText(
                          context,
                          12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 12),
            complianceSectionTitle(
              context,
              'Corrective Actions',
              actions: [
                TextButton(
                  onPressed: onOpenActions,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controller.actions.isEmpty)
              const ComplianceEmpty(
                message: 'Nothing outstanding.',
                icon: Icons.build_outlined,
              )
            else
              for (final a in controller.actions.take(3)) ...[
                ComplianceCard(child: Text(a.description)),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 12),
            ComplianceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Audits / Inspections',
                    style: handoverText(context, 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    o.upcoming.isEmpty
                        ? 'Nothing falls due in the next month.'
                        : '${o.upcoming.length} upcoming',
                    style: handoverText(context, 13, color: AppColors.textMuted),
                  ),
                  for (final u in o.upcoming.take(3))
                    Text(
                      '${u.title} · ${ComplianceMapper.when(u.dueAt)}',
                      style: handoverText(context, 12.5),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ComplianceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports & Exports',
                    style: handoverText(context, 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.exports.isEmpty
                        ? 'No exports have been run yet.'
                        : 'Last: ${ComplianceMapper.label(controller.exports.first.status)}',
                    style: handoverText(context, 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            complianceSectionTitle(
              context,
              'Recent Activity / Audit Log',
              actions: [
                TextButton(
                  onPressed: onOpenAudit,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final log in controller.auditLogs.take(6)) ...[
              ComplianceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.action,
                      style: handoverText(context, 13, weight: FontWeight.w600),
                    ),
                    Text(
                      '${log.actorName ?? 'System'} · ${ComplianceMapper.when(log.createdAt)}',
                      style: handoverText(
                        context,
                        12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    });
  }
}

class _DomainCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _DomainCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ComplianceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: handoverText(context, 13.5, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
