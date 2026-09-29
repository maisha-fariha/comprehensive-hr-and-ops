import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../controllers/incident_creation_controller.dart';
import 'create_incident_form_fields.dart';

/// Location & People — web create-incident step (BUG_Report011–014).
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
          Text(
            'Link the incident to a location, the people involved, and immediate response.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          const CreateIncidentFieldLabel('Residence', required: true),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-residence'),
              value: controller.residenceLabel,
              placeholder: 'Select residence',
              onTap: controller.pickResidence,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Related Client', required: true),
          CreateIncidentSearchField(
            fieldKey: const Key('staff-incident-client-search'),
            controller: controller.clientSearchController,
            hint: 'Search related client...',
            onChanged: controller.onClientQueryChanged,
          ),
          Obx(() {
            if (!controller.showClientSuggestions.value) {
              return const SizedBox.shrink();
            }
            return _ClientSuggestions(controller: controller);
          }),
          Obx(() {
            final selected = controller.selectedClient.value;
            if (selected == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(
                top: ResponsiveHelper.getResponsiveHeight(context, 8),
              ),
              child: CreateIncidentDropdownField(
                value: selected.name,
                placeholder: 'Related client',
                onTap: controller.pickResident,
              ),
            );
          }),
          fieldGap,
          _CfsDetailsCard(controller: controller),
          fieldGap,
          const CreateIncidentFieldLabel('Reported By Staff'),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-reported-by-staff'),
              value: controller.reportedByStaffLabel ??
                  controller.reporterName.value,
              placeholder: 'Select staff...',
              onTap: controller.pickReportedByStaff,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Supervisor'),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-supervisor-staff'),
              value: controller.supervisorStaffLabel,
              placeholder: 'Select supervisor...',
              onTap: controller.pickSupervisorStaff,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel(
            'Witnesses — staff or residents present',
          ),
          Obx(
            () => _WitnessChipRow(
              witnesses: controller.witnesses.toList(),
              onAdd: controller.promptAddWitness,
              onRemove: controller.removeWitness,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Immediate Action Taken'),
          CreateIncidentTextField(
            key: const Key('staff-incident-immediate-action'),
            controller: controller.immediateActionController,
            hint: 'What was done right away in response to this incident?',
            maxLines: 4,
          ),
          fieldGap,
          Obx(
            () => _PeopleToggle(
              key: const Key('staff-incident-emergency-services'),
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
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Obx(
            () => _PeopleToggle(
              key: const Key('staff-incident-family-notified'),
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
  }
}

class _CfsDetailsCard extends StatelessWidget {
  final IncidentCreationController controller;

  const _CfsDetailsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final fieldGap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 12),
    );
    return Container(
      key: const Key('staff-incident-cfs-details'),
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CFS Details',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(optional)',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          fieldGap,
          const CreateIncidentFieldLabel("Child's I.D. Number"),
          CreateIncidentTextField(
            controller: controller.childIdController,
            hint: "Child's I.D. Number",
          ),
          fieldGap,
          const CreateIncidentFieldLabel('CFS Status'),
          Obx(
            () => Wrap(
              key: const Key('staff-incident-cfs-status'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in IncidentCreationController.cfsStatusOptions)
                  FilterChip(
                    label: Text(option.$2),
                    selected: controller.cfsStatuses.contains(option.$1),
                    onSelected: (_) => controller.toggleCfsStatus(option.$1),
                  ),
                ActionChip(
                  label: const Text('Add status'),
                  onPressed: controller.pickCfsStatus,
                ),
              ],
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel(
            'Child Intervention Practitioner (CIP)',
          ),
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
        ],
      ),
    );
  }
}

class _EmergencyDetails extends StatelessWidget {
  final IncidentCreationController controller;

  const _EmergencyDetails({required this.controller});

  @override
  Widget build(BuildContext context) {
    final fieldGap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 12),
    );
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(
          color: AppColors.cardBorder,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreateIncidentFieldLabel('Which service'),
          Obx(
            () => CreateIncidentDropdownField(
              key: const Key('staff-incident-agency-type'),
              value: controller.externalAgencyTypeLabel,
              placeholder: 'Choose a service',
              onTap: controller.pickExternalAgencyType,
            ),
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Agency reference'),
          CreateIncidentTextField(
            controller: controller.agencyReferenceController,
            hint: 'CAD / incident number, as they gave it',
          ),
          fieldGap,
          const CreateIncidentFieldLabel('Responding station or officer'),
          CreateIncidentTextField(
            controller: controller.agencyResponderController,
            hint: 'Name or station, as given',
          ),
        ],
      ),
    );
  }
}

class _ClientSuggestions extends StatelessWidget {
  final IncidentCreationController controller;

  static const Color _avatarBg = Color(0xFFE8F0FE);
  static const Color _avatarFg = Color(0xFF1D4ED8);
  static const Color _selectedBorder = Color(0xFF2563EB);

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
          maxHeight: ResponsiveHelper.getResponsiveHeight(context, 220),
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: AppColors.searchBorder),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowNavy.withValues(alpha: 0.06),
              offset: Offset(
                0,
                ResponsiveHelper.getResponsiveHeight(context, 4),
              ),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
            ),
          ],
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
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getResponsiveHeight(context, 6),
                horizontal: ResponsiveHelper.getResponsiveWidth(context, 6),
              ),
              itemCount: controller.clientSuggestions.length,
              separatorBuilder: (_, _) => SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 4),
              ),
              itemBuilder: (context, index) {
                final option = controller.clientSuggestions[index];
                final selected =
                    controller.selectedClient.value?.id == option.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 10),
                  ),
                  onTap: () => controller.selectClientFromSearch(option),
                  child: Container(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFEFF6FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, 10),
                      ),
                      border: Border.all(
                        color: selected
                            ? _selectedBorder
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius:
                              ResponsiveHelper.getResponsiveSize(context, 18),
                          backgroundColor: _avatarBg,
                          child: Text(
                            option.initials,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                12,
                              ),
                              color: _avatarFg,
                            ),
                          ),
                        ),
                        SizedBox(
                          width:
                              ResponsiveHelper.getResponsiveWidth(context, 10),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    14,
                                  ),
                                  color: AppColors.textHeading,
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  2,
                                ),
                              ),
                              Text(
                                option.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w400,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    12,
                                  ),
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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

class _PeopleToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PeopleToggle({
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
