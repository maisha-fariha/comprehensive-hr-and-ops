import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/client_extras.dart';
import '../client_files.dart';
import '../client_form.dart';
import '../clients_labels.dart';
import 'clients_common.dart';

const _gap = SizedBox(height: 16);

List<(String, String)> _options(List<String> values) => [for (final v in values) (v, v)];

/// "Basic Information".
class ClientBasicSection extends StatelessWidget {
  final ClientForm form;
  final Map<String, String> errors;
  final bool enabled;
  final VoidCallback onChanged;

  const ClientBasicSection({
    super.key,
    required this.form,
    required this.errors,
    required this.enabled,
    required this.onChanged,
  });

  void _set(VoidCallback update) {
    update();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClientSectionHeader(
          title: 'Basic Information',
          description: 'Personal identity and care classification for the client profile.',
        ),
        _gap,
        ClientFileField(
          label: 'Client Photo',
          hint: 'Image only • JPG, PNG up to 2MB',
          icon: Icons.add_a_photo_outlined,
          fileName: form.photo?.name,
          existingUrl: form.photoUrl,
          onPick: !enabled
              ? null
              : () async {
                  final file = await ClientFiles.pickPhoto();
                  if (file != null) _set(() => form.photo = file);
                },
          onClear: () => _set(() => form.photo = null),
        ),
        _gap,
        ClientInput(
          key: const ValueKey('client-first-name'),
          label: 'First Name',
          required: true,
          placeholder: 'John',
          controller: form.firstName,
          enabled: enabled,
          error: errors['firstName'],
          onChanged: (_) => onChanged(),
        ),
        _gap,
        ClientInput(
          key: const ValueKey('client-last-name'),
          label: 'Last Name',
          required: true,
          placeholder: 'Doe',
          controller: form.lastName,
          enabled: enabled,
          error: errors['lastName'],
          onChanged: (_) => onChanged(),
        ),
        _gap,
        ClientDateField(
          key: const ValueKey('client-dob'),
          label: 'Date of Birth',
          required: true,
          value: form.dob,
          lastDate: DateTime.now(),
          enabled: enabled,
          error: errors['dob'],
          onChanged: (v) => _set(() => form.dob = v),
        ),
        _gap,
        ClientSelect(
          label: 'Gender',
          placeholder: 'Select gender',
          value: form.gender,
          options: _options(ClientsLabels.genders),
          enabled: enabled,
          onChanged: (v) => _set(() => form.gender = v),
        ),
        _gap,
        ClientSelect(
          label: 'Care Level',
          required: true,
          placeholder: 'Select care level',
          value: form.careLevel,
          options: _options(ClientsLabels.careLevels),
          enabled: enabled,
          error: errors['careLevel'],
          onChanged: (v) => _set(() => form.careLevel = v),
        ),
        _gap,
        ClientSelect(
          label: 'Status',
          required: true,
          placeholder: 'Select status',
          value: form.status,
          options: _options(ClientsLabels.statuses),
          enabled: enabled,
          error: errors['status'],
          onChanged: (v) => _set(() => form.status = v),
        ),
      ],
    );
  }
}

/// The web `RoomPicker`.
class ClientRoomPicker extends StatelessWidget {
  final String? residenceId;
  final List<ClientRoom>? rooms;
  final String? value;
  final String? currentRoomId;
  final String label;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const ClientRoomPicker({
    super.key,
    required this.residenceId,
    required this.rooms,
    required this.value,
    required this.onChanged,
    this.currentRoomId,
    this.label = 'Room',
    this.enabled = true,
  });

  static const _none = '__none__';

  @override
  Widget build(BuildContext context) {
    final loading = residenceId != null && rooms == null;
    final all = rooms ?? const <ClientRoom>[];
    final options = <(String, String)>[
      (_none, 'No room yet'),
      for (final r in all)
        if ((r.isActive && r.available > 0) || r.id == currentRoomId)
          (
            r.id,
            r.id == currentRoomId && r.available == 0
                ? '${r.name} — their room now'
                : '${r.name} — ${r.available} free${r.roomType == null ? '' : ' (${r.roomType})'}',
          ),
    ];
    final empty = !loading && all.isEmpty;
    final full = !loading && all.isNotEmpty && options.length == 1;
    final helper = residenceId == null
        ? 'A room belongs to one home — pick the home first'
        : empty
            ? 'This home has no rooms recorded yet — add them on the residence'
            : full
                ? 'Every room in this home is full'
                : 'Only rooms with a bed going spare are listed';
    return ClientSelect(
      key: const ValueKey('client-room-picker'),
      label: label,
      value: value ?? _none,
      options: options,
      placeholder: residenceId == null ? 'Pick a residence first' : 'Which room',
      helper: helper,
      enabled: enabled && residenceId != null && !loading && !empty,
      onChanged: (v) => onChanged(v == _none ? null : v),
    );
  }
}

/// "Residence Assignment".
class ClientResidenceSection extends StatefulWidget {
  final ClientForm form;
  final Map<String, String> errors;
  final bool enabled;
  final bool residenceEnabled;
  final List<(String, String)> residenceOptions;
  final Future<List<ClientRoom>> Function(String residenceId) roomsFor;
  final VoidCallback onChanged;

  const ClientResidenceSection({
    super.key,
    required this.form,
    required this.errors,
    required this.enabled,
    required this.residenceOptions,
    required this.roomsFor,
    required this.onChanged,
    this.residenceEnabled = true,
  });

  @override
  State<ClientResidenceSection> createState() => _ClientResidenceSectionState();
}

class _ClientResidenceSectionState extends State<ClientResidenceSection> {
  String? _loadedFor;
  List<ClientRoom>? _rooms;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void didUpdateWidget(covariant ClientResidenceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final id = widget.form.currentResidence;
    if (id == _loadedFor) return;
    _loadedFor = id;
    _rooms = null;
    if (id.isEmpty) return;
    final rooms = await widget.roomsFor(id);
    if (!mounted || _loadedFor != id) return;
    setState(() => _rooms = rooms);
  }

  void _set(VoidCallback update) {
    update();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final hasRooms = (_rooms?.length ?? 0) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClientSectionHeader(
          title: 'Residence Assignment',
          description: 'Assign the client to an active residence and capture admission details.',
        ),
        _gap,
        ClientSelect(
          key: const ValueKey('client-residence'),
          label: 'Current Residence',
          required: true,
          placeholder: 'Select a residence',
          value: form.currentResidence,
          options: widget.residenceOptions,
          enabled: widget.enabled && widget.residenceEnabled,
          error: widget.errors['currentResidence'],
          onChanged: (v) => _set(() {
            form.currentResidence = v;
            form.roomId = '';
          }),
        ),
        _gap,
        ClientDateField(
          key: const ValueKey('client-admission-date'),
          label: 'Admission Date',
          required: true,
          value: form.admissionDate,
          enabled: widget.enabled,
          error: widget.errors['admissionDate'],
          onChanged: (v) => _set(() => form.admissionDate = v),
        ),
        _gap,
        if (hasRooms)
          ClientRoomPicker(
            residenceId: form.currentResidence.isEmpty ? null : form.currentResidence,
            rooms: _rooms,
            value: form.roomId.isEmpty ? null : form.roomId,
            currentRoomId: form.roomId.isEmpty ? null : form.roomId,
            enabled: widget.enabled,
            onChanged: (v) => _set(() => form.roomId = v ?? ''),
          )
        else
          ClientInput(
            label: 'Room Number',
            placeholder: 'e.g., 204B',
            helper: 'This home has no rooms recorded yet',
            controller: form.roomNumber,
            enabled: widget.enabled,
            onChanged: (_) => widget.onChanged(),
          ),
        _gap,
        ClientSelect(
          label: 'Funding Source',
          placeholder: 'Select funding source',
          value: form.fundingSource,
          options: _options(ClientsLabels.fundingSources),
          enabled: widget.enabled,
          onChanged: (v) => _set(() => form.fundingSource = v),
        ),
        _gap,
        ClientInput(
          label: 'Assignment Notes',
          placeholder: 'Add any residence assignment notes…',
          controller: form.assignmentNotes,
          lines: 3,
          enabled: widget.enabled,
          onChanged: (_) => widget.onChanged(),
        ),
      ],
    );
  }
}

/// Wizard "Family / Guardian": guardian, portal access and visibility.
class ClientGuardianSection extends StatelessWidget {
  final ClientForm form;
  final Map<String, String> errors;
  final VoidCallback onChanged;

  const ClientGuardianSection({
    super.key,
    required this.form,
    required this.errors,
    required this.onChanged,
  });

  void _set(VoidCallback update) {
    update();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClientSectionHeader(
          title: 'Family / Guardian',
          description:
              'Capture guardian contact information and family portal access settings.',
        ),
        _gap,
        ClientInput(
          key: const ValueKey('client-guardian-name'),
          label: 'Guardian Name',
          placeholder: 'e.g., Mary Benson',
          controller: form.guardianName,
          error: errors['guardianName'],
          onChanged: (_) => onChanged(),
        ),
        _gap,
        ClientSelect(
          label: 'Relationship',
          placeholder: 'Select relationship',
          value: form.relationship,
          options: _options(ClientsLabels.relationships),
          onChanged: (v) => _set(() => form.relationship = v),
        ),
        _gap,
        ClientInput(
          key: const ValueKey('client-guardian-phone'),
          label: 'Phone',
          placeholder: '(555) 123-4567',
          keyboardType: TextInputType.phone,
          controller: form.guardianPhone,
          error: errors['guardianPhone'],
          onChanged: (_) => onChanged(),
        ),
        _gap,
        ClientInput(
          key: const ValueKey('client-guardian-email'),
          label: 'Email',
          placeholder: 'guardian@email.com',
          keyboardType: TextInputType.emailAddress,
          controller: form.guardianEmail,
          error: errors['guardianEmail'],
          onChanged: (_) => onChanged(),
        ),
        _gap,
        ClientSwitchTile(
          label: 'Enable Family Portal Access',
          description: 'Grants a secure family login',
          value: form.familyPortalAccess,
          bordered: true,
          onChanged: (v) => _set(() => form.familyPortalAccess = v),
        ),
        _gap,
        _PortalVisibilityCard(form: form, onChanged: onChanged),
        _gap,
        _OutlinedCard(
          icon: Icons.groups_outlined,
          iconColor: const Color(0xFF7656D6),
          iconBackground: const Color(0xFFF0ECFB),
          title: 'Family Communication Settings',
          description: 'Notes kept with the client record.',
          child: ClientInput(
            label: 'Contact Notes',
            placeholder: 'Add family communication notes...',
            controller: form.contactNotes,
            lines: 3,
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

class _OutlinedCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final Widget? badge;
  final Widget child;

  const _OutlinedCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.child,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: handoverText(context, 14.5, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(description, style: handoverText(context, 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PortalVisibilityCard extends StatelessWidget {
  final ClientForm form;
  final VoidCallback onChanged;

  const _PortalVisibilityCard({required this.form, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _OutlinedCard(
      icon: Icons.visibility_outlined,
      iconColor: AppColors.secondaryTeal,
      iconBackground: const Color(0xFFE4F3F2),
      title: 'Family Portal Visibility',
      description:
          'Choose which client information family members can access through the portal.',
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Portal access only',
          style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in portalVisibilityGroups) ...[
            Text(
              group.label.toUpperCase(),
              style: handoverText(context, 12, weight: FontWeight.w600, color: AppColors.infoBlue)
                  .copyWith(letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            for (final item in group.items) ...[
              _VisibilityOption(
                item: item,
                value: form.portalVisibility[item.key] ?? false,
                onTap: () {
                  form.portalVisibility[item.key] = !(form.portalVisibility[item.key] ?? false);
                  onChanged();
                },
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final PortalVisibilityItem item;
  final bool value;
  final VoidCallback onTap;

  const _VisibilityOption({required this.item, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('portal-${item.key}'),
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFF1F8F7) : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: value ? const Color(0xFFCFE6E3) : AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF0E7C7B) : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: value ? const Color(0xFF0E7C7B) : AppColors.cardBorder),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 13, color: AppColors.surfaceWhite)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: handoverText(context, 13, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.description, style: handoverText(context, 12, color: AppColors.textMuted)),
                  if (item.note != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFAF3),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: const Color(0xFFF3E5CB)),
                      ),
                      child: Text(
                        item.note!,
                        style: handoverText(context, 11, color: const Color(0xFF96631A)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Medical Information".
class ClientMedicalSection extends StatelessWidget {
  final ClientForm form;
  final bool enabled;
  final VoidCallback onChanged;

  const ClientMedicalSection({
    super.key,
    required this.form,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClientSectionHeader(
          title: 'Medical Information',
          description:
              'Document medical context, safety risks, allergies, and care considerations.',
        ),
        _gap,
        ClientTagInput(
          key: const ValueKey('client-allergies'),
          label: 'Allergies',
          placeholder: 'Type an allergy and press Enter…',
          values: form.allergies,
          onChanged: !enabled
              ? null
              : (v) {
                  form.allergies = v;
                  onChanged();
                },
        ),
        _gap,
        ClientTagInput(
          label: 'Diagnoses',
          placeholder: 'Type a diagnosis and press Enter…',
          values: form.diagnoses,
          onChanged: !enabled
              ? null
              : (v) {
                  form.diagnoses = v;
                  onChanged();
                },
        ),
        _gap,
        ClientTagInput(
          label: 'Current Medications',
          placeholder: 'Type a medication and press Enter…',
          helper: 'Detailed medication records belong in the MAR module.',
          values: form.currentMedications,
          onChanged: !enabled
              ? null
              : (v) {
                  form.currentMedications = v;
                  onChanged();
                },
        ),
        _gap,
        ClientInput(
          label: 'Doctor Name',
          placeholder: 'e.g., Dr. Sarah Miller',
          controller: form.doctorName,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        ),
        _gap,
        ClientInput(
          label: 'Pharmacy Name',
          placeholder: 'e.g., Oak Pharmacy',
          controller: form.pharmacyName,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        ),
        _gap,
        ClientInput(
          label: 'Behavioral Triggers',
          placeholder: 'e.g., Loud noises, crowds',
          controller: form.behavioralTriggers,
          lines: 3,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        ),
        _gap,
        ClientInput(
          label: 'Safety Plan Notes',
          placeholder: 'e.g., Call guardian first, remove sharp objects.',
          controller: form.safetyPlanNotes,
          lines: 3,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

/// "Care Planning".
class ClientCareSection extends StatelessWidget {
  final ClientForm form;
  final bool enabled;
  final VoidCallback onChanged;

  const ClientCareSection({
    super.key,
    required this.form,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClientSectionHeader(
          title: 'Care Planning',
          description: 'Capture service plan details, goals, outcomes, and progress notes.',
        ),
        _gap,
        ClientInput(
          label: 'Individual Service Plan',
          placeholder: 'Describe the individual service plan…',
          controller: form.servicePlan,
          lines: 3,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        ),
        _gap,
        ClientFileField(
          label: 'Upload Care Plan Document',
          hint: 'PDF or DOCX up to 10MB',
          fileName: form.carePlanDocument?.name,
          onPick: !enabled
              ? null
              : () async {
                  final file = await ClientFiles.pickCarePlan();
                  if (file != null) {
                    form.carePlanDocument = file;
                    onChanged();
                  }
                },
          onClear: () {
            form.carePlanDocument = null;
            onChanged();
          },
        ),
        _gap,
        ClientListEditor(
          key: const ValueKey('client-goals'),
          label: 'Goals',
          addLabel: 'Add Goal',
          items: form.goals,
          onChanged: enabled ? onChanged : null,
        ),
        _gap,
        ClientListEditor(
          label: 'Outcomes',
          addLabel: 'Add Outcome',
          items: form.outcomes,
          onChanged: enabled ? onChanged : null,
        ),
        _gap,
        ClientInput(
          label: 'Progress Notes',
          placeholder: 'Add progress notes…',
          controller: form.progressNotes,
          lines: 3,
          enabled: enabled,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
