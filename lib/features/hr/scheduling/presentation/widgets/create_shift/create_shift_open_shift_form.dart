import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import 'create_shift_fields.dart';

/// "Open Shift" step — bidding toggle plus the bidding configuration
/// (people needed, deadline, max bids, priority, award method, note).
class CreateShiftOpenShiftForm extends StatelessWidget {
  final bool isOpenShift;
  final ValueChanged<bool> onChanged;
  final TextEditingController requiredStaffCountController;
  final TextEditingController maxBidsController;
  final TextEditingController noteToBiddersController;
  final String? deadlineDateValue;
  final VoidCallback? onDeadlineDateTap;
  final String? deadlineTimeValue;
  final VoidCallback? onDeadlineTimeTap;
  final String? priorityValue;
  final VoidCallback? onPriorityTap;
  final String? awardMethodValue;
  final VoidCallback? onAwardMethodTap;
  final ValueChanged<String>? onTextChanged;

  const CreateShiftOpenShiftForm({
    super.key,
    required this.isOpenShift,
    required this.onChanged,
    required this.requiredStaffCountController,
    required this.maxBidsController,
    required this.noteToBiddersController,
    this.deadlineDateValue,
    this.onDeadlineDateTap,
    this.deadlineTimeValue,
    this.onDeadlineTimeTap,
    this.priorityValue,
    this.onPriorityTap,
    this.awardMethodValue,
    this.onAwardMethodTap,
    this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));

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
            title: 'Open Shift',
            description: 'Leave this shift open for staff to bid on.',
          ),
          CreateShiftSwitchCard(
            key: const ValueKey('create-shift-open-toggle'),
            label: 'Make this an open shift',
            description:
                'Anyone at this home can submit a bid until the deadline.',
            value: isOpenShift,
            onChanged: onChanged,
          ),
          if (isOpenShift) ...[
            gap,
            const CreateShiftFieldLabel('People needed'),
            CreateShiftTextField(
              key: const ValueKey('create-shift-people-needed'),
              controller: requiredStaffCountController,
              hint: '1',
              keyboardType: TextInputType.number,
              onChanged: onTextChanged,
            ),
            const CreateShiftHelperText(
              'How many staff should end up on this shift.',
            ),
            gap,
            CreateShiftFieldRow(
              left: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CreateShiftFieldLabel('Bidding Deadline'),
                  CreateShiftDateField(
                    key: const ValueKey('create-shift-bid-deadline'),
                    value: deadlineDateValue,
                    onTap: onDeadlineDateTap,
                  ),
                ],
              ),
              right: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CreateShiftFieldLabel('Deadline Time'),
                  CreateShiftTimeField(
                    key: const ValueKey('create-shift-bid-deadline-time'),
                    value: deadlineTimeValue,
                    onTap: onDeadlineTimeTap,
                  ),
                ],
              ),
            ),
            gap,
            CreateShiftFieldRow(
              left: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CreateShiftFieldLabel('Maximum Bids'),
                  CreateShiftTextField(
                    key: const ValueKey('create-shift-max-bids'),
                    controller: maxBidsController,
                    hint: '10',
                    keyboardType: TextInputType.number,
                    onChanged: onTextChanged,
                  ),
                ],
              ),
              right: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CreateShiftFieldLabel('Priority'),
                  CreateShiftDropdownField(
                    key: const ValueKey('create-shift-priority'),
                    value: priorityValue,
                    placeholder: 'Select an option',
                    onTap: onPriorityTap,
                  ),
                ],
              ),
            ),
            gap,
            const CreateShiftFieldLabel('Award Method'),
            CreateShiftDropdownField(
              key: const ValueKey('create-shift-award-method'),
              value: awardMethodValue,
              placeholder: 'Select an option',
              onTap: onAwardMethodTap,
            ),
            gap,
            const CreateShiftFieldLabel('Note to Bidders'),
            CreateShiftTextField(
              key: const ValueKey('create-shift-note-to-bidders'),
              controller: noteToBiddersController,
              hint: 'Describe requirements or context to help staff decide…',
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              onChanged: onTextChanged,
            ),
          ],
        ],
      ),
    );
  }
}
