import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/staff_shift.dart';
import 'shift_card.dart';

/// "My Shifts" heading (+ a "N this week" trailing label) and the vertical
/// list of shift cards beneath it.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(
          title: 'My Shifts',
          trailing: Text(
            shiftsThisWeekLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
        for (final shift in shifts)
          ShiftCard(
            shift: shift,
            onTap: onShiftTap == null ? null : () => onShiftTap!(shift),
          ),
      ],
    );
  }
}
