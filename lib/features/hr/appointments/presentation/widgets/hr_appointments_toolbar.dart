import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_appointment.dart';
import '../hr_appointments_labels.dart';

/// Queue tabs with counts, "Search requests..." and the Filters toggle.
class HrAppointmentsToolbar extends StatelessWidget {
  final String tab;
  final Map<String, int> counts;
  final TextEditingController search;
  final bool filtersShown;
  final ValueChanged<String> onTab;
  final ValueChanged<String> onSearch;
  final VoidCallback onToggleFilters;

  const HrAppointmentsToolbar({
    super.key,
    required this.tab,
    required this.counts,
    required this.search,
    required this.filtersShown,
    required this.onTab,
    required this.onSearch,
    required this.onToggleFilters,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in HrAppointmentsLabels.tabs)
                  _TabChip(
                    key: ValueKey('appointments-tab-${t.id}'),
                    label: t.label,
                    count: counts[t.id],
                    active: t.id == tab,
                    onTap: () => onTab(t.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    key: const ValueKey('appointments-search'),
                    controller: search,
                    onChanged: onSearch,
                    style: handoverText(context, 13.5),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search requests...',
                      hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.searchBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.searchBorder),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: filtersShown
                    ? AppColors.secondaryTeal.withValues(alpha: 0.1)
                    : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  key: const ValueKey('appointments-filters-toggle'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: onToggleFilters,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: filtersShown ? AppColors.secondaryTeal : AppColors.searchBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: filtersShown ? AppColors.secondaryTeal : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Filters',
                          style: handoverText(
                            context,
                            13,
                            weight: FontWeight.w500,
                            color: filtersShown ? AppColors.secondaryTeal : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    super.key,
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.urgentBackground : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: handoverText(
                  context,
                  13,
                  weight: FontWeight.w500,
                  color: active ? AppColors.primaryNavy : AppColors.textSecondary,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: active ? AppColors.secondaryTeal : AppColors.filterButtonBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: handoverText(
                      context,
                      11,
                      weight: FontWeight.w600,
                      color: active ? AppColors.surfaceWhite : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Status / type / residence selects and "Clear filters".
class HrAppointmentsFilters extends StatelessWidget {
  final String status;
  final String type;
  final String residenceId;
  final List<HrAppointmentOption> residences;
  final void Function(String key, String value) onChanged;
  final VoidCallback onClear;

  const HrAppointmentsFilters({
    super.key,
    required this.status,
    required this.type,
    required this.residenceId,
    required this.residences,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final residenceOptions = [
      ('', 'All residences'),
      for (final r in residences) (r.id, r.label),
    ];
    Widget select(String key, String title, String value, List<(String, String)> options) {
      final label = options
          .firstWhere((o) => o.$1 == value, orElse: () => options.first)
          .$2;
      return Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          key: ValueKey('appointments-filter-$key'),
          borderRadius: BorderRadius.circular(9),
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: title,
              options: options,
              selected: value,
            );
            if (picked != null) onChanged(key, picked);
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: handoverText(context, 13, weight: FontWeight.w500)),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        select('status', 'Status', status, HrAppointmentsLabels.statusOptions),
        select('type', 'Type', type, HrAppointmentsLabels.typeOptions),
        select('residenceId', 'Residence', residenceId, residenceOptions),
        TextButton(
          key: const ValueKey('appointments-clear-filters'),
          onPressed: onClear,
          child: Text(
            'Clear filters',
            style: handoverText(context, 13, weight: FontWeight.w500, color: AppColors.infoBlue),
          ),
        ),
      ],
    );
  }
}
