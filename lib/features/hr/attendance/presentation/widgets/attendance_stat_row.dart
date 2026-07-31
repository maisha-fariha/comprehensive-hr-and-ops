import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/attendance_stat.dart';
import 'attendance_stat_card.dart';

/// Row of [AttendanceStatCard] tiles shown at the top of every Attendance
/// tab. Figma shows these as a single row (4-up on "Today", 3-up on the
/// other tabs) rather than a wrapping grid, so a plain `Row` of `Expanded`
/// tiles is used - matching `QuickActionsSection`'s pattern in the
/// Dashboard feature.
class AttendanceStatRow extends StatelessWidget {
  final List<AttendanceStat> stats;

  const AttendanceStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i != 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(child: AttendanceStatCard(stat: stats[i])),
        ],
      ],
    );
  }
}
