import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/my_visit_request.dart';
import 'visit_request_status_style.dart';
import 'visit_request_type_tag.dart';

/// Fuller request card on the "My Requests" tab.
class MyVisitRequestCard extends StatelessWidget {
  final MyVisitRequest request;
  final VoidCallback? onViewDetails;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _metaColor = Color(0xFF6B7B8A);
  static const Color _iconColor = Color(0xFF8E9BAE);
  static const Color _divider = Color(0xFFEEF1F4);
  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);
  static const Color _buttonBorder = Color(0xFF8DC4BF);
  static const Color _buttonFill = Color(0xFFF3FAF9);
  static const Color _buttonText = Color(0xFF0E7C7B);
  static const String _locationIcon =
      'assets/icons/family_visit_requests/location.svg';
  static const String _videoIcon =
      'assets/icons/family_visit_requests/video.svg';

  const MyVisitRequestCard({
    super.key,
    required this.request,
    this.onViewDetails,
  });

  bool get _isRemote {
    final value = request.locationModeLabel.toLowerCase();
    return value.contains('telehealth') ||
        value.contains('remote') ||
        value.contains('video');
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = VisitRequestStatusStyle.of(request.status);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);
    final notes = request.notes?.trim();
    final hasNotes = notes != null && notes.isNotEmpty;

    return Container(
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
                child: Row(
                  children: [
                    Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 8),
                      height: ResponsiveHelper.getResponsiveSize(context, 8),
                      decoration: BoxDecoration(
                        color: statusStyle.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 8),
                    ),
                    Expanded(
                      child: Text(
                        request.dateTimeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            14.5,
                          ),
                          color: _titleColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
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
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          VisitRequestTypeTag(type: request.type),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Row(
            children: [
              AppSvgIcon(
                _isRemote ? _videoIcon : _locationIcon,
                size: 14,
                color: _iconColor,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Expanded(
                child: Text(
                  request.locationModeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12.5,
                    ),
                    color: _metaColor,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          if (hasNotes) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            const Divider(height: 1, thickness: 1, color: _divider),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              notes,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: _metaColor,
                height: 1.4,
              ),
            ),
          ],
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
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(context, vertical: 12),
          decoration: BoxDecoration(
            color: MyVisitRequestCard._buttonFill,
            border: Border.all(color: MyVisitRequestCard._buttonBorder),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'View Request Details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      13,
                    ),
                    color: MyVisitRequestCard._buttonText,
                    height: 1.15,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              const AppSvgIcon(
                AppAssets.chevronRight,
                size: 16,
                color: MyVisitRequestCard._buttonText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
