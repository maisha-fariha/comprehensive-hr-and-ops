import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../controllers/incident_creation_controller.dart';
import '../evidence_upload_section.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';

/// Step 4 of the "Create Incident" wizard - "Evidence & Submission".
/// UI matched to the Step 4 reference; responsive for all screen sizes.
class Step4EvidenceForm extends StatelessWidget {
  final IncidentCreationController controller;

  /// Soft teal badge + navy numeral from the Step 4 reference.
  static const Color _badgeBackground = Color(0xFFE6F4F1);
  static const Color _badgeForeground = Color(0xFF1E3A5F);

  const Step4EvidenceForm({super.key, required this.controller});

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
                number: 4,
                title: 'Evidence & Submission',
                subtitle: 'Attach supporting evidence before submitting',
                badgeBackground: _badgeBackground,
                badgeForeground: _badgeForeground,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
              const WizardFieldLabel('Upload Evidence'),
              EvidenceUploadDropzone(
                onBrowseFiles: () {
                  // UI-only: keep the mock file list as-is.
                },
              ),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                maxLines: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}
