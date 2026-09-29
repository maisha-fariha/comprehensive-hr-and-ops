import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/staff_house_activity_entry.dart';

/// House activity tab — `GET /client-activities` for the selected residence.
class StaffHouseActivityTabView extends StatelessWidget {
  final bool hasResidence;
  final List<StaffHouseActivityEntry> activities;
  final int totalCount;

  const StaffHouseActivityTabView({
    super.key,
    required this.hasResidence,
    required this.activities,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        ),
        ResponsiveHelper.getResponsiveHeight(context, 8),
        ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        ),
        ResponsiveHelper.getResponsiveHeight(context, 32),
      ),
      children: [
        if (!hasResidence)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Text(
                  'Choose a residence to begin',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 16),
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Daily logs are read one residence at a time.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'House activity',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Text(
                '${activities.length} shown · $totalCount total',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.secondaryTeal,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No house activities for this residence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final item in activities) _ActivityCard(entry: item),
        ],
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final StaffHouseActivityEntry entry;

  const _ActivityCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 10),
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.clientName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.quickActionCreateShiftBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.status.isEmpty ? '—' : entry.status,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              entry.activityType,
              entry.dateLabel,
              if (entry.authorName.isNotEmpty) entry.authorName,
            ].where((s) => s.isNotEmpty).join(' · '),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.notes,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textBody,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
