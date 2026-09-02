import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_appointment.dart';
import '../../domain/entities/family_appointments_enums.dart';

class _IconVisual {
  final String asset;
  final Color accent;
  final Color background;

  const _IconVisual({
    required this.asset,
    required this.accent,
    required this.background,
  });
}

class _StatusVisual {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusVisual({
    required this.label,
    required this.background,
    required this.foreground,
  });
}

/// A single appointment card on the Family Appointments list.
class FamilyAppointmentCard extends StatelessWidget {
  final FamilyAppointment appointment;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _dateColor = Color(0xFF0E7C7B);
  static const Color _locationColor = Color(0xFF8A97A8);
  static const Color _border = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);
  static const String _locationAsset = 'assets/icons/family_appointments/location.svg';

  const FamilyAppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
  });

  _IconVisual get _iconVisual {
    if (appointment.status == FamilyAppointmentStatus.completed) {
      return _IconVisual(
        asset: _assetFor(appointment.iconKind),
        accent: const Color(0xFF58687E),
        background: const Color(0xFFEAEDF2),
      );
    }

    switch (appointment.iconKind) {
      case FamilyAppointmentIconKind.dental:
        return const _IconVisual(
          asset: 'assets/icons/family_appointments/teeth.svg',
          accent: Color(0xFF2A5DA6),
          background: Color(0xFFEAF0F9),
        );
      case FamilyAppointmentIconKind.medical:
        return const _IconVisual(
          asset: 'assets/icons/family_appointments/plus_outlined.svg',
          accent: Color(0xFF0E7C7B),
          background: Color(0xFFE6F5F2),
        );
      case FamilyAppointmentIconKind.physiotherapy:
        return const _IconVisual(
          asset: 'assets/icons/family_appointments/activities.svg',
          accent: Color(0xFF0E7C7B),
          background: Color(0xFFE6F5F2),
        );
      case FamilyAppointmentIconKind.familyVisit:
        return const _IconVisual(
          asset: 'assets/icons/family_appointments/family.svg',
          accent: Color(0xFF006E5C),
          background: Color(0xFFE6F4F1),
        );
    }
  }

  _StatusVisual get _statusVisual {
    switch (appointment.status) {
      case FamilyAppointmentStatus.upcoming:
        return const _StatusVisual(
          label: 'Upcoming',
          background: Color(0xFFE7EFFA),
          foreground: Color(0xFF2A5DA6),
        );
      case FamilyAppointmentStatus.pending:
        return const _StatusVisual(
          label: 'Pending',
          background: Color(0xFFFFF3E0),
          foreground: Color(0xFFE65100),
        );
      case FamilyAppointmentStatus.approved:
        return const _StatusVisual(
          label: 'Approved',
          background: Color(0xFFE6F4F1),
          foreground: Color(0xFF006E5C),
        );
      case FamilyAppointmentStatus.rescheduleRequested:
        return const _StatusVisual(
          label: 'Reschedule requested',
          background: Color(0xFFFFF3E0),
          foreground: Color(0xFFE65100),
        );
      case FamilyAppointmentStatus.completed:
        return const _StatusVisual(
          label: 'Completed',
          background: Color(0xFFEAEDF2),
          foreground: Color(0xFF58687E),
        );
      case FamilyAppointmentStatus.rejected:
        return const _StatusVisual(
          label: 'Rejected',
          background: Color(0xFFFDECEC),
          foreground: Color(0xFFE53935),
        );
      case FamilyAppointmentStatus.cancelled:
        return const _StatusVisual(
          label: 'Cancelled',
          background: Color(0xFFEAEDF2),
          foreground: Color(0xFF58687E),
        );
    }
  }

  static String _assetFor(FamilyAppointmentIconKind kind) {
    switch (kind) {
      case FamilyAppointmentIconKind.medical:
        return 'assets/icons/family_appointments/plus_outlined.svg';
      case FamilyAppointmentIconKind.dental:
        return 'assets/icons/family_appointments/teeth.svg';
      case FamilyAppointmentIconKind.physiotherapy:
        return 'assets/icons/family_appointments/activities.svg';
      case FamilyAppointmentIconKind.familyVisit:
        return 'assets/icons/family_appointments/family.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconVisual;
    final status = _statusVisual;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 48);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
          ),
          BoxShadow(
            color: _shadow.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: icon.background,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 14),
              ),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(icon.asset, size: 22, color: icon.accent),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.dateTimeLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: _dateColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                    Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                          color: status.foreground,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Text(
                  appointment.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    color: _titleColor,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: ResponsiveHelper.getResponsiveHeight(context, 1),
                      ),
                      child: const AppSvgIcon(
                        _locationAsset,
                        size: 14,
                        color: _locationColor,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                    Expanded(
                      child: Text(
                        appointment.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                          color: _locationColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
