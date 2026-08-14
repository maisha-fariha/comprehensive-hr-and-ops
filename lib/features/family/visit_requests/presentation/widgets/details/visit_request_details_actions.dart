import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/widgets/app_svg_icon.dart';

/// Review actions under Purpose & Notes: notice banner, Approve, then
/// Reschedule / Reject.
class VisitRequestDetailsActions extends StatelessWidget {
  final VoidCallback? onApprove;
  final VoidCallback? onReschedule;
  final VoidCallback? onReject;

  static const Color _bannerBg = Color(0xFFFFF5E6);
  static const Color _bannerBorder = Color(0xFFFFE0B8);
  static const Color _bannerIcon = Color(0xFFD98324);
  static const Color _approveBg = Color(0xFF0E7C7B);
  static const Color _approveShadow = Color(0xFF0E4A54);
  static const Color _rescheduleBg = Color(0xFFF0ECFB);
  static const Color _rescheduleFg = Color(0xFF6A4BC7);
  static const Color _rejectBorder = Color(0xFFF5C4C4);
  static const Color _rejectFg = Color(0xFFD64545);

  static const String _errorIcon =
      'assets/icons/family_visit_requests/error.svg';
  static const String _checkIcon =
      'assets/icons/family_visit_requests/check.svg';
  static const String _rescheduleIcon =
      'assets/icons/family_visit_requests/reschedule.svg';
  static const String _crossIcon =
      'assets/icons/family_visit_requests/cross.svg';

  const VisitRequestDetailsActions({
    super.key,
    this.onApprove,
    this.onReschedule,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
          decoration: BoxDecoration(
            color: _bannerBg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _bannerBorder),
          ),
          alignment: Alignment.centerLeft,
          child: const AppSvgIcon(_errorIcon, size: 20, color: _bannerIcon),
        ),
        gap,
        _ActionButton(
          label: 'Approve',
          iconAsset: _checkIcon,
          foreground: Colors.white,
          background: _approveBg,
          borderColor: _approveBg,
          shadow: BoxShadow(
            color: _approveShadow.withValues(alpha: 0.22),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
          ),
          onTap: onApprove,
        ),
        gap,
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Reschedule',
                iconAsset: _rescheduleIcon,
                foreground: _rescheduleFg,
                background: _rescheduleBg,
                borderColor: _rescheduleBg,
                onTap: onReschedule,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: _ActionButton(
                label: 'Reject',
                iconAsset: _crossIcon,
                foreground: _rejectFg,
                background: Colors.white,
                borderColor: _rejectBorder,
                onTap: onReject,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final BoxShadow? shadow;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.iconAsset,
    required this.foreground,
    required this.background,
    required this.borderColor,
    this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            vertical: 14,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor),
            boxShadow: shadow == null ? null : [shadow!],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              AppSvgIcon(iconAsset, size: 16, color: foreground),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: foreground,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
