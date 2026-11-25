import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../controllers/ai_alerts_controller.dart';
import '../widgets/ai_report_detail_body.dart';

/// Phone layout — full-screen report detail (wide layout uses split pane).
class AiReportDetailPage extends StatelessWidget {
  const AiReportDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AiAlertsController>();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHeading),
                    ),
                    Expanded(
                      child: Text(
                        'Report',
                        style: handoverText(context, 18, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.detailLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final error = controller.detailError.value;
              if (error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error, textAlign: TextAlign.center),
                  ),
                );
              }
              final detail = controller.detail.value;
              if (detail == null) {
                return const Center(child: Text('Report not found'));
              }
              return AiReportDetailBody(report: detail);
            }),
          ),
        ],
      ),
    );
  }
}
