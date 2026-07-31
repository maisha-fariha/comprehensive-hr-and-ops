import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import '../evidence_upload_section.dart';
import '../../../incidents_constants.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';

/// Step 4 of the "Create Incident" wizard - "Evidence & Submission".
class Step4EvidenceForm extends StatelessWidget {
  final IncidentCreationController controller;

  const Step4EvidenceForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardSectionHeader(
          number: 4,
          title: 'Evidence & Submission',
          subtitle: 'Attach supporting evidence before submitting',
          badgeBackground: IncidentsColors.evidenceAccentBackground,
          badgeForeground: AppColors.secondaryTeal,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
        const WizardFieldLabel('Upload Evidence'),
        const EvidenceUploadDropzone(),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final fileName in controller.uploadedFileNames) ...[
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                EvidenceFileChip(
                  fileName: fileName,
                  subtitle: 'JPG · 2.4 MB',
                  onRemove: () => controller.removeUploadedFile(fileName),
                ),
              ],
            ],
          ),
        ),
        gap,
        const WizardFieldLabel('Additional Notes'),
        WizardTextField(
          controller: controller.additionalNotesController,
          hint: 'Add any final notes for the reviewing supervisor...',
          maxLines: 3,
        ),
      ],
    );
  }
}
