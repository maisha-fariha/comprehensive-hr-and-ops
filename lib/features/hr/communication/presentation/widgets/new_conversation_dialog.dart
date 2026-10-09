import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

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
}) {
  return showAppPopup<NewConversationResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => NewConversationDialog(
      contacts: contacts,
      residences: residences,
      clients: clients,
      initialResidenceId: initialResidenceId,
    ),
  );
}

/// Web-parity New Conversation modal (Direct / Group / Family).
class NewConversationDialog extends StatefulWidget {
  final List<HrMessageContact> contacts;
  final List<CommunicationResidenceOption> residences;
  final List<CommunicationClientOption> clients;
  final String? initialResidenceId;

  const NewConversationDialog({
    super.key,
    required this.contacts,
    required this.residences,
    required this.clients,
    this.initialResidenceId,
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

  List<CommunicationClientOption> _filterClients(String query) {
    final q = query.trim().toLowerCase();
    return widget.clients.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          (c.residenceName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _setType(ConversationCreateType type) {
    setState(() {
      _type = type;
      _banner = null;
      _directStaffId = null;
      _groupMemberIds.clear();
      _familyClientId = null;
      _staffSearch.clear();
      _groupName.clear();
      _membersSearch.clear();
      _familySearch.clear();
      _subject.clear();
    });
  }

  void _submit() {
    if (!_canStart) {
      setState(() {
        _banner = switch (_type) {
          ConversationCreateType.direct => 'Select a staff member.',
          ConversationCreateType.residenceGroup =>
            'Group name and residence are required.',
          ConversationCreateType.familySupport =>
            'Select a family contact.',
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
          ConversationCreateType.familySupport => const [],
        },
        residenceId: _residenceId,
        clientId: _familyClientId,
        firstMessage: _message.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return AppSheetPanel(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
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
            Flexible(
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
                      onPressed: () => Navigator.of(context).pop(),
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
            singleSelect: true,
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
            singleSelect: false,
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
        return [
          const _FieldLabel('Family contact'),
          const SizedBox(height: 8),
          _OutlinedField(
            controller: _familySearch,
            hint: 'Search family contacts...',
            prefixIcon: Icons.search_rounded,
          ),
          const SizedBox(height: 8),
          _ClientList(
            clients: _filterClients(_familySearch.text),
            selectedId: _familyClientId,
            onSelected: (client) {
              setState(() {
                _familyClientId = client.id;
                _familySearch.text = client.name;
              });
            },
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

  const _OutlinedField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
  final bool singleSelect;
  final ValueChanged<HrMessageContact> onToggle;

  const _ContactList({
    required this.contacts,
    required this.selectedIds,
    required this.singleSelect,
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: ResponsiveHelper.getResponsiveHeight(context, 160),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: contacts.length.clamp(0, 12),
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final contact = contacts[index];
          final selected = selectedIds.contains(contact.id);
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
        },
      ),
    );
  }
}

class _ClientList extends StatelessWidget {
  final List<CommunicationClientOption> clients;
  final String? selectedId;
  final ValueChanged<CommunicationClientOption> onSelected;

  const _ClientList({
    required this.clients,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return const Text(
        'No family contacts found.',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.5,
          color: AppColors.textMuted,
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: ResponsiveHelper.getResponsiveHeight(context, 160),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: clients.length.clamp(0, 12),
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final client = clients[index];
          final selected = selectedId == client.id;
          return Material(
            color: selected
                ? const Color(0xFFE8F4F3)
                : AppColors.filterButtonBackground,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelected(client),
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
                            client.name,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textHeading,
                            ),
                          ),
                          if (client.residenceName != null)
                            Text(
                              client.residenceName!,
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
        },
      ),
    );
  }
}
