import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/schedule_dose.dart';
import 'schedule_dose_tile.dart';
import 'schedule_period_selector.dart';

/// Content of the "Due" tab: schedule title, period chips, Priority
/// Medications and Later Today lists — matched to the Due tab reference.
class DueTabView extends StatelessWidget {
  final String title;
  final String subtitle;
  final SchedulePeriod selectedPeriod;
  final ValueChanged<SchedulePeriod> onPeriodSelected;
  final List<ScheduleDose> priorityDoses;
  final List<ScheduleDose> laterTodayDoses;

  static const Color _priorityTitle = Color(0xFF9B3A3A);
  static const Color _prioritySuffix = Color(0xFFB57A7A);
  static const Color _priorityDot = Color(0xFFD64545);
  static const Color _laterDot = Color(0xFF2A5DA6);

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
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                color: AppColors.textHeading,
                height: 1.2,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textMuted,
                height: 1.3,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            SchedulePeriodSelector(
              selected: selectedPeriod,
              onSelected: onPeriodSelected,
            ),
            if (priorityDoses.isNotEmpty) ...[
              SizedBox(height: sectionGap),
              const _SectionCaption(
                dotColor: _priorityDot,
                title: 'Priority Medications',
                titleColor: _priorityTitle,
                suffix: ' · Due within 30 min',
                suffixColor: _prioritySuffix,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
              for (var i = 0; i < priorityDoses.length; i++) ...[
                if (i > 0) SizedBox(height: cardGap),
                ScheduleDoseTile(dose: priorityDoses[i], isPriority: true),
              ],
            ],
            if (laterTodayDoses.isNotEmpty) ...[
              SizedBox(height: sectionGap),
              const _SectionCaption(
                dotColor: _laterDot,
                title: 'Later Today',
                titleColor: AppColors.textHeading,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
              for (var i = 0; i < laterTodayDoses.length; i++) ...[
                if (i > 0) SizedBox(height: cardGap),
                ScheduleDoseTile(dose: laterTodayDoses[i]),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _SectionCaption extends StatelessWidget {
  final Color dotColor;
  final String title;
  final Color titleColor;
  final String suffix;
  final Color? suffixColor;

  const _SectionCaption({
    required this.dotColor,
    required this.title,
    required this.titleColor,
    this.suffix = '',
    this.suffixColor,
  });

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
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: titleColor,
                  ),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: suffixColor ?? AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
