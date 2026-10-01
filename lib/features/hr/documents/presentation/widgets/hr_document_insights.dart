import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_document_row.dart';
import 'hr_documents_common.dart';

Widget _cardHeader(BuildContext context, String title, {IconData? icon}) => Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primaryNavy),
            const SizedBox(width: 10),
          ],
          Text(title, style: handoverText(context, 15, weight: FontWeight.w700)),
        ],
      ),
    );

/// "Document Categories": donut of the summary `byType` with percentages.
class HrDocumentCategoriesCard extends StatelessWidget {
  final List<HrCategoryShare> categories;
  final int total;

  /// Only writers can open the types manager from here.
  final VoidCallback? onViewAll;

  const HrDocumentCategoriesCard({
    super.key,
    required this.categories,
    required this.total,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    Color colorOf(HrCategoryShare c) => hrCategoryColors[c.colorIndex % hrCategoryColors.length];
    return HandoverPanel(
      key: const ValueKey('documents-categories'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(context, 'Document Categories'),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(132),
                        painter: _DonutPainter([
                          for (final c in categories) (c.count.toDouble(), colorOf(c)),
                        ]),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(hrCount(total), style: handoverText(context, 19, weight: FontWeight.w700)),
                          Text(
                            'DOCUMENTS',
                            style: handoverText(
                              context,
                              10,
                              weight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < categories.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: i == categories.length - 1
                          ? null
                          : const Border(bottom: BorderSide(color: AppColors.cardBorder)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorOf(categories[i]),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            categories[i].label,
                            overflow: TextOverflow.ellipsis,
                            style: handoverText(context, 12.5),
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            text: '${categories[i].count} ',
                            children: [
                              TextSpan(
                                text: '(${categories[i].percent})',
                                style: handoverText(context, 12.5, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          style: handoverText(context, 12.5, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (onViewAll != null)
            InkWell(
              key: const ValueKey('documents-view-all-categories'),
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Text(
                  'View All Categories',
                  textAlign: TextAlign.center,
                  style: handoverText(
                    context,
                    12.5,
                    weight: FontWeight.w600,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> slices;

  _DonutPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 20.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final sum = slices.fold<double>(0, (a, s) => a + s.$1);
    if (sum <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = AppColors.filterButtonBackground);
      return;
    }
    var start = -math.pi / 2;
    for (final (value, color) in slices) {
      final sweep = value / sum * math.pi * 2;
      canvas.drawArc(rect, start, sweep, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => oldDelegate.slices != slices;
}

/// "Compliance Alerts": what is expired, missing, expiring or restricted.
class HrComplianceAlertsCard extends StatelessWidget {
  final List<HrComplianceAlert> alerts;
  final ValueChanged<HrComplianceAlert> onSelect;

  const HrComplianceAlertsCard({super.key, required this.alerts, required this.onSelect});

  static (Color, Color) _tone(HrAlertTone tone) => switch (tone) {
        HrAlertTone.critical => (AppColors.criticalRed, AppColors.criticalBackgroundSoft),
        HrAlertTone.warning => (AppColors.urgentAmber, AppColors.urgentBackground),
        HrAlertTone.secondary => (AppColors.secondaryTeal, AppColors.quickActionCreateShiftBg),
        HrAlertTone.purple => (AppColors.nightPurple, AppColors.nightBackground),
      };

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      key: const ValueKey('documents-alerts'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(context, 'Compliance Alerts', icon: Icons.shield_outlined),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nothing expiring, expired or missing. The registry is up to date.',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            ),
          for (var i = 0; i < alerts.length; i++)
            Container(
              key: ValueKey('documents-alert-${alerts[i].id}'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: i == alerts.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Builder(
                builder: (context) {
                  final alert = alerts[i];
                  final (fg, bg) = _tone(alert.tone);
                  return Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
                        child: Text(
                          '${alert.count}',
                          style: handoverText(context, 13, weight: FontWeight.w700, color: fg),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${alert.count} ${alert.title}',
                              style: handoverText(context, 13, weight: FontWeight.w600),
                            ),
                            Text(
                              alert.description,
                              style: handoverText(context, 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      HandoverButton(
                        key: ValueKey('documents-alert-action-${alert.id}'),
                        label: alert.actionLabel,
                        compact: true,
                        foreground: AppColors.secondaryTeal,
                        onPressed: () => onSelect(alert),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
