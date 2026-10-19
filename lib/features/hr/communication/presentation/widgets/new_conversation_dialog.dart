import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/communication_enums.dart';
import '../../domain/entities/hr_message_contact.dart';
import '../../domain/repositories/communication_repository.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

class NewConversationResult {
  final ConversationCreateType type;
  final String? title;
  final List<String> memberUserIds;
  final String? residenceId;
  final String? clientId;
  final String firstMessage;

  const NewConversationResult({
    required this.type,
    this.title,
    this.memberUserIds = const [],
    this.residenceId,
    this.clientId,
    this.firstMessage = '',
  });
}

Future<NewConversationResult?> showNewConversationDialog(
  BuildContext context, {
  required List<HrMessageContact> contacts,
  required List<CommunicationResidenceOption> residences,
  required List<CommunicationClientOption> clients,
  String? initialResidenceId,
  Future<List<HrMessageContact>> Function(String clientId)? loadFamilyContacts,
}) {
  return showAppPopup<NewConversationResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => NewConversationDialog(
      contacts: contacts,
      residences: residences,
      clients: clients,
      initialResidenceId: initialResidenceId,
      loadFamilyContacts: loadFamilyContacts,
    ),
  );
}

/// Web-parity New Conversation modal (Direct / Group / Family).
class NewConversationDialog extends StatefulWidget {
  final List<HrMessageContact> contacts;
  final List<CommunicationResidenceOption> residences;
  final List<CommunicationClientOption> clients;
  final String? initialResidenceId;

  /// `GET /conversations/contacts?clientId=` — that resident's family.
  final Future<List<HrMessageContact>> Function(String clientId)?
      loadFamilyContacts;

  const NewConversationDialog({
    super.key,
    required this.contacts,
    required this.residences,
    required this.clients,
    this.initialResidenceId,
    this.loadFamilyContacts,
  });

  @override
  State<NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  ConversationCreateType _type = ConversationCreateType.direct;

  late final TextEditingController _staffSearch;
  late final TextEditingController _groupName;
  late final TextEditingController _membersSearch;
  late final TextEditingController _familySearch;
  late final TextEditingController _subject;
  late final TextEditingController _message;

  String? _directStaffId;
  String? _residenceId;
  final Set<String> _groupMemberIds = {};
  String? _familyClientId;
  final Set<String> _familyMemberIds = {};
  List<HrMessageContact> _familyContacts = const [];
  bool _loadingFamily = false;
  bool _residentListOpen = false;
  String? _banner;

  @override
  void initState() {
    super.initState();
    _staffSearch = TextEditingController()..addListener(_refresh);
    _groupName = TextEditingController()..addListener(_refresh);
    _membersSearch = TextEditingController()..addListener(_refresh);
    _familySearch = TextEditingController()..addListener(_refresh);
    _subject = TextEditingController()..addListener(_refresh);
    _message = TextEditingController()..addListener(_refresh);
    final initial = widget.initialResidenceId;
    if (initial != null &&
        widget.residences.any((r) => r.id == initial)) {
      _residenceId = initial;
    } else if (widget.residences.length == 1) {
      _residenceId = widget.residences.first.id;
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [
      _staffSearch,
      _groupName,
      _membersSearch,
      _familySearch,
      _subject,
      _message,
    ]) {
      c
        ..removeListener(_refresh)
        ..dispose();
    }
    super.dispose();
  }

  bool get _canStart {
    switch (_type) {
      case ConversationCreateType.direct:
        return _directStaffId != null && _directStaffId!.isNotEmpty;
      case ConversationCreateType.residenceGroup:
        return (_residenceId?.isNotEmpty ?? false) &&
            _groupName.text.trim().isNotEmpty;
      case ConversationCreateType.familySupport:
        return _familyClientId != null && _familyClientId!.isNotEmpty;
    }
  }

  List<HrMessageContact> _filterContacts(String query) {
    final q = query.trim().toLowerCase();
    return widget.contacts.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.roleLabel.toLowerCase().contains(q);
    }).toList();
  }

  void _setType(ConversationCreateType type) {
    setState(() {
      _type = type;
      _banner = null;
      _directStaffId = null;
      _groupMemberIds.clear();
      _familyClientId = null;
      _familyMemberIds.clear();
      _familyContacts = const [];
      _loadingFamily = false;
      _residentListOpen = false;
      _staffSearch.clear();
      _groupName.clear();
      _membersSearch.clear();
      _familySearch.clear();
      _subject.clear();
    });
  }

  String? get _residentLabel {
    for (final client in widget.clients) {
      if (client.id != _familyClientId) continue;
      final home = client.residenceName;
      if (home == null || home.isEmpty) return client.name;
      return '${client.name} · $home';
    }
    return null;
  }

  String _familyContactName(String id) {
    for (final contact in _familyContacts) {
      if (contact.id == id) return contact.name;
    }
    return 'Family';
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  Future<void> _selectResident(String? id) async {
    _familySearch.removeListener(_refresh);
    _familySearch.clear();
    _familySearch.addListener(_refresh);
    setState(() {
      _familyClientId = id;
      _residentListOpen = false;
      _familyMemberIds.clear();
      _familyContacts = const [];
      _loadingFamily = id != null && id.isNotEmpty;
    });
    final loader = widget.loadFamilyContacts;
    if (id == null || id.isEmpty || loader == null) {
      if (mounted) setState(() => _loadingFamily = false);
      return;
    }
    final contacts = await loader(id);
    if (!mounted || _familyClientId != id) return;
    setState(() {
      _familyContacts = contacts;
      _loadingFamily = false;
    });
  }

  void _submit() {
    if (!_canStart) {
      setState(() {
        _banner = switch (_type) {
          ConversationCreateType.direct => 'Select a staff member.',
          ConversationCreateType.residenceGroup =>
            'Group name and residence are required.',
          ConversationCreateType.familySupport => 'Select a resident.',
        };
      });
      return;
    }

    Navigator.of(context).pop(
      NewConversationResult(
        type: _type,
        title: switch (_type) {
          ConversationCreateType.direct => null,
          ConversationCreateType.residenceGroup => _groupName.text.trim(),
          ConversationCreateType.familySupport =>
            _subject.text.trim().isEmpty ? null : _subject.text.trim(),
        },
        memberUserIds: switch (_type) {
          ConversationCreateType.direct => [_directStaffId!],
          ConversationCreateType.residenceGroup => _groupMemberIds.toList(),
          ConversationCreateType.familySupport => _familyMemberIds.toList(),
        },
        residenceId: _residenceId,
        clientId: _familyClientId,
        firstMessage: _message.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.92;
        return Material(
          color: AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: maxHeight,
            child: Column(
              children: [
            _Header(onClose: _close),
            if (_banner != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.criticalBackgroundSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _banner!,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: AppColors.criticalRed,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel('Conversation Type'),
                    const SizedBox(height: 10),
                    _TypeRow(type: _type, onChanged: _setType),
                    const SizedBox(height: 18),
                    ..._buildTypeFields(context),
                    const SizedBox(height: 14),
                    const _FieldLabel(
                      'First message',
                      optional: true,
                    ),
                    const SizedBox(height: 8),
                    _OutlinedField(
                      controller: _message,
                      hint:
                          'Type a message to send right away, or leave blank to start an empty conversation...',
                      minLines: 3,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _close,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textHeading,
                        side: const BorderSide(color: AppColors.searchBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _canStart ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _canStart
                            ? AppColors.primaryNavy
                            : AppColors.textMuted,
                        disabledBackgroundColor: const Color(0xFF9AA6B2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text(
                        'Start Conversation',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
    );
  }

  List<Widget> _buildTypeFields(BuildContext context) {
    switch (_type) {
      case ConversationCreateType.direct:
        return [
          const _FieldLabel('Staff member'),
          const SizedBox(height: 8),
          _OutlinedField(
            controller: _staffSearch,
            hint: 'Search by name or role...',
            prefixIcon: Icons.search_rounded,
          ),
          const SizedBox(height: 8),
          _ContactList(
            contacts: _filterContacts(_staffSearch.text),
            selectedIds: {
              ?_directStaffId,
            },
            onToggle: (contact) {
              setState(() {
                _directStaffId = contact.id;
                _staffSearch.text = contact.name;
              });
            },
          ),
        ];
      case ConversationCreateType.residenceGroup:
        return [
          const _FieldLabel('Group name'),
          const SizedBox(height: 8),
          _OutlinedField(
            controller: _groupName,
            hint: 'e.g. Elm House evening shift',
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Residence', required: true),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(_residenceId ?? 'none'),
            initialValue: _residenceId,
            decoration: _inputDecoration(),
            hint: const Text('Select residence'),
            items: [
              for (final r in widget.residences)
                DropdownMenuItem(value: r.id, child: Text(r.name)),
            ],
            onChanged: (v) => setState(() => _residenceId = v),
          ),
          const SizedBox(height: 4),
          const Text(
            'The home this group belongs to',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Group members'),
          const SizedBox(height: 8),
          _OutlinedField(
            controller: _membersSearch,
            hint: 'Add people to this group...',
            prefixIcon: Icons.search_rounded,
          ),
          if (_groupMemberIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final id in _groupMemberIds)
                  Chip(
                    label: Text(
                      widget.contacts
                          .firstWhere(
                            (c) => c.id == id,
                            orElse: () => HrMessageContact(
                              id: id,
                              name: 'Member',
                            ),
                          )
                          .name,
                    ),
                    onDeleted: () => setState(() => _groupMemberIds.remove(id)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _ContactList(
            contacts: _filterContacts(_membersSearch.text),
            selectedIds: _groupMemberIds,
            onToggle: (contact) {
              setState(() {
                if (_groupMemberIds.contains(contact.id)) {
                  _groupMemberIds.remove(contact.id);
                } else {
                  _groupMemberIds.add(contact.id);
                }
              });
            },
          ),
        ];
      case ConversationCreateType.familySupport:
        final familyMatches = _familyContacts.where((contact) {
          final query = _familySearch.text.trim().toLowerCase();
          if (query.isEmpty) return true;
          return contact.name.toLowerCase().contains(query) ||
              contact.roleLabel.toLowerCase().contains(query);
        }).toList();
        return [
          const _FieldLabel('Resident', required: true),
          const SizedBox(height: 8),
          _PickerField(
            label: _residentLabel ?? 'Select a resident',
            isHint: _residentLabel == null,
            open: _residentListOpen,
            onTap: widget.clients.isEmpty
                ? null
                : () => setState(() => _residentListOpen = !_residentListOpen),
          ),
          if (widget.clients.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No residents found.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else if (_residentListOpen) ...[
            const SizedBox(height: 8),
            for (final client in widget.clients)
              _PersonTile(
                name: client.name,
                subtitle: client.residenceName,
                selected: client.id == _familyClientId,
                onTap: () => _selectResident(client.id),
              ),
          ],
          const SizedBox(height: 14),
          const _FieldLabel('Family contact'),
          if (_familyMemberIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final id in _familyMemberIds)
                  InputChip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.secondaryTeal,
                      child: Text(
                        _initials(_familyContactName(id)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    label: Text(_familyContactName(id)),
                    onDeleted: () =>
                        setState(() => _familyMemberIds.remove(id)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _OutlinedField(
            controller: _familySearch,
            hint: 'Search this resident\'s family...',
            prefixIcon: Icons.search_rounded,
            enabled: _familyClientId != null,
          ),
          const SizedBox(height: 8),
          if (_loadingFamily)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_familyClientId == null)
            const Text(
              'Select a resident to see their family.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            )
          else if (familyMatches.isEmpty)
            const Text(
              'No family contacts found.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            )
          else
            for (final contact in familyMatches)
              _PersonTile(
                name: contact.name,
                subtitle: contact.roleLabel,
                selected: _familyMemberIds.contains(contact.id),
                onTap: () {
                  setState(() {
                    if (_familyMemberIds.contains(contact.id)) {
                      _familyMemberIds.remove(contact.id);
                    } else {
                      _familyMemberIds.add(contact.id);
                    }
                  });
                },
              ),
          const SizedBox(height: 8),
          const Text(
            'Family threads are answered by the tenant admin and the resident\'s residence manager.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Subject', optional: true),
          const SizedBox(height: 8),
          _OutlinedField(
            controller: _subject,
            hint: 'e.g. Weekend visit arrangements',
          ),
        ];
    }
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  String letter(String word) => word.isEmpty ? '' : word[0].toUpperCase();
  if (parts.length == 1) return letter(parts.first);
  return '${letter(parts.first)}${letter(parts.last)}';
}

class _PickerField extends StatelessWidget {
  final String label;
  final bool isHint;
  final bool open;
  final VoidCallback? onTap;

  const _PickerField({
    required this.label,
    required this.isHint,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: isHint ? FontWeight.w400 : FontWeight.w600,
                    color: isHint ? AppColors.textMuted : AppColors.textHeading,
                  ),
                ),
              ),
              Icon(
                open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PersonTile({
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final detail = subtitle?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFFE8F4F3) : AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondaryTeal,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textHeading,
                        ),
                      ),
                      if (detail != null && detail.isNotEmpty)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.secondaryTeal,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.add_comment_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Conversation',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Start a direct message, a residence group, or a family thread.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  final bool optional;

  const _FieldLabel(
    this.text, {
    this.required = false,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textHeading,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: AppColors.criticalRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (optional)
            const TextSpan(
              text: ' (optional)',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  final ConversationCreateType type;
  final ValueChanged<ConversationCreateType> onChanged;

  const _TypeRow({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Direct',
            subtitle: 'One person, staff to staff',
            selected: type == ConversationCreateType.direct,
            onTap: () => onChanged(ConversationCreateType.direct),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TypeCard(
            icon: Icons.groups_outlined,
            title: 'Group',
            subtitle: 'Everyone posted to a home',
            selected: type == ConversationCreateType.residenceGroup,
            onTap: () => onChanged(ConversationCreateType.residenceGroup),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TypeCard(
            icon: Icons.favorite_border_rounded,
            title: 'Family',
            subtitle: 'A relative and the office',
            selected: type == ConversationCreateType.familySupport,
            onTap: () => onChanged(ConversationCreateType.familySupport),
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.secondaryTeal
                  : AppColors.searchBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? AppColors.secondaryTeal
                        : AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
              if (selected)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.secondaryTeal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({String? hint, IconData? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Outfit',
      fontSize: 14,
      color: AppColors.textMuted,
    ),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 20, color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surfaceWhite,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.searchBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.secondaryTeal, width: 1.4),
    ),
  );
}

class _OutlinedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final int minLines;
  final int maxLines;
  final bool enabled;

  const _OutlinedField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.minLines = 1,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: AppColors.textHeading,
      ),
      decoration: _inputDecoration(hint: hint, prefixIcon: prefixIcon),
    );
  }
}

class _ContactList extends StatelessWidget {
  final List<HrMessageContact> contacts;
  final Set<String> selectedIds;
  final ValueChanged<HrMessageContact> onToggle;

  const _ContactList({
    required this.contacts,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const Text(
        'No contacts match.',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.5,
          color: AppColors.textMuted,
        ),
      );
    }
    final shown = contacts.take(12).toList();
    return Column(
      children: [
        for (final contact in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _contactTile(contact, selectedIds.contains(contact.id)),
          ),
      ],
    );
  }

  Widget _contactTile(HrMessageContact contact, bool selected) {
    return Material(
            color: selected
                ? const Color(0xFFE8F4F3)
                : AppColors.filterButtonBackground,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onToggle(contact),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textHeading,
                            ),
                          ),
                          Text(
                            contact.roleLabel,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.secondaryTeal,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
