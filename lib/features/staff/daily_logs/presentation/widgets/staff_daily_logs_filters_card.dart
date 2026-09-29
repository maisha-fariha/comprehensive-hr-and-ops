import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Web filter card: Residence *, Resident, From, To.
class StaffDailyLogsFiltersCard extends StatelessWidget {
  final String? residenceId;
  final String? clientId;
  final DateTime fromDate;
  final DateTime toDate;
  final List<({String id, String name})> residences;
  final List<({String id, String name})> residents;
  final ValueChanged<String?> onResidenceChanged;
  final ValueChanged<String?> onResidentChanged;
  final ValueChanged<DateTime> onFromChanged;
  final ValueChanged<DateTime> onToChanged;
  final String Function(DateTime) formatDate;

  const StaffDailyLogsFiltersCard({
    super.key,
    required this.residenceId,
    required this.clientId,
    required this.fromDate,
    required this.toDate,
    required this.residences,
    required this.residents,
    required this.onResidenceChanged,
    required this.onResidentChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final hasResidence = residenceId != null && residenceId!.isNotEmpty;
    final residenceItems = [
      for (final r in residences)
        DropdownMenuItem(value: r.id, child: Text(r.name)),
    ];
    final residentItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(value: null, child: Text('All residents')),
      for (final r in residents)
        DropdownMenuItem(value: r.id, child: Text(r.name)),
    ];
    final residenceValue =
        residenceItems.any((i) => i.value == residenceId) ? residenceId : null;
    final clientValue =
        residentItems.any((i) => i.value == clientId) ? clientId : null;

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            label: 'Residence',
            required: true,
            child: _DropdownShell(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Choose a residence'),
                  value: residenceValue,
                  items: residenceItems,
                  onChanged: onResidenceChanged,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _LabeledField(
            label: 'Resident',
            child: _DropdownShell(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  hint: Text(
                    hasResidence
                        ? 'All residents'
                        : 'Choose a residence first',
                  ),
                  value: hasResidence ? clientValue : null,
                  items: hasResidence ? residentItems : const [],
                  onChanged: hasResidence ? onResidentChanged : null,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'From',
                  child: _DateField(
                    label: formatDate(fromDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fromDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) onFromChanged(picked);
                    },
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: _LabeledField(
                  label: 'To',
                  child: _DateField(
                    label: formatDate(toDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: toDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) onToChanged(picked);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textHeading,
            ),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.criticalRed),
                ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
        child,
      ],
    );
  }
}

class _DropdownShell extends StatelessWidget {
  final Widget child;

  const _DropdownShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: child,
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.searchBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            const AppSvgIcon(
              AppAssets.navCalendar,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
