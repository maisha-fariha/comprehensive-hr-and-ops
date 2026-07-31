import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../controllers/incident_creation_controller.dart';
import '../widgets/create_incident/create_incident_form_fields.dart';
import '../widgets/create_incident/numbered_section_header.dart';
import '../widgets/create_incident/severity_pill_selector.dart';
import '../widgets/staff_incidents_header.dart';
import '../widgets/staff_primary_button.dart';

/// The single-page "Create Incident" form, reached from the "+ Create
/// Incident" button on the Staff Incidents list screen.
///
/// Unlike the Manager Incidents feature's 4-step wizard, the Figma
/// "Create Incident - Incidents" screenshot shows a single scrollable form
/// (Incident Details / Severity / People & Location sections + a bottom
/// action bar), so this page mirrors that simpler shape.
class CreateIncidentPage extends StatelessWidget {
  const CreateIncidentPage({super.key});

  /// Always starts a fresh controller instance for a new draft rather than
  /// resolving the `get_it`-registered singleton - reusing the same
  /// instance across multiple "Create Incident" sessions would resurface a
  /// previous draft's field values, and its `TextEditingController`s would
  /// already be disposed after the first time this page is closed (see the
  /// identical rationale on the Manager Incidents wizard's page).
  IncidentCreationController _resolveController() {
    if (Get.isRegistered<IncidentCreationController>()) {
      Get.delete<IncidentCreationController>(force: true);
    }
    return Get.put(IncidentCreationController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    final sectionGap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 26));
    final fieldGap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.surfaceWhite,
              child: StaffIncidentsHeader(
                title: 'Create Incident',
                subtitle: 'Report incident for safety, compliance & supervisor review',
                onBack: Get.back,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NumberedSectionHeader(number: 1, title: 'INCIDENT DETAILS'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const CreateIncidentFieldLabel('Incident Category'),
                    Obx(
                      () => CreateIncidentDropdownField(
                        value: controller.incidentCategory.value,
                        placeholder: 'Select category...',
                      ),
                    ),
                    fieldGap,
                    const CreateIncidentFieldLabel('Incident Title'),
                    CreateIncidentTextField(
                      controller: controller.incidentTitleController,
                      hint: 'e.g. Fall - No Injury',
                    ),
                    fieldGap,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CreateIncidentFieldLabel('Date'),
                              CreateIncidentDateField(controller: controller.incidentDateController),
                            ],
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CreateIncidentFieldLabel('Time'),
                              CreateIncidentTimeField(controller: controller.incidentTimeController),
                            ],
                          ),
                        ),
                      ],
                    ),
                    fieldGap,
                    const CreateIncidentFieldLabel('Detected During'),
                    Obx(
                      () => CreateIncidentDropdownField(
                        value: controller.detectedDuring.value,
                        placeholder: 'Select context...',
                      ),
                    ),
                    sectionGap,
                    const NumberedSectionHeader(number: 2, title: 'SEVERITY'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    Obx(
                      () => SeverityPillSelector(
                        selected: controller.severity.value,
                        onChanged: controller.selectSeverity,
                      ),
                    ),
                    sectionGap,
                    const NumberedSectionHeader(number: 3, title: 'PEOPLE & LOCATION'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const CreateIncidentFieldLabel('Resident / Client'),
                    Obx(
                      () => CreateIncidentDropdownField(
                        value: controller.resident.value,
                        placeholder: 'Select resident...',
                      ),
                    ),
                    fieldGap,
                    const CreateIncidentFieldLabel('Location'),
                    CreateIncidentTextField(
                      controller: controller.locationController,
                      hint: 'e.g. Room 101, Common Area',
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 12, bottom: 12),
                child: StaffPrimaryButton(
                  label: 'Submit Incident',
                  icon: Icons.send_rounded,
                  onTap: Get.back,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
