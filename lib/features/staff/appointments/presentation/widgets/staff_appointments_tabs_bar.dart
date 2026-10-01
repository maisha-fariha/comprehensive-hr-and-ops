import 'package:flutter/material.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_appointment.dart';

class StaffAppointmentsTabsBar extends StatelessWidget {
  final StaffAppointmentTab selected;
  final StaffAppointmentsSummary summary;
  final ValueChanged<StaffAppointmentTab> onChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const StaffAppointmentsTabsBar({
    super.key,
    required this.selected,
    required this.summary,
    required this.onChanged,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TabChip(
                label: 'Pending (${summary.pending})',
                selected: selected == StaffAppointmentTab.pending,
                onTap: () => onChanged(StaffAppointmentTab.pending),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Approved (${summary.approved})',
                selected: selected == StaffAppointmentTab.approved,
                onTap: () => onChanged(StaffAppointmentTab.approved),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Family visits',
                selected: selected == StaffAppointmentTab.familyVisits,
                onTap: () => onChanged(StaffAppointmentTab.familyVisits),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'External',
                selected: selected == StaffAppointmentTab.external,
                onTap: () => onChanged(StaffAppointmentTab.external),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Rejected (${summary.rejected})',
                selected: selected == StaffAppointmentTab.rejected,
                onTap: () => onChanged(StaffAppointmentTab.rejected),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'All (${summary.total})',
                selected: selected == StaffAppointmentTab.all,
                onTap: () => onChanged(StaffAppointmentTab.all),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: AppColors.textHeading,
          ),
          decoration: InputDecoration(
            hintText: 'Search requests...',
            hintStyle: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondaryTeal),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryNavy : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primaryNavy : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: selected ? Colors.white : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}
