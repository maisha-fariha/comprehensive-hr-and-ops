import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/residence_form.dart';
import '../../domain/entities/residence_summary.dart';
import '../residences_labels.dart';
import 'residence_form_inputs.dart';

/// State shared by the wizard steps.
class ResidenceFormBinding {
  final ResidenceFormValues values;
  final Map<String, String> errors;
  final List<ResidenceStaffOption> staff;
  final bool staffLoading;
  final List<String> enabledTypes;
  final TextEditingController Function(String field, String initial) text;
  final void Function(VoidCallback change) update;

  const ResidenceFormBinding({
    required this.values,
    required this.errors,
    required this.staff,
    required this.staffLoading,
    required this.enabledTypes,
    required this.text,
    required this.update,
  });

  String get staffPlaceholder =>
      staffLoading ? 'Loading staff…' : 'Select a staff member';

  List<(String, String)> get staffOptions => [for (final s in staff) (s.id, s.label)];

  String? staffName(String id) {
    if (id.isEmpty) return null;
    for (final s in staff) {
      if (s.id == id) return s.label;
    }
    return null;
  }

  Widget input(
    String field,
    String label,
    String current,
    void Function(String v) set, {
    String? placeholder,
    String? helper,
    bool required = false,
    bool numeric = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return ResidenceTextInput(
      field: field,
      label: label,
      controller: text(field, current),
      onChanged: (v) => update(() {
        set(v);
        errors.remove(field);
      }),
      placeholder: placeholder,
      helper: helper,
      error: errors[field],
      required: required,
      numeric: numeric,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }
}

class ResidenceBasicStep extends StatelessWidget {
  final ResidenceFormBinding b;

  const ResidenceBasicStep({super.key, required this.b});

  static const _typeIcons = {
    'Assisted Living': (Icons.verified_user_outlined, AppColors.secondaryTeal),
    'Skilled Nursing': (Icons.assignment_outlined, AppColors.criticalRed),
    'Memory Care': (Icons.lightbulb_outline_rounded, AppColors.nightPurple),
    'Independent Living': (Icons.place_outlined, AppColors.urgentAmber),
    'Group Home': (Icons.home_outlined, AppColors.criticalRed),
  };

  @override
  Widget build(BuildContext context) {
    final v = b.values;
    final types = b.enabledTypes.isEmpty
        ? [for (final (value, _, _) in ResidencesLabels.residenceTypes) value]
        : b.enabledTypes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidenceFormCard(
          icon: Icons.apartment_rounded,
          title: 'Basic Information',
          description: 'Identify the residence and set its operational status.',
          children: [
            b.input('name', 'Residence Name', v.name, (x) => v.name = x,
                placeholder: 'e.g. Sunrise House', required: true),
            b.input('phone', 'Phone Number', v.phone, (x) => v.phone = x,
                keyboardType: TextInputType.phone),
            b.input('emergencyContact', 'Emergency Contact Number', v.emergencyContact,
                (x) => v.emergencyContact = x,
                keyboardType: TextInputType.phone),
          ],
        ),
        const SizedBox(height: 12),
        ResidenceFormCard(
          icon: Icons.home_outlined,
          title: 'Residence Type',
          description: 'Determines default care workflows and compliance rules.',
          children: [
            for (final type in types)
              ResidenceChoiceCard(
                key: ValueKey('residence-type-$type'),
                label: ResidencesLabels.typeLabel(type),
                description: ResidencesLabels.typeDescription(type),
                icon: _typeIcons[type]?.$1 ?? Icons.home_outlined,
                tone: _typeIcons[type]?.$2 ?? AppColors.infoBlue,
                selected: v.type == type,
                onTap: () => b.update(() {
                  v.type = type;
                  b.errors.remove('type');
                }),
              ),
            if (b.errors['type'] != null) residenceFieldError(context, b.errors['type']),
          ],
        ),
        const SizedBox(height: 12),
        ResidenceFormCard(
          icon: Icons.verified_user_outlined,
          title: 'Status',
          description: 'Set whether the residence is live and accepting clients.',
          children: [
            Row(
              children: [
                for (final status in ResidencesLabels.lifecycleStatuses) ...[
                  if (status != ResidencesLabels.lifecycleStatuses.first) const SizedBox(width: 8),
                  Expanded(
                    child: ResidenceChoiceCard(
                      key: ValueKey('residence-status-$status'),
                      label: status,
                      compact: true,
                      icon: switch (status) {
                        'Active' => Icons.check_circle_outline_rounded,
                        'Pending' => Icons.schedule_rounded,
                        _ => Icons.cancel_outlined,
                      },
                      tone: switch (status) {
                        'Active' => AppColors.activeGreen,
                        'Pending' => AppColors.urgentAmber,
                        _ => AppColors.criticalRed,
                      },
                      selected: v.lifecycleStatus == status,
                      onTap: () => b.update(() => v.lifecycleStatus = status),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ResidenceAddressStep extends StatelessWidget {
  final ResidenceFormBinding b;

  const ResidenceAddressStep({super.key, required this.b});

  @override
  Widget build(BuildContext context) {
    final v = b.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidenceFormCard(
          icon: Icons.place_outlined,
          title: 'Address',
          description: 'Physical location of the residence.',
          children: [
            b.input('streetAddress', 'Street Address', v.streetAddress, (x) => v.streetAddress = x,
                placeholder: '1420 Lakeside Drive', required: true),
            b.input('city', 'City', v.city, (x) => v.city = x,
                placeholder: 'Portland', required: true),
            b.input('state', 'State / Region', v.state, (x) => v.state = x,
                placeholder: 'Oregon', required: true),
            b.input('postalCode', 'Postal Code', v.postalCode, (x) => v.postalCode = x,
                placeholder: '97035', required: true),
            ResidenceSelectInput(
              field: 'country',
              label: 'Country',
              required: true,
              value: v.country,
              options: [for (final c in ResidencesLabels.countries) (c, c)],
              error: b.errors['country'],
              onChanged: (x) => b.update(() {
                v.country = x;
                b.errors.remove('country');
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ResidenceFormCard(
          icon: Icons.navigation_outlined,
          title: 'GPS Coordinates & Geofence',
          description: 'Used for staff geofenced attendance and location checks.',
          children: [
            b.input('latitude', 'Latitude', v.latitude, (x) => v.latitude = x,
                placeholder: '45.5231',
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
            b.input('longitude', 'Longitude', v.longitude, (x) => v.longitude = x,
                placeholder: '-122.6765',
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
            ResidenceSelectInput(
              field: 'timeZone',
              label: 'Time Zone',
              value: v.timeZone,
              options: ResidencesLabels.timeZones,
              onChanged: (x) => b.update(() => v.timeZone = x),
            ),
            b.input('geofenceRadius', 'Geofence Radius (meters)', v.geofenceRadius,
                (x) => v.geofenceRadius = x,
                numeric: true,
                helper: 'Radius used to validate staff clock-in proximity.'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_outlined, size: 16, color: AppColors.infoBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enable GPS Tracking',
                            style: handoverText(context, 13.5, weight: FontWeight.w600)),
                        Text('Require staff to be within the geofence to clock in.',
                            style: handoverText(context, 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Switch(
                    key: const ValueKey('residence-field-enableGpsTracking'),
                    value: v.enableGpsTracking,
                    activeTrackColor: AppColors.secondaryTeal,
                    onChanged: (x) => b.update(() => v.enableGpsTracking = x),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ResidenceCapacityStep extends StatelessWidget {
  final ResidenceFormBinding b;

  const ResidenceCapacityStep({super.key, required this.b});

  @override
  Widget build(BuildContext context) {
    final v = b.values;
    final declared = v.isDeclaredOccupancy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidenceFormCard(
          icon: Icons.bed_outlined,
          title: 'Bed Capacity',
          description: 'Total beds and current availability for this residence.',
          children: [
            b.input('totalBeds', 'Total Capacity / Beds', v.totalBeds, (x) => v.totalBeds = x,
                numeric: true, required: true, helper: 'beds'),
            _readOnly(context, 'Available Beds', '${v.calculatedAvailableBeds}', 'calculated',
                key: const ValueKey('residence-available-beds')),
            if (declared)
              b.input('initialOccupiedBeds', 'Occupied Beds', v.initialOccupiedBeds,
                  (x) => v.initialOccupiedBeds = x,
                  numeric: true, helper: 'already taken')
            else
              _readOnly(context, 'Occupied Beds', '${v.calculatedOccupiedBeds}', 'in use'),
            Text(
              declared
                  ? 'If people already live here, say how many beds they take. It is a starting '
                      'figure only — once residents are added as clients, the real count replaces it.'
                  : 'Occupancy comes from active client assignments. Available beds are '
                      'Total − Occupied, worked out on the server.',
              style: handoverText(context, 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ResidenceFormCard(
          icon: Icons.schedule_rounded,
          title: 'Operations',
          description: 'Operating hours, time zone and service configuration.',
          children: [
            b.input('operatingHours', 'Operating Hours', v.operatingHours,
                (x) => v.operatingHours = x,
                placeholder: '24 Hours / Day'),
            ResidenceSelectInput(
              field: 'serviceType',
              label: 'Service Type',
              value: v.serviceType,
              options: [for (final s in ResidencesLabels.serviceTypes) (s, s)],
              onChanged: (x) => b.update(() => v.serviceType = x),
            ),
            b.input('operationsNotes', 'Notes', v.operationsNotes, (x) => v.operationsNotes = x,
                maxLines: 5,
                placeholder: 'Overnight nursing on-call. New admissions reviewed weekly by the '
                    'clinical lead.'),
          ],
        ),
      ],
    );
  }

  Widget _readOnly(BuildContext context, String label, String value, String unit, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFE3E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.textMuted)),
          ),
          Text(value, style: handoverText(context, 20, weight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(unit, style: handoverText(context, 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class ResidenceManagementStep extends StatelessWidget {
  final ResidenceFormBinding b;

  const ResidenceManagementStep({super.key, required this.b});

  @override
  Widget build(BuildContext context) {
    final v = b.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidenceFormCard(
          icon: Icons.people_outline_rounded,
          title: 'Management',
          description: 'Assign the leadership responsible for this residence.',
          children: [
            ResidenceSelectInput(
              field: 'primaryManager',
              label: 'Primary Manager',
              value: v.primaryManager.isEmpty ? null : v.primaryManager,
              options: b.staffOptions,
              placeholder: b.staffPlaceholder,
              searchable: true,
              onChanged: (x) => b.update(() => v.primaryManager = x),
            ),
            ResidenceSelectInput(
              field: 'assistantManager',
              label: 'Assistant Manager',
              value: v.assistantManager.isEmpty ? null : v.assistantManager,
              options: b.staffOptions,
              placeholder: b.staffPlaceholder,
              searchable: true,
              onChanged: (x) => b.update(() => v.assistantManager = x),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ResidenceFormCard(
          icon: Icons.people_outline_rounded,
          title: 'Assigned Staff & Care Team',
          description: 'Staff members and clinical team supporting this residence.',
          children: [
            ResidenceStaffChips(
              field: 'assignedStaff',
              label: 'Assigned Staff',
              value: v.assignedStaff,
              options: b.staff,
              placeholder: 'Add staff…',
              onChanged: (x) => b.update(() => v.assignedStaff = x),
            ),
            ResidenceStaffChips(
              field: 'careTeam',
              label: 'Care Team',
              value: v.careTeam,
              options: b.staff,
              placeholder: 'Add care team…',
              onChanged: (x) => b.update(() => v.careTeam = x),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ResidenceFormCard(
          icon: Icons.phone_outlined,
          title: 'Contact Information',
          description: 'Direct line for management enquiries and escalations.',
          children: [
            b.input('managementPhone', 'Management Phone', v.managementPhone,
                (x) => v.managementPhone = x,
                keyboardType: TextInputType.phone),
            b.input('managementEmail', 'Management Email', v.managementEmail,
                (x) => v.managementEmail = x,
                keyboardType: TextInputType.emailAddress),
          ],
        ),
      ],
    );
  }
}

class ResidenceReviewStep extends StatelessWidget {
  final ResidenceFormBinding b;
  final ValueChanged<ResidenceFormStep> onEditStep;

  const ResidenceReviewStep({super.key, required this.b, required this.onEditStep});

  @override
  Widget build(BuildContext context) {
    final v = b.values;
    String names(List<String> ids) =>
        ids.map(b.staffName).whereType<String>().join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.secondaryTeal.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review before creating',
                  style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.secondaryTeal)),
              const SizedBox(height: 4),
              Text(
                'Confirm the details below. You can edit any section before the residence is registered.',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _section(context, Icons.apartment_rounded, 'Residence Information', ResidenceFormStep.basic, [
          ('Residence Name', v.name),
          ('Type', v.type),
          ('Status', v.lifecycleStatus),
          ('Emergency Contact', v.emergencyContact),
        ]),
        _section(context, Icons.place_outlined, 'Address', ResidenceFormStep.address, [
          ('Street Address', v.streetAddress),
          ('City / Region', [v.city, v.state].where((s) => s.isNotEmpty).join(', ')),
          ('Country', v.country),
          ('Coordinates',
              v.latitude.isNotEmpty && v.longitude.isNotEmpty ? '${v.latitude}, ${v.longitude}' : ''),
          ('Geofence',
              '${v.geofenceRadius.isEmpty ? '0' : v.geofenceRadius} m · GPS tracking '
                  '${v.enableGpsTracking ? 'on' : 'off'}'),
        ]),
        _section(context, Icons.bed_outlined, 'Capacity & Operations', ResidenceFormStep.capacity, [
          ('Total Beds', v.totalBeds),
          ('Available Beds', v.availableBeds),
          ('Operating Hours', v.operatingHours),
          ('Service Type', v.serviceType),
        ]),
        _section(context, Icons.people_outline_rounded, 'Management & Staff',
            ResidenceFormStep.management, [
          ('Primary Manager', b.staffName(v.primaryManager) ?? '—'),
          ('Assigned Staff', names(v.assignedStaff)),
          ('Care Team', names(v.careTeam)),
          ('Management Phone', v.managementPhone),
        ]),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    IconData icon,
    String title,
    ResidenceFormStep step,
    List<(String, String)> rows,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HandoverPanel(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.secondaryTeal),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: handoverText(context, 13, weight: FontWeight.w600))),
                  TextButton.icon(
                    key: ValueKey('residence-review-edit-${step.name}'),
                    onPressed: () => onEditStep(step),
                    icon: const Icon(Icons.edit_outlined, size: 12, color: AppColors.secondaryTeal),
                    label: Text('Edit',
                        style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.secondaryTeal)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.dividerLight),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  for (final (label, value) in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: handoverText(context, 12.5, color: AppColors.textMuted)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              value.isEmpty ? '—' : value,
                              textAlign: TextAlign.right,
                              style: handoverText(context, 12.5, weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Web side panel "Residence Preview" / "Live summary".
class ResidencePreviewCard extends StatelessWidget {
  final ResidenceFormValues values;

  const ResidencePreviewCard({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final v = values;
    final location = v.city.isNotEmpty && v.state.isNotEmpty
        ? '${v.city}, ${v.state}'
        : (v.city.isNotEmpty ? v.city : 'Location not set yet');
    final total = int.tryParse(v.totalBeds.trim());
    final free = int.tryParse(v.availableBeds.trim());
    final totalSet = total != null && total != 0;
    final freeSet = free != null && free != 0;
    final capacity = totalSet ? '${freeSet ? total - free : total} / $total' : 'Not set';
    return HandoverPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 16, color: AppColors.secondaryTeal),
                const SizedBox(width: 8),
                Text('Residence Preview', style: handoverText(context, 13, weight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text('Live summary', style: handoverText(context, 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1C2E4A), Color(0xFF24406B)]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.name.isEmpty ? 'New Residence' : v.name,
                        style: handoverText(context, 16, weight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    if (v.type.isNotEmpty)
                      Text(
                        v.type.toUpperCase(),
                        style: handoverText(context, 10, weight: FontWeight.w700, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(location, style: handoverText(context, 11.5, color: Colors.white70)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                _row(context, 'Type', Text(v.type, style: handoverText(context, 12.5, weight: FontWeight.w500))),
                _row(
                  context,
                  'Status',
                  AttendancePill(
                    label: v.lifecycleStatus,
                    tone: ResidencesLabels.lifecycleTone(v.lifecycleStatus),
                  ),
                ),
                _row(context, 'Phone',
                    Text(v.phone.isEmpty ? 'Not set' : v.phone, style: handoverText(context, 12.5, weight: FontWeight.w500))),
                _row(context, 'Capacity',
                    Text(capacity, style: handoverText(context, 12.5, weight: FontWeight.w500))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, Widget value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: handoverText(context, 12.5, color: AppColors.textMuted))),
            value,
          ],
        ),
      );
}

/// Web "Setup Progress" and the "Almost there" note.
class ResidenceSetupProgress extends StatelessWidget {
  final int currentIndex;

  const ResidenceSetupProgress({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final steps = ResidenceFormStep.values.where((s) => s != ResidenceFormStep.review).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HandoverPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Setup Progress', style: handoverText(context, 13, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < currentIndex ? AppColors.secondaryTeal : Colors.transparent,
                          border: i < currentIndex ? null : Border.all(color: AppColors.cardBorder),
                        ),
                        child: i < currentIndex
                            ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        ResidencesLabels.progressLabel(steps[i]),
                        style: handoverText(
                          context,
                          12.5,
                          color: i < currentIndex ? AppColors.textHeading : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFAF3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF3E6D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 16, color: Color(0xFFE9A23B)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Almost there',
                        style: handoverText(context, 12.5, weight: FontWeight.w600, color: const Color(0xFFA9791F))),
                    Text('Complete all 5 steps to register the residence into the directory.',
                        style: handoverText(context, 11.5, color: const Color(0xFFA98A4A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
