import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/board_overview.dart';
import '../../scheduling_constants.dart';
import 'board_coverage_tile.dart';
import 'board_open_position_card.dart';
import 'board_shift_card.dart';

/// The Board tab's content: a "Today's Coverage" summary row, the detailed
/// "Coverage Board" shift cards, and the "Open Positions" list.
class BoardTabView extends StatelessWidget {
  final BoardOverview data;

  const BoardTabView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.getResponsiveWidth(
      context,
      SchedulingDimens.screenPaddingHorizontal,
    );

    return ColoredBox(
      color: AppColors.scaffoldBackground,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          ResponsiveHelper.getResponsiveHeight(context, 18),
          horizontalPadding,
          ResponsiveHelper.getResponsiveHeight(context, 24),
        ),
        children: [
          const SectionHeaderRow(title: "Today's Coverage"),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < data.coverageSummaries.length; i++) ...[
                if (i != 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                Expanded(child: BoardCoverageTile(summary: data.coverageSummaries[i])),
              ],
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
          const SectionHeaderRow(title: 'Coverage Board'),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          for (final shift in data.shifts) BoardShiftCard(shift: shift),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          const SectionHeaderRow(title: 'Open Positions'),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          for (var i = 0; i < data.openPositions.length; i++) ...[
            if (i != 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            BoardOpenPositionCard(position: data.openPositions[i]),
          ],
        ],
      ),
    );
  }
}
