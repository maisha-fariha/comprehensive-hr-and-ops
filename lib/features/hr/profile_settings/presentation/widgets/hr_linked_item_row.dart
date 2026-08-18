import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/hr_linked_item.dart';
import '../../hr_profile_settings_constants.dart';
import 'hr_initials_avatar.dart';

class HrLinkedItemRow extends StatelessWidget {
  final HrLinkedItem item;

  static const Color _nameColor = Color(0xFF1A2B48);
  static const Color _subtitleColor = Color(0xFF6B7C93);
  static const Color _activeBg = Color(0xFFEAF6F0);
  static const Color _activeFg = Color(0xFF2E8C58);

  const HrLinkedItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          HrInitialsAvatar(
            initials: item.initials,
            size: 46,
            background: HrProfileSettingsConstants.linkedItemAvatarBackground,
            foreground: HrProfileSettingsConstants.linkedItemAvatarForeground,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: _nameColor,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: _subtitleColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          StatusBadge.pill(
            label: item.statusLabel,
            background: _activeBg,
            foreground: _activeFg,
          ),
        ],
      ),
    );
  }
}
