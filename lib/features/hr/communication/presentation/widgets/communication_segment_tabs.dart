import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/communication_enums.dart';

class CommunicationSegmentTabs extends StatelessWidget {
  final CommunicationTab selected;
  final ValueChanged<CommunicationTab> onSelected;

  const CommunicationSegmentTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        bottom: 8,
      ),
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF1F5),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _Segment(
                label: 'Messages',
                selected: selected == CommunicationTab.messages,
                onTap: () => onSelected(CommunicationTab.messages),
              ),
            ),
            Expanded(
              child: _Segment(
                label: 'Communication Log',
                selected: selected == CommunicationTab.communicationLog,
                onTap: () => onSelected(CommunicationTab.communicationLog),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceWhite : Colors.transparent,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 10),
      ),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            vertical: 10,
            horizontal: 8,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: selected ? AppColors.textHeading : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
