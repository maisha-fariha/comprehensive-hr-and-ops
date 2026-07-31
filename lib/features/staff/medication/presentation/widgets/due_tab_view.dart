import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/due_dose.dart';
import 'due_dose_card.dart';

/// Content of the "Due" tab: the "Due Now" list (with a trailing time
/// label) followed by the "Later Today" list.
class DueTabView extends StatelessWidget {
  final List<DueDose> dueNowDoses;
  final List<DueDose> laterTodayDoses;
  final ValueChanged<String> onAdminister;
  final ValueChanged<String> onNotGiven;

  const DueTabView({
    super.key,
    required this.dueNowDoses,
    required this.laterTodayDoses,
    required this.onAdminister,
    required this.onNotGiven,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dueNowDoses.isNotEmpty) ...[
          SectionHeaderRow(
            title: 'Due Now',
            trailing: _TimeTrailing(timeLabel: dueNowDoses.first.timeLabel),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (var i = 0; i < dueNowDoses.length; i++) ...[
            DueDoseCard(
              dose: dueNowDoses[i],
              onAdminister: () => onAdminister(dueNowDoses[i].id),
              onNotGiven: () => onNotGiven(dueNowDoses[i].id),
            ),
            if (i != dueNowDoses.length - 1)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          ],
        ],
        if (laterTodayDoses.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
          SectionHeaderRow(
            title: 'Later Today',
            trailing: _TimeTrailing(timeLabel: laterTodayDoses.first.timeLabel),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (var i = 0; i < laterTodayDoses.length; i++) ...[
            DueDoseCard(
              dose: laterTodayDoses[i],
              onAdminister: () => onAdminister(laterTodayDoses[i].id),
              onNotGiven: () => onNotGiven(laterTodayDoses[i].id),
            ),
            if (i != laterTodayDoses.length - 1)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          ],
        ],
      ],
    );
  }
}

class _TimeTrailing extends StatelessWidget {
  final String timeLabel;

  const _TimeTrailing({required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgIcon(AppAssets.clock, size: 12, color: AppColors.textMuted),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
        Text(
          timeLabel,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
