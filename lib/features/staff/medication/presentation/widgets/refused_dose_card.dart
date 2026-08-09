import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/refused_dose.dart';
import 'dose_note_box.dart';
import 'medication_route_row.dart';
import 'staff_medication_avatar.dart';
import 'status_by_row.dart';

/// A single card in the Refused tab, matched to the reference.
class RefusedDoseCard extends StatelessWidget {
  final RefusedDose dose;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _timeLabel = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFEEF2F6);
  static const Color _refusedOrange = Color(0xFFC27803);
  static const Color _noteBg = Color(0xFFF8FAFC);

  const RefusedDoseCard({super.key, required this.dose});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaffMedicationAvatar(
                initials: dose.residentInitials,
                palette: dose.avatarColor,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dose.residentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: _titleColor,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                    Text(
                      '${dose.medicationName} ${dose.dose}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: _titleColor,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                    MedicationRouteRow(route: dose.route),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TIME',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                      color: _timeLabel,
                      letterSpacing: 0.6,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Text(
                    dose.timeLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: _titleColor,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
            ),
            child: const Divider(height: 1, thickness: 1, color: _divider),
          ),
          StatusByRow(
            label: 'Refused',
            byName: dose.refusedByName,
            background: AppColors.urgentBackground,
            foreground: _refusedOrange,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          DoseNoteBox(
            label: 'Notes',
            text: dose.notes,
            background: _noteBg,
          ),
        ],
      ),
    );
  }
}
