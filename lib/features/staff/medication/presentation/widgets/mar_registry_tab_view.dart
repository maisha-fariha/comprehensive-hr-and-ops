import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/offline/presentation/pending_sync_chip.dart';
import '../../domain/entities/due_dose.dart';
import 'administered_tab_view.dart';
import 'due_dose_card.dart';
import 'staff_mar_filters_bar.dart';

/// Web MAR tab — today's scheduled / due occurrences from `GET /mar/round`.
class MarRegistryTabView extends StatelessWidget {
  final List<DueDose> doses;
  final int scheduledCount;
  final TextEditingController searchController;
  final String residenceId;
  final String clientId;
  final String medication;
  final String state;
  final List<({String value, String label})> residenceOptions;
  final List<({String value, String label})> residentOptions;
  final List<({String value, String label})> medicationOptions;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final void Function({
    String? residenceId,
    String? clientId,
    String? medication,
    String? state,
  }) onFilterChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<String> onAdminister;
  final ValueChanged<String> onNotGiven;
  final ValueChanged<DueDose>? onOpenClientMedications;
  final ValueChanged<DueDose>? onEdit;
  final String Function(DueDose dose)? administeredByName;
  final bool Function(DueDose dose)? isPendingSync;
  final bool canWriteScheduled;
  final bool canWritePrn;

  const MarRegistryTabView({
    super.key,
    required this.doses,
    required this.scheduledCount,
    required this.searchController,
    required this.residenceId,
    required this.clientId,
    required this.medication,
    required this.state,
    required this.residenceOptions,
    required this.residentOptions,
    required this.medicationOptions,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClearFilters,
    required this.onAdminister,
    required this.onNotGiven,
    this.onOpenClientMedications,
    this.onEdit,
    this.administeredByName,
    this.isPendingSync,
    this.canWriteScheduled = true,
    this.canWritePrn = false,
  });

  bool _canWrite(DueDose dose) =>
      dose.isPrn ? canWritePrn : canWriteScheduled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
        Row(
          children: [
            const Expanded(
              child: Text(
                'MAR Administration Registry',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            StaffMedicationCountLabel(
              text: '$scheduledCount scheduled today',
              background: AppColors.scaffoldBackground,
              foreground: AppColors.textMuted,
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        StaffMarFiltersBar(
          searchController: searchController,
          residenceId: residenceId,
          clientId: clientId,
          medication: medication,
          state: state,
          residenceOptions: residenceOptions,
          residentOptions: residentOptions,
          medicationOptions: medicationOptions,
          hasActiveFilters: hasActiveFilters,
          onSearchChanged: onSearchChanged,
          onFilterChanged: onFilterChanged,
          onClear: onClearFilters,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (doses.isEmpty)
          const _EmptyRegistry(
            message: 'No doses scheduled for today under these filters.',
          )
        else ...[
          for (var i = 0; i < doses.length; i++) ...[
            if (isPendingSync?.call(doses[i]) ?? false)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: PendingSyncChip(
                  key: Key('mar-dose-pending-sync'),
                  label: 'Recorded offline – pending sync',
                ),
              ),
            DueDoseCard(
              dose: doses[i],
              canWrite: _canWrite(doses[i]),
              onAdminister: () => onAdminister(doses[i].id),
              onNotGiven: () => onNotGiven(doses[i].id),
              onOpenClientMedications: onOpenClientMedications == null
                  ? null
                  : () => onOpenClientMedications!(doses[i]),
              onEdit: onEdit == null ? null : () => onEdit!(doses[i]),
              administeredByName:
                  administeredByName?.call(doses[i]) ?? 'you',
            ),
            if (i != doses.length - 1)
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
          ],
        ],
      ],
    );
  }
}

class _EmptyRegistry extends StatelessWidget {
  final String message;

  const _EmptyRegistry({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
