import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_shift.dart';
import '../../domain/entities/staff_shift_form_option.dart';
import '../controllers/staff_schedule_controller.dart';

/// Web "Request a swap" dialog: colleague, optional exchange, note.
Future<void> showStaffSwapRequestSheet(
  BuildContext context,
  StaffScheduleController controller,
  StaffShift shift,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _SwapRequestSheet(
      controller: controller,
      shift: shift,
    ),
  );
}

class _SwapRequestSheet extends StatefulWidget {
  final StaffScheduleController controller;
  final StaffShift shift;

  const _SwapRequestSheet({required this.controller, required this.shift});

  @override
  State<_SwapRequestSheet> createState() => _SwapRequestSheetState();
}

class _SwapRequestSheetState extends State<_SwapRequestSheet> {
  final _note = TextEditingController();
  List<StaffShiftStaffOption> _colleagues = const [];
  List<StaffColleagueShift> _exchanges = const [];
  String? _colleagueId;
  String? _exchangeId;
  bool _canSeeStaff = true;
  bool _loadingStaff = true;
  bool _loadingShifts = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadColleagues();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String? get _ownStaffId {
    if (!Get.isRegistered<UserSession>()) return null;
    return Get.find<UserSession>().staffId;
  }

  Future<void> _loadColleagues() async {
    final result = await widget.controller.repository.listColleagues(
      residenceId: widget.shift.residenceId,
    );
    if (!mounted) return;
    result.when(
      success: (people) {
        final taken = widget.shift.staffIds.toSet();
        final own = _ownStaffId;
        setState(() {
          _canSeeStaff = true;
          _loadingStaff = false;
          _colleagues = [
            for (final person in people)
              if (person.id != own && !taken.contains(person.id)) person,
          ];
        });
      },
      failure: (_) {
        setState(() {
          _canSeeStaff = false;
          _loadingStaff = false;
        });
      },
    );
  }

  Future<void> _selectColleague(String? id) async {
    setState(() {
      _colleagueId = id;
      _exchangeId = null;
      _exchanges = const [];
      _error = null;
    });
    if (id == null || id.isEmpty) return;
    setState(() => _loadingShifts = true);
    final result = await widget.controller.repository.listColleagueShifts(id);
    if (!mounted) return;
    result.when(
      success: (shifts) {
        setState(() {
          _loadingShifts = false;
          _exchanges = [
            for (final item in shifts)
              if (item.id != widget.shift.id) item,
          ];
        });
      },
      failure: (_) => setState(() => _loadingShifts = false),
    );
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final colleague = _colleagueId;
    final message = await widget.controller.submitSwapRequest(
      shiftId: widget.shift.id,
      targetStaffId: colleague,
      toShiftId: colleague == null ? null : _exchangeId,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!mounted) return;
    if (message != null) {
      setState(() {
        _sending = false;
        _error = message;
      });
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.show(
      colleague == null
          ? 'Cover requested — a manager will decide'
          : 'Swap requested — your colleague has been asked',
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final when = _whenLabel(widget.shift.startAt);
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Request a swap',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$when — ask a colleague to take it, or ask for cover.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.criticalBackgroundSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.criticalRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Who',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('Ask a colleague', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String?>(
                  initialValue: _colleagueId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Anyone — put it out for cover'),
                    ),
                    for (final person in _colleagues)
                      DropdownMenuItem<String?>(
                        value: person.id,
                        child: Text(
                          person.detail.trim().isEmpty
                              ? person.name
                              : '${person.name} · ${person.detail}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: !_canSeeStaff || _loadingStaff
                      ? null
                      : _selectColleague,
                ),
                const SizedBox(height: 4),
                Text(
                  _canSeeStaff
                      ? 'Leave empty and the shift goes out for bids once a manager approves.'
                      : 'You cannot see the staff list here — ask for cover instead and a manager will place it.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_colleagueId != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Take one of theirs in exchange',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('exchange-$_colleagueId'),
                    initialValue: _exchangeId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Nothing in exchange'),
                      ),
                      for (final item in _exchanges)
                        DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(item.label, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: _loadingShifts
                        ? null
                        : (value) => setState(() => _exchangeId = value),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Optional — leave empty to simply hand the shift over.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Note', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Why you need the swap…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _colleagueId == null
                          ? 'A manager decides. Nothing on the rota changes until they do.'
                          : 'Your colleague is asked first. If they agree, a manager still has to approve it before the rota changes.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _sending ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _sending ? null : _send,
                        child: Text(_sending ? 'Sending…' : 'Send request'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _whenLabel(DateTime? start) {
  if (start == null) return 'This shift';
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final day = start.day.toString().padLeft(2, '0');
  final month = start.month.toString().padLeft(2, '0');
  final hour = start.hour.toString().padLeft(2, '0');
  final minute = start.minute.toString().padLeft(2, '0');
  return '${days[start.weekday - 1]} $day/$month/${start.year} $hour:$minute';
}
