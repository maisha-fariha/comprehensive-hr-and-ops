import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/incident_client_option.dart';
import '../../domain/entities/incident_residence_option.dart';
import '../../domain/entities/incident_staff_option.dart';
import '../../domain/entities/incidents_enums.dart';

/// Compact web-parity Incident Reports filters.
///
/// All Incidents / Reported by Me, then a tight wrap of equal-height chips:
/// Any Status, Any Severity, All Residences, Any Resident, Any Investigator,
/// From, To, Clear filters.
class IncidentsFiltersBar extends StatelessWidget {
  final bool reportedByMe;
  final IncidentListStatus? statusFilter;
  final IncidentSeverity? severityFilter;
  final String? residenceFilterId;
  final String? clientFilterId;
  final String? investigatorFilterId;
  final List<IncidentResidenceOption> residences;
  final List<IncidentClientOption> clients;
  final List<IncidentStaffOption> investigators;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<bool> onReportedByMeChanged;
  final ValueChanged<IncidentListStatus?> onStatusChanged;
  final ValueChanged<IncidentSeverity?> onSeverityChanged;
  final ValueChanged<String?> onResidenceChanged;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onInvestigatorChanged;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;
  final VoidCallback onClearFilters;

  const IncidentsFiltersBar({
    super.key,
    required this.reportedByMe,
    required this.statusFilter,
    required this.severityFilter,
    required this.residenceFilterId,
    required this.clientFilterId,
    required this.investigatorFilterId,
    required this.residences,
    required this.clients,
    required this.investigators,
    required this.fromDate,
    required this.toDate,
    required this.onReportedByMeChanged,
    required this.onStatusChanged,
    required this.onSeverityChanged,
    required this.onResidenceChanged,
    required this.onClientChanged,
    required this.onInvestigatorChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onClearFilters,
  });

  static String _shortDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 6);
    final runGap = ResponsiveHelper.getResponsiveHeight(context, 6);

    return Column(
      key: const Key('hr-incidents-filters'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScopeToggle(
          reportedByMe: reportedByMe,
          onChanged: onReportedByMeChanged,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
        Wrap(
          spacing: gap,
          runSpacing: runGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _FilterDropdown<IncidentListStatus?>(
              value: statusFilter,
              hint: 'Any Status',
              items: [
                const DropdownMenuItem<IncidentListStatus?>(
                  value: null,
                  child: Text('Any Status'),
                ),
                for (final status in IncidentListStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
              ],
              onChanged: onStatusChanged,
            ),
            _FilterDropdown<IncidentSeverity?>(
              value: severityFilter,
              hint: 'Any Severity',
              items: [
                const DropdownMenuItem<IncidentSeverity?>(
                  value: null,
                  child: Text('Any Severity'),
                ),
                for (final severity in IncidentSeverity.values)
                  DropdownMenuItem(
                    value: severity,
                    child: Text(_severityLabel(severity)),
                  ),
              ],
              onChanged: onSeverityChanged,
            ),
            _FilterDropdown<String?>(
              key: const Key('hr-incidents-filter-residence'),
              value: residenceFilterId,
              hint: 'All Residences',
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Residences'),
                ),
                for (final residence in residences)
                  DropdownMenuItem(
                    value: residence.id,
                    child: Text(residence.name),
                  ),
              ],
              onChanged: onResidenceChanged,
            ),
            _FilterDropdown<String?>(
              key: const Key('hr-incidents-filter-resident'),
              value: clientFilterId,
              hint: 'Any Resident',
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Any Resident'),
                ),
                for (final client in clients)
                  DropdownMenuItem(
                    value: client.id,
                    child: Text(client.name),
                  ),
              ],
              onChanged: onClientChanged,
            ),
            _FilterDropdown<String?>(
              key: const Key('hr-incidents-filter-investigator'),
              value: investigatorFilterId,
              hint: 'Any Investigator',
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Any Investigator'),
                ),
                for (final staff in investigators)
                  DropdownMenuItem(
                    value: staff.id,
                    child: Text(staff.name),
                  ),
              ],
              onChanged: onInvestigatorChanged,
            ),
            _DateChip(
              label: fromDate == null ? 'dd/mm/yyyy' : _shortDate(fromDate!),
              isActive: fromDate != null,
              onTap: () => _pickSingleDate(
                context,
                initial: fromDate,
                onPicked: onFromChanged,
              ),
            ),
            _DateChip(
              label: toDate == null ? 'dd/mm/yyyy' : _shortDate(toDate!),
              isActive: toDate != null,
              onTap: () => _pickSingleDate(
                context,
                initial: toDate,
                onPicked: onToChanged,
              ),
            ),
            GestureDetector(
              key: const Key('hr-incidents-clear-filters'),
              onTap: onClearFilters,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 2,
                  vertical: 6,
                ),
                child: Text(
                  'Clear filters',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.secondaryTeal,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickSingleDate(
    BuildContext context, {
    required DateTime? initial,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked == null) return;
    onPicked(picked);
  }

  static String _severityLabel(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return 'Low';
      case IncidentSeverity.medium:
        return 'Medium';
      case IncidentSeverity.high:
        return 'High';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }
}

class _ScopeToggle extends StatelessWidget {
  final bool reportedByMe;
  final ValueChanged<bool> onChanged;

  const _ScopeToggle({
    required this.reportedByMe,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 10);

    return Container(
      key: const Key('hr-incidents-scope-toggle'),
      height: ResponsiveHelper.getResponsiveHeight(context, 36),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScopeChip(
              label: 'All Incidents',
              selected: !reportedByMe,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ScopeChip(
              label: 'Reported by Me',
              selected: reportedByMe,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 8),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: selected ? AppColors.secondaryTeal : AppColors.textMuted,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  const _FilterDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 10);
    final hasValue = value != null;
    final height = ResponsiveHelper.getResponsiveHeight(context, 36);

    return SizedBox(
      height: height,
      width: ResponsiveHelper.getResponsiveWidth(context, 148),
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.searchBorder),
        ),
        alignment: Alignment.center,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            isDense: true,
            borderRadius: BorderRadius.circular(radius),
            hint: Text(
              hint,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.textHeading,
              ),
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: hasValue ? AppColors.secondaryTeal : AppColors.textHeading,
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 16),
              color: AppColors.textMuted,
            ),
            items: items,
            onChanged: (next) {
              if (next != null || items.any((item) => item.value == null)) {
                onChanged(next as T);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 10);
    final height = ResponsiveHelper.getResponsiveHeight(context, 36);

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          width: ResponsiveHelper.getResponsiveWidth(context, 128),
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isActive
                  ? AppColors.secondaryTeal.withValues(alpha: 0.45)
                  : AppColors.searchBorder,
            ),
          ),
          child: Row(
            children: [
              AppSvgIcon(
                AppAssets.navCalendar,
                size: 14,
                color: isActive
                    ? AppColors.secondaryTeal
                    : AppColors.textMuted,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: isActive
                        ? AppColors.secondaryTeal
                        : AppColors.textMuted,
                    height: 1.1,
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
