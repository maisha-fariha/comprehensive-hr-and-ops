import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/recurring_check.dart';
import '../controllers/recurring_checks_controller.dart';
import 'check_common.dart';

/// Web Assign popover: staff rostered when the occurrence falls due.
Future<void> showAssignInstanceSheet(
  BuildContext context, {
  required RecurringChecksController controller,
  required CheckInstance instance,
}) =>
    showCheckSheet<void>(
      context,
      (_) => _AssignInstanceSheet(controller: controller, instance: instance),
    );

class _AssignInstanceSheet extends StatefulWidget {
  final RecurringChecksController controller;
  final CheckInstance instance;

  const _AssignInstanceSheet({required this.controller, required this.instance});

  @override
  State<_AssignInstanceSheet> createState() => _AssignInstanceSheetState();
}

class _AssignInstanceSheetState extends State<_AssignInstanceSheet> {
  List<CheckAvailableStaff>? _staff;
  bool _applyToSchedule = false;
  String? _saving;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await widget.controller.repository.availableStaff(widget.instance.id);
    if (!mounted) return;
    setState(() => _staff = result.when(success: (s) => s, failure: (_) => const []));
  }

  Future<void> _assign(CheckAvailableStaff person) async {
    setState(() => _saving = person.staffId);
    final ok = await widget.controller.assignInstance(
      widget.instance,
      person,
      applyToSchedule: _applyToSchedule,
    );
    if (!mounted) return;
    setState(() => _saving = null);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final staff = _staff;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'On shift when this is due',
              style: handoverText(context, 15, weight: FontWeight.w600,
                  color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 8),
            InkWell(
              key: const ValueKey('assign-apply-future'),
              onTap: () => setState(() => _applyToSchedule = !_applyToSchedule),
              child: Row(
                children: [
                  Checkbox(
                    value: _applyToSchedule,
                    onChanged: (v) => setState(() => _applyToSchedule = v ?? false),
                  ),
                  Text(
                    'Also apply to future checks',
                    style: handoverText(context, 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (staff == null)
              for (var i = 0; i < 2; i++)
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.filterButtonBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
            else if (staff.isEmpty)
              Text(
                'Nobody is rostered at this home when the check falls due.',
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              )
            else
              for (final person in staff)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton(
                    key: ValueKey('assign-staff-${person.staffId}'),
                    onPressed: _saving != null ? null : () => _assign(person),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.searchBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            person.name,
                            overflow: TextOverflow.ellipsis,
                            style: handoverText(context, 13, weight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          person.shiftTitle ??
                              '${WebFormat.time(person.shiftStartsAt?.toLocal())}'
                                  '–${WebFormat.time(person.shiftEndsAt?.toLocal())}',
                          style: handoverText(context, 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Web "Who usually does this" popover on a schedule row.
Future<void> showScheduleWhoSheet(
  BuildContext context, {
  required RecurringChecksController controller,
  required CheckSchedule schedule,
}) =>
    showCheckSheet<void>(
      context,
      (_) => _ScheduleWhoSheet(controller: controller, schedule: schedule),
    );

class _ScheduleWhoSheet extends StatefulWidget {
  final RecurringChecksController controller;
  final CheckSchedule schedule;

  const _ScheduleWhoSheet({required this.controller, required this.schedule});

  @override
  State<_ScheduleWhoSheet> createState() => _ScheduleWhoSheetState();
}

class _ScheduleWhoSheetState extends State<_ScheduleWhoSheet> {
  List<CheckOption> _colleagues = const [];
  late final bool _allowed = widget.controller.canSeeColleagues;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (_allowed) _load();
  }

  Future<void> _load() async {
    final result = await widget.controller.repository.colleagues(widget.schedule.residenceId);
    if (!mounted) return;
    result.when(success: (c) => setState(() => _colleagues = c), failure: (_) {});
  }

  Future<void> _assign(CheckOption? person) async {
    setState(() => _saving = true);
    final ok = await widget.controller.assignSchedule(widget.schedule, person);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    final assigned = s.assignedStaffName ?? s.assignedRole;
    Widget option(Key key, IconData icon, String label, VoidCallback onTap, {Color? color}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: OutlinedButton.icon(
            key: key,
            onPressed: _saving ? null : onTap,
            icon: Icon(icon, size: 14, color: color ?? AppColors.textHeading),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: handoverText(context, 13, weight: FontWeight.w500, color: color ?? AppColors.textHeading),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.searchBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          children: [
            Text(
              'Who usually does this',
              style: handoverText(context, 15, weight: FontWeight.w600,
                  color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 10),
            if (!_allowed)
              Text(
                "You cannot see this home's staff list.",
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              )
            else if (_colleagues.isEmpty)
              for (var i = 0; i < 2; i++)
                Container(
                  height: 34,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.filterButtonBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
            else ...[
              if (assigned != null)
                option(const ValueKey('schedule-unassign'), Icons.close_rounded, 'Unassign',
                    () => _assign(null),
                    color: AppColors.criticalRed),
              for (final c in _colleagues)
                option(ValueKey('schedule-colleague-${c.id}'), Icons.person_add_alt_1_outlined,
                    c.label, () => _assign(c)),
            ],
          ],
        ),
      ),
    );
  }
}
