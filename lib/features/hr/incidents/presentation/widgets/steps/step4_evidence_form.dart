import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import '../../../domain/entities/incident_evidence_file.dart';
import '../../../domain/entities/incident_party_notification.dart';
import '../evidence_upload_section.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';

/// Step 4 — Evidence & Submission (web parity). BUG 023 Parties Notified.
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
                hint: 'Transcription / additional notes will appear here…',
                maxLines: 4,
              ),
              gap,
              _PartiesNotifiedCard(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

class _PartiesNotifiedCard extends StatelessWidget {
  final IncidentCreationController controller;

  const _PartiesNotifiedCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('hr-incident-parties-notified'),
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
          Text(
            'Parties Notified',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            'Track who has been informed of this incident and when.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Obx(() {
            final parties = controller.partyNotifications;
            return Column(
              children: [
                for (var i = 0; i < parties.length; i++) ...[
                  _PartyNotificationRow(
                    index: i,
                    party: parties[i],
                    controller: controller,
                  ),
                  if (i < parties.length - 1)
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 10),
                    ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _PartyNotificationRow extends StatelessWidget {
  final int index;
  final IncidentPartyNotification party;
  final IncidentCreationController controller;

  const _PartyNotificationRow({
    required this.index,
    required this.party,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  party.party,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Switch(
                value: party.notified,
                onChanged: (value) => controller.updatePartyNotification(
                  index,
                  notified: value,
                ),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.secondaryTeal,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.cardBorder,
                trackOutlineColor:
                    const WidgetStatePropertyAll(Colors.transparent),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (party.notified) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            TextFormField(
              initialValue: party.contactName,
              decoration: const InputDecoration(
                hintText: 'Contact name (optional)',
                isDense: true,
              ),
              onChanged: (value) => controller.updatePartyNotification(
                index,
                contactName: value,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            TextFormField(
              initialValue: party.dateNotified,
              decoration: const InputDecoration(
                hintText: 'Date notified (yyyy-mm-dd)',
                isDense: true,
              ),
              onChanged: (value) => controller.updatePartyNotification(
                index,
                dateNotified: value,
              ),
            ),
          ],
        ],
      ),
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
