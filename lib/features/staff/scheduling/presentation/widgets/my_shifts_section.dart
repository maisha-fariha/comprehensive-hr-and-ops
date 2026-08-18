import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_shift.dart';
import 'shift_card.dart';

/// "My Shifts" heading + shared white card listing the week's shifts.
class MyShiftsSection extends StatelessWidget {
  final String shiftsThisWeekLabel;
  final List<StaffShift> shifts;
  final ValueChanged<StaffShift>? onShiftTap;

  const MyShiftsSection({
    super.key,
    required this.shiftsThisWeekLabel,
    required this.shifts,
    this.onShiftTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final itemGap = ResponsiveHelper.getResponsiveHeight(context, 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'My Shifts',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Text(
              shiftsThisWeekLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (shifts.isNotEmpty)
          Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowNavy.withValues(alpha: 0.04),
                  offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
                  blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < shifts.length; i++) ...[
                  if (i > 0) SizedBox(height: itemGap),
                  ShiftCard(
                    shift: shifts[i],
                    onTap: onShiftTap == null ? null : () => onShiftTap!(shifts[i]),
                    showDividerBar: true,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
