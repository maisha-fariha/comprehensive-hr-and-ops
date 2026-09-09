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
          badgeBackground: Color(0xFFFBEAED),
          badgeForeground: Color(0xFFC45C6A),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
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
        const WizardFieldLabel('CIR Template'),
        Obx(
          () => WizardDropdownField(
            value: controller.cirTemplateLabel,
            placeholder: controller.isLoadingCirTemplates.value
                ? 'Loading templates…'
                : 'Select CIR template',
            onTap: () => controller.pickCirTemplate(context),
          ),
        ),
        gap,
        const WizardFieldLabel('Incident Title', required: true),
        WizardTextField(controller: controller.incidentTitleController, hint: 'Enter a short title'),
        gap,
        const WizardFieldLabel('Client / Resident', required: true),
        WizardSearchField(
          controller: controller.clientController,
          hint: 'Search client...',
          onChanged: controller.onClientQueryChanged,
        ),
        Obx(() {
          if (!controller.showClientSuggestions.value) {
            return const SizedBox.shrink();
          }
          return _ClientSuggestionsPanel(controller: controller);
        }),
        gap,
        const WizardFieldLabel('Residence', required: true),
        Obx(
          () => WizardDropdownField(
            value: controller.residence.value,
            placeholder: controller.isLoadingResidences.value
                ? 'Loading residences…'
                : 'Select residence',
            onTap: () => controller.pickResidence(context),
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
                  const WizardFieldLabel('Time', required: true),
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
            onTap: () => controller.pickDetectedDuring(context),
          ),
        ),
      ],
    );
  }
}

class _ClientSuggestionsPanel extends StatelessWidget {
  final IncidentCreationController controller;

  const _ClientSuggestionsPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    return Padding(
      padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 8)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: ResponsiveHelper.getResponsiveHeight(context, 220),
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: AppColors.searchBorder),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Obx(() {
          if (controller.isSearchingClients.value &&
              controller.clientSuggestions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
            );
          }

          final error = controller.clientSearchError.value;
          if (error.isNotEmpty && controller.clientSuggestions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          if (controller.clientSuggestions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No clients found.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: controller.clientSuggestions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final option = controller.clientSuggestions[index];
              final selected = controller.selectedClient.value?.id == option.id;
              return ListTile(
                dense: true,
                title: Text(
                  option.name,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                  ),
                ),
                subtitle: option.subtitle == null
                    ? null
                    : Text(
                        option.subtitle!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize:
                              ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: AppColors.textSecondary,
                        ),
                      ),
                trailing: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.secondaryTeal,
                      )
                    : null,
                onTap: () => controller.selectClient(option),
              );
            },
          );
        }),
      ),
    );
  }
}
