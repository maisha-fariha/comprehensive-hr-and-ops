import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/compliance_requirement_item.dart';
import 'person_avatar_chip.dart';

/// Row for "Upcoming Compliance Reviews" (`GET /compliance/requirements`).
class ComplianceRequirementTile extends StatelessWidget {
  final ComplianceRequirementItem item;

  const ComplianceRequirementTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0F9),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.event_note_outlined,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: const Color(0xFF2A5DA6),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${item.frequencyLabel} · ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            11.5,
                          ),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    PersonAvatarChip(assignee: item.supervisor),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 5),
                    ),
                    Flexible(
                      flex: 2,
                      child: Text(
                        item.supervisor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            11.5,
                          ),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.category,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                color: const Color(0xFF2A5DA6),
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
