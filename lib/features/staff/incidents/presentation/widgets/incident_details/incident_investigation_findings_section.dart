import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/incident_detail.dart';

/// Investigation findings & corrective action (web parity).
class IncidentInvestigationFindingsSection extends StatelessWidget {
  final IncidentDetail detail;

  static const Color _openBackground = Color(0xFFFEE2E2);
  static const Color _openForeground = Color(0xFFDC2626);
  static const Color _statusBackground = Color(0xFFEEF2FF);
  static const Color _statusForeground = Color(0xFF4338CA);

  const IncidentInvestigationFindingsSection({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final status = detail.investigationStatus?.trim();
    final findings = detail.investigationFindings?.trim();
    final rootCause = detail.investigationRootCause?.trim();
    final corrective = detail.investigationCorrectiveAction?.trim();
    final recordedBy = detail.investigationRecordedBy?.trim();
    final recordedAt = detail.investigationRecordedAtLabel?.trim();
    final isOpen = (status ?? '').toLowerCase() == 'open';

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Investigation findings & corrective action',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (status != null && status.isNotEmpty)
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen ? _openBackground : _statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: isOpen ? _openForeground : _statusForeground,
                    ),
                  ),
                ),
            ],
          ),
          if ((recordedBy != null && recordedBy.isNotEmpty) ||
              (recordedAt != null && recordedAt.isNotEmpty)) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Text(
              [
                if (recordedBy != null && recordedBy.isNotEmpty)
                  'Recorded by $recordedBy',
                if (recordedAt != null && recordedAt.isNotEmpty) recordedAt,
              ].join(' · '),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (findings != null && findings.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            _LabeledBlock(label: 'FINDINGS', value: findings),
          ],
          if (rootCause != null && rootCause.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            _LabeledBlock(label: 'ROOT CAUSE', value: rootCause),
          ],
          if (corrective != null && corrective.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            _LabeledBlock(label: 'CORRECTIVE ACTION', value: corrective),
          ],
        ],
      ),
    );
  }
}

class _LabeledBlock extends StatelessWidget {
  final String label;
  final String value;

  const _LabeledBlock({required this.label, required this.value});

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
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: AppColors.textHeading,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
