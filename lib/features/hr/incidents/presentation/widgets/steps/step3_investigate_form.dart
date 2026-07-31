import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import '../follow_up_toggle_row.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';

/// Step 3 of the "Create Incident" wizard - "Immediate Action &
/// Investigation".
class Step3InvestigateForm extends StatelessWidget {
  final IncidentCreationController controller;

  const Step3InvestigateForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardSectionHeader(
          number: 3,
          title: 'Immediate Action & Investigation',
          subtitle: 'Response taken and review follow-up',
          badgeBackground: AppColors.nightBackground,
          badgeForeground: AppColors.nightPurple,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
        const WizardFieldLabel('Immediate Action Taken'),
        WizardTextField(
          controller: controller.immediateActionController,
          hint: 'Describe actions taken immediately after the incident...',
          maxLines: 3,
        ),
        gap,
        const WizardFieldLabel('Investigation Notes'),
        WizardTextField(
          controller: controller.investigationNotesController,
          hint: 'Summarise findings, interviews, and root cause...',
          maxLines: 3,
        ),
        gap,
        Obx(
          () => FollowUpToggleRow(
            value: controller.followUpRequired.value,
            onChanged: (value) => controller.followUpRequired.value = value,
          ),
        ),
        gap,
        const WizardFieldLabel('Follow-up Date'),
        WizardDateField(controller: controller.followUpDateController),
        gap,
        const WizardFieldLabel('Supervisor Review Assignment'),
        Obx(
          () => WizardDropdownField(
            value: controller.supervisorAssignment.value,
            placeholder: 'Assign supervisor...',
          ),
        ),
      ],
    );
  }
}
