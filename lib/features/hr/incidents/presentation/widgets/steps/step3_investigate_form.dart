import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import '../follow_up_toggle_row.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';

/// Step 3 — Investigation (web parity). BUG 022.
class Step3InvestigateForm extends StatelessWidget {
  final IncidentCreationController controller;

  static const Color _badgeBackground = Color(0xFFF0ECFB);
  static const Color _badgeForeground = Color(0xFF6A4BC7);

  const Step3InvestigateForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18));

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WizardSectionHeader(
                number: 3,
                title: 'Investigation',
                subtitle: 'Document findings, root cause and follow-up',
                badgeBackground: _badgeBackground,
                badgeForeground: _badgeForeground,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
              const WizardFieldLabel('Investigation Status'),
              Obx(
                () => WizardDropdownField(
                  key: const Key('hr-incident-investigation-status'),
                  value: controller.investigationStatusLabel,
                  placeholder: 'Select status...',
                  onTap: () => controller.pickInvestigationStatus(context),
                ),
              ),
              gap,
              const WizardFieldLabel('Investigator'),
              Obx(
                () => WizardDropdownField(
                  key: const Key('hr-incident-investigator'),
                  value: controller.investigatorLabel,
                  placeholder: controller.isLoadingStaff.value
                      ? 'Loading staff…'
                      : 'Select investigator...',
                  onTap: () => controller.pickInvestigator(context),
                ),
              ),
              gap,
              const WizardFieldLabel('Investigation Notes'),
              WizardTextField(
                controller: controller.investigationNotesController,
                hint: 'Summarise the investigation process and interviews...',
                maxLines: 4,
              ),
              gap,
              const WizardFieldLabel('Root Cause'),
              WizardTextField(
                key: const Key('hr-incident-root-cause'),
                controller: controller.rootCauseController,
                hint: 'What actually caused this to happen?',
                maxLines: 3,
              ),
              gap,
              const WizardFieldLabel('Corrective Action'),
              WizardTextField(
                key: const Key('hr-incident-corrective-action'),
                controller: controller.correctiveActionController,
                hint: 'Describe corrective measures to prevent recurrence...',
                maxLines: 3,
              ),
              gap,
              const WizardFieldLabel('Follow-up Required'),
              Obx(
                () => FollowUpToggleRow(
                  key: const Key('hr-incident-follow-up-toggle'),
                  title: 'Follow-up Required',
                  subtitle: 'Schedule a follow-up review for this incident',
                  value: controller.followUpRequired.value,
                  onChanged: (value) =>
                      controller.followUpRequired.value = value,
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
                      const WizardFieldLabel('Follow-up Due Date'),
                      WizardDateField(
                        key: const Key('hr-incident-follow-up-date'),
                        controller: controller.followUpDateController,
                        onTap: () => controller.pickFollowUpDate(context),
                      ),
                      gap,
                      const WizardFieldLabel('Assigned To'),
                      Obx(
                        () => WizardDropdownField(
                          key: const Key('hr-incident-assigned-to'),
                          value: controller.assignedToLabel ??
                              controller.supervisorAssignment.value,
                          placeholder: controller.isLoadingStaff.value
                              ? 'Loading staff…'
                              : 'Select assignee...',
                          onTap: () => controller.pickAssignedTo(context),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              gap,
              _DebriefCard(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

class _DebriefCard extends StatelessWidget {
  final IncidentCreationController controller;

  const _DebriefCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 12),
    );
    return Container(
      key: const Key('hr-incident-debrief'),
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
          gap,
          Obx(
            () => FollowUpToggleRow(
              key: const Key('hr-incident-debrief-completed'),
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
                  const WizardFieldLabel('Debrief Details'),
                  WizardTextField(
                    controller: controller.debriefDetailsController,
                    hint: 'Provide details of the debrief.',
                    maxLines: 3,
                  ),
                  gap,
                  FollowUpToggleRow(
                    key: const Key('hr-incident-child-informed'),
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
