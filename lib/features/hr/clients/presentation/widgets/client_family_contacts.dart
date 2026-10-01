import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/client_extras.dart';
import '../client_form.dart';
import '../clients_labels.dart';
import '../controllers/clients_controller.dart';
import 'clients_common.dart';

class _ContactDraft {
  final name = TextEditingController();
  final relationship = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  bool isPrimaryGuardian = false;
  bool isEmergencyContact = false;
  bool receiveNotifications = true;
  bool emergencyAlerts = true;
  bool portalAccess = false;

  _ContactDraft();

  factory _ContactDraft.from(ClientFamilyMember m) {
    final d = _ContactDraft()
      ..isPrimaryGuardian = m.isPrimaryGuardian
      ..isEmergencyContact = m.isEmergencyContact
      ..receiveNotifications = m.receiveNotifications
      ..emergencyAlerts = m.emergencyAlerts
      ..portalAccess = m.hasPortalAccess;
    d.name.text = m.name;
    d.relationship.text = m.relationship ?? '';
    d.email.text = m.email ?? '';
    d.phone.text = m.phone ?? '';
    return d;
  }

  void dispose() {
    name.dispose();
    relationship.dispose();
    email.dispose();
    phone.dispose();
  }
}

/// Web record section "Family / Guardian": the contacts on the record, with
/// add / edit / remove when editing.
class ClientFamilyContacts extends StatefulWidget {
  final ClientsController controller;
  final String clientId;
  final bool readOnly;
  final ValueChanged<int>? onCount;

  const ClientFamilyContacts({
    super.key,
    required this.controller,
    required this.clientId,
    required this.readOnly,
    this.onCount,
  });

  @override
  State<ClientFamilyContacts> createState() => _ClientFamilyContactsState();
}

class _ClientFamilyContactsState extends State<ClientFamilyContacts> {
  List<ClientFamilyMember> _members = const [];
  bool _loading = true;
  String? _editingId;
  _ContactDraft? _draft;
  Map<String, String> _errors = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.controller.loadFamily(widget.clientId);
    if (!mounted) return;
    setState(() {
      _members = result.when(success: (m) => m, failure: (_) => const []);
      _loading = false;
    });
    widget.onCount?.call(_members.length);
  }

  void _open(ClientFamilyMember? member) {
    _draft?.dispose();
    setState(() {
      _editingId = member?.id;
      _draft = member == null ? _ContactDraft() : _ContactDraft.from(member);
      _errors = {};
    });
  }

  void _close() {
    _draft?.dispose();
    setState(() {
      _editingId = null;
      _draft = null;
      _errors = {};
    });
  }

  ClientFamilyMember? get _editing {
    for (final m in _members) {
      if (m.id == _editingId) return m;
    }
    return null;
  }

  Future<void> _save() async {
    final d = _draft;
    if (d == null) return;
    final errors = <String, String>{};
    final name = requiredNameError(d.name.text, 'Name');
    final phone = optionalPhoneError(d.phone.text);
    final email = optionalEmailError(d.email.text);
    if (name != null) errors['name'] = name;
    if (phone != null) errors['phone'] = phone;
    if (email != null) {
      errors['email'] = email;
    } else if (d.portalAccess && d.email.text.trim().isEmpty) {
      errors['email'] = 'An email address is needed to give portal access';
    }
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    final hasUser = _editing?.hasPortalAccess ?? false;
    final relationship = d.relationship.text.trim();
    final emailText = d.email.text.trim();
    final phoneText = d.phone.text.trim();
    final base = <String, dynamic>{
      'name': d.name.text.trim(),
      'isPrimaryGuardian': d.isPrimaryGuardian,
      'isEmergencyContact': d.isEmergencyContact,
      'receiveNotifications': d.receiveNotifications,
      'emergencyAlerts': d.emergencyAlerts,
    };
    final body = _editingId == null
        ? {
            ...base,
            'createPortalUser': d.portalAccess,
            if (relationship.isNotEmpty) 'relationship': relationship,
            if (emailText.isNotEmpty) 'email': emailText,
            if (phoneText.isNotEmpty) 'phone': phoneText,
          }
        : {
            ...base,
            if (d.portalAccess && !hasUser) 'createPortalUser': true,
            'relationship': relationship.isEmpty ? null : relationship,
            'email': emailText.isEmpty ? null : emailText,
            'phone': phoneText.isEmpty ? null : phoneText,
          };
    setState(() => _saving = true);
    final error = await widget.controller.saveFamilyMember(
      widget.clientId,
      body,
      memberId: _editingId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      _close();
      await _load();
    }
  }

  Future<void> _remove(ClientFamilyMember member) async {
    final ok = await confirmClientAction(
      context,
      title: 'Remove ${member.name.isEmpty ? 'this contact' : member.name}?',
      description: 'They stop receiving updates and lose portal access. '
          'The record is kept for the audit trail.',
      confirmLabel: 'Remove',
      confirmKey: const ValueKey('client-contact-remove-confirm'),
    );
    if (!ok) return;
    final removed = await widget.controller.removeFamilyMember(widget.clientId, member.id);
    if (removed && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final muted = handoverText(context, 13, color: AppColors.textMuted);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Family / Guardian', style: handoverText(context, 14.5, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            'Relatives on this record, who to reach first, and what reaches them.',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          if (_loading) Text('Loading contacts…', style: muted),
          if (!_loading && _members.isEmpty && _draft == null)
            Text('No family contacts on this record yet.', style: muted),
          for (final m in _members) ...[
            _ContactCard(
              member: m,
              readOnly: widget.readOnly,
              onEdit: () => _open(m),
              onRemove: () => _remove(m),
            ),
            const SizedBox(height: 10),
          ],
          if (_draft != null) _editor(context, _draft!),
          if (!widget.readOnly && _draft == null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: HandoverButton(
                key: const ValueKey('client-contact-add'),
                label: 'Add contact',
                icon: Icons.add_rounded,
                onPressed: () => _open(null),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _editor(BuildContext context, _ContactDraft d) {
    final hasUser = _editing?.hasPortalAccess ?? false;
    void set(VoidCallback f) => setState(f);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClientInput(
            key: const ValueKey('client-contact-name'),
            label: 'Name',
            required: true,
            controller: d.name,
            error: _errors['name'],
          ),
          const SizedBox(height: 12),
          ClientInput(
            label: 'Relationship',
            placeholder: 'Daughter, son, spouse…',
            controller: d.relationship,
          ),
          const SizedBox(height: 12),
          ClientInput(
            label: 'Phone',
            placeholder: '(555) 123-4567',
            keyboardType: TextInputType.phone,
            controller: d.phone,
            error: _errors['phone'],
          ),
          const SizedBox(height: 12),
          ClientInput(
            key: const ValueKey('client-contact-email'),
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            controller: d.email,
            error: _errors['email'],
            helper: 'Where an invitation would be sent.',
          ),
          const SizedBox(height: 12),
          ClientSwitchTile(
            key: const ValueKey('client-contact-portal'),
            label: 'Family portal access',
            description: hasUser
                ? 'Already has a login. Remove it from the People directory.'
                : 'Sends an invitation so they can sign in and follow this resident.',
            value: d.portalAccess,
            bordered: true,
            onChanged: hasUser ? null : (v) => set(() => d.portalAccess = v),
          ),
          const SizedBox(height: 8),
          ClientSwitchTile(
            label: 'Primary guardian',
            description: 'The person who speaks for this resident.',
            value: d.isPrimaryGuardian,
            onChanged: (v) => set(() => d.isPrimaryGuardian = v),
          ),
          ClientSwitchTile(
            label: 'Emergency contact',
            description: 'Reached first when something goes wrong.',
            value: d.isEmergencyContact,
            onChanged: (v) => set(() => d.isEmergencyContact = v),
          ),
          ClientSwitchTile(
            label: 'Emergency alerts',
            description: 'Sent whatever the hour.',
            value: d.emergencyAlerts,
            onChanged: (v) => set(() => d.emergencyAlerts = v),
          ),
          ClientSwitchTile(
            label: 'Routine updates',
            description: 'Daily notes, visits, appointments.',
            value: d.receiveNotifications,
            onChanged: (v) => set(() => d.receiveNotifications = v),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              HandoverButton(label: 'Cancel', onPressed: _close),
              HandoverButton(
                key: const ValueKey('client-contact-save'),
                label: _editingId == null ? 'Add contact' : 'Save contact',
                filled: true,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final ClientFamilyMember member;
  final bool readOnly;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ContactCard({
    required this.member,
    required this.readOnly,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final m = member;
    final muted = handoverText(context, 12.5, color: AppColors.textMuted);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textMuted),
              Text(m.name, style: handoverText(context, 14, weight: FontWeight.w600)),
              if (m.relationship != null) Text(m.relationship!, style: muted),
              if (m.isPrimaryGuardian)
                const ClientPill(label: 'Primary guardian', tone: ClientTone.info),
              if (m.isEmergencyContact)
                const ClientPill(
                  label: 'Emergency contact',
                  tone: ClientTone.warning,
                  icon: Icons.shield_outlined,
                ),
              if (m.hasPortalAccess)
                const ClientPill(label: 'Portal access', tone: ClientTone.success),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (m.phone != null)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(m.phone!, style: muted),
                ]),
              if (m.email != null)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.mail_outline_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(m.email!, style: muted),
                ]),
              if (m.phone == null && m.email == null)
                Text(
                  'No way to contact this person',
                  style: handoverText(context, 12.5, color: AppColors.criticalRed),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${m.emergencyAlerts ? 'Receives emergency alerts' : 'No emergency alerts'}'
            ' · ${m.receiveNotifications ? 'Receives updates' : 'No routine updates'}',
            style: handoverText(context, 12, color: AppColors.textMuted),
          ),
          if (!readOnly) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                HandoverButton(
                  key: ValueKey('client-contact-edit-${m.id}'),
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  compact: true,
                  onPressed: onEdit,
                ),
                const SizedBox(width: 6),
                HandoverButton(
                  key: ValueKey('client-contact-remove-${m.id}'),
                  label: '',
                  icon: Icons.delete_outline_rounded,
                  compact: true,
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Web record section "Inventory Spend".
class ClientSpendSection extends StatefulWidget {
  final ClientsController controller;
  final String clientId;

  const ClientSpendSection({super.key, required this.controller, required this.clientId});

  @override
  State<ClientSpendSection> createState() => _ClientSpendSectionState();
}

class _ClientSpendSectionState extends State<ClientSpendSection> {
  ClientSpend? _spend;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.canSeeSpend) {
      _load();
    } else {
      _loading = false;
      _failed = true;
    }
  }

  Future<void> _load() async {
    final result = await widget.controller.loadSpend(widget.clientId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.when(success: (s) => _spend = s, failure: (_) => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = handoverText(context, 13, color: AppColors.textMuted);
    final s = _spend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Inventory Spend', style: handoverText(context, 15, weight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          'Purchases made for this resident, and the stock still held for them.',
          style: muted,
        ),
        const SizedBox(height: 12),
        if (_loading) Text('Loading spend…', style: muted),
        if (_failed)
          Text(
            'Spend could not be loaded. It needs both inventory and client access.',
            style: muted,
          ),
        if (s != null) ...[
          for (final (label, value, hint) in [
            ('Purchased', ClientsLabels.money(s.spend), '${s.purchaseCount} order lines'),
            (
              'Stock on hand',
              ClientsLabels.money(s.stockOnHandValue),
              '${s.stockOnHandCount} items',
            ),
            (
              'Unpriced items',
              '${s.unpricedStockCount}',
              s.unpricedStockCount > 0 ? 'not included in the value' : 'all items priced',
            ),
          ]) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: handoverText(context, 12, color: AppColors.textMuted)),
                  Text(value, style: handoverText(context, 19, weight: FontWeight.w700)),
                  Text(hint, style: handoverText(context, 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (s.purchases.isEmpty)
            Text('Nothing has been purchased against this resident yet.', style: muted)
          else
            for (final p in s.purchases)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.item, style: handoverText(context, 13, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Qty ${ClientsLabels.quantity(p.quantity)}${p.unit == null ? '' : ' ${p.unit}'}'
                      ' · Unit cost ${ClientsLabels.money(p.unitCost)}'
                      ' · Total ${ClientsLabels.money(p.lineTotal)}',
                      style: handoverText(context, 12.5, color: AppColors.textSecondary),
                    ),
                    Text(
                      'Ordered ${ClientsLabels.date(p.orderedAt?.toLocal())}',
                      style: handoverText(context, 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
        ],
      ],
    );
  }
}
