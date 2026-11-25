import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../controllers/compliance_controller.dart';
import '../widgets/compliance_common.dart';
import '../widgets/create_action_sheet.dart';

class ComplianceActionsView extends StatelessWidget {
  final ComplianceController controller;

  const ComplianceActionsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value && controller.actions.isEmpty;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Show overdue only'),
                  selected: controller.actionsOverdueOnly.value,
                  onSelected: controller.setActionsOverdueOnly,
                  selectedColor:
                      AppColors.secondaryTeal.withValues(alpha: 0.25),
                ),
                const Spacer(),
                if (controller.canWrite)
                  HandoverButton(
                    label: '+ New action',
                    filled: true,
                    compact: true,
                    onPressed: () =>
                        showCreateActionSheet(context, controller: controller),
                  ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: controller.loadActions,
                    child: controller.actions.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: ComplianceEmpty(
                                  message:
                                      'Nothing outstanding. Actions raised off an incident appear here until they are signed off.',
                                  icon: Icons.build_outlined,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: controller.actions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final a = controller.actions[i];
                              return ComplianceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.description,
                                      style: handoverText(
                                        context,
                                        14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (a.findingTitle != null &&
                                        a.findingTitle!.isNotEmpty)
                                      Text(
                                        a.findingTitle!,
                                        style: handoverText(
                                          context,
                                          12.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    Text(
                                      'Owner: ${a.ownerName ?? '—'}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Due: ${ComplianceMapper.when(a.dueAt)}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Status: ${ComplianceMapper.label(a.status ?? '—')}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      'Signed off: ${a.verifiedAt == null ? 'No' : ComplianceMapper.when(a.verifiedAt)}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (controller.canWrite &&
                                        a.verifiedAt == null) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () async {
                                            final err = await controller
                                                .verifyAction(a.id);
                                            if (!context.mounted) return;
                                            if (err != null) {
                                              AppSnackbar.show(
                                                err,
                                                '',
                                                force: true,
                                              );
                                            } else {
                                              AppSnackbar.show(
                                                'Action signed off',
                                                '',
                                                force: true,
                                              );
                                            }
                                          },
                                          child: const Text('Sign off'),
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
            page: controller.actionsPage.value,
            limit: controller.actionsLimit.value,
            total: controller.actionsTotal.value,
            totalPages: controller.actionsTotalPages.value,
            onPage: controller.setActionsPage,
            onLimit: controller.setActionsLimit,
          ),
        ],
      );
    });
  }
}
