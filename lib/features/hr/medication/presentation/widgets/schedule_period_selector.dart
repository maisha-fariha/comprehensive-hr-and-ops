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

/// Due tab time-of-day filter chips (Today / Morning / Afternoon / Evening).
/// Selected = solid navy pill; unselected = white pill with light border.
class SchedulePeriodSelector extends StatelessWidget {
  final SchedulePeriod selected;
  final ValueChanged<SchedulePeriod> onSelected;

  const SchedulePeriodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            for (var i = 0; i < SchedulePeriod.values.length; i++) ...[
              if (i > 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: _PeriodChip(
                  label: _periodLabels[SchedulePeriod.values[i]]!,
                  isSelected: SchedulePeriod.values[i] == selected,
                  onTap: () => onSelected(SchedulePeriod.values[i]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 8,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.searchBorder,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: isSelected ? Colors.white : AppColors.textBody,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
