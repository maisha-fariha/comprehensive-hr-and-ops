import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

/// Centered light-mint "You are On Shift" banner with a status dot.
class OnShiftBanner extends StatelessWidget {
  final bool isOnShift;
  final String startedLabel;

  static const Color _mint = Color(0xFFEAF7F0);
  static const Color _forest = Color(0xFF2D7A50);

  const OnShiftBanner({
    super.key,
    required this.isOnShift,
    required this.startedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 9),
            height: ResponsiveHelper.getResponsiveSize(context, 9),
            decoration: const BoxDecoration(
              color: _forest,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOnShift ? 'You are On Shift' : 'You are Off Shift',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                    color: _forest,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  startedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: _forest,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
