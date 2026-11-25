import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/ai_report.dart';
import '../ai_alerts_styles.dart';

class AiReportListTile extends StatelessWidget {
  final AiReportListItem item;
  final bool selected;
  final VoidCallback onTap;

  const AiReportListTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = aiSeverityStyle(item.severity);
    final residence = item.residence?.name ?? '';
    final time = aiReportTimeLabel(item.createdAt ?? item.sharedAt);
    final unread = !item.read;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.infoBackground.withValues(alpha: 0.55)
            : AppColors.surfaceWhite,
        elevation: unread ? 0.5 : 0,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          // Left severity bar via Border — avoid Row.stretch in a sliver
          // (unbounded height → size MISSING → paint null-check crash).
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? AppColors.infoBlue.withValues(alpha: 0.35)
                    : AppColors.cardBorder,
                width: selected ? 1.2 : 1,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(color: style.bar, width: 4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label ?? item.kind,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: handoverText(
                            context,
                            11.5,
                            weight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.infoBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: handoverText(
                      context,
                      14.5,
                      weight: unread ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (residence.isNotEmpty || time.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (residence.isNotEmpty) residence,
                        if (time.isNotEmpty) time,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: handoverText(
                        context,
                        12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  if (item.waitingOnYou) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Waiting on you',
                      style: handoverText(
                        context,
                        11.5,
                        weight: FontWeight.w600,
                        color: AppColors.urgentAmber,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
