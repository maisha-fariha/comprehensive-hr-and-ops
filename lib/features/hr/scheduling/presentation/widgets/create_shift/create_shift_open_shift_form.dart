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
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            'Leave this shift open for staff to bid on.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          _OpenShiftToggleCard(
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
        ],
      ),
    );
  }
}

class _OpenShiftToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OpenShiftToggleCard({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        side: const BorderSide(color: AppColors.searchBorder),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Make this an open shift',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          14.5,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    Text(
                      'Anyone at this home can submit a bid until the deadline.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.secondaryTeal,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.cardBorder,
                trackOutlineColor:
                    const WidgetStatePropertyAll(Colors.transparent),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
