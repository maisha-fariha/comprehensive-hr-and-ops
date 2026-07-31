import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/staff_status_entry.dart';
import 'staff_status_tile.dart';

/// "Staff Status" heading (with the "17 on duty" trailing label) + the
/// vertical list of staff cards on the "Today" tab.
class StaffStatusSection extends StatelessWidget {
  final String onDutyLabel;
  final List<StaffStatusEntry> entries;
  final ValueChanged<StaffStatusEntry>? onEntryTap;

  const StaffStatusSection({
    super.key,
    required this.onDutyLabel,
    required this.entries,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(
          title: 'Staff Status',
          trailing: Text(
            onDutyLabel,
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
          StaffStatusTile(
            entry: entries[i],
            onTap: onEntryTap == null ? null : () => onEntryTap!(entries[i]),
          ),
        ],
      ],
    );
  }
}
