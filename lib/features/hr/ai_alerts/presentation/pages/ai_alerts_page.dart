import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/ai_report.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../controllers/ai_alerts_controller.dart';
import '../widgets/ai_automation_card.dart';
import '../widgets/ai_report_detail_body.dart';
import '../widgets/ai_report_filters.dart';
import '../widgets/ai_report_list_tile.dart';
import 'ai_report_detail_page.dart';

/// Manager **AI Alerts & Insights** — mirrors web `/dashboard/ai-reports`.
class AiAlertsPage extends StatefulWidget {
  const AiAlertsPage({super.key});

  @override
  State<AiAlertsPage> createState() => _AiAlertsPageState();
}

class _AiAlertsPageState extends State<AiAlertsPage> {
  late final AiAlertsController _controller;
  var _detailRouteOpen = false;

  bool _wide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(GetIt.instance<AiAlertsController>());
    TenantClock.syncFromApi(GetIt.instance<AppApiClient>());
  }

  @override
  void dispose() {
    Get.delete<AiAlertsController>();
    super.dispose();
  }

  Future<void> _openReport(BuildContext context, String id) async {
    final wide = _wide(context);
    await _controller.selectReport(id, wide: wide);
    if (!context.mounted) return;
    if (wide) return;
    if (_detailRouteOpen) return;
    _detailRouteOpen = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AiReportDetailPage()),
    );
    _detailRouteOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final wide = _wide(context);
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Alerts & Insights',
                                style: handoverText(context, 18, weight: FontWeight.w700),
                              ),
                              Text(
                                'Checks the AI runs on its own schedule — medication, incidents, rotas, pay runs, stock and more.',
                                style: handoverText(context, 12, color: AppColors.textMuted),
                              ),
                            ],
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
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Obx(() {
                      final unread = _controller.reportsPage.value.unread;
                      return Row(
                        children: [
                          _TabChip(
                            label: 'Reports${unread > 0 ? ' ($unread)' : ''}',
                            selected: _controller.selectedTab.value.name == 'reports',
                            onTap: () => _controller.selectTab(AiAlertsTab.reports),
                          ),
                          const SizedBox(width: 8),
                          _TabChip(
                            label: 'Automations',
                            selected: _controller.selectedTab.value.name == 'automations',
                            onTap: () => _controller.selectTab(AiAlertsTab.automations),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_controller.selectedTab.value == AiAlertsTab.automations) {
                return _AutomationsPane(controller: _controller);
              }
              return wide
                  ? Row(
                      children: [
                        Expanded(flex: 4, child: _ReportsListPane(
                          controller: _controller,
                          onOpen: (id) => _openReport(context, id),
                        )),
                        const VerticalDivider(width: 1, color: AppColors.cardBorder),
                        Expanded(
                          flex: 6,
                          child: _ReportDetailPane(controller: _controller),
                        ),
                      ],
                    )
                  : _ReportsListPane(
                      controller: _controller,
                      onOpen: (id) => _openReport(context, id),
                    );
            }),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryNavy : AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryNavy : AppColors.searchBorder,
          ),
        ),
        child: Text(
          label,
          style: handoverText(
            context,
            13,
            weight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textBody,
          ),
        ),
      ),
    );
  }
}

class _ReportsListPane extends StatelessWidget {
  final AiAlertsController controller;
  final ValueChanged<String> onOpen;

  const _ReportsListPane({
    required this.controller,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.reportsLoading.value &&
          controller.reportsPage.value.items.isEmpty;
      final error = controller.reportsError.value;
      final items = List<AiReportListItem>.from(
        controller.reportsPage.value.items,
      );
      final selected = controller.selectedReportId.value;

      if (loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (error != null && items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: controller.loadReports,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      return AppRefreshIndicator(
        onRefresh: controller.refreshAll,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: items.isEmpty ? 2 : items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AiReportFilters(controller: controller),
              );
            }
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Text(
                  'No reports match your filters.',
                  textAlign: TextAlign.center,
                  style: handoverText(context, 14, color: AppColors.textMuted),
                ),
              );
            }
            final item = items[index - 1];
            return AiReportListTile(
              item: item,
              selected: item.id == selected,
              onTap: () => onOpen(item.id),
            );
          },
        ),
      );
    });
  }
}

class _ReportDetailPane extends StatelessWidget {
  final AiAlertsController controller;

  const _ReportDetailPane({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedReportId.value;
      if (selected == null) {
        return Center(
          child: Text(
            'Select a report to read',
            style: handoverText(context, 14, color: AppColors.textMuted),
          ),
        );
      }
      if (controller.detailLoading.value && controller.detail.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final error = controller.detailError.value;
      if (error != null && controller.detail.value == null) {
        return Center(child: Text(error, textAlign: TextAlign.center));
      }
      final detail = controller.detail.value;
      if (detail == null) {
        return const Center(child: Text('Report not found'));
      }
      return ColoredBox(
        color: AppColors.scaffoldBackground,
        child: AiReportDetailBody(report: detail),
      );
    });
  }
}

class _AutomationsPane extends StatelessWidget {
  final AiAlertsController controller;

  const _AutomationsPane({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: controller.loadAutomations,
      child: Obx(() {
        if (controller.automationsLoading.value &&
            controller.automationsPage.value.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = controller.automationsError.value;
        if (error != null && controller.automationsPage.value.items.isEmpty) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error, textAlign: TextAlign.center),
              ),
            ],
          );
        }
        final items = controller.automationsPage.value.items;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Scheduled checks the AI runs for your organisation.',
              style: handoverText(context, 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            for (final item in items) AiAutomationCard(automation: item),
            if (items.isEmpty)
              Text(
                'No automations returned.',
                style: handoverText(context, 14, color: AppColors.textMuted),
              ),
          ],
        );
      }),
    );
  }
}
