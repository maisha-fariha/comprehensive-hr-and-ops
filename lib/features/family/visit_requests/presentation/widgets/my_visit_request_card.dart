import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/my_visit_request.dart';
import 'visit_request_status_style.dart';
import 'visit_request_type_tag.dart';

/// A single request card shown on the "My Requests" tab - fuller than the
/// "All"/"History" tabs' rows: a colored status dot + date/time line, the
/// type tag, a status pill top-right, a description/notes line, and a
/// "View Request Details" link at the bottom.
class MyVisitRequestCard extends StatelessWidget {
  final MyVisitRequest request;
  final VoidCallback? onViewDetails;

  const MyVisitRequestCard({super.key, required this.request, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final statusStyle = VisitRequestStatusStyle.of(request.status);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 8),
                      height: ResponsiveHelper.getResponsiveSize(context, 8),
                      decoration: BoxDecoration(color: statusStyle.color, shape: BoxShape.circle),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                    Flexible(
                      child: Text(
                        request.dateTimeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                          color: AppColors.textHeading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              StatusBadge.pill(
                label: statusStyle.label,
                background: statusStyle.background,
                foreground: statusStyle.color,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          VisitRequestTypeTag(type: request.type),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(
            request.description,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textBody,
              height: 1.35,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          _ViewRequestDetailsButton(onTap: onViewDetails),
        ],
      ),
    );
  }
}

class _ViewRequestDetailsButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ViewRequestDetailsButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 12),
          ),
          child: Container(
            padding: ResponsiveHelper.getResponsivePadding(context, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Request Details',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.secondaryTeal,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                Icon(
                  Icons.chevron_right_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 18),
                  color: AppColors.secondaryTeal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
