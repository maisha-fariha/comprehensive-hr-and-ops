import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../../core/widgets/surface_card.dart';
import '../../../domain/entities/incident_detail.dart';
import 'section_label.dart';

/// "INCIDENT INFORMATION" card: a set of icon + label + value rows
/// (Category / Date & Time / Detected During / Location).
///
/// Icon note: no exact "category"/"detected during"/"location" glyphs
/// exist in `assets/icons/*` yet, so this uses Material `Icons.*`
/// placeholders for those 3 rows (flagged in the feature's final report).
/// The "Date & Time" row reuses the existing `nav_calendar.svg` asset (an
/// exact visual match).
class IncidentInfoSection extends StatelessWidget {
  final IncidentDetail detail;

  const IncidentInfoSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IncidentDetailsSectionLabel('INCIDENT INFORMATION'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        SurfaceCard.card(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
          child: Column(
            children: [
              _InfoRow(
                icon: const Icon(Icons.category_outlined, color: AppColors.textFaint),
                label: 'Category',
                value: detail.categoryLabel[0] + detail.categoryLabel.substring(1).toLowerCase(),
              ),
              _rowDivider(context),
              _InfoRow(
                icon: const AppSvgIcon(AppAssets.navCalendar, size: 16, color: AppColors.textFaint),
                label: 'Date & Time',
                value: detail.dateTimeLabel,
              ),
              _rowDivider(context),
              _InfoRow(
                icon: const Icon(Icons.access_time_rounded, color: AppColors.textFaint),
                label: 'Detected During',
                value: detail.detectedDuring,
              ),
              _rowDivider(context),
              _InfoRow(
                icon: const Icon(Icons.location_on_outlined, color: AppColors.textFaint),
                label: 'Location',
                value: detail.location,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveHeight(context, 12)),
      child: Divider(height: 1, color: AppColors.dividerLight),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: ResponsiveHelper.getResponsiveSize(context, 18),
          height: ResponsiveHelper.getResponsiveSize(context, 18),
          child: icon,
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textHeading,
            ),
          ),
        ),
      ],
    );
  }
}
