import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
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
          subtitle: 'Capture what happened, when, and how serious it is.',
          badgeBackground: Color(0xFFFBEAED),
          badgeForeground: Color(0xFFC45C6A),
        ),
        Obx(() {
          if (!controller.aiDraftingEnabled.value) {
            return SizedBox(
              height: ResponsiveHelper.getResponsiveHeight(context, 22),
            );
          }
          return Padding(
            padding: EdgeInsets.only(
              top: ResponsiveHelper.getResponsiveHeight(context, 14),
              bottom: ResponsiveHelper.getResponsiveHeight(context, 18),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('incident-draft-from-notes'),
                onPressed: () => controller.openDraftFromNotes(context),
                icon: Icon(
                  Icons.auto_awesome,
                  size: ResponsiveHelper.getResponsiveSize(context, 16),
                  color: AppColors.primaryNavy,
                ),
                label: Text(
                  'Draft from my notes',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.primaryNavy,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  backgroundColor: AppColors.surfaceWhite,
                  side: const BorderSide(color: AppColors.searchBorder),
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 12),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const WizardFieldLabel('Incident Category', required: true),
        Obx(
          () => WizardDropdownField(
            value: controller.incidentCategory,
            placeholder: controller.isLoadingCategories.value
                ? 'Loading categories…'
                : 'Select category',
            onTap: () => controller.pickCategory(context),
          ),
        ),
        gap,
        const WizardFieldLabel('Incident Title', required: true),
        WizardTextField(
          controller: controller.incidentTitleController,
          hint: 'e.g. Client refused morning medication',
        ),
        Obx(() {
          final hint = controller.categoryDetailHint;
          if (hint == null) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WizardFieldLabel('Category Details (optional)'),
                WizardTextField(
                  controller: controller.categoryDetailController,
                  hint: hint,
                  maxLines: 3,
                ),
              ],
            ),
          );
        }),
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
                  WizardDateField(
                    controller: controller.incidentDateController,
                    onTap: () => controller.pickIncidentDate(context),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WizardFieldLabel('Incident Time', required: true),
                  WizardTimeField(
                    controller: controller.incidentTimeController,
                    onTap: () => controller.pickIncidentTime(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        gap,
        const WizardFieldLabel('Time Ended (optional)'),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller.endTimeController,
          builder: (context, value, _) => Row(
            children: [
              Expanded(
                child: WizardTimeField(
                  controller: controller.endTimeController,
                  onTap: () => controller.pickEndTime(context),
                ),
              ),
              if (value.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear time ended',
                  onPressed: controller.clearEndTime,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        gap,
        const WizardFieldLabel('Severity', required: true),
        Obx(
          () => WizardDropdownField(
            value: controller.severityLabel,
            placeholder: 'Select severity',
            onTap: () => controller.pickSeverity(context),
          ),
        ),
        gap,
        const WizardFieldLabel('Detected During (optional)'),
        Obx(
          () => WizardDropdownField(
            value: controller.detectedDuring.value,
            placeholder: 'Select context',
            onTap: () => controller.pickDetectedDuring(context),
          ),
        ),
        gap,
        const WizardFieldLabel('Incident Description', required: true),
        WizardTextField(
          controller: controller.descriptionController,
          hint:
              'Describe the events in chronological order — who, what, when, and where.',
          maxLines: 5,
        ),
      ],
    );
  }
}
