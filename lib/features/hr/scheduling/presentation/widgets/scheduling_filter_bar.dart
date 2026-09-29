import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/shift_residence_option.dart';
import '../../scheduling_constants.dart';

/// Date-range chip ("28 Sep – 4 Oct"), "My shifts" toggle and "Filters"
/// button shown under the Schedule top bar.
class SchedulingFilterBar extends StatelessWidget {
  final DateTime weekOf;
  final int activeFilterCount;
  final VoidCallback onDateTap;
  final VoidCallback onFiltersTap;

  /// Hidden when null (no `scheduling:write`).
  final VoidCallback? onMineTap;
  final bool mineOnly;

  const SchedulingFilterBar({
    super.key,
    required this.weekOf,
    required this.activeFilterCount,
    required this.onDateTap,
    required this.onFiltersTap,
    this.onMineTap,
    this.mineOnly = false,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String rangeLabel(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    return '${weekStart.day} ${_months[weekStart.month - 1]} – '
        '${end.day} ${_months[end.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final active = activeFilterCount > 0;
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: SchedulingDimens.screenPaddingHorizontal,
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Pill(
              onTap: onDateTap,
              icon: Icons.calendar_today_rounded,
              label: rangeLabel(weekOf),
              trailing: Icons.keyboard_arrow_down_rounded,
            ),
          ),
          if (onMineTap != null) ...[
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Semantics(
              button: true,
              toggled: mineOnly,
              child: _Pill(
                key: const ValueKey('scheduling-my-shifts'),
                onTap: onMineTap!,
                label: 'My shifts',
                highlighted: mineOnly,
              ),
            ),
          ],
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          _Pill(
            onTap: onFiltersTap,
            icon: Icons.tune_rounded,
            label: active ? 'Filters ($activeFilterCount)' : 'Filters',
            highlighted: active,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final String label;
  final IconData? trailing;
  final bool highlighted;

  const _Pill({
    super.key,
    required this.onTap,
    this.icon,
    required this.label,
    this.trailing,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? AppColors.secondaryTeal : AppColors.textPrimary;
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
        color: fg,
      ),
    );
    return Material(
      color: highlighted
          ? AppColors.quickActionCreateShiftBg
          : AppColors.filterButtonBackground,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusChip),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusChip),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: ResponsiveHelper.getResponsiveSize(context, 16),
                  color: fg,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              ],
              if (trailing == null) text,
              if (trailing != null) ...[
                Expanded(child: text),
                Icon(
                  trailing,
                  size: ResponsiveHelper.getResponsiveSize(context, 18),
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Result of the Scheduling filters sheet. `null` fields mean "All".
class SchedulingFilterSelection {
  final String? residenceId;
  final ShiftStatusFilter? status;

  const SchedulingFilterSelection({this.residenceId, this.status});
}

/// Bottom sheet with the Home dropdown and Shift status chips.
Future<SchedulingFilterSelection?> showSchedulingFiltersSheet(
  BuildContext context, {
  required List<ShiftResidenceOption> residences,
  String? residenceId,
  ShiftStatusFilter? status,
}) {
  return showModalBottomSheet<SchedulingFilterSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FiltersSheet(
      residences: residences,
      residenceId: residenceId,
      status: status,
    ),
  );
}

class _FiltersSheet extends StatefulWidget {
  final List<ShiftResidenceOption> residences;
  final String? residenceId;
  final ShiftStatusFilter? status;

  const _FiltersSheet({
    required this.residences,
    this.residenceId,
    this.status,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _residenceId = widget.residences.any(
    (r) => r.id == widget.residenceId,
  )
      ? widget.residenceId
      : null;
  late ShiftStatusFilter? _status = widget.status;

  TextStyle _label(BuildContext context) => TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
        color: AppColors.textSecondary,
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 20,
          top: 16,
          bottom: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _residenceId = null;
                    _status = null;
                  }),
                  child: const Text('Reset'),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text('Home', style: _label(context)),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            DropdownButtonFormField<String?>(
              initialValue: _residenceId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.filterButtonBackground,
                contentPadding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All homes'),
                ),
                for (final r in widget.residences)
                  DropdownMenuItem<String?>(
                    value: r.id,
                    child: Text(r.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _residenceId = value),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
            Text('Shift status', style: _label(context)),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(context, null, 'All'),
                for (final s in ShiftStatusFilter.values)
                  _statusChip(context, s, s.label),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
            SizedBox(
              height: ResponsiveHelper.getResponsiveHeight(context, 48),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(
                  SchedulingFilterSelection(
                    residenceId: _residenceId,
                    status: _status,
                  ),
                ),
                child: const Text(
                  'Apply filters',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(
    BuildContext context,
    ShiftStatusFilter? value,
    String label,
  ) {
    final selected = _status == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _status = value),
      selectedColor: AppColors.secondaryTeal,
      backgroundColor: AppColors.filterButtonBackground,
      side: BorderSide.none,
      labelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }
}
