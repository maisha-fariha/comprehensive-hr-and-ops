import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/family_appointments_enums.dart';

const Map<AppointmentRequestType, String> _segmentLabels = {
  AppointmentRequestType.visit: 'Visit',
  AppointmentRequestType.appointment: 'Appointment',
};

/// The "Request Type" segmented toggle at the top of the Create Appointment
/// form, switching between the "Visit" and "Appointment" field sets.
class RequestTypeToggle extends StatelessWidget {
  final AppointmentRequestType selected;
  final ValueChanged<AppointmentRequestType> onSelected;

  static const Color _track = Color(0xFFF0F4F7);
  static const Color _trackBorder = Color(0xFFE4E9EE);
  static const Color _activeText = Color(0xFF0B6B5F);
  static const Color _inactiveText = Color(0xFF6B7B8A);
  static const Color _shadow = Color(0xFF142846);

  const RequestTypeToggle({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 15);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: _track,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _trackBorder,
          width: ResponsiveHelper.getResponsiveWidth(context, 1),
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

  const _ToggleSegment({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 12,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 8),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: RequestTypeToggle._shadow.withValues(alpha: 0.08),
                    offset: Offset(
                      0,
                      ResponsiveHelper.getResponsiveHeight(context, 1),
                    ),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: isActive
                ? RequestTypeToggle._activeText
                : RequestTypeToggle._inactiveText,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}
