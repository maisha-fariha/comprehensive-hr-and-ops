import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import 'section_label.dart';

/// "ACTIVITY LOG" section on Incident Details.
///
/// Entries match the Figma details reference (not yet on [IncidentDetail]).
class IncidentActivityLogSection extends StatelessWidget {
  static const Color _titleColor = Color(0xFF1E293B);
  static const Color _metaColor = Color(0xFF6B7280);
  static const Color _inactiveRing = Color(0xFFD1D5DB);

  static const List<_ActivityEntry> _entries = [
    _ActivityEntry(
      title: 'Marked Under Investigation',
      meta: 'Susan N.  •  May 10, 5:10 PM',
      isActive: true,
    ),
    _ActivityEntry(
      title: 'Supervisor notified',
      meta: 'System  •  May 10, 4:52 PM',
      isActive: false,
    ),
    _ActivityEntry(
      title: 'Incident reported',
      meta: 'David L.  •  May 10, 4:48 PM',
      isActive: false,
    ),
  ];

  const IncidentActivityLogSection({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IncidentDetailsSectionLabel('ACTIVITY LOG'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.04),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < _entries.length; i++) ...[
                if (i > 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                _ActivityRow(entry: _entries[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityEntry {
  final String title;
  final String meta;
  final bool isActive;

  const _ActivityEntry({
    required this.title,
    required this.meta,
    required this.isActive,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityEntry entry;

  const _ActivityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final ringSize = ResponsiveHelper.getResponsiveSize(context, 14);
    final ringColor = entry.isActive ? AppColors.secondaryTeal : IncidentActivityLogSection._inactiveRing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: ResponsiveHelper.getResponsiveHeight(context, 3),
          ),
          child: Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ringColor,
                width: ResponsiveHelper.getResponsiveSize(context, 2.5),
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: IncidentActivityLogSection._titleColor,
                  height: 1.25,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
              Text(
                entry.meta,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: IncidentActivityLogSection._metaColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
