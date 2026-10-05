import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import 'create_incident_form_fields.dart';

/// Investigation section — web create-incident step (BUG_Report015).
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
          Text(
            'Document the investigation, root cause and any corrective follow-up.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          const CreateIncidentFieldLabel('Investigation Status'),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-investigation-status'),
              value: controller.investigationStatusLabel,
              placeholder: 'Select status...',
              onTap: controller.pickInvestigationStatus,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Investigator'),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-investigator'),
              value: controller.investigatorLabel,
              placeholder: 'Select investigator...',
              onTap: controller.pickInvestigator,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Investigation Notes'),
          CreateIncidentTextField(
            controller: controller.investigationNotesController,
            hint: 'Summarise the investigation process and interviews...',
            maxLines: 4,
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Root Cause'),
          CreateIncidentTextField(
            key: const Key('staff-incident-root-cause'),
            controller: controller.rootCauseController,
            hint: 'What actually caused this to happen?',
            maxLines: 3,
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Corrective Action'),
          CreateIncidentTextField(
            key: const Key('staff-incident-corrective-action'),
            controller: controller.correctiveActionController,
            hint: 'Describe corrective measures to prevent recurrence...',
            maxLines: 3,
          ),
          fieldGap,
          Obx(
            () => _ToggleCard(
              key: const Key('staff-incident-follow-up-toggle'),
              title: 'Follow-up Required',
              subtitle: 'Schedule a follow-up review for this incident',
              value: controller.followUpRequired.value,
              onChanged: (v) => controller.followUpRequired.value = v,
            ),
          ),
          Obx(() {
            if (!controller.followUpRequired.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(
                top: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CreateIncidentFieldLabel('Follow-up Due Date'),
                  CreateIncidentDateField(
                    key: const Key('staff-incident-follow-up-date'),
                    controller: controller.followUpDateController,
                  ),
                  fieldGap,
                  const CreateIncidentFieldLabel('Assigned To'),
                  CreateIncidentDropdownField(
                    key: const Key('staff-incident-assigned-to'),
                    value: controller.assignedToLabel,
                    placeholder: 'Select assignee...',
                    onTap: controller.pickAssignedTo,
                  ),
                ],
              ),
            );
          }),
          fieldGap,
          _DebriefCard(controller: controller),
        ],
      ),
    );
  }
}

class _DebriefCard extends StatelessWidget {
  final IncidentCreationController controller;

  const _DebriefCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final fieldGap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 12),
    );
    return Container(
      key: const Key('staff-incident-debrief'),
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Debrief',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(optional)',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          fieldGap,
          Obx(
            () => _ToggleCard(
              key: const Key('staff-incident-debrief-completed'),
              title: 'Debrief Completed with Child?',
              subtitle: '',
              value: controller.debriefCompleted.value,
              onChanged: (v) => controller.debriefCompleted.value = v,
            ),
          ),
          Obx(() {
            if (!controller.debriefCompleted.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(
                top: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CreateIncidentFieldLabel('Debrief Details'),
                  CreateIncidentTextField(
                    controller: controller.debriefDetailsController,
                    hint: 'Provide details of the debrief.',
                    maxLines: 3,
                  ),
                  fieldGap,
                  _ToggleCard(
                    key: const Key('staff-incident-child-informed'),
                    title:
                        'Child Informed of Rights, Grievance Procedures & OCYA Access?',
                    subtitle: '',
                    value: controller.childInformedOfRights.value,
                    onChanged: (v) =>
                        controller.childInformedOfRights.value = v,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 2),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
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
