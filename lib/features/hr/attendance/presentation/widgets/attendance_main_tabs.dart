import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/time_off_request.dart';

/// Web Attendance | Time-Off Requests segmented control.
class AttendanceMainTabs extends StatelessWidget {
  final AttendanceMainTab selected;
  final ValueChanged<AttendanceMainTab> onSelected;

  const AttendanceMainTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveHelper.getResponsiveHeight(context, 40),
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusInput),
        ),
      ),
      child: Row(
        children: [
          _Segment(
            key: const ValueKey('attendance-main-records'),
            label: 'Attendance',
            isActive: selected == AttendanceMainTab.records,
            onTap: () => onSelected(AttendanceMainTab.records),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 2)),
          _Segment(
            key: const ValueKey('attendance-main-time-off'),
            label: 'Time-Off',
            isActive: selected == AttendanceMainTab.timeOff,
            onTap: () => onSelected(AttendanceMainTab.timeOff),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Segment({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.surfaceWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusChip),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.shadowNavy.withValues(alpha: 0.06),
                      offset: Offset(
                        0,
                        ResponsiveHelper.getResponsiveHeight(context, 1),
                      ),
                      blurRadius: ResponsiveHelper.getResponsiveHeight(context, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: isActive ? AppColors.textHeading : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
