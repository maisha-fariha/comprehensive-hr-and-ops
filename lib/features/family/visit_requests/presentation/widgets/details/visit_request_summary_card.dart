import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/status_badge.dart';
import '../../../../../../core/widgets/surface_card.dart';
import '../../../domain/entities/visit_request_detail.dart';
import '../visit_request_status_style.dart';
import '../visit_request_type_tag.dart';
import 'visit_request_info_row.dart';

/// "Request Summary" card at the top of the Request Details screen: a type
/// tag + status pill row, then "Date & Time" and "Location / Mode" info
/// rows.
class VisitRequestSummaryCard extends StatelessWidget {
  final VisitRequestDetail detail;

  const VisitRequestSummaryCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final statusStyle = VisitRequestStatusStyle.of(detail.status);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VisitRequestTypeTag(type: detail.type, showIcon: true),
              const Spacer(),
              StatusBadge.pill(
                label: statusStyle.label,
                background: statusStyle.background,
                foreground: statusStyle.color,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          VisitRequestInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date & Time',
            value: detail.dateTimeLabel,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveHeight(context, 14)),
            child: Divider(height: 1, color: AppColors.dividerLight),
          ),
          VisitRequestInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location / Mode',
            value: detail.locationModeLabel,
          ),
        ],
      ),
    );
  }
}
