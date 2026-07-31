import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Thin, reusable wrapper around [SvgPicture] used for every icon exported
/// from Figma. Centralizing this keeps sizing/coloring/responsiveness
/// consistent and avoids repeating `SvgPicture.asset` boilerplate.
class AppSvgIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;

  const AppSvgIcon(
    this.asset, {
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);
    return SvgPicture.asset(
      asset,
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}
