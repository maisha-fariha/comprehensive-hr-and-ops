import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../medication_labels.dart';

/// Search plus the web's four registry selects and "Clear".
class MarFilters extends StatelessWidget {
  final TextEditingController search;
  final String residenceId;
  final String clientId;
  final String medication;
  final String state;
  final List<MarChoice> residenceOptions;
  final List<MarChoice> residentOptions;
  final List<MarChoice> medicationOptions;
  final bool hasActive;
  final ValueChanged<String> onSearch;
  final void Function(String key, String value) onChanged;
  final VoidCallback onClear;

  const MarFilters({
    super.key,
    required this.search,
    required this.residenceId,
    required this.clientId,
    required this.medication,
    required this.state,
    required this.residenceOptions,
    required this.residentOptions,
    required this.medicationOptions,
    required this.hasActive,
    required this.onSearch,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('mar-search'),
          controller: search,
          onChanged: onSearch,
          style: handoverText(context, 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search',
            hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              key: const ValueKey('mar-filter-residence'),
              all: 'All residences',
              value: residenceId,
              options: residenceOptions,
              onPicked: (v) => onChanged('residenceId', v),
            ),
            _Chip(
              key: const ValueKey('mar-filter-resident'),
              all: 'All residents',
              value: clientId,
              options: residentOptions,
              onPicked: (v) => onChanged('clientId', v),
            ),
            _Chip(
              key: const ValueKey('mar-filter-medicine'),
              all: 'All medicines',
              value: medication,
              options: medicationOptions,
              onPicked: (v) => onChanged('medication', v),
            ),
            _Chip(
              key: const ValueKey('mar-filter-status'),
              all: 'Any status',
              value: state,
              options: MedicationLabels.statusFilter.skip(1).toList(),
              onPicked: (v) => onChanged('state', v),
            ),
            if (hasActive)
              HandoverButton(
                key: const ValueKey('mar-filter-clear'),
                label: 'Clear',
                icon: Icons.close_rounded,
                compact: true,
                onPressed: onClear,
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String all;
  final String value;
  final List<MarChoice> options;
  final ValueChanged<String> onPicked;

  const _Chip({
    super.key,
    required this.all,
    required this.value,
    required this.options,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final label = value.isEmpty ? all : MedicationLabels.label(options, value);
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () async {
        final picked = await pickHandoverOption(
          context,
          title: all,
          options: [('', all), ...options],
          selected: value,
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.searchBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: handoverText(context, 13, weight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
