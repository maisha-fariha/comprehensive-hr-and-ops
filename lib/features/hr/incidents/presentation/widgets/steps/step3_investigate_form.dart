import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../controllers/incident_creation_controller.dart';
import '../follow_up_toggle_row.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';

/// Step 3 of the "Create Incident" wizard - "Immediate Action & Investigation".
/// UI matched to the Step 3 reference; responsive for all screen sizes.
class Step3InvestigateForm extends StatelessWidget {
  final IncidentCreationController controller;

  /// Soft purple badge + deep purple numeral from the Step 3 reference.
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
                title: 'Immediate Action & Investigation',
                subtitle: 'Response taken and review follow-up',
                badgeBackground: _badgeBackground,
                badgeForeground: _badgeForeground,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
              const WizardFieldLabel('Immediate Action Taken'),
              WizardTextField(
                controller: controller.immediateActionController,
                hint: 'Describe actions taken immediately after the incident...',
                maxLines: 4,
              ),
              gap,
              const WizardFieldLabel('Investigation Notes'),
              WizardTextField(
                controller: controller.investigationNotesController,
                hint: 'Summarise findings, interviews, and root cause...',
                maxLines: 4,
              ),
              gap,
              const WizardFieldLabel('Follow-up Required'),
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
          ),
        );
      },
    );
  }
}
