import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../domain/entities/create_shift_draft.dart';
import 'create_shift_fields.dart';

/// "Shift Information" step — residence, timing, break, title and notes,
/// matching the web Add New Shift dialog.
class CreateShiftInfoForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController notesController;
  final String? residenceValue;
  final bool isLoadingResidences;
  final VoidCallback? onResidenceTap;
  final String? shiftTypeValue;
  final VoidCallback? onShiftTypeTap;
  final String? shiftDateValue;
  final VoidCallback? onShiftDateTap;
  final String? startTimeValue;
  final VoidCallback? onStartTimeTap;
  final String? endTimeValue;
  final VoidCallback? onEndTimeTap;
  final String? breakDurationValue;
  final VoidCallback? onBreakDurationTap;
  final ValueChanged<String>? onTextChanged;
  final Map<String, String> errors;

  const CreateShiftInfoForm({
    super.key,
    required this.titleController,
    required this.notesController,
    this.residenceValue,
    this.isLoadingResidences = false,
    this.onResidenceTap,
    this.shiftTypeValue,
    this.onShiftTypeTap,
    this.shiftDateValue,
    this.onShiftDateTap,
    this.startTimeValue,
    this.onStartTimeTap,
    this.endTimeValue,
    this.onEndTimeTap,
    this.breakDurationValue,
    this.onBreakDurationTap,
    this.onTextChanged,
    this.errors = const {},
  });

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));
    final residenceError = errors[CreateShiftField.residenceId];
    final shiftTypeError = errors[CreateShiftField.shiftType];
    final shiftDateError = errors[CreateShiftField.shiftDate];
    final startError = errors[CreateShiftField.startTime];
    final endError = errors[CreateShiftField.endTime];

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
            title: 'Shift Information',
            description:
                'Set the timing, residence, and role coverage for this shift.',
          ),
          CreateShiftFieldRow(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Residence', required: true),
                CreateShiftDropdownField(
                  key: const ValueKey('create-shift-residence'),
                  value: residenceValue,
                  placeholder: isLoadingResidences
                      ? 'Loading residences…'
                      : 'Select residence',
                  onTap: onResidenceTap,
                  hasError: residenceError != null,
                ),
                CreateShiftErrorText(residenceError),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Shift Type', required: true),
                CreateShiftDropdownField(
                  key: const ValueKey('create-shift-type'),
                  value: shiftTypeValue,
                  placeholder: 'Select an option',
                  onTap: onShiftTypeTap,
                  hasError: shiftTypeError != null,
                ),
                CreateShiftErrorText(shiftTypeError),
              ],
            ),
          ),
          gap,
          CreateShiftFieldRow(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Shift Date', required: true),
                CreateShiftDateField(
                  key: const ValueKey('create-shift-date'),
                  value: shiftDateValue,
                  onTap: onShiftDateTap,
                  hasError: shiftDateError != null,
                ),
                CreateShiftErrorText(shiftDateError),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Start Time', required: true),
                CreateShiftTimeField(
                  key: const ValueKey('create-shift-start'),
                  value: startTimeValue,
                  onTap: onStartTimeTap,
                  hasError: startError != null,
                ),
                CreateShiftErrorText(startError),
              ],
            ),
          ),
          gap,
          CreateShiftFieldRow(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('End Time', required: true),
                CreateShiftTimeField(
                  key: const ValueKey('create-shift-end'),
                  value: endTimeValue,
                  onTap: onEndTimeTap,
                  hasError: endError != null,
                ),
                if (endError != null)
                  CreateShiftErrorText(endError)
                else
                  const CreateShiftHelperText(
                    'Earlier than the start means it runs overnight.',
                  ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Break Duration'),
                CreateShiftDropdownField(
                  key: const ValueKey('create-shift-break'),
                  value: breakDurationValue,
                  placeholder: 'Select an option',
                  onTap: onBreakDurationTap,
                ),
              ],
            ),
          ),
          gap,
          const CreateShiftFieldLabel('Title'),
          CreateShiftTextField(
            key: const ValueKey('create-shift-title'),
            controller: titleController,
            hint: 'Optional — e.g. Weekend cover',
            onChanged: onTextChanged,
          ),
          gap,
          const CreateShiftFieldLabel('Shift Notes'),
          CreateShiftTextField(
            key: const ValueKey('create-shift-notes'),
            controller: notesController,
            hint:
                'Add any handover notes or special instructions for this shift…',
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            onChanged: onTextChanged,
          ),
        ],
      ),
    );
  }
}
