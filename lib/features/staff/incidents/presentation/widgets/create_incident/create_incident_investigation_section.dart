import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import 'create_incident_form_fields.dart';

/// Investigation section for Staff Create Incident (BUG_Report015).
class CreateIncidentInvestigationSection extends StatelessWidget {
  final IncidentCreationController controller;

  const CreateIncidentInvestigationSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final fieldGap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 16),
    );

    return Container(
      key: const Key('staff-incident-investigation'),
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreateIncidentFieldLabel('Immediate Action Taken'),
          CreateIncidentTextField(
            controller: controller.immediateActionController,
            hint: 'Describe actions taken immediately after the incident...',
            maxLines: 4,
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Investigation Notes'),
          CreateIncidentTextField(
            controller: controller.investigationNotesController,
            hint: 'Summarise findings, interviews, and root cause...',
            maxLines: 4,
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Follow-up Required'),
          Obx(
            () => _FollowUpToggle(
              value: controller.followUpRequired.value,
              onChanged: (v) => controller.followUpRequired.value = v,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Follow-up Date'),
          CreateIncidentDateField(
            controller: controller.followUpDateController,
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Supervisor Review Assignment'),
          CreateIncidentTextField(
            key: const Key('staff-incident-supervisor'),
            controller: controller.supervisorAssignmentController,
            hint: 'Assign supervisor...',
          ),
        ],
      ),
    );
  }
}

class _FollowUpToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FollowUpToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('staff-incident-follow-up-toggle'),
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F5),
        border: Border.all(color: const Color(0xFFB7E0DB)),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule a follow-up review',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  'Assign a supervisor to re-check this incident',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.secondaryTeal,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.cardBorder,
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
