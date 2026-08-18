import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';

/// Squircle teal FAB with a white "+" used to start a new message.
class NewMessageFab extends StatelessWidget {
  final VoidCallback onTap;

  static const Color _background = Color(0xFF0E7C7B);
  static const Color _shadow = Color(0xFF0E7C7B);

  const NewMessageFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 56);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: _shadow.withValues(alpha: 0.40),
                offset: Offset(
                  0,
                  ResponsiveHelper.getResponsiveHeight(context, 12),
                ),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 26),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/family_messages/plus.svg',
              width: 26,
            ),
          ),
        ),
      ),
    );
  }
}
