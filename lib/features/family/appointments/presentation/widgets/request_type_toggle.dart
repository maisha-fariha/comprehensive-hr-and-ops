import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_appointments_enums.dart';

const Map<AppointmentRequestType, String> _segmentLabels = {
  AppointmentRequestType.visit: 'Visit',
  AppointmentRequestType.appointment: 'Appointment',
};

/// The "Request Type" segmented toggle at the top of the Create Appointment
/// form, switching between the "Visit" and "Appointment" field sets. Reuses
/// the same raised-white-pill visual pattern as the Appointments list's
/// segmented tab bar, per the app's existing segmented-control language.
class RequestTypeToggle extends StatelessWidget {
  final AppointmentRequestType selected;
  final ValueChanged<AppointmentRequestType> onSelected;

  const RequestTypeToggle({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          for (final type in AppointmentRequestType.values)
            Expanded(
              child: _ToggleSegment(
                label: _segmentLabels[type]!,
                isActive: selected == type,
                onTap: () => onSelected(type),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleSegment({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 11),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.06),
                    offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: isActive ? AppColors.secondaryTeal : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
