import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/medication_enums.dart';

const Map<SchedulePeriod, String> _periodLabels = {
  SchedulePeriod.today: 'Today',
  SchedulePeriod.morning: 'Morning',
  SchedulePeriod.afternoon: 'Afternoon',
  SchedulePeriod.evening: 'Evening',
};

/// The "Due" tab's secondary time-of-day filter row (Today / Morning /
/// Afternoon / Evening). The selected chip renders as a solid dark pill;
/// only "Today" carries source data, the rest are selectable for visual
/// parity.
class SchedulePeriodSelector extends StatelessWidget {
  final SchedulePeriod selected;
  final ValueChanged<SchedulePeriod> onSelected;

  const SchedulePeriodSelector({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final period in SchedulePeriod.values) ...[
          if (period != SchedulePeriod.values.first)
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          _PeriodChip(
            label: _periodLabels[period]!,
            isSelected: period == selected,
            onTap: () => onSelected(period),
          ),
        ],
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
