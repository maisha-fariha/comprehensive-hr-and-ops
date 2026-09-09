import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../controllers/incident_creation_controller.dart';
import '../../../domain/entities/incident_evidence_file.dart';
import '../evidence_upload_section.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';

/// Step 4 of the "Create Incident" wizard - "Evidence & Submission".
class Step4EvidenceForm extends StatelessWidget {
  final IncidentCreationController controller;

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
                onBrowseFiles: controller.pickEvidenceFiles,
              ),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final file in controller.evidenceFiles) ...[
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 12),
                      ),
                      _EvidenceFileRow(
                        file: file,
                        onRemove: () => controller.removeEvidenceFile(file),
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

class _EvidenceFileRow extends StatelessWidget {
  final IncidentEvidenceFile file;
  final VoidCallback onRemove;

  const _EvidenceFileRow({
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = file.isUploading
        ? 'Uploading…'
        : (file.uploadError ??
            (file.isReady
                ? (file.mimeType ?? 'Ready')
                : 'Waiting for upload'));

    return EvidenceFileChip(
      fileName: file.fileName,
      subtitle: subtitle,
      onRemove: file.isUploading ? null : onRemove,
    );
  }
}
