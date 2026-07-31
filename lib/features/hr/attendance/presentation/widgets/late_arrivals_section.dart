import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/late_arrival_entry.dart';
import 'late_arrival_card.dart';

/// "Late Arrivals" heading (with the "Today" trailing label) + the vertical
/// list of late-arrival cards on the "Late" tab.
class LateArrivalsSection extends StatelessWidget {
  final List<LateArrivalEntry> entries;
  final ValueChanged<LateArrivalEntry>? onEntryTap;

  const LateArrivalsSection({super.key, required this.entries, this.onEntryTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(
          title: 'Late Arrivals',
          trailing: Text(
            'Today',
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
          LateArrivalCard(
            entry: entries[i],
            onTap: onEntryTap == null ? null : () => onEntryTap!(entries[i]),
          ),
        ],
      ],
    );
  }
}
