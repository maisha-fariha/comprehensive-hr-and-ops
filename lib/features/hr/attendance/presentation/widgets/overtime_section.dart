import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/overtime_entry.dart';
import 'overtime_card.dart';

/// "Overtime Tracking · This week" heading + the vertical list of overtime
/// cards on the "OT" tab.
class OvertimeSection extends StatelessWidget {
  final List<OvertimeEntry> entries;
  final ValueChanged<OvertimeEntry>? onEntryTap;

  const OvertimeSection({super.key, required this.entries, this.onEntryTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Overtime Tracking',
              style: AppTextStyles.heading3.copyWith(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Text(
              '· This week',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < entries.length; i++) ...[
          if (i != 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          OvertimeCard(
            entry: entries[i],
            onTap: onEntryTap == null ? null : () => onEntryTap!(entries[i]),
          ),
        ],
      ],
    );
  }
}
