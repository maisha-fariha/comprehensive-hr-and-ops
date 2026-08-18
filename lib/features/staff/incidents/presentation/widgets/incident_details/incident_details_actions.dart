import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

/// Bottom action row on Incident Details: Close / Add Note / Acknowledge.
class IncidentDetailsActions extends StatelessWidget {
  static const Color _closeInk = Color(0xFF5E6278);
  static const Color _closeBorder = Color(0xFFE1E3EA);
  static const Color _teal = Color(0xFF0E7C7B);

  final VoidCallback? onClose;
  final VoidCallback? onAddNote;
  final VoidCallback? onAcknowledge;

  const IncidentDetailsActions({
    super.key,
    this.onClose,
    this.onAddNote,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getResponsiveHeight(context, 52);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                height: height,
                radius: radius,
                background: AppColors.surfaceWhite,
                borderColor: _closeBorder,
                onTap: onClose ?? Get.back,
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: _closeInk,
                    height: 1,
                  ),
                ),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _ActionButton(
                height: height,
                radius: radius,
                background: AppColors.surfaceWhite,
                borderColor: _teal,
                onTap: onAddNote ?? () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      'assets/icons/staff_incidents/edit.svg',
                      size: ResponsiveHelper.getResponsiveSize(context, 16),
                      color: _teal,
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                    Flexible(
                      child: Text(
                        'Add Note',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                          color: _teal,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        _ActionButton(
          height: height,
          radius: radius,
          background: _teal,
          borderColor: _teal,
          elevated: true,
          onTap: onAcknowledge ?? () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                'assets/icons/staff_incidents/check.svg',
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: Colors.white,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Text(
                'Acknowledge',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final double height;
  final double radius;
  final Color background;
  final Color borderColor;
  final Widget child;
  final VoidCallback onTap;
  final bool elevated;

  const _ActionButton({
    required this.height,
    required this.radius,
    required this.background,
    required this.borderColor,
    required this.child,
    required this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor),
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: IncidentDetailsActions._teal.withValues(alpha: 0.25),
                      offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
                      blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
                    ),
                  ]
                : null,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
