import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import 'create_incident_form_fields.dart';

/// Report Form section for Staff Create Incident (BUG_Report017).
class CreateIncidentReportFormSection extends StatelessWidget {
  final IncidentCreationController controller;

  const CreateIncidentReportFormSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final fieldGap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 16),
    );

    return Container(
      key: const Key('staff-incident-report-form'),
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
            'Report form',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            'Complete CIR report fields for supervisor review',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          const CreateIncidentFieldLabel('CIR Template'),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-report-cir'),
              value: controller.cirTemplateLabel,
              placeholder: controller.cirTemplates.isEmpty
                  ? 'No templates available'
                  : 'Select CIR template...',
              onTap: controller.cirTemplates.isEmpty
                  ? null
                  : controller.pickCirTemplate,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Persons Involved / Witnesses'),
          CreateIncidentTextField(
            controller: controller.personsInvolvedController,
            hint: 'Describe who was involved including any witnesses...',
            maxLines: 3,
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Incident Location Description'),
          CreateIncidentTextField(
            controller: controller.incidentLocationDescriptionController,
            hint: 'Describe the location of the incident...',
            maxLines: 3,
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Type of Incident Notes'),
          CreateIncidentTextField(
            controller: controller.incidentTypeNotesController,
            hint: 'Identify the type of incident and categories that apply...',
            maxLines: 3,
          ),
          fieldGap,
          const CreateIncidentFieldLabel('End / Return Time'),
          CreateIncidentTextField(
            controller: controller.endReturnTimeController,
            hint: 'e.g. 4:30 PM',
          ),
        ],
      ),
    );
  }
}
