import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/schedule_dose.dart';
import 'schedule_dose_tile.dart';
import 'schedule_period_selector.dart';

/// Content of the "Due" tab: the "Today's Medication Schedule" title block,
/// the Today/Morning/Afternoon/Evening filter chips, the "Priority
/// Medications" list and the "Later Today" list.
class DueTabView extends StatelessWidget {
  final String title;
  final String subtitle;
  final SchedulePeriod selectedPeriod;
  final ValueChanged<SchedulePeriod> onPeriodSelected;
  final List<ScheduleDose> priorityDoses;
  final List<ScheduleDose> laterTodayDoses;

  const DueTabView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedPeriod,
    required this.onPeriodSelected,
    required this.priorityDoses,
    required this.laterTodayDoses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
        SchedulePeriodSelector(selected: selectedPeriod, onSelected: onPeriodSelected),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
        if (priorityDoses.isNotEmpty) ...[
          _SectionCaption(
            dotColor: AppColors.criticalRed,
            title: 'Priority Medications',
            suffix: ' · Due within 30 min',
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (var i = 0; i < priorityDoses.length; i++) ...[
            ScheduleDoseTile(dose: priorityDoses[i]),
            if (i != priorityDoses.length - 1)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          ],
        ],
        if (laterTodayDoses.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
          const _SectionCaption(dotColor: AppColors.infoBlue, title: 'Later Today'),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (var i = 0; i < laterTodayDoses.length; i++) ...[
            ScheduleDoseTile(dose: laterTodayDoses[i]),
            if (i != laterTodayDoses.length - 1)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          ],
        ],
      ],
    );
  }
}

class _SectionCaption extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String suffix;

  const _SectionCaption({required this.dotColor, required this.title, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: ResponsiveHelper.getResponsiveSize(context, 7),
          height: ResponsiveHelper.getResponsiveSize(context, 7),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textPrimary,
                  ),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
