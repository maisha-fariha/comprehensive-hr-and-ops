import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_incident_options.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import 'incident_severity_style.dart';

/// Filters matching web Incident Reports:
/// Any Status, Any Severity, All Residences, Any Resident, date range, Clear.
class StaffIncidentsFiltersBar extends StatelessWidget {
  final IncidentStatus? statusFilter;
  final IncidentSeverity? severityFilter;
  final String? residenceFilterId;
  final String? clientFilterId;
  final List<StaffIncidentResidenceOption> residences;
  final List<StaffIncidentClientOption> clients;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<IncidentStatus?> onStatusChanged;
  final ValueChanged<IncidentSeverity?> onSeverityChanged;
  final ValueChanged<String?> onResidenceChanged;
  final ValueChanged<String?> onClientChanged;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearFilters;

  const StaffIncidentsFiltersBar({
    super.key,
    required this.statusFilter,
    required this.severityFilter,
    required this.residenceFilterId,
    required this.clientFilterId,
    required this.residences,
    required this.clients,
    required this.fromDate,
    required this.toDate,
    required this.onStatusChanged,
    required this.onSeverityChanged,
    required this.onResidenceChanged,
    required this.onClientChanged,
    required this.onPickDateRange,
    required this.onClearFilters,
  });

  String get _dateRangeLabel {
    if (fromDate == null && toDate == null) return 'Date range';
    final from = fromDate;
    final to = toDate;
    if (from != null && to != null) {
      return '${_shortDate(from)} – ${_shortDate(to)}';
    }
    if (from != null) return 'From ${_shortDate(from)}';
    return 'To ${_shortDate(to!)}';
  }

  static String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('staff-incidents-filters'),
      spacing: ResponsiveHelper.getResponsiveWidth(context, 8),
      runSpacing: ResponsiveHelper.getResponsiveHeight(context, 8),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterDropdown<IncidentStatus?>(
          value: statusFilter,
          hint: 'Any Status',
          items: const [
            DropdownMenuItem<IncidentStatus?>(
              value: null,
              child: Text('Any Status'),
            ),
            DropdownMenuItem(
              value: IncidentStatus.open,
              child: Text('Open'),
            ),
            DropdownMenuItem(
              value: IncidentStatus.inReview,
              child: Text('Investigating'),
            ),
            DropdownMenuItem(
              value: IncidentStatus.closed,
              child: Text('Closed'),
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
                child: Text(IncidentSeverityStyle.of(severity).shortLabel),
              ),
          ],
          onChanged: onSeverityChanged,
        ),
        _FilterDropdown<String?>(
          key: const Key('staff-incidents-filter-residence'),
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
          key: const Key('staff-incidents-filter-resident'),
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
        _DateRangeChip(
          label: _dateRangeLabel,
          isActive: fromDate != null || toDate != null,
          onTap: onPickDateRange,
        ),
        GestureDetector(
          key: const Key('staff-incidents-clear-filters'),
          onTap: onClearFilters,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 4,
              vertical: 8,
            ),
            child: Text(
              'Clear filters',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize:
                    ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.secondaryTeal,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
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
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);
    final hasValue = value != null;

    return Container(
      constraints: BoxConstraints(
        maxWidth: ResponsiveHelper.getResponsiveWidth(context, 180),
      ),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textHeading,
            ),
          ),
          isDense: true,
          isExpanded: true,
          borderRadius: BorderRadius.circular(radius),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: hasValue ? AppColors.secondaryTeal : AppColors.textHeading,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 18),
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
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DateRangeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isActive
                  ? AppColors.secondaryTeal.withValues(alpha: 0.45)
                  : AppColors.searchBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                AppAssets.navCalendar,
                size: 15,
                color: isActive
                    ? AppColors.secondaryTeal
                    : AppColors.textMuted,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: isActive
                      ? AppColors.secondaryTeal
                      : AppColors.textHeading,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
