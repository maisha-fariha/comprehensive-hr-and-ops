import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import 'create_shift_fields.dart';

/// "Notifications" step — assignee notify toggle, reminder, custom message.
class CreateShiftNotificationsForm extends StatelessWidget {
  final bool notifyAssignedStaff;
  final ValueChanged<bool> onNotifyAssignedStaffChanged;

  /// Selected reminder label; `null` shows the "Select an option" placeholder.
  final String? reminderValue;
  final VoidCallback onReminderTap;
  final TextEditingController messageController;
  final ValueChanged<String>? onTextChanged;

  const CreateShiftNotificationsForm({
    super.key,
    required this.notifyAssignedStaff,
    required this.onNotifyAssignedStaffChanged,
    required this.reminderValue,
    required this.onReminderTap,
    required this.messageController,
    this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18));

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 8,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreateShiftSectionHeader(
            title: 'Notifications',
            description:
                'Choose whether the people on this shift are told, and when they are reminded.',
          ),
          CreateShiftSwitchCard(
            key: const ValueKey('create-shift-notify-toggle'),
            label: 'Notify assigned staff',
            description:
                'Send each assignee a notification as soon as the shift is saved. Turn off while drafting a rota.',
            value: notifyAssignedStaff,
            onChanged: onNotifyAssignedStaffChanged,
          ),
          gap,
          const CreateShiftFieldLabel('Reminder'),
          CreateShiftDropdownField(
            key: const ValueKey('create-shift-reminder'),
            value: reminderValue,
            placeholder: 'Select an option',
            onTap: onReminderTap,
          ),
          const CreateShiftHelperText(
            'A second notification this long before the shift starts.',
          ),
          gap,
          const CreateShiftFieldLabel('Custom Message'),
          CreateShiftTextField(
            key: const ValueKey('create-shift-notification-message'),
            controller: messageController,
            hint:
                'Add a note included in the notification instead of the shift time…',
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            onChanged: onTextChanged,
          ),
          gap,
          const CreateShiftNoteBox(
            'Quiet hours, digesting and which channels each notification uses are set once for the whole tenant, under Settings → Notifications.',
          ),
        ],
      ),
    );
  }
}
