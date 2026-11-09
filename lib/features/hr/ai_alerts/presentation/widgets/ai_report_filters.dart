import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../controllers/ai_alerts_controller.dart';

class AiReportFilters extends StatelessWidget {
  final AiAlertsController controller;

  const AiReportFilters({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final kinds = controller.kindOptions;
      final homes = controller.homeOptions;
      final from = controller.fromDate.value;
      final to = controller.toDate.value;
      final dateLabel = from == null && to == null
          ? 'Any date'
          : from != null && to != null
              ? IsoDateRange.formatWeekRange(from, to)
              : 'Date range';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller.searchController,
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search reports',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.searchBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.searchBorder),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: controller.kindFilter.value == null
                      ? 'All report types'
                      : kinds
                              .where((k) => k.kind == controller.kindFilter.value)
                              .map((k) => k.label)
                              .firstOrNull ??
                          controller.kindFilter.value!,
                  onTap: () => _pickKind(context, kinds),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: controller.homeFilter.value == null
                      ? 'All homes'
                      : homes
                              .where((h) => h.id == controller.homeFilter.value)
                              .map((h) => h.name)
                              .firstOrNull ??
                          'Home',
                  onTap: () => _pickHome(context, homes),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _severityLabel(controller.severityFilter.value),
                  onTap: () => _pickSeverity(context),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: dateLabel,
                  onTap: () => controller.pickDateRange(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: Text(
                  'Unread only',
                  style: handoverText(context, 12.5),
                ),
                selected: controller.unreadOnly.value,
                onSelected: controller.toggleUnreadOnly,
                selectedColor: AppColors.infoBackground,
                checkmarkColor: AppColors.infoBlue,
              ),
              const Spacer(),
              if (controller.hasActiveFilters)
                TextButton(
                  onPressed: controller.clearFilters,
                  child: Text(
                    'Clear filters',
                    style: handoverText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: AppColors.infoBlue,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }

  String _severityLabel(String? value) {
    return switch (value) {
      'info' => 'Quiet updates',
      'attention' => 'Needs a look',
      'urgent' => 'Safety flags',
      _ => 'Any urgency',
    };
  }

  Future<void> _pickKind(BuildContext context, List kinds) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _OptionSheet(
        title: 'Report type',
        options: [
          (null, 'All report types'),
          for (final k in kinds) (k.kind as String, k.label as String),
        ],
        selected: controller.kindFilter.value,
      ),
    );
    if (picked != null || controller.kindFilter.value != null) {
      controller.setKindFilter(picked);
    }
  }

  Future<void> _pickHome(BuildContext context, List homes) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _OptionSheet(
        title: 'Home',
        options: [
          (null, 'All homes'),
          for (final h in homes) (h.id as String, h.name as String),
        ],
        selected: controller.homeFilter.value,
      ),
    );
    if (picked != null || controller.homeFilter.value != null) {
      controller.setHomeFilter(picked);
    }
  }

  Future<void> _pickSeverity(BuildContext context) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _OptionSheet(
        title: 'Urgency',
        options: const [
          (null, 'Any urgency'),
          ('info', 'Quiet updates'),
          ('attention', 'Needs a look'),
          ('urgent', 'Safety flags'),
        ],
        selected: controller.severityFilter.value,
      ),
    );
    if (picked != null || controller.severityFilter.value != null) {
      controller.setSeverityFilter(picked);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.searchBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: handoverText(context, 12.5, weight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<(String?, String)> options;
  final String? selected;

  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: handoverText(context, 16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final (value, label) in options)
              ListTile(
                title: Text(label, style: handoverText(context, 14)),
                trailing: value == selected
                    ? const Icon(Icons.check_rounded, color: AppColors.infoBlue)
                    : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
  }
}
