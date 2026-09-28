import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import 'create_incident_form_fields.dart';

/// Report Form — web create-incident step (BUG_Report017).
///
/// Web shows a "Report form" CIR-template picker. When a template is selected,
/// its sections/fields render dynamically. When none are configured, the
/// placeholder is "No forms configured".
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
            'The form the regulator requires',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          const CreateIncidentFieldLabel('Report form'),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-report-cir'),
              value: controller.cirTemplateLabel,
              placeholder: controller.cirTemplates.isEmpty
                  ? 'No forms configured'
                  : 'None — this incident is not reportable',
              onTap: controller.cirTemplates.isEmpty
                  ? null
                  : controller.pickCirTemplate,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            'Leave blank if this incident does not have to be reported on a form.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          Obx(() {
            final template = controller.selectedCirTemplate.value;
            if (template == null || template.sections.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(
                top: ResponsiveHelper.getResponsiveHeight(context, 16),
              ),
              child: _TemplateFields(
                controller: controller,
                fieldGap: fieldGap,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TemplateFields extends StatelessWidget {
  final IncidentCreationController controller;
  final Widget fieldGap;

  const _TemplateFields({
    required this.controller,
    required this.fieldGap,
  });

  @override
  Widget build(BuildContext context) {
    final template = controller.selectedCirTemplate.value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.version == null || template.version!.isEmpty
                    ? template.name
                    : '${template.name} · v${template.version}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Every answer is filed against this form, and the form is stored with the report — so a later revision cannot change what this one asked.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        for (final section in template.sections) ...[
          fieldGap,
          Text(
            section.title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (final field in section.fields) ...[
            CreateIncidentFieldLabel(
              field.label,
              required: field.required,
            ),
            CreateIncidentTextField(
              controller: controller.reportFormAnswerController(field.key),
              hint: field.helpText.isEmpty ? field.label : field.helpText,
              maxLines: field.type == 'textarea' ? 3 : 1,
            ),
            fieldGap,
          ],
        ],
      ],
    );
  }
}
