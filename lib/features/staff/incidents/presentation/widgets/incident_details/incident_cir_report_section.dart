import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../hr/incidents/domain/entities/incident_investigation_summary.dart';
import 'section_label.dart';

/// CIR template "Report form" block — same Print / Download PDF flow as manager.
class IncidentCirReportSection extends StatelessWidget {
  final List<CirFormSection> sections;
  final bool pdfBusy;
  final VoidCallback onPrint;
  final VoidCallback onDownload;

  const IncidentCirReportSection({
    super.key,
    required this.sections,
    required this.pdfBusy,
    required this.onPrint,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IncidentDetailsSectionLabel('CIR TEMPLATE'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Report form',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 15),
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  _PillButton(
                    label: 'Print',
                    icon: Icons.print_outlined,
                    filled: false,
                    onTap: pdfBusy ? null : onPrint,
                  ),
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 8),
                  ),
                  _PillButton(
                    label: 'Download PDF',
                    icon: Icons.download_outlined,
                    filled: true,
                    onTap: pdfBusy ? null : onDownload,
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
              Text(
                'As filed. The form is stored with the report, so this is what was asked at the time.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
              for (final section in sections) ...[
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 16),
                ),
                Text(
                  section.title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textHeading,
                  ),
                ),
                if (section.fields.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: ResponsiveHelper.getResponsiveHeight(context, 8),
                    ),
                    child: Text(
                      'No filed answers in this section.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                else
                  for (final field in section.fields) ...[
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 12),
                    ),
                    _DetailRow(
                      label: field.label.toUpperCase(),
                      value: field.value,
                    ),
                  ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: filled
          ? (enabled
              ? AppColors.primaryNavy
              : AppColors.primaryNavy.withValues(alpha: 0.5))
          : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        child: Container(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 10),
            ),
            border: filled ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ResponsiveHelper.getResponsiveSize(context, 14),
                color: filled ? Colors.white : AppColors.textHeading,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: filled ? Colors.white : AppColors.textHeading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
