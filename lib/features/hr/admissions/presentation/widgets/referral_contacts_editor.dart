import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import 'admissions_common.dart';

class _ContactDraft {
  final String? id;
  final TextEditingController name;
  final TextEditingController relationship;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController address;
  bool isPrimaryGuardian;
  bool isEmergencyContact;

  _ContactDraft({
    this.id,
    String name = '',
    String relationship = '',
    String phone = '',
    String email = '',
    String address = '',
    this.isPrimaryGuardian = false,
    this.isEmergencyContact = true,
  })  : name = TextEditingController(text: name),
        relationship = TextEditingController(text: relationship),
        phone = TextEditingController(text: phone),
        email = TextEditingController(text: email),
        address = TextEditingController(text: address);

  factory _ContactDraft.from(ReferralContact c) => _ContactDraft(
        id: c.id,
        name: c.name,
        relationship: c.relationship ?? '',
        phone: c.phone ?? '',
        email: c.email ?? '',
        address: c.address ?? '',
        isPrimaryGuardian: c.isPrimaryGuardian,
        isEmergencyContact: c.isEmergencyContact,
      );

  Map<String, dynamic> toJson() {
    String? t(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    return {
      'id': ?id,
      'name': name.text.trim(),
      'relationship': ?t(relationship),
      'phone': ?t(phone),
      'email': ?t(email),
      'address': ?t(address),
      'isPrimaryGuardian': isPrimaryGuardian,
      'isEmergencyContact': isEmergencyContact,
    };
  }

  void dispose() {
    for (final c in [name, relationship, phone, email, address]) {
      c.dispose();
    }
  }
}

/// "Family and guardians" editor: add, edit and remove contacts, then save
/// the whole list in one `PUT`.
class ReferralContactsEditor extends StatefulWidget {
  final List<ReferralContact> initial;

  /// Returns the error message, or null once saved.
  final Future<String?> Function(List<Map<String, dynamic>> contacts) onSave;

  const ReferralContactsEditor({
    super.key,
    required this.initial,
    required this.onSave,
  });

  @override
  State<ReferralContactsEditor> createState() => _ReferralContactsEditorState();
}

class _ReferralContactsEditorState extends State<ReferralContactsEditor> {
  late final List<_ContactDraft> _rows =
      widget.initial.map(_ContactDraft.from).toList();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _remove(int index) {
    final removed = _rows.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_rows.any((r) => r.name.text.trim().isEmpty)) {
      setState(() => _error = 'Every contact needs a name.');
      return;
    }
    setState(() => _saving = true);
    final error = await widget.onSave([for (final r in _rows) r.toJson()]);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          AdmissionErrorBanner(_error!, key: const ValueKey('contacts-error')),
          gap,
        ],
        for (var i = 0; i < _rows.length; i++) ...[
          Container(
            key: ValueKey('contact-row-$i'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdmissionInput(
                  key: ValueKey('contact-name-$i'),
                  label: 'Name',
                  required: true,
                  controller: _rows[i].name,
                ),
                gap,
                AdmissionInput(
                  key: ValueKey('contact-relationship-$i'),
                  label: 'Relationship',
                  placeholder: 'Daughter, son, solicitor…',
                  controller: _rows[i].relationship,
                ),
                gap,
                AdmissionInput(
                  key: ValueKey('contact-phone-$i'),
                  label: 'Phone',
                  controller: _rows[i].phone,
                  keyboardType: TextInputType.phone,
                ),
                gap,
                AdmissionInput(
                  key: ValueKey('contact-email-$i'),
                  label: 'Email',
                  controller: _rows[i].email,
                  keyboardType: TextInputType.emailAddress,
                ),
                gap,
                AdmissionInput(
                  key: ValueKey('contact-address-$i'),
                  label: 'Address',
                  controller: _rows[i].address,
                ),
                gap,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          AdmissionCheckbox(
                            key: ValueKey('contact-guardian-$i'),
                            label: 'Decides on their behalf',
                            value: _rows[i].isPrimaryGuardian,
                            onChanged: (v) =>
                                setState(() => _rows[i].isPrimaryGuardian = v),
                          ),
                          AdmissionCheckbox(
                            key: ValueKey('contact-emergency-$i'),
                            label: 'Called first in an emergency',
                            value: _rows[i].isEmergencyContact,
                            onChanged: (v) =>
                                setState(() => _rows[i].isEmergencyContact = v),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: ValueKey('contact-remove-$i'),
                      tooltip:
                          'Remove ${_rows[i].name.text.isEmpty ? 'contact' : _rows[i].name.text}',
                      onPressed: () => _remove(i),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          gap,
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            HandoverButton(
              key: const ValueKey('contacts-add'),
              label: 'Add a contact',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: () => setState(() => _rows.add(_ContactDraft())),
            ),
            HandoverButton(
              key: const ValueKey('contacts-save'),
              label: _saving ? 'Saving…' : 'Save contacts',
              filled: true,
              compact: true,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ],
    );
  }
}
