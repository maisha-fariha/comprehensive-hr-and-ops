import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../controllers/compliance_controller.dart';
import '../widgets/compliance_common.dart';
import '../widgets/create_requirement_sheet.dart';

class ComplianceRequirementsView extends StatelessWidget {
  final ComplianceController controller;

  const ComplianceRequirementsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading =
          controller.isLoading.value && controller.requirements.isEmpty;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => controller.setShowArchived(
                    !controller.showArchivedRequirements.value,
                  ),
                  child: Text(
                    controller.showArchivedRequirements.value
                        ? 'HIDE ARCHIVED RULES'
                        : 'SHOW ARCHIVED RULES',
                  ),
                ),
                const Spacer(),
                if (controller.canWrite)
                  HandoverButton(
                    label: '+ Add requirement',
                    filled: true,
                    compact: true,
                    onPressed: () =>
                        showCreateRequirementSheet(context, controller: controller),
                  ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: controller.loadRequirements,
                    child: controller.requirements.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: ComplianceEmpty(
                                  message:
                                      'No requirements yet. Add what this provider is held to, and checks can be raised against it.',
                                  icon: Icons.assignment_outlined,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: controller.requirements.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final r = controller.requirements[i];
                              return ComplianceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            r.name,
                                            style: handoverText(
                                              context,
                                              14,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (!r.isActive)
                                          const ComplianceStatusPill('archived'),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'How often: ${ComplianceMapper.label(r.frequency)}'
                                      '${r.frequencyNote == null || r.frequencyNote!.isEmpty ? '' : ' · ${r.frequencyNote}'}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Priority: ${ComplianceMapper.label(r.priority)}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (r.category != null &&
                                        r.category!.isNotEmpty)
                                      Text(
                                        'Applies to: ${ComplianceMapper.label(r.category!)}',
                                        style: handoverText(
                                          context,
                                          12.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    Text(
                                      'Evidence: ${r.evidenceRequired ? 'Required' : 'Optional'}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (controller.canWrite) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () async {
                                            final err = r.isActive
                                                ? await controller
                                                    .archiveRequirement(r.id)
                                                : await controller
                                                    .restoreRequirement(r.id);
                                            if (!context.mounted) return;
                                            if (err != null) {
                                              AppSnackbar.show(
                                                err,
                                                '',
                                                force: true,
                                              );
                                            }
                                          },
                                          child: Text(
                                            r.isActive ? 'Archive' : 'Restore',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
          compliancePagination(
            page: controller.requirementsPage.value,
            limit: controller.requirementsLimit.value,
            total: controller.requirementsTotal.value,
            totalPages: controller.requirementsTotalPages.value,
            onPage: controller.setRequirementsPage,
            onLimit: controller.setRequirementsLimit,
          ),
        ],
      );
    });
  }
}
