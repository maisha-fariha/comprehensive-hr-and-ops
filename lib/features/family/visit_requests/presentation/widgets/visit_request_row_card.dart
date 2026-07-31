import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/family_visit_requests_enums.dart';
import '../../domain/entities/visit_request.dart';
import 'visit_request_status_style.dart';
import 'visit_request_type_tag.dart';

/// A single request row shown on both the "All" and "History" tabs of the
/// Visit Requests list.
///
/// The "All" tab's rows include a location-or-telehealth line (driven by
/// [VisitRequest.mode]); the "History" tab's rows omit that line entirely,
/// per the Figma screenshots - handled here by only rendering the line
/// when [VisitRequest.mode] is non-null.
///
/// Icon note: no location-pin/video-call glyphs exist in `assets/icons/*`
/// yet, so this uses Material `Icons.location_on_outlined` /
/// `Icons.videocam_outlined` as temporary stand-ins.
class VisitRequestRowCard extends StatelessWidget {
  final VisitRequest request;

  const VisitRequestRowCard({super.key, required this.request});

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
                child: Text(
                  request.requesterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                  ),
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
          if (request.mode != null) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            _ModeLine(mode: request.mode!, locationLabel: request.locationLabel),
          ],
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Row(
            children: [
              const AppSvgIcon(AppAssets.navCalendar, size: 14, color: AppColors.textFaint),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                request.dateTimeLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeLine extends StatelessWidget {
  final VisitRequestMode mode;
  final String? locationLabel;

  const _ModeLine({required this.mode, this.locationLabel});

  @override
  Widget build(BuildContext context) {
    final isTelehealth = mode == VisitRequestMode.telehealth;

    return Row(
      children: [
        Icon(
          isTelehealth ? Icons.videocam_outlined : Icons.location_on_outlined,
          size: ResponsiveHelper.getResponsiveSize(context, 14),
          color: AppColors.textFaint,
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
        Text(
          isTelehealth ? 'Telehealth' : (locationLabel ?? ''),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
