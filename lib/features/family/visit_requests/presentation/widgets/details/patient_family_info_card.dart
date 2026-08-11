import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../domain/entities/visit_request_detail.dart';

/// "Patient & Family Information" card: Patient / Assigned Staff /
/// Room / Location rows.
class PatientFamilyInfoCard extends StatelessWidget {
  final VisitRequestDetail detail;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);
  static const Color _labelColor = Color(0xFF64748B);
  static const Color _valueColor = Color(0xFF1A2B48);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _iconBoxBg = Color(0xFFF0F4F7);
  static const Color _iconColor = Color(0xFF0E7C7B);

  static const String _patientIcon =
      'assets/icons/family_visit_requests/visit.svg';
  static const String _staffIcon = 'assets/icons/family_visit_requests/team.svg';
  static const String _roomIcon = 'assets/icons/family_visit_requests/room.svg';

  const PatientFamilyInfoCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
          ),
          BoxShadow(
            color: _shadow.withValues(alpha: 0.06),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            iconAsset: _patientIcon,
            label: 'Patient',
            value: detail.patientName,
          ),
          _rowDivider(context),
          _InfoRow(
            iconAsset: _staffIcon,
            label: 'Assigned Staff',
            value: detail.assignedStaffLabel,
          ),
          _rowDivider(context),
          _InfoRow(
            iconAsset: _roomIcon,
            label: 'Room / Location',
            value: detail.roomLocationLabel,
          ),
        ],
      ),
    );
  }

  Widget _rowDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
      ),
      child: const Divider(height: 1, thickness: 1, color: _divider),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String value;

  const _InfoRow({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: PatientFamilyInfoCard._iconBoxBg,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
          ),
          alignment: Alignment.center,
          child: AppSvgIcon(
            iconAsset,
            size: 18,
            color: PatientFamilyInfoCard._iconColor,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: PatientFamilyInfoCard._labelColor,
                  height: 1.2,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    14.5,
                  ),
                  color: PatientFamilyInfoCard._valueColor,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
