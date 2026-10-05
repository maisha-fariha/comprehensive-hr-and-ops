import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import 'attendance_filters.dart';

/// "Showing X to Y of Z entries", Prev / page numbers / Next and "N / Page".
class AttendancePagination extends StatelessWidget {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<int> limitOptions;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onLimit;

  const AttendancePagination({
    super.key,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.limitOptions,
    required this.onPage,
    required this.onLimit,
  });

  List<int> get _visiblePages {
    if (totalPages <= 5) return [for (var i = 1; i <= totalPages; i++) i];
    var start = (page - 2).clamp(1, totalPages - 4);
    return [for (var i = start; i < start + 5; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    final first = total == 0 ? 0 : (page - 1) * limit + 1;
    final last = (page * limit).clamp(0, total);
    final style = TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w500,
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
      color: AppColors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Showing $first to $last of $total entries',
                style: style,
              ),
            ),
            GestureDetector(
              key: const ValueKey('attendance-page-size'),
              onTap: () async {
                final picked = await showAttendanceOptionSheet<int>(
                  context,
                  title: 'Rows per page',
                  options: limitOptions,
                  labelOf: (value) => '$value',
                  selected: limit,
                );
                if (picked != null) onLimit(picked.value);
              },
              child: Container(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  border: Border.all(color: AppColors.searchBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$limit / Page', style: style),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Wrap(
          runSpacing: 6,
          children: [
            _PageButton(
              key: const ValueKey('attendance-page-prev'),
              label: 'Prev',
              onTap: page > 1 ? () => onPage(page - 1) : null,
            ),
            for (final number in _visiblePages)
              _PageButton(
                key: ValueKey('attendance-page-$number'),
                label: '$number',
                selected: number == page,
                onTap: number == page ? null : () => onPage(number),
              ),
            _PageButton(
              key: const ValueKey('attendance-page-next'),
              label: 'Next',
              onTap: page < totalPages ? () => onPage(page + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _PageButton({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null || selected;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minWidth: ResponsiveHelper.getResponsiveSize(context, 30),
          ),
          height: ResponsiveHelper.getResponsiveSize(context, 30),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryNavy : AppColors.surfaceWhite,
            border: Border.all(
              color: selected ? AppColors.primaryNavy : AppColors.searchBorder,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: selected
                    ? Colors.white
                    : enabled
                        ? AppColors.textHeading
                        : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
