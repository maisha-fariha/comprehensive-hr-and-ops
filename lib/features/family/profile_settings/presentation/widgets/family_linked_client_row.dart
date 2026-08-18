import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/family_linked_client.dart';
import '../../family_profile_settings_constants.dart';
import 'family_initials_avatar.dart';

/// A single linked-client row: blue initials avatar, name + residence/room
/// subtext, and a trailing status pill (e.g. "Active").
///
/// Intended to sit inside the Linked Clients card above
/// [FamilyAddClientLink], not as its own elevated card.
class FamilyLinkedClientRow extends StatelessWidget {
  final FamilyLinkedClient client;

  static const Color _nameColor = Color(0xFF1A2B48);
  static const Color _subtitleColor = Color(0xFF6B7C93);
  static const Color _activeBg = Color(0xFFEAF6F0);
  static const Color _activeFg = Color(0xFF2E8C58);

  const FamilyLinkedClientRow({super.key, required this.client});

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
          FamilyInitialsAvatar(
            initials: client.initials,
            size: 46,
            background:
                FamilyProfileSettingsConstants.linkedClientAvatarBackground,
            foreground:
                FamilyProfileSettingsConstants.linkedClientAvatarForeground,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  client.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      15,
                    ),
                    color: _nameColor,
                    height: 1.25,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 2),
                ),
                Text(
                  client.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12.5,
                    ),
                    color: _subtitleColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          StatusBadge.pill(
            label: client.statusLabel,
            background: _activeBg,
            foreground: _activeFg,
          ),
        ],
      ),
    );
  }
}
