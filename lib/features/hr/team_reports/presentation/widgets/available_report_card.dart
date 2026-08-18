import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/available_report_item.dart';
import '../../domain/entities/team_reports_enums.dart';
import 'team_reports_icon_box.dart';

class _ReportVisual {
  final String asset;
  final Color color;
  final Color background;

  const _ReportVisual({
    required this.asset,
    required this.color,
    required this.background,
  });
}

const Map<ReportTypeTag, _ReportVisual> _reportVisuals = {
  ReportTypeTag.dailyCensus: _ReportVisual(
    asset: 'assets/icons/team_reports/team_doc.svg',
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
  ),
  ReportTypeTag.incidentAnalysis: _ReportVisual(
    asset: 'assets/icons/team_reports/team_alert.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
  ),
  ReportTypeTag.medicationCompliance: _ReportVisual(
    asset: 'assets/icons/team_reports/team_heart.svg',
    color: Color(0xFF0E7C7B),
    background: Color(0xFFE3F3F1),
  ),
  ReportTypeTag.staffAttendance: _ReportVisual(
    asset: 'assets/icons/team_reports/team_staff.svg',
    color: Color(0xFF6A4BC7),
    background: Color(0xFFF0ECFB),
  ),
};

/// A single card in the Reports tab's "Available Reports" list.
class AvailableReportCard extends StatelessWidget {
  final String title;
  final String categoryLabel;
  final String updatedLabel;
  final String? asset;
  final IconData? materialIcon;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  AvailableReportCard({
    super.key,
    required AvailableReportItem item,
    this.onTap,
  })  : title = item.title,
        categoryLabel = item.categoryLabel,
        updatedLabel = item.updatedLabel,
        asset = _reportVisuals[item.tag]!.asset,
        materialIcon = null,
        color = _reportVisuals[item.tag]!.color,
        background = _reportVisuals[item.tag]!.background;

  /// UI-only constructor for reference cards not represented by [ReportTypeTag].
  const AvailableReportCard.custom({
    super.key,
    required this.title,
    required this.categoryLabel,
    required this.updatedLabel,
    this.asset,
    this.materialIcon,
    required this.color,
    required this.background,
    this.onTap,
  }) : assert(asset != null || materialIcon != null);

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final chevronSize = ResponsiveHelper.getResponsiveSize(context, 32);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            TeamReportsIconBox(
              asset: asset,
              materialIcon: materialIcon,
              color: color,
              background: background,
              boxSize: 42,
              iconSize: 20,
              radius: 12,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textHeading,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                  Text(
                    categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.secondaryTeal,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Row(
                    children: [
                      const AppSvgIcon(
                        'assets/icons/team_reports/team_clock.svg',
                        size: 11,
                        color: AppColors.textFaint,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                      Flexible(
                        child: Text(
                          updatedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Container(
              width: chevronSize,
              height: chevronSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_right_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: AppColors.iconChevron,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
