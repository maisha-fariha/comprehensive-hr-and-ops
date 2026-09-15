import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/message_contact.dart';

class NewMessageResult {
  final String title;
  final List<String> memberUserIds;
  final String firstMessage;

  const NewMessageResult({
    required this.title,
    required this.memberUserIds,
    this.firstMessage = '',
  });
}

/// Simple sheet to start a conversation via `POST /conversations`
/// after picking contacts from `GET /conversations/contacts`.
Future<NewMessageResult?> showStaffNewMessageSheet(
  BuildContext context, {
  required List<MessageContact> contacts,
}) {
  return showModalBottomSheet<NewMessageResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _StaffNewMessageSheet(contacts: contacts),
  );
}

class _StaffNewMessageSheet extends StatefulWidget {
  final List<MessageContact> contacts;

  const _StaffNewMessageSheet({required this.contacts});

  @override
  State<_StaffNewMessageSheet> createState() => _StaffNewMessageSheetState();
}

class _StaffNewMessageSheetState extends State<_StaffNewMessageSheet> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _selected = <String>{};

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one contact.')),
      );
      return;
    }
    var title = _titleController.text.trim();
    if (title.isEmpty) {
      title = widget.contacts
          .where((c) => _selected.contains(c.id))
          .map((c) => c.name.trim())
          .where((name) => name.isNotEmpty)
          .join(', ');
      if (title.isEmpty) title = 'Conversation';
    }
    Navigator.of(context).pop(
      NewMessageResult(
        title: title,
        memberUserIds: _selected.toList(),
        firstMessage: _messageController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New message',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'First message (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Contacts',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.contacts.isEmpty
                  ? const Center(
                      child: Text(
                        'No contacts available.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.contacts.length,
                      itemBuilder: (context, index) {
                        final contact = widget.contacts[index];
                        final checked = _selected.contains(contact.id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selected.add(contact.id);
                              } else {
                                _selected.remove(contact.id);
                              }
                            });
                          },
                          title: Text(
                            contact.name,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: contact.subtitle.isEmpty
                              ? null
                              : Text(
                                  contact.subtitle,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.textMuted,
                                  ),
                                ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
              ),
              child: const Text('Start conversation'),
            ),
          ],
        ),
      ),
    );
  }
}
