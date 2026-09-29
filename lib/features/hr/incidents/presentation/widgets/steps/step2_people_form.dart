import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import '../incident_selected_client_card.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';
import '../witness_chip_row.dart';

/// Step 2 of the "Create Incident" wizard - "People & Location".
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
                title: 'People & Location',
                subtitle: 'Who was involved and where it happened',
                badgeBackground: _badgeBackground,
                badgeForeground: _badgeForeground,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
              const WizardFieldLabel('Involved Client'),
              Obx(() {
                final selected = controller.selectedInvolvedClient.value;
                if (selected != null) {
                  return IncidentSelectedClientCard(
                    client: selected,
                    onClear: controller.clearInvolvedClient,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WizardSearchField(
                      controller: controller.involvedClientController,
                      hint: 'Search client...',
                      onChanged: controller.onInvolvedClientQueryChanged,
                      onTap: controller.openInvolvedClientSuggestions,
                    ),
                    if (controller.showInvolvedClientSuggestions.value)
                      _InvolvedClientSuggestions(controller: controller)
                    else
                      const WizardHelperText('Type to search involved client'),
                  ],
                );
              }),
              gap,
              _CfsDetailsCard(controller: controller),
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
              const WizardFieldLabel('Witness Information'),
              Obx(
                () => WitnessChipRow(
                  witnesses: controller.witnesses.toList(),
                  onAddWitness: () => controller.promptAddWitness(context),
                  onRemoveWitness: controller.removeWitness,
                ),
              ),
            ],
          ),
        );
      },
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
                'No matches found',
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
                onTap: () => controller.selectInvolvedClient(option),
              );
            },
          );
        }),
      ),
    );
  }
}

/// "CFS Details (optional)" card - child ID, CFS status chips, CIP and CIP
/// office, sent as `childIdNumber`, `cfsStatus`, `cipName`, `cipOffice`.
class _CfsDetailsCard extends StatelessWidget {
  final IncidentCreationController controller;

  const _CfsDetailsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14));
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'CFS Details',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                  ),
                ),
                TextSpan(
                  text: '  (optional)',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          gap,
          const WizardFieldLabel("Child's I.D. Number"),
          WizardTextField(controller: controller.childIdController, hint: ''),
          gap,
          const WizardFieldLabel('CFS Status'),
          Obx(
            () => WitnessChipRow(
              witnesses: controller.cfsStatuses.toList(),
              addLabel: 'Add status',
              onAddWitness: () => controller.promptAddCfsStatus(context),
              onRemoveWitness: controller.removeCfsStatus,
            ),
          ),
          gap,
          const WizardFieldLabel('Child Intervention Practitioner (CIP)'),
          WizardTextField(controller: controller.cipController, hint: ''),
          gap,
          const WizardFieldLabel('CIP Office'),
          WizardTextField(controller: controller.cipOfficeController, hint: ''),
        ],
      ),
    );
  }
}
