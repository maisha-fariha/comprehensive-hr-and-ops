import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/referral.dart';

/// The four web KPI tiles from `GET /referrals/board`.
class AdmissionsKpiGrid extends StatelessWidget {
  final ReferralBoard board;

  const AdmissionsKpiGrid({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: a), SizedBox(width: gap), Expanded(child: b)],
          ),
        );

    return Column(
      children: [
        row(
          _Tile(
            key: const ValueKey('admissions-kpi-pending'),
            icon: Icons.assignment_outlined,
            tone: AppColors.secondaryTeal,
            toneBackground: AppColors.quickActionCreateShiftBg,
            value: board.pending,
            label: 'IN THE PIPELINE',
            caption: 'Referrals still moving forward',
          ),
          _Tile(
            key: const ValueKey('admissions-kpi-documents'),
            icon: Icons.file_present_outlined,
            tone: AppColors.urgentAmber,
            toneBackground: AppColors.urgentBackground,
            value: board.awaitingDocuments,
            label: 'CANNOT BE ADMITTED',
            caption: 'Something required is missing or unsigned',
          ),
        ),
        SizedBox(height: gap),
        row(
          _Tile(
            key: const ValueKey('admissions-kpi-assessment'),
            icon: Icons.medical_services_outlined,
            tone: AppColors.infoBlue,
            toneBackground: AppColors.infoBackground,
            value: board.assessmentPending,
            label: 'NOT YET ASSESSED',
            caption: 'Nobody has written an assessment',
          ),
          _Tile(
            key: const ValueKey('admissions-kpi-admitted'),
            icon: Icons.how_to_reg_outlined,
            tone: AppColors.successGreen,
            toneBackground: const Color(0xFFE9F5EE),
            value: board.admittedLast30Days,
            label: 'ADMITTED',
            caption: 'In the last 30 days',
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final Color toneBackground;
  final int value;
  final String label;
  final String caption;

  const _Tile({
    super.key,
    required this.icon,
    required this.tone,
    required this.toneBackground,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle text(double size, FontWeight weight, Color color) => TextStyle(
          fontFamily: 'Outfit',
          fontWeight: weight,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size),
          color: color,
        );
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 36),
            height: ResponsiveHelper.getResponsiveSize(context, 36),
            decoration: BoxDecoration(
              color: toneBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 11),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: ResponsiveHelper.getResponsiveSize(context, 17),
              color: tone,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text('$value', style: text(24, FontWeight.w700, AppColors.textHeading)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            label,
            style: text(11, FontWeight.w600, AppColors.textSecondary)
                .copyWith(letterSpacing: 0.4),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
          Text(caption, style: text(12, FontWeight.w400, AppColors.textMuted)),
        ],
      ),
    );
  }
}
