import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../../core/widgets/status_badge.dart';
import '../../../domain/entities/family_visit_requests_enums.dart';
import '../../../domain/entities/visit_request_detail.dart';
import '../visit_request_status_style.dart';

/// "Request Summary" card on Request Details: type + status, then
/// Date & Time and Location / Mode rows.
class VisitRequestSummaryCard extends StatelessWidget {
  final VisitRequestDetail detail;

  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);
  static const Color _labelColor = Color(0xFF8E9BAE);
  static const Color _valueColor = Color(0xFF1A2B48);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _iconBoxBg = Color(0xFFF0F4F7);
  static const Color _iconColor = Color(0xFF0E7C7B);
  static const Color _visitFg = Color(0xFF0E7C7B);
  static const Color _visitBg = Color(0xFFE6F4F1);
  static const Color _appointmentFg = Color(0xFF2A5DA6);
  static const Color _appointmentBg = Color(0xFFEAF0F9);

  static const String _visitIcon = 'assets/icons/family_visit_requests/visit.svg';
  static const String _videoIcon = 'assets/icons/family_visit_requests/video.svg';
  static const String _calendarIcon =
      'assets/icons/family_visit_requests/calendar.svg';
  static const String _locationIcon =
      'assets/icons/family_visit_requests/location.svg';

  const VisitRequestSummaryCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final statusStyle = VisitRequestStatusStyle.of(detail.status);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);
    final isVisit = detail.type == VisitRequestType.visit;

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
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
            color: _shadow.withValues(alpha: 0.06),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: _TypeTag(
                  label: isVisit ? 'Visit' : 'Appointment',
                  asset: isVisit ? _visitIcon : _videoIcon,
                  foreground: isVisit ? _visitFg : _appointmentFg,
                  background: isVisit ? _visitBg : _appointmentBg,
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
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
          _SummaryInfoRow(
            iconAsset: _calendarIcon,
            label: 'Date & Time',
            value: detail.dateTimeLabel,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
            ),
            child: const Divider(height: 1, thickness: 1, color: _divider),
          ),
          _SummaryInfoRow(
            iconAsset: _locationIcon,
            label: 'Location / Mode',
            value: detail.locationModeLabel,
          ),
        ],
      ),
    );
  }
}

class _TypeTag extends StatelessWidget {
  final String label;
  final String asset;
  final Color foreground;
  final Color background;

  const _TypeTag({
    required this.label,
    required this.asset,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 999),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(asset, size: 14, color: foreground),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: foreground,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryInfoRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String value;

  const _SummaryInfoRow({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: VisitRequestSummaryCard._iconBoxBg,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
          ),
          alignment: Alignment.center,
          child: AppSvgIcon(
            iconAsset,
            size: 18,
            color: VisitRequestSummaryCard._iconColor,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    12,
                  ),
                  color: VisitRequestSummaryCard._labelColor,
                  height: 1.2,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    14.5,
                  ),
                  color: VisitRequestSummaryCard._valueColor,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
