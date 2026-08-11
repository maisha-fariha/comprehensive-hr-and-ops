import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_next_appointment.dart';

/// "Next Appointment" heading + card for the Family Dashboard.
class FamilyNextAppointmentSection extends StatelessWidget {
  final FamilyNextAppointment appointment;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _dateColor = Color(0xFF0E7C7B);
  static const Color _locationColor = Color(0xFF8A97A8);
  static const Color _iconBg = Color(0xFFE6F5F2);
  static const Color _iconFg = Color(0xFF0E7C7B);
  static const Color _badgeBg = Color(0xFFE7EFFA);
  static const Color _badgeFg = Color(0xFF2A5DA6);
  static const Color _border = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  static const String _calendarAsset = 'assets/icons/family_core/calendar.svg';
  static const String _locationAsset = 'assets/icons/family_core/location.svg';

  const FamilyNextAppointmentSection({
    super.key,
    required this.appointment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 46);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Appointment',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            color: _titleColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        GestureDetector(
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
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 14),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const AppSvgIcon(_calendarAsset, size: 22, color: _iconFg),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              appointment.dateTimeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
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
                              color: _badgeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              appointment.statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                                color: _badgeFg,
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
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          color: _titleColor,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                      Row(
                        children: [
                          const AppSvgIcon(_locationAsset, size: 14, color: _locationColor),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                          Expanded(
                            child: Text(
                              appointment.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w400,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                                color: _locationColor,
                                height: 1.25,
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
        ),
      ],
    );
  }
}
