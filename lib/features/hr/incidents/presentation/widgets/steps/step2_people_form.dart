import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import '../follow_up_toggle_row.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';
import '../witness_chip_row.dart';

/// Step 2 — People & Location (web: Location & People). BUG 021 toggles.
class Step2PeopleForm extends StatelessWidget {
  final IncidentCreationController controller;

  static const Color _badgeBackground = Color(0xFFE8F0FA);
  static const Color _badgeForeground = Color(0xFF1A2B48);

  const Step2PeopleForm({super.key, required this.controller});

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
                number: 2,
                title: 'Location & People',
                subtitle: 'Who was involved and where it happened',
                badgeBackground: _badgeBackground,
                badgeForeground: _badgeForeground,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
              const WizardFieldLabel('Involved Client'),
              WizardSearchField(
                controller: controller.involvedClientController,
                hint: 'Search client...',
                onChanged: controller.onInvolvedClientQueryChanged,
              ),
              Obx(() {
                if (!controller.showInvolvedClientSuggestions.value) {
                  return const SizedBox.shrink();
                }
                return _InvolvedClientSuggestions(controller: controller);
              }),
              gap,
              const WizardFieldLabel('Staff Involved'),
              WizardSearchField(
                controller: controller.staffInvolvedController,
                hint: 'Select staff...',
                readOnly: true,
                onTap: () => controller.pickStaffInvolved(context),
              ),
              gap,
              const WizardFieldLabel('Reported By'),
              Obx(
                () => WizardDropdownField(
                  value: controller.reportedBy.value,
                  placeholder: controller.isLoadingStaff.value
                      ? 'Loading staff…'
                      : 'Select reporter',
                  onTap: () => controller.pickReporter(context),
                ),
              ),
              gap,
              const WizardFieldLabel('Location'),
              WizardTextField(
                controller: controller.locationController,
                hint: 'e.g. Living Room, Room 3',
              ),
              gap,
              const WizardFieldLabel('Witnesses — staff or residents present'),
              Obx(
                () => WitnessChipRow(
                  witnesses: controller.witnesses.toList(),
                  onAddWitness: () => controller.promptAddWitness(context),
                  onRemoveWitness: controller.removeWitness,
                ),
              ),
              gap,
              const WizardFieldLabel('Immediate Action Taken'),
              WizardTextField(
                controller: controller.immediateActionController,
                hint: 'What was done right away in response to this incident?',
                maxLines: 4,
              ),
              gap,
              Obx(
                () => FollowUpToggleRow(
                  key: const Key('hr-incident-emergency-services'),
                  title: 'Emergency Services Contacted',
                  subtitle: 'Ambulance, police or fire services',
                  value: controller.emergencyServicesContacted.value,
                  onChanged: (v) =>
                      controller.emergencyServicesContacted.value = v,
                ),
              ),
              Obx(() {
                if (!controller.emergencyServicesContacted.value) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.only(
                    top: ResponsiveHelper.getResponsiveHeight(context, 12),
                  ),
                  child: _EmergencyDetails(controller: controller),
                );
              }),
              gap,
              Obx(
                () => FollowUpToggleRow(
                  key: const Key('hr-incident-family-notified'),
                  title: 'Family / Guardian Notified',
                  subtitle: 'Primary contact informed of the incident',
                  value: controller.familyGuardianNotified.value,
                  onChanged: (v) =>
                      controller.familyGuardianNotified.value = v,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmergencyDetails extends StatelessWidget {
  final IncidentCreationController controller;

  const _EmergencyDetails({required this.controller});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 12),
    );
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WizardFieldLabel('Which service'),
          Obx(
            () => WizardDropdownField(
              key: const Key('hr-incident-agency-type'),
              value: controller.externalAgencyTypeLabel,
              placeholder: 'Choose a service',
              onTap: () => controller.pickExternalAgencyType(context),
            ),
          ),
          gap,
          const WizardFieldLabel('Agency reference'),
          WizardTextField(
            controller: controller.agencyReferenceController,
            hint: 'CAD / incident number, as they gave it',
          ),
          gap,
          const WizardFieldLabel('Responding station or officer'),
          WizardTextField(
            controller: controller.agencyResponderController,
            hint: 'Name or station, as given',
          ),
        ],
      ),
    );
  }
}

class _InvolvedClientSuggestions extends StatelessWidget {
  final IncidentCreationController controller;

  const _InvolvedClientSuggestions({required this.controller});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveHelper.getResponsiveHeight(context, 8),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: ResponsiveHelper.getResponsiveHeight(context, 180),
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: AppColors.searchBorder),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Obx(() {
          if (controller.isSearchingInvolvedClients.value &&
              controller.involvedClientSuggestions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
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
          if (controller.involvedClientSuggestions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No clients found.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: controller.involvedClientSuggestions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final option = controller.involvedClientSuggestions[index];
              return ListTile(
                dense: true,
                title: Text(
                  option.name,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      13.5,
                    ),
                    color: AppColors.textHeading,
                  ),
                ),
                onTap: () => controller.selectInvolvedClient(option),
              );
            },
          );
        }),
      ),
    );
  }
}
