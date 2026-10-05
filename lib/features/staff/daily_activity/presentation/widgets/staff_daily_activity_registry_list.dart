import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_daily_activity_item.dart';
import '../../domain/entities/staff_daily_activity_overview.dart';

/// Client Activity Registry list (mobile card layout matching web columns).
class StaffDailyActivityRegistryList extends StatelessWidget {
  final StaffDailyActivityOverview overview;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int>? onLimitChanged;

  const StaffDailyActivityRegistryList({
    super.key,
    required this.overview,
    this.onPrev,
    this.onNext,
    this.onLimitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pending = overview.metrics.pendingReview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Client Activity Registry',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$pending pending review',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Most recent activity first.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (overview.items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'No activities match these filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          ...overview.items.map((item) => _ActivityCard(item: item)),
        if (overview.total > 0) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          _Pagination(
            overview: overview,
            onPrev: onPrev,
            onNext: onNext,
            onLimitChanged: onLimitChanged,
          ),
        ],
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final StaffDailyActivityItem item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 10),
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.activityCode,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              _Pill(
                label: item.statusLabel,
                background: AppColors.activeBackground,
                foreground: AppColors.activeGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.residentName,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textHeading,
            ),
          ),
          if (item.residenceName.isNotEmpty)
            Text(
              item.residenceName,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                label: item.activityTypeLabel,
                background: AppColors.infoBackground,
                foreground: AppColors.infoBlue,
              ),
              Text(
                item.dateTimeLabel,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.secondaryTeal,
                child: Text(
                  item.recordedByInitials,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.recordedByName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: foreground,
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final StaffDailyActivityOverview overview;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int>? onLimitChanged;

  const _Pagination({
    required this.overview,
    this.onPrev,
    this.onNext,
    this.onLimitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = overview.total == 0
        ? 0
        : ((overview.page - 1) * overview.limit) + 1;
    final end = (overview.page * overview.limit).clamp(0, overview.total);
    return Column(
      children: [
        Text(
          'Showing $start to $end of ${overview.total} entries',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: overview.page > 1 ? onPrev : null,
              child: const Text('‹ Prev'),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.searchBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${overview.page}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed:
                  overview.page < overview.totalPages ? onNext : null,
              child: const Text('Next ›'),
            ),
            const Spacer(),
            DropdownButton<int>(
              value: overview.limit,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10 / Page')),
                DropdownMenuItem(value: 20, child: Text('20 / Page')),
                DropdownMenuItem(value: 50, child: Text('50 / Page')),
              ],
              onChanged: onLimitChanged == null
                  ? null
                  : (v) {
                      if (v != null) onLimitChanged!(v);
                    },
            ),
          ],
        ),
      ],
    );
  }
}
