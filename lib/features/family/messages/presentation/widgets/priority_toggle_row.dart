import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';

/// "Mark as Priority" card: peach bell icon, title/subtitle, and switch.
class PriorityToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  static const Color _border = Color(0xFFE2E8EE);
  static const Color _title = Color(0xFF1A2B48);
  static const Color _subtitle = Color(0xFF8E9BAE);
  static const Color _iconBg = Color(0xFFFBF0E4);
  static const Color _iconColor = Color(0xFFD98324);
  static const String _bellIcon =
      'assets/icons/family_messages/notification.svg';

  const PriorityToggleRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 11),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(_bellIcon, size: 18, color: _iconColor),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mark as Priority',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      14,
                    ),
                    color: _title,
                    height: 1.2,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 3),
                ),
                Text(
                  'Notify the recipient immediately',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12,
                    ),
                    color: _subtitle,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          _PrioritySwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Compact pill switch matching the reference: soft grey track, inset white
/// thumb with a light drop shadow (teal track when on).
class _PrioritySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  static const Color _trackOff = Color(0xFFD8DEE6);
  static const Color _trackOn = Color(0xFF0E7C7B);
  static const Color _thumbShadow = Color(0xFF142846);

  const _PrioritySwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveHelper.getResponsiveWidth(context, 44);
    final height = ResponsiveHelper.getResponsiveHeight(context, 26);
    final padding = ResponsiveHelper.getResponsiveSize(context, 2.5);
    final thumbSize = height - (padding * 2);

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        height: height,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: value ? _trackOn : _trackOff,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: thumbSize,
          height: thumbSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _thumbShadow.withValues(alpha: 0.14),
                offset: Offset(
                  0,
                  ResponsiveHelper.getResponsiveHeight(context, 1),
                ),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
