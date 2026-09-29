import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_document.dart';

class StaffDocumentsBottomPanels extends StatelessWidget {
  final StaffDocumentsSummary summary;
  final VoidCallback onSeeGaps;
  final VoidCallback? onViewRestricted;

  const StaffDocumentsBottomPanels({
    super.key,
    required this.summary,
    required this.onSeeGaps,
    this.onViewRestricted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoriesCard(slices: summary.byType),
        const SizedBox(height: 12),
        _ComplianceCard(
          missing: summary.missingMandatory,
          restricted: summary.restricted,
          onSeeGaps: onSeeGaps,
          onViewRestricted: onViewRestricted,
        ),
      ],
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  final List<StaffDocumentCategorySlice> slices;

  const _CategoriesCard({required this.slices});

  static const _palette = [
    AppColors.infoBlue,
    AppColors.secondaryTeal,
    AppColors.urgentAmber,
    AppColors.nightPurple,
    AppColors.activeGreen,
  ];

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (sum, s) => sum + s.count);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Categories',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutPainter(
                    slices: slices,
                    colors: _palette,
                    total: total,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const Text(
                          'DOCUMENTS',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (slices.isEmpty)
                      const Text(
                        'No category data yet.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textMuted,
                        ),
                      )
                    else
                      for (var i = 0; i < slices.length; i++) ...[
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _palette[i % _palette.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                slices[i].name,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5,
                                  color: AppColors.textHeading,
                                ),
                              ),
                            ),
                            Text(
                              '${slices[i].count}${total == 0 ? '' : ' (${((slices[i].count / total) * 100).round()}%)'}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (i < slices.length - 1) const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  final int missing;
  final int restricted;
  final VoidCallback onSeeGaps;
  final VoidCallback? onViewRestricted;

  const _ComplianceCard({
    required this.missing,
    required this.restricted,
    required this.onSeeGaps,
    this.onViewRestricted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Alerts',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          _AlertRow(
            count: missing,
            color: AppColors.criticalRed,
            text:
                '$missing missing required documents. Mandatory types nobody has filed for these people.',
            actionLabel: 'See gaps',
            onAction: onSeeGaps,
          ),
          const SizedBox(height: 10),
          _AlertRow(
            count: restricted,
            color: AppColors.nightPurple,
            text:
                '$restricted restricted files. Held in a band narrower than everyone.',
            actionLabel: 'View',
            onAction: onViewRestricted,
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final int count;
  final Color color;
  final String text;
  final String actionLabel;
  final VoidCallback? onAction;

  const _AlertRow({
    required this.count,
    required this.color,
    required this.text,
    required this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.textBody,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<StaffDocumentCategorySlice> slices;
  final List<Color> colors;
  final int total;

  _DonutPainter({
    required this.slices,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;

    if (total <= 0 || slices.isEmpty) {
      paint.color = AppColors.cardBorder;
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }

    var start = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final sweep = (slices[i].count / total) * math.pi * 2;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.total != total;
}
