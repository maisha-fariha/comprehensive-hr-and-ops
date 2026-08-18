import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/compliance_summary.dart';

/// Dark "Overall Compliance" hero card — matched to the close-up reference.
class ComplianceOverviewCard extends StatelessWidget {
  final ComplianceSummary summary;

  static const Color _cardNavy = Color(0xFF172436);
  static const Color _ringTrack = Color(0xFF2C3E50);
  static const Color _ringProgress = Color(0xFF44AB6F);
  static const Color _description = Color(0xFF9EADBA);
  static const Color _trendBg = Color(0xFF213540);

  const ComplianceOverviewCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final ringSize = ResponsiveHelper.getResponsiveSize(context, 96);
    final stroke = ResponsiveHelper.getResponsiveSize(context, 10);
    final progress = (summary.percent.clamp(0, 100)) / 100;

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 18,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: CustomPaint(
              painter: _ComplianceRingPainter(
                progress: progress,
                trackColor: _ringTrack,
                progressColor: _ringProgress,
                strokeWidth: stroke,
              ),
              child: Center(
                child: Text(
                  '${summary.percent}%',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Overall Compliance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                Text(
                  summary.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: _description,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _trendBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: ResponsiveHelper.getResponsiveSize(context, 16),
                        color: _ringProgress,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 2)),
                      Flexible(
                        child: Text(
                          summary.trendLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: _ringProgress,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thick donut progress ring that starts at the top and sweeps clockwise.
class _ComplianceRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _ComplianceRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      // Start at top (−90°) and draw clockwise.
      canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ComplianceRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
