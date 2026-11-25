import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/calendar_shift.dart';

/// Web month-cell dialog: "Wed 11 Nov · 3 shifts across 1 home", grouped by
/// residence, with Add shift, open (edit) and delete.
Future<void> showScheduleDaySheet({
  required BuildContext context,
  required DateTime date,
  required String title,
  required List<CalendarShift> shifts,
  required bool canWrite,
  String? initialResidenceId,
  required void Function(String? residenceId) onAdd,
  required void Function(CalendarShift shift) onEdit,
  required void Function(CalendarShift shift) onDelete,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => _DaySheet(
      title: title,
      shifts: shifts,
      canWrite: canWrite,
      initialResidenceId: initialResidenceId,
      onAdd: onAdd,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}

class _DaySheet extends StatefulWidget {
  final String title;
  final List<CalendarShift> shifts;
  final bool canWrite;
  final String? initialResidenceId;
  final void Function(String? residenceId) onAdd;
  final void Function(CalendarShift shift) onEdit;
  final void Function(CalendarShift shift) onDelete;

  const _DaySheet({
    required this.title,
    required this.shifts,
    required this.canWrite,
    required this.initialResidenceId,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  String? _home;

  @override
  void initState() {
    super.initState();
    _home = widget.initialResidenceId;
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, (String, List<CalendarShift>)>{};
    for (final s in widget.shifts) {
      final id = s.residenceId ?? '';
      final name = (s.residenceName?.trim().isNotEmpty ?? false)
          ? s.residenceName!
          : 'Home';
      groups.putIfAbsent(id, () => (name, <CalendarShift>[])).$2.add(s);
    }
    final ordered = groups.entries.toList()
      ..sort((a, b) => a.value.$1.compareTo(b.value.$1));
    final visible = _home == null
        ? ordered
        : ordered.where((e) => e.key == _home).toList();
    final total = widget.shifts.length;
    final shown = visible.fold<int>(0, (n, e) => n + e.value.$2.length);
    final subtitle = total == 0
        ? 'No shifts scheduled for this day'
        : _home != null
        ? '$shown shift${shown == 1 ? '' : 's'} scheduled'
        : '$total shift${total == 1 ? '' : 's'} across '
              '${ordered.length} home${ordered.length == 1 ? '' : 's'}';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.canWrite)
                  FilledButton.icon(
                    key: const ValueKey('day-sheet-add-shift'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAdd(_home);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add shift'),
                  ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          if (ordered.length > 1)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _chip('All Homes ($total)', _home == null, () {
                    setState(() => _home = null);
                  }),
                  for (final e in ordered)
                    _chip(
                      '${e.value.$1} (${e.value.$2.length})',
                      _home == e.key,
                      () => setState(() => _home = e.key),
                    ),
                ],
              ),
            ),
          Flexible(
            child: total == 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_busy_outlined,
                          size: 32,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No shifts scheduled',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'There are no shifts scheduled for any home on this day.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final entry in visible) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.apartment_outlined,
                              size: 15,
                              color: AppColors.secondaryTeal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value.$1,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value.$2.length} '
                              '${entry.value.$2.length == 1 ? 'shift' : 'shifts'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.cardBorder),
                        for (final s in entry.value.$2) _row(context, s),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: on,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryNavy,
      labelStyle: TextStyle(color: on ? Colors.white : AppColors.textSecondary),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    ),
  );

  Widget _row(BuildContext context, CalendarShift s) {
    final names = s.staffNames.where((n) => n.trim().isNotEmpty).toList();
    final who = names.join(', ');
    final title = s.title?.trim() ?? '';
    final initials = () {
      if (names.isEmpty) return '?';
      final p = names.first.trim().split(RegExp(r'\s+'));
      return ((p.first.isEmpty ? '' : p.first[0]) +
              (p.length > 1 ? p.last[0] : ''))
          .toUpperCase();
    }();
    final duration = WebFormat.durationHours(s.startsAt, s.endsAt);
    final (pillBg, pillFg) = switch (s.apiStatus.toLowerCase()) {
      'published' => (const Color(0xFFE5F5EC), const Color(0xFF1E8E5A)),
      'open' => (AppColors.criticalBackgroundSoft, AppColors.criticalRed),
      'draft' => (AppColors.urgentBackgroundSoft, AppColors.urgentAmber),
      _ => (AppColors.dividerLight, AppColors.textSecondary),
    };
    final whoText = who.isEmpty
        ? const Text(
            'Unassigned (Open shift)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.criticalRed,
              fontSize: 13,
            ),
          )
        : Text(
            who,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: title.isEmpty ? 13.5 : 12,
              fontWeight: title.isEmpty ? FontWeight.w600 : FontWeight.w400,
              color: title.isEmpty
                  ? AppColors.primaryNavy
                  : AppColors.textSecondary,
            ),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('day-sheet-shift-${s.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: widget.canWrite
            ? () {
                Navigator.of(context).pop();
                widget.onEdit(s);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    whoText,
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${WebFormat.time(s.startsAt)} – ${WebFormat.time(s.endsAt)}'
                    '${duration == null ? '' : ' ($duration)'}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: pillBg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          s.apiStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: pillFg,
                          ),
                        ),
                      ),
                      if (widget.canWrite)
                        InkWell(
                          key: ValueKey('day-sheet-delete-${s.id}'),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onDelete(s);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
