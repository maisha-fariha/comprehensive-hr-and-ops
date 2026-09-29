import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/incident_client_option.dart';

/// Selected state of the client picker: initials avatar, name, subtitle,
/// a "Selected" pill and an X that clears the choice.
class IncidentSelectedClientCard extends StatelessWidget {
  final IncidentClientOption client;
  final VoidCallback onClear;

  const IncidentSelectedClientCard({
    super.key,
    required this.client,
    required this.onClear,
  });

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveHelper.getResponsiveSize(context, 16),
            backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.1),
            child: Text(
              _initials(client.name),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
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
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      13.5,
                    ),
                    color: AppColors.textHeading,
                  ),
                ),
                if (client.subtitle != null)
                  Text(
                    client.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        11.5,
                      ),
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 11),
                  color: AppColors.successGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'Selected',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      11,
                    ),
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Change client',
            visualDensity: VisualDensity.compact,
            onPressed: onClear,
            icon: Icon(
              Icons.close_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 16),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
