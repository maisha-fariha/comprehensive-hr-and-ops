import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../domain/entities/task_analytics.dart';

/// Web Task Management charts: category summary, status breakdown, trend.
class TaskAnalyticsSection extends StatelessWidget {
  final TaskAnalytics analytics;

  const TaskAnalyticsSection({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveHeight(context, 10);
    return Column(
      children: [
        _CategorySummaryCard(analytics: analytics),
        SizedBox(height: gap),
        _StatusBreakdownCard(analytics: analytics),
        SizedBox(height: gap),
        _TrendCard(analytics: analytics),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          child,
        ],
      ),
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  final TaskAnalytics analytics;

  const _CategorySummaryCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final percent = (analytics.overallCompletedFraction * 100).round();
    return _Panel(
      title: 'Task Category Summary',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveSize(context, 88),
            height: ResponsiveHelper.getResponsiveSize(context, 88),
            child: CustomPaint(
              painter: _RingPainter(
                progress: analytics.overallCompletedFraction,
                color: AppColors.secondaryTeal,
              ),
              child: Center(
                child: Text(
                  '$percent%\nCompleted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: AppColors.textHeading,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
          Expanded(
            child: analytics.byType.isEmpty
                ? Text(
                    'No category data yet.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textMuted,
                    ),
                  )
                : Column(
                    children: [
                      for (final row in analytics.byType) ...[
                        _CategoryBar(row: row),
                        SizedBox(
                          height:
                              ResponsiveHelper.getResponsiveHeight(context, 8),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final TaskTypeBreakdown row;

  const _CategoryBar({required this.row});

  @override
  Widget build(BuildContext context) {
    final fraction = row.total <= 0 ? 0.0 : row.completed / row.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Text(
              '${row.completed}/${row.total} · ${row.percent}%',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFE8EEF2),
            color: AppColors.secondaryTeal,
          ),
        ),
      ],
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  final TaskAnalytics analytics;

  const _StatusBreakdownCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final total = math.max(analytics.statusTotal, 1);
    return _Panel(
      title: 'Task Status Breakdown',
      child: Row(
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveSize(context, 110),
            height: ResponsiveHelper.getResponsiveSize(context, 110),
            child: CustomPaint(
              painter: _DonutPainter(
                slices: [
                  _Slice(
                    analytics.statusCompleted / total,
                    const Color(0xFF2E8C58),
                  ),
                  _Slice(
                    analytics.statusPending / total,
                    const Color(0xFF9AE6B4),
                  ),
                  _Slice(
                    analytics.statusOverdue / total,
                    const Color(0xFFD64545),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${analytics.statusCompleted}\nCompleted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                  color: const Color(0xFF2E8C58),
                  label: 'Completed',
                  value: analytics.statusCompleted,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                _LegendRow(
                  color: const Color(0xFF9AE6B4),
                  label: 'Pending',
                  value: analytics.statusPending,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                _LegendRow(
                  color: const Color(0xFFD64545),
                  label: 'Overdue',
                  value: analytics.statusOverdue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textBody,
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: AppColors.textHeading,
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  final TaskAnalytics analytics;

  const _TrendCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final change = analytics.trendChangePercent;
    final badge = change == null
        ? null
        : '${change.abs()}% ${change <= 0 ? 'decrease' : 'increase'}';
    return _Panel(
      title: 'Task Trend (Over Time)',
      trailing: badge == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6F0),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                  color: const Color(0xFF2E8C58),
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: ResponsiveHelper.getResponsiveHeight(context, 120),
            child: CustomPaint(
              painter: _TrendPainter(
                points: [
                  for (final point in analytics.trend) point.completed.toDouble(),
                ],
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
          if (analytics.trend.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final point in analytics.trend)
                  Flexible(
                    child: Text(
                      WebFormat.date(point.weekStart),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 9.5),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final track = Paint()
      ..color = const Color(0xFFE8EEF2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _Slice {
  final double fraction;
  final Color color;
  const _Slice(this.fraction, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_Slice> slices;

  _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    var drawn = false;
    for (final slice in slices) {
      if (slice.fraction <= 0) continue;
      drawn = true;
      paint.color = slice.color;
      final sweep = 2 * math.pi * slice.fraction.clamp(0.0, 1.0);
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
    if (!drawn) {
      paint.color = const Color(0xFFE8EEF2);
      canvas.drawCircle(center, radius, paint);
    }
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.62, paint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class _TrendPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _TrendPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxY = points.reduce(math.max).clamp(1, double.infinity);
    final dx = points.length == 1 ? 0.0 : size.width / (points.length - 1);
    final path = Path();
    final fill = Path();
    for (var i = 0; i < points.length; i++) {
      final x = dx * i;
      final y = size.height - (points[i] / maxY) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = color;
    for (var i = 0; i < points.length; i++) {
      final x = dx * i;
      final y = size.height - (points[i] / maxY) * (size.height - 8) - 4;
      canvas.drawCircle(Offset(x, y), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}
