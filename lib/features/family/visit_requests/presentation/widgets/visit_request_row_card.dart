import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/family_visit_requests_enums.dart';
import '../../domain/entities/visit_request.dart';
import 'visit_request_status_style.dart';
import 'visit_request_type_tag.dart';

/// A single request card on the "All" and "History" Visit Requests tabs.
class VisitRequestRowCard extends StatelessWidget {
  final VisitRequest request;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _metaColor = Color(0xFF6B7B8A);
  static const Color _iconColor = Color(0xFF8E9BAE);
  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);
  static const String _locationIcon =
      'assets/icons/family_visit_requests/location.svg';
  static const String _calendarIcon =
      'assets/icons/family_visit_requests/calendar.svg';

  const VisitRequestRowCard({super.key, required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusStyle = VisitRequestStatusStyle.of(request.status);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _shadow.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
          ),
          BoxShadow(
            color: _shadow.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
          ),
        ],
      ),
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
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      15.5,
                    ),
                    color: _titleColor,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: StatusBadge.pill(
                    label: statusStyle.label,
                    background: statusStyle.background,
                    foreground: statusStyle.color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          VisitRequestTypeTag(type: request.type),
          if (request.mode != null) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            _MetaLine(
              iconAsset: _locationIcon,
              text: request.mode == VisitRequestMode.telehealth
                  ? 'Telehealth'
                  : (request.locationLabel ?? ''),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          ] else
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _MetaLine(
            iconAsset: _calendarIcon,
            text: request.dateTimeLabel,
          ),
        ],
      ),
    ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String iconAsset;
  final String text;

  const _MetaLine({required this.iconAsset, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        AppSvgIcon(
          iconAsset,
          size: 14,
          color: VisitRequestRowCard._iconColor,
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: VisitRequestRowCard._metaColor,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
