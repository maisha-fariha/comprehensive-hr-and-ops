import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../controllers/compliance_controller.dart';
import '../widgets/compliance_common.dart';

class ComplianceFindingsView extends StatefulWidget {
  final ComplianceController controller;
  final VoidCallback? onAddIssue;

  const ComplianceFindingsView({
    super.key,
    required this.controller,
    this.onAddIssue,
  });

  @override
  State<ComplianceFindingsView> createState() => _ComplianceFindingsViewState();
}

class _ComplianceFindingsViewState extends State<ComplianceFindingsView> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.controller.applyFindingsFilters(search: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Obx(() {
      final loading =
          controller.isLoading.value && controller.findings.isEmpty;
      final status =
          controller.findingsStatus.value.isEmpty
              ? 'all'
              : controller.findingsStatus.value;
      final severity =
          controller.findingsSeverity.value.isEmpty
              ? 'all'
              : controller.findingsSeverity.value;
      final source =
          controller.findingsSource.value.isEmpty
              ? 'all'
              : controller.findingsSource.value;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliance Issues Queue',
                  style: handoverText(context, 15, weight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search issues...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All statuses'),
                        ),
                        DropdownMenuItem(value: 'open', child: Text('Open')),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('In progress'),
                        ),
                        DropdownMenuItem(
                          value: 'resolved',
                          child: Text('Resolved'),
                        ),
                        DropdownMenuItem(
                          value: 'closed',
                          child: Text('Closed'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        controller.applyFindingsFilters(
                          status: v == 'all' ? '' : v,
                        );
                      },
                    ),
                    DropdownButton<String>(
                      value: severity,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All severities'),
                        ),
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(
                          value: 'critical',
                          child: Text('Critical'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        controller.applyFindingsFilters(
                          severity: v == 'all' ? '' : v,
                        );
                      },
                    ),
                    DropdownButton<String>(
                      value: source,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All sources'),
                        ),
                        DropdownMenuItem(
                          value: 'internal_audit',
                          child: Text('Internal audit'),
                        ),
                        DropdownMenuItem(
                          value: 'compliance_check',
                          child: Text('Compliance check'),
                        ),
                        DropdownMenuItem(
                          value: 'automated_alert',
                          child: Text('Automated alert'),
                        ),
                        DropdownMenuItem(
                          value: 'staff_report',
                          child: Text('Staff report'),
                        ),
                        DropdownMenuItem(
                          value: 'regulatory_inspection',
                          child: Text('Regulatory inspection'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        controller.applyFindingsFilters(
                          source: v == 'all' ? '' : v,
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        _search.clear();
                        controller.clearFindingsFilters();
                      },
                      child: const Text('Clear filters'),
                    ),
                    if (controller.canWrite && widget.onAddIssue != null)
                      HandoverButton(
                        label: '+ Add Issue',
                        filled: true,
                        compact: true,
                        onPressed: widget.onAddIssue,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: controller.loadFindings,
                    child: controller.findings.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: ComplianceEmpty(
                                  message: 'No results found',
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: controller.findings.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final f = controller.findings[i];
                              return ComplianceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.title,
                                      style: handoverText(
                                        context,
                                        14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Source: ${ComplianceMapper.label(f.issueOrigin ?? f.sourceRecordType ?? '—')}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Residence / Person: ${f.residenceName ?? '—'}'
                                      '${f.clientName == null || f.clientName!.isEmpty ? '' : ' · ${f.clientName}'}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Severity: ',
                                          style: handoverText(
                                            context,
                                            12.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        if (f.severity != null)
                                          ComplianceStatusPill(f.severity!)
                                        else
                                          Text(
                                            '—',
                                            style: handoverText(
                                              context,
                                              12.5,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      'Due: ${ComplianceMapper.when(f.dueAt)}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Assigned: ${f.assigneeName ?? '—'}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Status: ${ComplianceMapper.label(f.status ?? '—')}',
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
          ),
          compliancePagination(
            page: controller.findingsPage.value,
            limit: controller.findingsLimit.value,
            total: controller.findingsTotal.value,
            totalPages: controller.findingsTotalPages.value,
            onPage: controller.setFindingsPage,
            onLimit: controller.setFindingsLimit,
          ),
        ],
      );
    });
  }
}
