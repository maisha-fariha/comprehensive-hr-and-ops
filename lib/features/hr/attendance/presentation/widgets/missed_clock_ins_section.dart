import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/missed_clock_in_entry.dart';
import 'missed_clock_in_card.dart';

/// "Missed Clock-Ins" heading (with the "Needs review" trailing label) +
/// the vertical list of missed-clock-in cards on the "Missed" tab.
class MissedClockInsSection extends StatelessWidget {
  final List<MissedClockInEntry> entries;
  final ValueChanged<MissedClockInEntry>? onReview;
  final ValueChanged<MissedClockInEntry>? onContact;

  const MissedClockInsSection({
    super.key,
    required this.entries,
    this.onReview,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(
          title: 'Missed Clock-Ins',
          trailing: Text(
            'Needs review',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textFaint,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < entries.length; i++) ...[
          if (i != 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          MissedClockInCard(
            entry: entries[i],
            onReview: onReview == null ? null : () => onReview!(entries[i]),
            onContact: onContact == null ? null : () => onContact!(entries[i]),
          ),
        ],
      ],
    );
  }
}
