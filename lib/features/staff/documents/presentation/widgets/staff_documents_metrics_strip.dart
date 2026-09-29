import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_document.dart';

class StaffDocumentsMetricsStrip extends StatelessWidget {
  final StaffDocumentsSummary summary;
  final VoidCallback? onMissingTap;

  const StaffDocumentsMetricsStrip({
    super.key,
    required this.summary,
    this.onMissingTap,
  });

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 10);
    final vGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Documents',
                value: '${summary.documents}',
                subtitle: '+${summary.addedLast30Days} in the last 30 days',
                icon: Icons.description_outlined,
                iconColor: AppColors.activeGreen,
                iconBg: AppColors.activeBackground,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                label: 'Missing Required Documents',
                value: '${summary.missingMandatory}',
                subtitle: 'Review required',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.criticalRed,
                iconBg: AppColors.criticalBackgroundSoft,
                onTap: onMissingTap,
              ),
            ),
          ],
        ),
        SizedBox(height: vGap),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Expiring Soon',
                value: '${summary.expiringSoon}',
                subtitle: 'Within 30 days',
                icon: Icons.schedule_rounded,
                iconColor: AppColors.urgentAmber,
                iconBg: AppColors.urgentBackgroundSoft,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetricCard(
                label: 'Restricted Files',
                value: '${summary.restricted}',
                subtitle: 'Access banded',
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.secondaryTeal,
                iconBg: AppColors.quickActionCreateShiftBg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12,
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
