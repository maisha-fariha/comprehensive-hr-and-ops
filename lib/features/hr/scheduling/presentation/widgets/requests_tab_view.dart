import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/requests_overview.dart';
import '../../scheduling_constants.dart';
import 'request_card.dart';

/// The Requests tab's content: a "Pending" section (with Decline/Approve
/// actions) followed by an "Approved" section (read-only).
class RequestsTabView extends StatelessWidget {
  final RequestsOverview data;

  const RequestsTabView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.getResponsiveWidth(
      context,
      SchedulingDimens.screenPaddingHorizontal,
    );

    return ColoredBox(
      color: AppColors.scaffoldBackground,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          ResponsiveHelper.getResponsiveHeight(context, 18),
          horizontalPadding,
          ResponsiveHelper.getResponsiveHeight(context, 24),
        ),
        children: [
          if (data.pendingRequests.isNotEmpty) ...[
            _RequestsSectionHeader(title: 'Pending', count: data.pendingRequests.length),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            for (final request in data.pendingRequests) RequestCard(request: request),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          ],
          if (data.approvedRequests.isNotEmpty) ...[
            _RequestsSectionHeader(title: 'Approved', count: data.approvedRequests.length),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            for (final request in data.approvedRequests) RequestCard(request: request),
          ],
        ],
      ),
    );
  }
}

class _RequestsSectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _RequestsSectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Container(
          constraints: const BoxConstraints(minWidth: 19),
          height: ResponsiveHelper.getResponsiveSize(context, 19),
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6.4),
          decoration: const BoxDecoration(
            color: AppColors.dividerLight,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
