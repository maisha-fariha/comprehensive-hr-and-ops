import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import '../controllers/admissions_controller.dart';
import 'admissions_common.dart';

Future<void> showAdmitReferralSheet(
  BuildContext context, {
  required AdmissionsController controller,
  required String referralId,
}) =>
    showAdmissionSheet<void>(
      context,
      AdmitReferralSheet(controller: controller, referralId: referralId),
    );

/// The web "Admit" modal: residence, room with a spare bed and care level.
class AdmitReferralSheet extends StatefulWidget {
  final AdmissionsController controller;
  final String referralId;

  const AdmitReferralSheet({
    super.key,
    required this.controller,
    required this.referralId,
  });

  @override
  State<AdmitReferralSheet> createState() => _AdmitReferralSheetState();
}

class _AdmitReferralSheetState extends State<AdmitReferralSheet> {
  static const _noRoom = '__none__';

  final _level = TextEditingController();
  Referral? _referral;
  bool _loading = true;
  String _residenceId = '';
  String? _roomId;
  List<AdmissionRoom>? _rooms;
  bool _roomsLoading = false;
  bool _saving = false;
  String? _error;

  AdmissionsController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _level.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _c.repository.referral(widget.referralId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _referral = result.when(success: (r) => r, failure: (_) => null);
    });
  }

  Future<void> _pickResidence(String id) async {
    setState(() {
      _residenceId = id;
      _roomId = null;
      _rooms = null;
    });
    if (!_c.canReadResidences) return;
    setState(() => _roomsLoading = true);
    final result = await _c.repository.rooms(id);
    if (!mounted || id != _residenceId) return;
    setState(() {
      _roomsLoading = false;
      _rooms = result.when(success: (r) => r, failure: (_) => const []);
    });
  }

  List<(String, String)> get _roomOptions => [
        (_noRoom, 'No room yet'),
        for (final room in _rooms ?? const <AdmissionRoom>[])
          if (room.isActive && room.available > 0)
            (
              room.id,
              '${room.name} — ${room.available} free'
                  '${room.roomType == null ? '' : ' (${room.roomType})'}',
            ),
      ];

  Future<void> _admit() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    final level = _level.text.trim();
    final error = await _c.admit(
      widget.referralId,
      residenceId: _residenceId,
      roomId: _roomId,
      level: level.isEmpty ? null : level,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  static Widget _withHint(String? hint, Widget child) =>
      hint == null ? child : Tooltip(message: hint, child: child);

  @override
  Widget build(BuildContext context) {
    final r = _referral;
    final closed = r != null && r.isClosed;
    final outstanding = r?.outstanding ?? const <IntakeChecklistItem>[];
    final rooms = _rooms ?? const <AdmissionRoom>[];
    final noRooms = !_roomsLoading && _rooms != null && rooms.isEmpty;
    final allFull =
        !_roomsLoading && rooms.isNotEmpty && _roomOptions.length == 1;
    final roomDisabled =
        closed || _residenceId.isEmpty || _roomsLoading || noRooms || _rooms == null;
    final canSubmit = !_saving &&
        !closed &&
        _c.canAdmit &&
        _residenceId.isNotEmpty &&
        outstanding.isEmpty;
    const gap = SizedBox(height: 14);
    return AdmissionSheetFrame(
      icon: Icons.assignment_turned_in_outlined,
      tall: false,
      title: r != null
          ? 'Admit ${r.fullName}'
          : _loading
              ? 'Loading…'
              : 'Admit',
      description:
          "Creates the resident record and closes the referral. Needs every required checklist item ticked, and counts against the plan's resident limit.",
      footer: [
        HandoverButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        _withHint(
          !_c.canAdmit
              ? 'Admitting creates a resident record, which needs clients:create'
              : outstanding.isNotEmpty
                  ? 'Required checklist items are outstanding'
                  : null,
          HandoverButton(
            key: const ValueKey('admit-submit'),
            label: _saving ? 'Admitting…' : 'Admit',
            icon: Icons.assignment_turned_in_outlined,
            filled: true,
            onPressed: canSubmit ? _admit : null,
          ),
        ),
      ],
      children: [
        if (closed) ...[
          const AdmissionNotice('This referral is already closed and cannot be admitted.'),
          gap,
        ],
        if (!closed && outstanding.isNotEmpty) ...[
          Text(
            'Admission is blocked until these are done: '
            '${outstanding.map((o) => o.label).join(', ')}',
            key: const ValueKey('admit-blocked'),
            style: handoverText(context, 12.5, color: AppColors.urgentAmber),
          ),
          gap,
        ],
        if (_error != null) ...[
          AdmissionErrorBanner(_error!, key: const ValueKey('admit-error')),
          gap,
        ],
        HandoverSelect(
          key: const ValueKey('admit-residence'),
          label: 'Residence',
          required: true,
          value: _c.residenceName(_residenceId.isEmpty ? null : _residenceId),
          placeholder: 'Which residence',
          onTap: closed
              ? null
              : () async {
                  final picked = await pickHandoverOption(
                    context,
                    title: 'Residence',
                    options: [for (final o in _c.residences) (o.id, o.label)],
                    selected: _residenceId,
                  );
                  if (picked != null && picked != _residenceId) {
                    await _pickResidence(picked);
                  }
                },
        ),
        gap,
        HandoverSelect(
          key: const ValueKey('admit-room'),
          label: 'Room',
          value: _residenceId.isEmpty
              ? null
              : _roomOptions
                  .where((o) => o.$1 == (_roomId ?? _noRoom))
                  .map((o) => o.$2)
                  .firstOrNull,
          placeholder: _residenceId.isEmpty ? 'Pick a residence first' : 'Which room',
          helper: _residenceId.isEmpty
              ? 'A room belongs to one home — pick the home first'
              : noRooms
                  ? 'This home has no rooms recorded yet — add them on the residence'
                  : allFull
                      ? 'Every room in this home is full'
                      : 'Only rooms with a bed going spare are listed',
          onTap: roomDisabled
              ? null
              : () async {
                  final picked = await pickHandoverOption(
                    context,
                    title: 'Room',
                    options: _roomOptions,
                    selected: _roomId ?? _noRoom,
                  );
                  if (picked != null) {
                    setState(() => _roomId = picked == _noRoom ? null : picked);
                  }
                },
        ),
        gap,
        AdmissionInput(
          key: const ValueKey('admit-level'),
          label: 'Care level',
          placeholder: 'Optional',
          controller: _level,
          enabled: !closed,
        ),
      ],
    );
  }
}
