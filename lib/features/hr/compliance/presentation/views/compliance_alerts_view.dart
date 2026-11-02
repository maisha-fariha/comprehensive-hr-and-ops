import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../controllers/compliance_controller.dart';
import '../widgets/compliance_common.dart';

class ComplianceAlertsView extends StatelessWidget {
  final ComplianceController controller;

  const ComplianceAlertsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value && controller.alerts.isEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Each of these is a live record, not a stored alert — clearing the record clears the alert and moves the score.',
              style: handoverText(context, 13, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: controller.loadAlerts,
                    child: controller.alerts.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: ComplianceEmpty(
                                  message: 'Nothing outstanding',
                                  icon: Icons.trending_down,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            itemCount: controller.alerts.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final a = controller.alerts[i];
                              return ComplianceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a.title,
                                            style: handoverText(
                                              context,
                                              14,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (a.severity != null)
                                          ComplianceStatusPill(a.severity!),
                                      ],
                                    ),
                                    if (a.kind != null && a.kind!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        ComplianceMapper.label(a.kind!),
                                        style: handoverText(
                                          context,
                                          12.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                    if (a.detail != null &&
                                        a.detail!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        a.detail!,
                                        style: handoverText(
                                          context,
                                          12.5,
                                          color: AppColors.textMuted,
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
        ],
      );
    });
  }
}
