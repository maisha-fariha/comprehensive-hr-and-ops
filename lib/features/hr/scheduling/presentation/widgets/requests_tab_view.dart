import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/open_position.dart';
import '../../domain/entities/requests_overview.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/shift_request.dart';
import 'request_card.dart';

/// The Requests tab content: Pending, Approved, Declined, and Open Shift
/// Requests sections — all driven by API data.
class RequestsTabView extends StatelessWidget {
  final RequestsOverview data;
  final void Function(ShiftRequest request)? onApprove;
  final void Function(ShiftRequest request)? onDecline;

  const RequestsTabView({
    super.key,
    required this.data,
    this.onApprove,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.getResponsiveWidth(
      context,
      20,
    );
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 16);
    final hasAny = data.pendingRequests.isNotEmpty ||
        data.approvedRequests.isNotEmpty ||
        data.declinedRequests.isNotEmpty ||
        data.openShiftRequests.isNotEmpty;

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
          if (!hasAny)
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveHelper.getResponsiveHeight(context, 48),
              ),
              child: Text(
                'No shift requests right now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (data.pendingRequests.isNotEmpty) ...[
            _RequestsSectionHeader(
              title: 'Pending',
              count: data.pendingRequests.length,
              badgeColor: const Color(0xFFB4791C),
              badgeBackground: const Color(0xFFFCF5ED),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (final request in data.pendingRequests)
              RequestCard(
                request: request,
                onApprove: onApprove == null ? null : () => onApprove!(request),
                onDecline: onDecline == null ? null : () => onDecline!(request),
              ),
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
            for (final request in data.approvedRequests)
              RequestCard(request: request),
            SizedBox(height: sectionGap),
          ],
          if (data.declinedRequests.isNotEmpty) ...[
            _RequestsSectionHeader(
              title: 'Declined',
              count: data.declinedRequests.length,
              badgeColor: AppColors.textSecondary,
              badgeBackground: const Color(0xFFF1F5F9),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (final request in data.declinedRequests)
              RequestCard(
                request: request,
                visualStatus: RequestCardStatus.declined,
              ),
            SizedBox(height: sectionGap),
          ],
          if (data.openShiftRequests.isNotEmpty) ...[
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
            for (var i = 0; i < data.openShiftRequests.length; i++) ...[
              if (i > 0)
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
              _OpenShiftRequestCard(item: data.openShiftRequests[i]),
            ],
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
  final OpenPosition item;

  const _OpenShiftRequestCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final boxSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final isUrgent = item.urgency == OpenPositionUrgency.urgent;
    final badgeColor = isUrgent ? const Color(0xFFD64545) : const Color(0xFFB4791C);
    final badgeBackground =
        isUrgent ? const Color(0xFFFBEDED) : const Color(0xFFFCF5ED);
    final iconColor = isUrgent ? const Color(0xFF6A4BC7) : const Color(0xFFB4791C);
    final iconBackground =
        isUrgent ? const Color(0xFFF0ECFB) : const Color(0xFFFCF5ED);
    final asset = isUrgent
        ? 'assets/icons/dashboard/moon.svg'
        : 'assets/icons/dashboard/clock.svg';

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
              color: iconBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(asset, size: 18, color: iconColor),
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
                        item.roleTitle,
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
                        isUrgent ? 'Urgent' : 'Open',
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
        ],
      ),
    );
  }
}
