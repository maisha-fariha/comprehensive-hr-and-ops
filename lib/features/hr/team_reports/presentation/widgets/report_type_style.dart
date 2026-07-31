import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../team_reports_assets.dart';
import '../../team_reports_constants.dart';

/// Icon/color styling for a [ReportTypeTag], shared by the Team tab's "Top
/// Reports" rows and the Reports tab's "Available Reports" cards so the
/// same report type always looks the same everywhere it appears.
class ReportTypeStyle {
  final String? asset;
  final IconData? materialIcon;
  final Color color;
  final Color background;

  const ReportTypeStyle({this.asset, this.materialIcon, required this.color, required this.background});
}

const Map<ReportTypeTag, ReportTypeStyle> reportTypeStyles = {
  // No matching exported SVG for a generic document/file glyph; falls back
  // to a Material icon (see the feature's final report).
  ReportTypeTag.dailyCensus: ReportTypeStyle(
    materialIcon: Icons.description_outlined,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
  ),
  ReportTypeTag.incidentAnalysis: ReportTypeStyle(
    asset: TeamReportsAssets.incidentAnalysis,
    color: AppColors.criticalRed,
    background: AppColors.criticalIconBackground,
  ),
  ReportTypeTag.medicationCompliance: ReportTypeStyle(
    asset: TeamReportsAssets.medicationCompliance,
    color: AppColors.secondaryTeal,
    background: TeamReportsColors.medicationTealBackground,
  ),
  ReportTypeTag.staffAttendance: ReportTypeStyle(
    asset: TeamReportsAssets.staffAttendance,
    color: AppColors.nightPurple,
    background: AppColors.nightBackground,
  ),
};
