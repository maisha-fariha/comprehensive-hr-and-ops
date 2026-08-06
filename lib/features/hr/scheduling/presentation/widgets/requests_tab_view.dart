import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/requests_overview.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/shift_request.dart';
import '../../scheduling_constants.dart';
import 'request_card.dart';

/// UI-only Declined card from the reference (not in domain/repository).
const ShiftRequest _declinedPreview = ShiftRequest(
  id: 'req-chris-declined',
  staffName: 'Chris B.',
  staffInitials: 'CB',
  status: RequestStatus.approved,
  timingLabel: 'Declined · conflict',
  givingLabel: 'Sat May 17 · Morning',
  receivingLabel: 'Sun May 18 · Morning',
);

class _OpenShiftPreview {
  final String title;
  final String subtitle;
  final String badgeLabel;
  final bool isUrgent;
  final String asset;
  final Color iconColor;
  final Color iconBackground;

  const _OpenShiftPreview({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.isUrgent,
    required this.asset,
    required this.iconColor,
    required this.iconBackground,
  });
}

const List<_OpenShiftPreview> _openShiftPreviews = [
  _OpenShiftPreview(
    title: 'Night Shift',
    subtitle: 'Pinecrest Manor · Need 1 RN',
    badgeLabel: 'Urgent',
    isUrgent: true,
    asset: 'assets/icons/dashboard/moon.svg',
    iconColor: Color(0xFF6A4BC7),
    iconBackground: Color(0xFFF0ECFB),
  ),
  _OpenShiftPreview(
    title: 'Evening Shift',
    subtitle: 'Sunrise Home · Need 1 CNA',
    badgeLabel: 'Open',
    isUrgent: false,
    asset: 'assets/icons/dashboard/clock.svg',
    iconColor: Color(0xFFB4791C),
    iconBackground: Color(0xFFFCF5ED),
  ),
];

/// The Requests tab content: Pending, Approved, Declined, and Open Shift
/// Requests sections.
class RequestsTabView extends StatelessWidget {
  final RequestsOverview data;

  const RequestsTabView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.getResponsiveWidth(
      context,
      SchedulingDimens.screenPaddingHorizontal,
    );
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 16);

    return ColoredBox(
      color: AppColors.scaffoldBackground,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          ResponsiveHelper.getResponsiveHeight(context, 16),
          horizontalPadding,
          ResponsiveHelper.getResponsiveHeight(context, 24),
        ),
        children: [
          if (data.pendingRequests.isNotEmpty) ...[
            _RequestsSectionHeader(
              title: 'Pending',
              count: data.pendingRequests.length,
              badgeColor: const Color(0xFFB4791C),
              badgeBackground: const Color(0xFFFCF5ED),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (final request in data.pendingRequests) RequestCard(request: request),
            SizedBox(height: sectionGap),
          ],
          if (data.approvedRequests.isNotEmpty) ...[
            _RequestsSectionHeader(
              title: 'Approved',
              count: data.approvedRequests.length,
              badgeColor: const Color(0xFF2E8C58),
              badgeBackground: const Color(0xFFEAF6F0),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (final request in data.approvedRequests) RequestCard(request: request),
            SizedBox(height: sectionGap),
          ],
          _RequestsSectionHeader(
            title: 'Declined',
            count: 1,
            badgeColor: AppColors.textSecondary,
            badgeBackground: const Color(0xFFF1F5F9),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          const RequestCard(
            request: _declinedPreview,
            visualStatus: RequestCardStatus.declined,
          ),
          SizedBox(height: sectionGap),
          Text(
            'Open Shift Requests',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (var i = 0; i < _openShiftPreviews.length; i++) ...[
            if (i > 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            _OpenShiftRequestCard(item: _openShiftPreviews[i]),
          ],
        ],
      ),
    );
  }
}

class _RequestsSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color badgeColor;
  final Color badgeBackground;

  const _RequestsSectionHeader({
    required this.title,
    required this.count,
    required this.badgeColor,
    required this.badgeBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
              color: AppColors.textHeading,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Container(
          constraints: BoxConstraints(
            minWidth: ResponsiveHelper.getResponsiveSize(context, 20),
          ),
          height: ResponsiveHelper.getResponsiveSize(context, 20),
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6),
          decoration: BoxDecoration(
            color: badgeBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: badgeColor,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _OpenShiftRequestCard extends StatelessWidget {
  final _OpenShiftPreview item;

  const _OpenShiftRequestCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final boxSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final badgeColor = item.isUrgent ? const Color(0xFFD64545) : const Color(0xFFB4791C);
    final badgeBackground =
        item.isUrgent ? const Color(0xFFFBEDED) : const Color(0xFFFCF5ED);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: item.iconBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(item.asset, size: 18, color: item.iconColor),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                          color: AppColors.textHeading,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                    Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.badgeLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                          color: badgeColor,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F3F1),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 10),
              ),
            ),
            child: Text(
              'Assign',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.secondaryTeal,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
