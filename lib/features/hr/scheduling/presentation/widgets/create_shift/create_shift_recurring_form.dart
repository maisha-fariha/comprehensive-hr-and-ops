import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/create_shift_draft.dart';
import 'create_shift_fields.dart';

/// "Recurring" step — repeat toggle, frequency, weekdays, end rule and the
/// planned-occurrences summary.
class CreateShiftRecurringForm extends StatelessWidget {
  final bool isRecurring;
  final ValueChanged<bool> onChanged;
  final String? frequencyValue;
  final VoidCallback? onFrequencyTap;
  final Set<int> repeatOnDays;
  final ValueChanged<int> onToggleDay;
  final ShiftRecurrenceEnd ends;
  final ValueChanged<ShiftRecurrenceEnd> onEndsChanged;
  final String? endDateValue;
  final VoidCallback? onEndDateTap;
  final TextEditingController occurrenceController;
  final ValueChanged<String>? onTextChanged;

  /// Planned shift count; 0 when the rule cannot be resolved yet.
  final int plannedOccurrences;
  final Map<String, String> errors;

  const CreateShiftRecurringForm({
    super.key,
    required this.isRecurring,
    required this.onChanged,
    required this.repeatOnDays,
    required this.onToggleDay,
    required this.ends,
    required this.onEndsChanged,
    required this.occurrenceController,
    required this.plannedOccurrences,
    this.frequencyValue,
    this.onFrequencyTap,
    this.endDateValue,
    this.onEndDateTap,
    this.onTextChanged,
    this.errors = const {},
  });

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18));
    final endDateError = errors[CreateShiftField.endDate];
    final occurrenceError = errors[CreateShiftField.occurrenceCount];

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
            title: 'Recurring',
            description: 'Repeat this shift automatically on a set schedule.',
          ),
          CreateShiftSwitchCard(
            key: const ValueKey('create-shift-recurring-toggle'),
            label: 'Repeat this shift',
            description: 'Create the same shift again on a recurring basis.',
            value: isRecurring,
            onChanged: onChanged,
          ),
          if (isRecurring) ...[
            gap,
            const CreateShiftFieldLabel('Frequency'),
            CreateShiftDropdownField(
              key: const ValueKey('create-shift-frequency'),
              value: frequencyValue,
              placeholder: 'Select an option',
              onTap: onFrequencyTap,
            ),
            gap,
            const CreateShiftFieldLabel('Repeat On'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in CreateShiftChoices.weekdays)
                  _WeekdayCircle(
                    key: ValueKey('create-shift-weekday-${day.value}'),
                    day: day,
                    selected: repeatOnDays.contains(day.value),
                    onTap: () => onToggleDay(day.value),
                  ),
              ],
            ),
            CreateShiftHelperText(
              repeatOnDays.isNotEmpty
                  ? 'The frequency becomes the gap between weeks — bi-weekly repeats on these days every other week.'
                  : 'Leave empty to repeat purely on the frequency above.',
            ),
            gap,
            const CreateShiftFieldLabel('Ends'),
            for (final option in ShiftRecurrenceEnd.values) ...[
              _EndsRadio(
                option: option,
                selected: ends == option,
                onTap: () => onEndsChanged(option),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            if (ends == ShiftRecurrenceEnd.onDate) ...[
              const CreateShiftFieldLabel('End Date'),
              CreateShiftDateField(
                key: const ValueKey('create-shift-end-date'),
                value: endDateValue,
                onTap: onEndDateTap,
                hasError: endDateError != null,
              ),
              CreateShiftErrorText(endDateError),
            ] else ...[
              const CreateShiftFieldLabel('Number of Occurrences'),
              CreateShiftTextField(
                key: const ValueKey('create-shift-occurrences'),
                controller: occurrenceController,
                hint: '4',
                keyboardType: TextInputType.number,
                onChanged: onTextChanged,
                hasError: occurrenceError != null,
              ),
              if (occurrenceError != null)
                CreateShiftErrorText(occurrenceError)
              else
                const CreateShiftHelperText('Up to 52'),
            ],
            gap,
            CreateShiftNoteBox(
              plannedOccurrences > 0
                  ? 'This will create $plannedOccurrences shift${plannedOccurrences == 1 ? '' : 's'}. Any that clash with an existing shift for the same person will be refused.'
                  : 'Pick a shift date and an end rule to see how many shifts this creates.',
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekdayCircle extends StatelessWidget {
  final ShiftWeekdayChoice day;
  final bool selected;
  final VoidCallback onTap;

  const _WeekdayCircle({
    super.key,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 38);
    return Semantics(
      label: day.name,
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppColors.secondaryTeal.withValues(alpha: 0.1)
            : AppColors.surfaceWhite,
        shape: CircleBorder(
          side: BorderSide(
            color: selected ? AppColors.secondaryTeal : AppColors.searchBorder,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Text(
                day.label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: selected ? AppColors.secondaryTeal : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EndsRadio extends StatelessWidget {
  final ShiftRecurrenceEnd option;
  final bool selected;
  final VoidCallback onTap;

  const _EndsRadio({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: const BorderSide(color: AppColors.searchBorder),
      ),
      child: InkWell(
        key: ValueKey('create-shift-ends-${option.value}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? AppColors.secondaryTeal : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
