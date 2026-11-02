import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../controllers/compliance_controller.dart';
import '../widgets/compliance_common.dart';
import '../widgets/create_check_sheet.dart';

class ComplianceChecksView extends StatelessWidget {
  final ComplianceController controller;

  const ComplianceChecksView({super.key, required this.controller});

  int _summaryInt(String key) {
    final v = controller.checksSummary[key];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value && controller.checks.isEmpty;
      final outstanding = _summaryInt('outstanding');
      final overdue = _summaryInt('overdue');
      final failing = _summaryInt('failing');
      final awaiting = _summaryInt('awaitingReview');

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ComplianceStatChip(
                  label: 'OUTSTANDING',
                  value: '$outstanding',
                  note: 'Nobody has done them.',
                ),
                ComplianceStatChip(
                  label: 'OVERDUE',
                  value: '$overdue',
                  note: 'Past their date.',
                  accent: AppColors.criticalRed,
                ),
                ComplianceStatChip(
                  label: 'FAILING',
                  value: '$failing',
                  note: 'Something to put right.',
                  accent: AppColors.urgentAmber,
                ),
                ComplianceStatChip(
                  label: 'AWAITING REVIEW',
                  value: '$awaiting',
                  note: 'Done, not signed off.',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in const [
                          ('all', 'All'),
                          ('outstanding', 'Outstanding'),
                          ('overdue', 'Overdue'),
                        ]) ...[
                          FilterChip(
                            label: Text(f.$2),
                            selected: controller.checkFilter.value == f.$1,
                            onSelected: (_) => controller.setCheckFilter(f.$1),
                            selectedColor:
                            AppColors.secondaryTeal.withValues(alpha: 0.25),
                            checkmarkColor: AppColors.secondaryTeal,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                if (controller.canWrite)
                  TextButton(
                    onPressed: () =>
                        showCreateCheckSheet(context, controller: controller),
                    child: const Text('+ Raise a check'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: controller.loadChecks,
                    child: controller.checks.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: ComplianceEmpty(
                                  message: 'No checks raised yet.',
                                  icon: Icons.assignment_outlined,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: controller.checks.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final c = controller.checks[i];
                              return ComplianceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.requirementName ?? 'Check',
                                      style: handoverText(
                                        context,
                                        14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Residence: ${c.residenceName ?? '—'}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Due: ${ComplianceMapper.when(c.dueAt)}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Result: ${ComplianceMapper.label(c.result ?? '—')}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Issue raised: ${c.findingId == null ? 'No' : (c.findingTitle ?? 'Yes')}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Signed off: ${c.reviewedAt == null ? 'No' : ComplianceMapper.when(c.reviewedAt)}',
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
            page: controller.checksPage.value,
            limit: controller.checksLimit.value,
            total: controller.checksTotal.value,
            totalPages: controller.checksTotalPages.value,
            onPage: controller.setChecksPage,
            onLimit: controller.setChecksLimit,
          ),
        ],
      );
    });
  }
}
