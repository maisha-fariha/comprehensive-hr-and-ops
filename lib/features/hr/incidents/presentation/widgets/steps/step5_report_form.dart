import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';

/// Step 5 — Report Form (web parity). BUG 024.
class Step5ReportForm extends StatelessWidget {
  final IncidentCreationController controller;

  static const Color _badgeBackground = Color(0xFFFFF4E8);
  static const Color _badgeForeground = Color(0xFFB7791F);

  const Step5ReportForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final fieldGap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 16),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardSectionHeader(
          number: 5,
          title: 'Report Form',
          subtitle: 'The form the regulator requires',
          badgeBackground: _badgeBackground,
          badgeForeground: _badgeForeground,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
        const WizardFieldLabel('Report form'),
        Obx(
          () => WizardDropdownField(
            key: const Key('hr-incident-report-cir'),
            value: controller.cirTemplateLabel,
            placeholder: controller.isLoadingCirTemplates.value
                ? 'Loading forms…'
                : (controller.cirTemplates.isEmpty
                    ? 'No forms configured'
                    : 'None — this incident is not reportable'),
            onTap: controller.cirTemplates.isEmpty
                ? null
                : () => controller.pickReportFormTemplate(context),
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
                template.version == null
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
            WizardFieldLabel(field.label, required: field.required),
            WizardTextField(
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
