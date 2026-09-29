import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Web MAR registry filters: search + residence / resident / medicine / status.
class StaffMarFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final String residenceId;
  final String clientId;
  final String medication;
  final String state;
  final List<({String value, String label})> residenceOptions;
  final List<({String value, String label})> residentOptions;
  final List<({String value, String label})> medicationOptions;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final void Function({
    String? residenceId,
    String? clientId,
    String? medication,
    String? state,
  }) onFilterChanged;
  final VoidCallback onClear;

  static const List<({String value, String label})> statusOptions = [
    (value: '', label: 'Any status'),
    (value: 'given', label: 'Given'),
    (value: 'late', label: 'Given late'),
    (value: 'due', label: 'Due now'),
    (value: 'upcoming', label: 'Upcoming'),
    (value: 'overdue', label: 'Overdue'),
    (value: 'missed', label: 'Missed'),
    (value: 'refused', label: 'Refused'),
    (value: 'withheld', label: 'Withheld'),
    (value: 'not_available', label: 'Not available'),
  ];

  const StaffMarFiltersBar({
    super.key,
    required this.searchController,
    required this.residenceId,
    required this.clientId,
    required this.medication,
    required this.state,
    required this.residenceOptions,
    required this.residentOptions,
    required this.medicationOptions,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: AppColors.textHeading,
          ),
          decoration: InputDecoration(
            hintText: 'Search residents, medicines…',
            hintStyle: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondaryTeal),
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: _optionLabel(
                residenceId,
                residenceOptions,
                emptyLabel: 'All residences',
              ),
              onTap: () => _pick(
                context,
                title: 'Residence',
                current: residenceId,
                options: [
                  (value: '', label: 'All residences'),
                  ...residenceOptions,
                ],
                onPicked: (v) => onFilterChanged(residenceId: v),
              ),
            ),
            _FilterChip(
              label: _optionLabel(
                clientId,
                residentOptions,
                emptyLabel: 'All residents',
              ),
              onTap: () => _pick(
                context,
                title: 'Resident',
                current: clientId,
                options: [
                  (value: '', label: 'All residents'),
                  ...residentOptions,
                ],
                onPicked: (v) => onFilterChanged(clientId: v),
              ),
            ),
            _FilterChip(
              label: _optionLabel(
                medication,
                medicationOptions,
                emptyLabel: 'All medicines',
              ),
              onTap: () => _pick(
                context,
                title: 'Medicine',
                current: medication,
                options: [
                  (value: '', label: 'All medicines'),
                  ...medicationOptions,
                ],
                onPicked: (v) => onFilterChanged(medication: v),
              ),
            ),
            _FilterChip(
              label: _optionLabel(
                state,
                statusOptions.where((o) => o.value.isNotEmpty).toList(),
                emptyLabel: 'Any status',
              ),
              onTap: () => _pick(
                context,
                title: 'Status',
                current: state,
                options: statusOptions,
                onPicked: (v) => onFilterChanged(state: v),
              ),
            ),
            if (hasActiveFilters)
              TextButton(
                onPressed: onClear,
                child: const Text(
                  'Clear filters',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _optionLabel(
    String value,
    List<({String value, String label})> options, {
    required String emptyLabel,
  }) {
    if (value.isEmpty) return emptyLabel;
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return emptyLabel;
  }

  Future<void> _pick(
    BuildContext context, {
    required String title,
    required String current,
    required List<({String value, String label})> options,
    required ValueChanged<String> onPicked,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (_, i) {
                    final o = options[i];
                    final isSelected = o.value == current;
                    return ListTile(
                      title: Text(
                        o.label,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textHeading,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.secondaryTeal,
                            )
                          : null,
                      onTap: () => Navigator.pop(ctx, o.value),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) onPicked(selected);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
