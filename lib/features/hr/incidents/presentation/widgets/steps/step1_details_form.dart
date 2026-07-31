import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import '../severity_selector.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';

/// Step 1 of the "Create Incident" wizard - "Incident Details".
class Step1DetailsForm extends StatelessWidget {
  final IncidentCreationController controller;

  const Step1DetailsForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardSectionHeader(
          number: 1,
          title: 'Incident Details',
          subtitle: 'Capture what happened and how serious it is',
          badgeBackground: AppColors.criticalBackground,
          badgeForeground: AppColors.criticalRed,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
        const WizardFieldLabel('Incident Category', required: true),
        Obx(
          () => WizardDropdownField(
            value: controller.incidentCategory.value,
            placeholder: 'Select category',
          ),
        ),
        gap,
        const WizardFieldLabel('Incident Title', required: true),
        WizardTextField(controller: controller.incidentTitleController, hint: 'Enter a short title'),
        gap,
        const WizardFieldLabel('Client / Resident', required: true),
        WizardSearchField(controller: controller.clientController, hint: 'Search client...'),
        gap,
        const WizardFieldLabel('Residence', required: true),
        Obx(
          () => WizardDropdownField(
            value: controller.residence.value,
            placeholder: 'Select residence',
          ),
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WizardFieldLabel('Incident Date', required: true),
                  WizardDateField(controller: controller.incidentDateController),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WizardFieldLabel('Time', required: true),
                  WizardTimeField(controller: controller.incidentTimeController),
                ],
              ),
            ),
          ],
        ),
        gap,
        const WizardFieldLabel('Severity', required: true),
        Obx(
          () => SeveritySelector(
            selected: controller.severity.value,
            onChanged: (value) => controller.severity.value = value,
          ),
        ),
        gap,
        const WizardFieldLabel('Detected During'),
        Obx(
          () => WizardDropdownField(
            value: controller.detectedDuring.value,
            placeholder: 'Select...',
          ),
        ),
      ],
    );
  }
}
