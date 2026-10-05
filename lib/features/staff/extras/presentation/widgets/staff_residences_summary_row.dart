import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_residence.dart';

/// Top summary strip matching web Residences Management KPI cards.
///
/// Residents / Beds free use active client count (`GET /clients?status=active`)
/// the same way the web KPI does — not a sum of `occupiedBeds`.
class StaffResidencesSummaryRow extends StatelessWidget {
  final List<StaffResidence> residences;
  final int activeResidentCount;

  const StaffResidencesSummaryRow({
    super.key,
    required this.residences,
    required this.activeResidentCount,
  });

  @override
  Widget build(BuildContext context) {
    final homes = residences.length;
    final active = residences.where((r) => r.isActive).length;
    final licensed = residences.fold<int>(
      0,
      (sum, r) => sum + (r.bedCapacity ?? 0),
    );
    final residents = activeResidentCount < 0 ? 0 : activeResidentCount;
    final free = licensed - residents;
    final bedsFree = free < 0 ? 0 : free;
    final atCapacity = residences.where((r) => r.atCapacity).length;

    final cards = [
      _SummaryData(
        label: 'Homes',
        value: '$homes',
        subtitle: '$active active',
      ),
      _SummaryData(
        label: 'Residents',
        value: '$residents',
        subtitle: 'Living in them today',
      ),
      _SummaryData(
        label: 'Beds free',
        value: '$bedsFree',
        subtitle: licensed > 0 ? 'Of $licensed licensed' : 'Licensed beds',
      ),
      _SummaryData(
        label: 'At capacity',
        value: '$atCapacity',
        subtitle: 'Homes that cannot take anyone',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = ResponsiveHelper.getResponsiveWidth(context, 8);
        final cardWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: cardWidth,
                child: _SummaryCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryData {
  final String label;
  final String value;
  final String subtitle;

  const _SummaryData({
    required this.label,
    required this.value,
    required this.subtitle,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            data.value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
              color: AppColors.textHeading,
              height: 1.1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
