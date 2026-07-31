import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/surface_card.dart';
import '../../../domain/entities/incident_detail.dart';
import '../staff_avatar_chip.dart';
import 'section_label.dart';

/// "PEOPLE" card: an avatar + label + value row for the resident/client
/// involved, and a second row for the reporting staff member.
class IncidentPeopleSection extends StatelessWidget {
  final IncidentDetail detail;

  const IncidentPeopleSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IncidentDetailsSectionLabel('PEOPLE'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        SurfaceCard.card(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
          child: Column(
            children: [
              _PersonRow(
                initials: detail.residentInitials,
                label: 'Resident/Client',
                value: '${detail.residentName} · ${detail.residentSubLabel}',
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveHeight(context, 12)),
                child: Divider(height: 1, color: AppColors.dividerLight),
              ),
              _PersonRow(
                initials: detail.reportedByInitials,
                label: 'Reported by',
                value: '${detail.reportedByName} · ${detail.reportedBySubLabel}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String initials;
  final String label;
  final String value;

  const _PersonRow({required this.initials, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StaffAvatarChip(initials: initials, size: 32),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.textFaint,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: AppColors.textHeading,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
