import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/schedule_shift.dart';
import 'schedule_shift_tile.dart';

/// "Today's Schedule" card: heading + a vertical timeline of shifts.
class TodaysScheduleCard extends StatelessWidget {
  final List<ScheduleShift> shifts;
  final VoidCallback? onViewAll;

  const TodaysScheduleCard({super.key, required this.shifts, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, left: 17, right: 17, top: 27, bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderRow(
            title: "Today's Schedule",
            trailing: ViewAllLink(onTap: onViewAll),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (final shift in shifts) ScheduleShiftTile(shift: shift),
        ],
      ),
    );
  }
}
