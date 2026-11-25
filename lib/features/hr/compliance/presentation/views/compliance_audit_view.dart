import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../controllers/compliance_controller.dart';
import '../widgets/compliance_common.dart';

class ComplianceAuditView extends StatelessWidget {
  final ComplianceController controller;

  const ComplianceAuditView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading =
          controller.isLoading.value && controller.auditLogs.isEmpty;
      return Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: controller.loadAuditLogs,
                    child: controller.auditLogs.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: ComplianceEmpty(
                                  message: 'No audit activity yet.',
                                  icon: Icons.history,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            itemCount: controller.auditLogs.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final log = controller.auditLogs[i];
                              return ComplianceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.action,
                                      style: handoverText(
                                        context,
                                        13.5,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Who: ${log.actorName ?? 'System'}',
                                      style: handoverText(
                                        context,
                                        12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (log.module != null &&
                                        log.module!.isNotEmpty)
                                      Text(
                                        'Origin: ${log.module}',
                                        style: handoverText(
                                          context,
                                          12.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    if (log.entityType != null)
                                      Text(
                                        '${log.entityType}${log.entityId == null ? '' : ' · ${log.entityId}'}',
                                        style: handoverText(
                                          context,
                                          12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    Text(
                                      ComplianceMapper.when(log.createdAt),
                                      style: handoverText(
                                        context,
                                        12,
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
            page: controller.auditPage.value,
            limit: controller.auditLimit.value,
            total: controller.auditTotal.value,
            totalPages: controller.auditTotalPages.value,
            onPage: controller.setAuditPage,
            onLimit: controller.setAuditLimit,
          ),
        ],
      );
    });
  }
}
