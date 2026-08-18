import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/due_dose.dart';
import 'due_dose_card.dart';

/// Content of the "Due" tab: "Due Now" then "Later Today" dose lists.
class DueTabView extends StatelessWidget {
  final List<DueDose> dueNowDoses;
  final List<DueDose> laterTodayDoses;
  final ValueChanged<String> onAdminister;
  final ValueChanged<String> onNotGiven;

  static const Color _titleColor = Color(0xFF1A2B48);

  /// Mint pill used on "Due Now".
  static const Color _dueNowPillBg = Color(0xFFE8F6EF);
  static const Color _dueNowPillFg = Color(0xFF2D8A56);

  /// Peach pill used on "Later Today" (reference).
  static const Color _laterTodayPillBg = Color(0xFFFFF0D8);
  static const Color _laterTodayPillFg = Color(0xFFC26E00);

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
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20),),
        if (dueNowDoses.isNotEmpty) ...[
          _SectionHeader(
            title: 'Due Now',
            timeLabel: dueNowDoses.first.timeLabel,
            pillBackground: _dueNowPillBg,
            pillForeground: _dueNowPillFg,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          for (var i = 0; i < dueNowDoses.length; i++) ...[
            DueDoseCard(
              dose: dueNowDoses[i],
              onAdminister: () => onAdminister(dueNowDoses[i].id),
              onNotGiven: () => onNotGiven(dueNowDoses[i].id),
            ),
            if (i != dueNowDoses.length - 1)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          ],
        ],
        if (laterTodayDoses.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          _SectionHeader(
            title: 'Later Today',
            timeLabel: laterTodayDoses.first.timeLabel,
            pillBackground: _laterTodayPillBg,
            pillForeground: _laterTodayPillFg,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          for (var i = 0; i < laterTodayDoses.length; i++) ...[
            DueDoseCard(
              dose: laterTodayDoses[i],
              onAdminister: () => onAdminister(laterTodayDoses[i].id),
              onNotGiven: () => onNotGiven(laterTodayDoses[i].id),
            ),
            if (i != laterTodayDoses.length - 1)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String timeLabel;
  final Color pillBackground;
  final Color pillForeground;

  const _SectionHeader({
    required this.title,
    required this.timeLabel,
    required this.pillBackground,
    required this.pillForeground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: DueTabView._titleColor,
              height: 1.2,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Container(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: pillBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            timeLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: pillForeground,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
