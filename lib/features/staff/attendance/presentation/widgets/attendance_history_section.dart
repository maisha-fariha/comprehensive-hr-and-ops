import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

class _HistoryItem {
  final String dateLabel;
  final String timeRange;
  final String durationLabel;

  const _HistoryItem({
    required this.dateLabel,
    required this.timeRange,
    required this.durationLabel,
  });
}

/// UI-hardcoded rows from the Attendance History reference.
const List<_HistoryItem> _historyItems = [
  _HistoryItem(
    dateLabel: 'Mon, May 12',
    timeRange: '7:01 AM – 3:02 PM',
    durationLabel: '8h 01m',
  ),
  _HistoryItem(
    dateLabel: 'Sun, May 11',
    timeRange: '3:00 PM – 11:04 PM',
    durationLabel: '8h 04m',
  ),
  _HistoryItem(
    dateLabel: 'Fri, May 9',
    timeRange: '7:00 AM – 3:00 PM',
    durationLabel: '8h 00m',
  ),
  _HistoryItem(
    dateLabel: 'Thu, May 8',
    timeRange: '7:03 AM – 2:58 PM',
    durationLabel: '7h 55m',
  ),
];
/// "Attendance History" heading + white card listing past shifts.
class AttendanceHistorySection extends StatelessWidget {
  const AttendanceHistorySection({super.key});

  static const Color _primary = Color(0xFF1A202C);
  static const Color _secondary = Color(0xFF718096);
  static const Color _divider = Color(0xFFEDF2F7);

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Attendance History',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
            color: _primary,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.04),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < _historyItems.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 1, color: _divider),
                _HistoryRow(item: _historyItems[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final _HistoryItem item;

  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AttendanceHistorySection._primary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Text(
                  item.timeRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AttendanceHistorySection._secondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.durationLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AttendanceHistorySection._primary,
                  height: 1.2,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
              Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                  color: AttendanceHistorySection._secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
