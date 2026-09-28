import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import 'create_incident_form_fields.dart';

/// People & Location section for Staff Create Incident (BUG_Report011–014).
class CreateIncidentPeopleLocationSection extends StatelessWidget {
  final IncidentCreationController controller;

  const CreateIncidentPeopleLocationSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final fieldGap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 16),
    );

    return Container(
      key: const Key('staff-incident-people-location'),
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(
              0,
              ResponsiveHelper.getResponsiveHeight(context, 4),
            ),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreateIncidentFieldLabel('Residence', required: true),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-residence'),
              value: controller.residenceLabel,
              placeholder: 'Select residence...',
              onTap: controller.pickResidence,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Client Search', required: true),
          CreateIncidentSearchField(
            fieldKey: const Key('staff-incident-client-search'),
            controller: controller.clientSearchController,
            hint: 'Search client...',
            onChanged: controller.onClientQueryChanged,
          ),
          Obx(() {
            if (!controller.showClientSuggestions.value) {
              return const SizedBox.shrink();
            }
            return _ClientSuggestions(controller: controller);
          }),
          fieldGap,
          const CreateIncidentFieldLabel('Resident / Client', required: true),
          Obx(
            () => CreateIncidentDropdownField(
              value: controller.residentLabel,
              placeholder: 'Select resident...',
              onTap: controller.pickResident,
            ),
          ),
          fieldGap,
          Text(
            'CFS Details',
            key: const Key('staff-incident-cfs-details'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          const CreateIncidentFieldLabel('CFS Status'),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-cfs-status'),
              value: controller.cfsStatusLabel,
              placeholder: 'Select CFS status...',
              onTap: controller.pickCfsStatus,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Child Last Name'),
          CreateIncidentTextField(
            controller: controller.childLastNameController,
            hint: 'Last name',
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Child First Name'),
          CreateIncidentTextField(
            controller: controller.childFirstNameController,
            hint: 'First name',
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Date of Birth'),
          CreateIncidentTextField(
            controller: controller.childDobController,
            hint: 'MM/DD/YYYY',
          ),
          fieldGap,
          const CreateIncidentFieldLabel("Child's I.D. Number"),
          CreateIncidentTextField(
            controller: controller.childIdController,
            hint: 'I.D. number',
          ),
          fieldGap,
          const CreateIncidentFieldLabel('CIP (Child Intervention Practitioner)'),
          CreateIncidentTextField(
            controller: controller.cipController,
            hint: 'CIP name',
          ),
          fieldGap,
          const CreateIncidentFieldLabel('CIP Office'),
          CreateIncidentTextField(
            controller: controller.cipOfficeController,
            hint: 'Office',
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Staff Involved'),
          CreateIncidentTextField(
            key: const Key('staff-incident-staff-involved'),
            controller: controller.staffInvolvedController,
            hint: 'Staff name(s)',
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Location', required: true),
          CreateIncidentTextField(
            controller: controller.locationController,
            hint: 'e.g. Bathroom 2',
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Witness Information'),
          Obx(
            () => _WitnessChipRow(
              witnesses: controller.witnesses.toList(),
              onAdd: controller.promptAddWitness,
              onRemove: controller.removeWitness,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Reported By'),
          Obx(
            () => _ReportedByField(
              name: controller.reporterName.value,
              meta: controller.reporterMeta.value,
              initials: controller.reporterInitials.value,
            ),
          ),
          fieldGap,
          Obx(
            () => _PeopleLocationToggle(
              key: const Key('staff-incident-cfs-notified'),
              title: 'CFS notified',
              subtitle: 'Children and Family Services has been informed',
              value: controller.cfsNotified.value,
              onChanged: (v) => controller.cfsNotified.value = v,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Obx(
            () => _PeopleLocationToggle(
              key: const Key('staff-incident-police-notified'),
              title: 'Police / authorities notified',
              subtitle: 'Emergency services were contacted',
              value: controller.policeNotified.value,
              onChanged: (v) => controller.policeNotified.value = v,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientSuggestions extends StatelessWidget {
  final IncidentCreationController controller;

  const _ClientSuggestions({required this.controller});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);
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
          if (controller.isSearchingClients.value &&
              controller.clientSuggestions.isEmpty) {
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
          if (controller.clientSuggestions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No clients found.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return Material(
            color: Colors.transparent,
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: controller.clientSuggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final option = controller.clientSuggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    option.name,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: option.subtitle.isEmpty
                      ? null
                      : Text(
                          option.subtitle,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textMuted,
                          ),
                        ),
                  onTap: () => controller.selectClientFromSearch(option),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _WitnessChipRow extends StatelessWidget {
  final List<String> witnesses;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _WitnessChipRow({
    required this.witnesses,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in witnesses)
          InputChip(
            label: Text(name),
            onDeleted: () => onRemove(name),
          ),
        ActionChip(
          key: const Key('staff-incident-add-witness'),
          avatar: const Icon(Icons.add, size: 16),
          label: const Text('Add witness'),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _PeopleLocationToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PeopleLocationToggle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F5),
        border: Border.all(color: const Color(0xFFB7E0DB)),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 2),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.secondaryTeal,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.cardBorder,
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _ReportedByField extends StatelessWidget {
  final String name;
  final String meta;
  final String initials;

  const _ReportedByField({
    required this.name,
    required this.meta,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F9),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveHelper.getResponsiveSize(context, 18),
            backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.15),
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  meta.isEmpty ? 'Auto' : meta,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
