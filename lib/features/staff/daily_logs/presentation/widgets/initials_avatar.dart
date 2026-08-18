import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Circular initials avatar with an optional status dot at the bottom-right
/// (My Clients reference rows).
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final Color background;
  final Color foreground;
  final double size;

  /// When set, draws a small filled dot overlaid on the avatar's
  /// bottom-right edge (matches the My Clients list reference).
  final Color? statusDotColor;

  const InitialsAvatar({
    super.key,
    required this.initials,
    required this.background,
    required this.foreground,
    this.size = 40,
    this.statusDotColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 10);
    final borderWidth = ResponsiveHelper.getResponsiveSize(context, 2);

    final avatar = Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, size * 0.32),
          color: foreground,
          height: 1,
        ),
      ),
    );

    if (statusDotColor == null) return avatar;

    return SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: statusDotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: borderWidth),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
