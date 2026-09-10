import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/missed_medication.dart';
import '../../domain/entities/refused_medication.dart';
import '../../domain/repositories/medication_repository.dart';
import 'contact_staff_sheet.dart';

Future<void> reviewMissedMedicationIssue(
  BuildContext context, {
  required MissedMedication medication,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        'Review Medication Issue',
        style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Create a compliance finding for the missed dose of '
        '${medication.medicationName} for ${medication.residentName}?',
        style: const TextStyle(fontFamily: 'Outfit'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondaryTeal),
          child: const Text('Review', style: TextStyle(fontFamily: 'Outfit')),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final repo = GetIt.instance<MedicationRepository>();
  final result = await repo.reviewMedicationIssue(
    administrationId: medication.id,
    title: 'Missed medication: ${medication.medicationName}',
    description:
        'Missed dose for ${medication.residentName} '
        '(${medication.dose.isEmpty ? 'dose n/a' : medication.dose}). '
        'Scheduled ${medication.scheduledTime.isEmpty ? 'n/a' : medication.scheduledTime}. '
        'Assignee: ${medication.assigneeName}.',
    clientId: medication.clientId,
    residenceId: medication.residenceId,
    severity: medication.isCritical ? 'high' : 'medium',
  );

  result.when(
    success: (_) {
      AppSnackbar.show(
        'Finding created',
        'Medication issue logged for review.',
      );
    },
    failure: (error) {
      AppSnackbar.show('Could not create finding', error.message);
    },
  );
}

Future<void> contactMissedMedicationStaff(
  BuildContext context, {
  required MissedMedication medication,
}) {
  return showContactStaffSheet(context, medication: medication);
}

Future<void> logRefusedMedicationFollowUp(
  BuildContext context, {
  required RefusedMedication medication,
}) async {
  final noteController = TextEditingController(
    text: medication.reason.trim().isEmpty
        ? ''
        : 'Follow-up for refusal: ${medication.reason}',
  );

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        'Log follow-up',
        style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Log a follow-up for ${medication.medicationName} '
            '(${medication.residentName}).',
            style: const TextStyle(fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Follow-up notes',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'Outfit'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondaryTeal),
          child: const Text('Log', style: TextStyle(fontFamily: 'Outfit')),
        ),
      ],
    ),
  );

  final note = noteController.text.trim();
  noteController.dispose();
  if (confirmed != true) return;

  final repo = GetIt.instance<MedicationRepository>();
  final result = await repo.logMedicationFollowUp(
    administrationId: medication.id,
    title: 'Follow-up: refused ${medication.medicationName}',
    description: note.isEmpty
        ? 'Follow-up required for refused dose '
            '(${medication.residentName}).'
        : note,
    clientId: medication.clientId,
    residenceId: medication.residenceId,
  );

  result.when(
    success: (_) {
      AppSnackbar.show('Follow-up logged', 'Corrective action / task created.');
    },
    failure: (error) {
      AppSnackbar.show('Could not log follow-up', error.message);
    },
  );
}
