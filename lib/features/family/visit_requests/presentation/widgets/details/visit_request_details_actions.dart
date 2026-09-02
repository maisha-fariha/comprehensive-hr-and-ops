import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/widgets/app_svg_icon.dart';

class VisitRequestDetailsActions extends StatelessWidget {
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;
  final bool enabled;

  static const Color _bannerBg = Color(0xFFE8F5F3);
  static const Color _bannerBorder = Color(0xFFBFE3DE);
  static const Color _bannerFg = Color(0xFF0E7C7B);
  static const Color _rescheduleBg = Color(0xFF0E7C7B);
  static const Color _rescheduleShadow = Color(0xFF0E4A54);
  static const Color _cancelBorder = Color(0xFFF5C4C4);
  static const Color _cancelFg = Color(0xFFD64545);
  static const String _rescheduleIcon =
      'assets/icons/family_visit_requests/reschedule.svg';
  static const String _crossIcon =
      'assets/icons/family_visit_requests/cross.svg';

  const VisitRequestDetailsActions({
    super.key,
    this.onReschedule,
    this.onCancel,
    this.enabled = true,
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
          child: Text(
            'The care team reviews this request. You can reschedule or cancel it.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: _bannerFg,
              height: 1.35,
            ),
          ),
        ),
        gap,
        _ActionButton(
          label: 'Reschedule',
          iconAsset: _rescheduleIcon,
          foreground: Colors.white,
          background: _rescheduleBg,
          borderColor: _rescheduleBg,
          shadow: BoxShadow(
            color: _rescheduleShadow.withValues(alpha: 0.22),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
          ),
          onTap: enabled ? onReschedule : null,
        ),
        gap,
        _ActionButton(
          label: 'Cancel request',
          iconAsset: _crossIcon,
          foreground: _cancelFg,
          background: Colors.white,
          borderColor: _cancelBorder,
          onTap: enabled ? onCancel : null,
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
