import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Teal circular floating action button with a white "+" icon, pinned to
/// the bottom-right of the "Messages" list screen to start a new message.
///
/// Icon note: no matching SVG exists in `assets/icons/*` for a plain "+"
/// glyph, so this uses `Icons.add_rounded` as a temporary stand-in.
class NewMessageFab extends StatelessWidget {
  final VoidCallback onTap;

  const NewMessageFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 56);

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppColors.secondaryTeal,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            Icons.add_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 26),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
