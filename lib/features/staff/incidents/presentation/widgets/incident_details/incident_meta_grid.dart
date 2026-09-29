import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/incident_detail.dart';

/// 2×2 meta grid: CLIENT / RESIDENCE / REPORTED / REPORTED BY.
class IncidentMetaGrid extends StatelessWidget {
  final IncidentDetail detail;

  const IncidentMetaGrid({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    final vGap = ResponsiveHelper.getResponsiveHeight(context, 12);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetaCell(
                  label: 'CLIENT',
                  value: _display(detail.residentName),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _MetaCell(
                  label: 'RESIDENCE',
                  value: _display(detail.residenceName),
                ),
              ),
            ],
          ),
          SizedBox(height: vGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetaCell(
                  label: 'REPORTED',
                  value: _display(detail.reportedAtLabel),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _MetaCell(
                  label: 'REPORTED BY',
                  value: _display(detail.reportedByName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _display(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }
}

class _MetaCell extends StatelessWidget {
  final String label;
  final String value;

  const _MetaCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
            letterSpacing: 0.4,
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: AppColors.textHeading,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
