import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../controllers/incident_creation_controller.dart';
import '../wizard_form_fields.dart';
import '../wizard_section_header.dart';
import '../witness_chip_row.dart';

/// Step 2 of the "Create Incident" wizard - "People & Location".
/// UI matched to the People & Location reference.
class Step2PeopleForm extends StatelessWidget {
  final IncidentCreationController controller;

  /// Soft blue badge + navy numeral from the Step 2 reference.
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
              WizardSearchField(
                controller: controller.involvedClientController,
                hint: 'Search client...',
              ),
              gap,
              const WizardFieldLabel('Staff Involved'),
              WizardSearchField(
                controller: controller.staffInvolvedController,
                hint: 'Search staff...',
              ),
              gap,
              const WizardFieldLabel('Reported By'),
              Obx(
                () => WizardDropdownField(
                  value: controller.reportedBy.value,
                  placeholder: 'Select reporter',
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
                  onAddWitness: () => controller.addWitness(
                    'Witness ${controller.witnesses.length + 1}',
                  ),
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
